defmodule Aurora.Uix.Integration.Ctx.FieldsParser do
  @moduledoc """
  Field metadata parser for Context-based (Ecto) schemas.

  Provides utilities for extracting and formatting field metadata from Ecto schemas,
  including type mapping, HTML input type generation, and field attribute determination.
  Handles associations, embeds, and standard Ecto field types.

  ## Key Features

  - Human-readable label generation from field names
  - Ecto type to HTML input type mapping
  - Field metadata extraction (length, precision, scale)
  - Association and embed handling
  - Default placeholder text generation
  - Field visibility and editability rules

  ## Key Constraints

  - Designed for Ecto schemas only
  - Assumes standard Ecto field types
  - Association metadata requires Ecto.Association structs
  - Embed metadata requires Ecto.Embedded structs
  """

  alias Aurora.Uix.Field
  alias Aurora.Uix.Helpers.Common, as: CommonHelpers
  alias Aurora.Uix.Integration.FieldsParser, as: CommonFieldsParser
  alias Aurora.Uix.Resource

  alias Ecto.Association.BelongsTo, as: AssociationBelongsTo
  alias Ecto.Association.Has, as: AssociationHas
  alias Ecto.Embedded

  @doc """
  Parses all fields from an Ecto schema into Field structs.

  Extracts field metadata from the schema and converts each field into a structured
  Field configuration with type information and display attributes.

  ## Parameters

  - `schema` (module() | nil) - The Ecto schema module to parse fields from.
  - `resource_name` (atom()) - The identifier for the resource.

  ## Returns

  list(Field.t()) - List of configured field structs, or empty list if schema is nil.
  """
  @spec parse_fields(module() | nil, atom()) :: list(Field.t())
  def parse_fields(nil, _resource_name), do: []

  def parse_fields(schema, resource_name) do
    Code.ensure_compiled(schema)

    if function_exported?(schema, :__schema__, 1) do
      :fields
      |> schema.__schema__()
      |> Enum.map(&parse_field(schema, resource_name, &1))
      |> List.flatten()
    else
      []
    end
  end

  @doc """
  Parses a single field from an Ecto schema into a Field struct.

  Generates a field configuration including display attributes, HTML input types,
  validation constraints, and association metadata.

  ## Parameters

  - `resource_schema` (module()) - The schema module for the resource.
  - `resource_name` (atom()) - The name of the resource this field belongs to.
  - `schema_field_key` (atom() | {atom(), atom()}) - The field identifier or tuple with type.

  ## Returns

  Field.t() - A fully configured field struct.
  """
  @spec parse_field(module(), atom(), atom() | {atom(), atom()}) :: Field.t()
  def parse_field(
        resource_schema,
        resource_name,
        schema_field_key
      ) do
    {field_key, ecto_type} =
      case schema_field_key do
        {field_key, ecto_type} -> {field_key, ecto_type}
        field_key -> {field_key, resource_schema.__schema__(:type, field_key)}
      end

    association_or_embed =
      resource_schema.__schema__(:association, field_key) ||
        resource_schema.__schema__(:embed, field_key)

    attribute = %{
      ecto_type: ecto_type,
      association_or_embed: association_or_embed
    }

    attrs =
      %{resource: resource_name, key: field_key}
      |> set(&field_type/2, :type, attribute)
      |> set(&field_html_type/2, :html_type, attribute)
      |> set(&field_label/2, :label, attribute)
      |> set(&field_placeholder/2, :placeholder, attribute)
      |> set(&field_length/2, :length, attribute)
      |> set(&field_precision/2, :precision, attribute)
      |> set(&field_scale/2, :scale, attribute)
      |> set(&field_disabled/2, :disabled, attribute)
      |> set(&field_omitted/2, :omitted, attribute)
      |> set(&field_hidden/2, :hidden, attribute)
      |> set(&field_filterable/2, :filterable?, attribute)
      |> set(&field_data/2, :data, attribute)

    Field.new(attrs)
  end

  @doc """
  Parses all associations from an Ecto schema.

  Iterates through schema associations and converts each into a Field struct with
  proper relationship metadata and type information.

  ## Parameters

  - `resource_schema` (module()) - The schema module containing associations.
  - `resource_name` (atom()) - The name of the resource.
  - `resources` (list(Resource.t())) - List of available resources for reference lookup.
  - `fields` (list(Field.t())) - Existing fields list to prepend associations to.

  ## Returns

  list(Field.t()) - Updated list with association fields added.
  """
  @spec parse_associations(module(), atom(), list(Resource.t()), list(Field.t())) ::
          list(Field.t())
  def parse_associations(resource_schema, resource_name, resources, fields) do
    :associations
    |> resource_schema.__schema__()
    |> Enum.reduce(
      Enum.reverse(fields),
      &parse_association(resource_schema, resource_name, resources, &1, &2)
    )
  end

  @doc """
  Processes embedded resources from an Ecto schema.

  Recursively discovers and configures embedded resources from the parent schema,
  creating new resource configurations for each embedded field found.

  ## Parameters

  - `parent_resource` ({atom(), module(), atom()}) - Tuple containing parent resource name,
  schema module, and type.
  - `result` (list(Resource.t())) - Accumulator list of resource configurations.

  ## Returns

  list(Resource.t()) - Updated list with embedded resource configurations added.

  ## Examples

      iex> embedded_resource({:users, MyApp.User, :ctx}, [])
      [%Resource{name: :users__profile, ...}]
  """
  @spec embedded_resource({atom(), module(), atom()}, list(Resource.t())) :: list(Resource.t())
  def embedded_resource({_parent_name, schema_module, _type} = parent_resource, result) do
    :embeds
    |> schema_module.__schema__()
    |> Enum.map(&schema_module.__schema__(:embed, &1))
    |> Enum.reduce(result, &embedded_resource_config(parent_resource, &1, &2))
  end

  ## PRIVATE

  # Converts a schema association into a Field struct.
  #
  # Extracts association metadata from the schema and creates a field configuration
  # with proper association type and relationship information.
  #
  # ## Parameters
  #
  # - `schema` (module()) - The schema module containing the association.
  # - `resource_name` (atom()) - The name of the resource.
  # - `resources` (list(Resource.t())) - List of available resources for reference lookup.
  # - `association_field_key` (atom()) - The association field identifier.
  # - `fields` (list(Field.t())) - Existing fields list to prepend to.
  #
  # ## Returns
  #
  # list(Field.t()) - Updated list with the association field added.
  @spec parse_association(module(), atom(), list(Resource.t()), atom(), list(Field.t())) ::
          list(Field.t())
  defp parse_association(
         resource_schema,
         resource_name,
         resources,
         association_field_key,
         fields
       ) do
    association = resource_schema.__schema__(:association, association_field_key)
    attribute = %{ecto_type: association}

    association_field =
      %{resource: resource_name, key: association_field_key, length: 0, filterable?: false}
      |> set(&field_type/2, :type, attribute)
      |> set(&field_html_type/2, :html_type, attribute)
      |> set(&field_data/2, :data, attribute)
      |> put_in([:data, :resource], field_resource(association, resources))
      |> Field.new()

    updated_fields = maybe_update_field_from_association(fields, association_field)

    [association_field | updated_fields]
  end

  # Maps an Elixir type to a field type, handling associations and embeds.
  @spec field_type(map(), map()) :: atom()
  defp field_type(_attrs, %{ecto_type: {:parameterized, {Ecto.Enum, %{}}}}), do: :string

  defp field_type(
         _attrs,
         %{ecto_type: {:parameterized, {Ecto.Embedded, %Ecto.Embedded{cardinality: :one}}}} =
           _embed
       ),
       do: :embeds_one

  defp field_type(
         _attrs,
         %{ecto_type: {:parameterized, {Ecto.Embedded, %Ecto.Embedded{cardinality: :many}}}} =
           _embed
       ),
       do: :embeds_many

  defp field_type(_attrs, %{ecto_type: %AssociationHas{cardinality: :many}} = _association),
    do: :one_to_many_association

  defp field_type(_attrs, %{ecto_type: %AssociationBelongsTo{cardinality: :one}} = _association),
    do: :many_to_one_association

  defp field_type(_attrs, %{ecto_type: :id}), do: :integer

  defp field_type(_attrs, %{ecto_type: ecto_type}), do: ecto_type

  # Maps an Elixir type to an HTML input type for form rendering.
  @spec field_html_type(map(), map()) :: atom()
  defp field_html_type(_attrs, %{ecto_type: {:parameterized, {Ecto.Enum, %{}}}}), do: :select

  defp field_html_type(%{type: type}, _attribute) when type in [:embeds_one, :embeds_many],
    do: :unimplemented

  defp field_html_type(_attrs, %{ecto_type: %AssociationHas{cardinality: :many}} = _association),
    do: :unimplemented

  defp field_html_type(
         _attrs,
         %{ecto_type: %AssociationBelongsTo{cardinality: :one}} = _association
       ),
       do: :unimplemented

  defp field_html_type(%{type: type}, _attribute)
       when type in [:string, :binary_id, :binary, :bitstring, :duration, Ecto.UUID],
       do: :text

  defp field_html_type(%{type: type}, _attribute) when type in [:id, :integer, :float, :decimal],
    do: :number

  defp field_html_type(%{type: type}, _attribute)
       when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
       do: :"datetime-local"

  defp field_html_type(%{type: type}, _attribute) when type in [:time, :time_usec], do: :time
  defp field_html_type(%{type: :select}, _attribute), do: :select

  defp field_html_type(%{type: :boolean}, _attribute), do: :checkbox
  defp field_html_type(%{type: type}, _attribute), do: type

  defp field_html_type(_type, _attribute), do: :unimplemented

  # Formats a display label from a field name, capitalizes and replaces underscores.
  @spec field_label(map(), map()) :: binary()
  defp field_label(%{key: name, resource: resource_name, type: type}, %{})
       when type in [:embeds_one, :embeds_many] do
    resource_name
    |> field_embedded_resource(name)
    |> CommonHelpers.capitalize()
  end

  defp field_label(%{key: name}, _attribute),
    do: CommonHelpers.capitalize(name)

  # Determines the default placeholder text for a field based on its type.
  @spec field_placeholder(map(), map()) :: binary()
  defp field_placeholder(_name, %{ecto_type: ecto_type})
       when ecto_type in [Ecto.UUID, :binary_id],
       do: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"

  defp field_placeholder(%{key: name}, %{ecto_type: ecto_type}),
    do: CommonFieldsParser.field_placeholder(name, ecto_type)

  # Determines the display length for a field based on its type.
  @spec field_length(map(), map()) :: integer()
  defp field_length(_attrs, %{ecto_type: {:parameterized, {Ecto.Enum, %{mappings: opts}}}}) do
    opts
    |> Enum.map(fn {_key, text} -> String.length(text) end)
    |> Enum.max()
  end

  defp field_length(_attrs, %{ecto_type: ecto_type}) when ecto_type in [Ecto.UUID, :binary_id],
    do: 36

  defp field_length(_attrs, %{ecto_type: ecto_type}),
    do: CommonFieldsParser.field_length(ecto_type)

  # Gets the numeric precision for number fields.
  @spec field_precision(map(), map()) :: integer()
  defp field_precision(_attrs, %{ecto_type: ecto_type}) when ecto_type in [Ecto.UUID, :binary_id],
    do: 0

  defp field_precision(_attrs, %{ecto_type: ecto_type}),
    do: CommonFieldsParser.field_precision(ecto_type)

  # Gets the numeric scale for decimal/float fields
  @spec field_scale(map(), map()) :: integer()
  defp field_scale(_attrs, %{ecto_type: ecto_type}), do: CommonFieldsParser.field_scale(ecto_type)

  # Checks if a field should be disabled by default
  @spec field_disabled(map(), map()) :: boolean()
  defp field_disabled(%{key: key}, _attribute), do: CommonFieldsParser.field_disabled(key)

  # Checks if a field should be omitted from forms
  @spec field_omitted(map(), map()) :: boolean()
  defp field_omitted(%{key: key}, _attribute), do: CommonFieldsParser.field_omitted(key)

  # Determines if a field should be hidden from display
  @spec field_hidden(map(), map()) :: boolean()
  defp field_hidden(%{key: key}, _attribute), do: CommonFieldsParser.field_hidden(key)

  # Determines if a field should be filterable in queries
  @spec field_filterable(map(), map()) :: boolean()
  defp field_filterable(_attrs, %{ecto_type: ecto_type}),
    do: CommonFieldsParser.field_filterable(ecto_type)

  # Extracts metadata for association fields including type-specific configuration.
  @spec field_data(map(), map()) :: map()
  defp field_data(_attrs, %{ecto_type: {:parameterized, {Ecto.Enum, %{mappings: opts}}}}) do
    opts = Enum.map(opts, fn {key, text} -> {field_label(%{key: text}, %{}), key} end)
    %{select: %{opts: opts, multiple: false}}
  end

  defp field_data(%{resource: resource_name}, %{
         ecto_type: {:parameterized, {Ecto.Embedded, %Ecto.Embedded{} = embedded}}
       }) do
    %{
      related: embedded.related,
      owner: embedded.owner,
      resource: field_embedded_resource(resource_name, embedded)
    }
  end

  defp field_data(_attrs, %{ecto_type: %{} = association}),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  defp field_data(%{type: type}, _attribute)
       when type in [:time_usec, :naive_datetime_usec, :utc_datetime_usec], do: %{step: 1}

  defp field_data(_attrs, _attribute), do: %{}

  # Generates a unique resource identifier for embedded fields
  @spec field_embedded_resource(atom(), map() | atom()) :: atom()
  defp field_embedded_resource(parent_resource_name, %Embedded{field: field}),
    do: field_embedded_resource(parent_resource_name, field)

  defp field_embedded_resource(parent_resource_name, field) do
    String.to_atom("#{parent_resource_name}__#{field}")
  end

  # Finds matching resource for an association by comparing schema modules.
  @spec field_resource(map(), list()) :: map() | nil
  defp field_resource(association, resources) do
    resources
    |> Enum.find({nil, nil}, fn {_resource_name, resource} ->
      resource.schema == association.related
    end)
    |> elem(0)
  end

  # Creates a resource configuration for an embedded field.
  @spec embedded_resource_config({atom(), module(), atom()}, map(), list(Resource.t())) ::
          list(Resource.t())
  defp embedded_resource_config(
         {parent_resource_name, schema_module, type},
         %Embedded{field: field, related: embed_schema},
         result
       ) do
    resource_name = field_embedded_resource(parent_resource_name, field)

    [
      Resource.new(
        name: resource_name,
        type: type,
        tag: :resource,
        opts: [related_schema: schema_module, schema: embed_schema]
      )
      | result
    ]
  end

  # Updates field type based on association metadata for foreign keys.
  @spec maybe_update_field_from_association(list(Field.t()), Field.t()) :: list(Field.t())
  defp maybe_update_field_from_association(
         fields,
         %{
           type: :many_to_one_association,
           data: %{related_key: related_key, related: related_schema} = data
         }
       ) do
    attribute = %{ecto_type: related_schema.__schema__(:type, related_key)}

    changes =
      %{}
      |> set(&field_type/2, :type, attribute)
      |> set(&field_html_type/2, :html_type, attribute)
      |> set(&field_placeholder/2, :placeholder, attribute)
      |> set(&field_length/2, :length, attribute)
      |> set(&field_precision/2, :precision, attribute)

    Enum.map(fields, &update_field_type(&1, data, changes))
  end

  defp maybe_update_field_from_association(fields, _data), do: fields

  # Merges type changes into a field if it matches the owner key.
  @spec update_field_type(Field.t(), map(), map()) :: Field.t()
  defp update_field_type(%{key: field_key} = field, %{owner_key: key_to_update}, changes)
       when field_key == key_to_update, do: Map.merge(field, changes)

  defp update_field_type(field, _data, _changes), do: field

  # Applies a function to attrs and attribute, storing result in attrs at attr_key.
  @spec set(map(), function(), atom(), map()) :: map()
  defp set(attrs, function, attr_key, attribute) do
    attrs
    |> function.(attribute)
    |> then(&Map.put(attrs, attr_key, &1))
  end
end
