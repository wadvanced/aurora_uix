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

  # Parses schema fields into Field structs with metadata.
  # Returns empty list if schema isn't available or compiled.
  @spec parse_fields(module() | nil, atom()) :: list()
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
    |> IO.inspect(label: "********* attrs", limit: :infinity)
  end

  @doc """
  Parses field metadata from an Elixir type and association information.

  Generates a field configuration including display attributes, HTML input types,
  validation constraints, and association metadata.

  ## Parameters
  - `resource_schema` (module()) - The schema module for the resource.
  - `field_key` (atom()) - The field identifier.
  - `type` (atom()) - The Elixir type (e.g., `:string`, `:integer`).
  - `resource_name` (atom()) - The name of the resource this field belongs to.
  - `association_or_embed` (map() | nil) - Association metadata with cardinality information.

  ## Returns
  Field.t() - A fully configured field struct.
  """
  @spec parse_field(module(), atom(), atom()) :: Field.t()
  def parse_field(
        resource_schema,
        resource_name,
        schema_field_key
      ) do
    {field_key, type} =
      case schema_field_key do
        {field_key, type} -> {field_key, type}
        field_key -> {field_key, resource_schema.__schema__(:type, field_key)}
      end

    association_or_embed =
      resource_schema.__schema__(:association, field_key) ||
        resource_schema.__schema__(:embed, field_key)

    attrs =
      %{
        key: field_key,
        type: field_type(type, association_or_embed),
        html_type: field_html_type(type, association_or_embed),
        label: field_label(field_key, resource_name, association_or_embed),
        placeholder: field_placeholder(field_key, type),
        length: field_length(type),
        precision: field_precision(type),
        scale: field_scale(type),
        disabled: field_disabled(field_key),
        omitted: field_omitted(field_key),
        hidden: field_hidden(field_key),
        filterable?: field_filterable(type),
        resource: resource_name,
        data:
          field_data(
            resource_schema,
            field_key,
            association_or_embed,
            resource_name,
            type
          )
      }

    Field.new(attrs)
  end

  def parse_associations(resource_schema, resource_name, resources, fields) do
    :associations
    |> resource_schema.__schema__()
    |> Enum.reduce(
      Enum.reverse(fields),
      &parse_association(resource_schema, resource_name, resources, &1, &2)
    )
  end

  @doc """
  Converts a schema association into a Field struct.

  Extracts association metadata from the schema and creates a field configuration
  with proper association type and relationship information.

  ## Parameters

  - `schema` (module()) - The schema module containing the association.
  - `resource_name` (atom()) - The name of the resource.
  - `resources` (list()) - List of available resources for reference lookup.
  - `association_field_key` (atom()) - The association field identifier.
  - `fields` (map()) - Existing fields map to append to.

  ## Returns

  list() - Updated list with the association field added.
  """
  @spec parse_association(module(), atom(), list(Resource.t()), atom(), map()) ::
          list(Resource.t())
  def parse_association(
        schema,
        resource_name,
        resources,
        association_field_key,
        fields
      ) do
    :association
    |> schema.__schema__(association_field_key)
    |> then(
      &Field.new(
        key: association_field_key,
        html_type: field_html_type(nil, &1),
        type: field_type(nil, &1),
        data:
          Map.put(
            field_data(schema, association_field_key, &1),
            :resource,
            field_resource(&1, resources)
          ),
        resource: resource_name
      )
    )
    |> then(&[&1 | fields])
  end

  @doc """
  Processes embedded resources from an Ecto schema.

  Recursively discovers and configures embedded resources from the parent schema,
  creating new resource configurations for each embedded field found.

  ## Parameters

  - `parent_resource` (tuple()) - Tuple containing parent resource name, schema module,
  and type.
  - `result` (list()) - Accumulator list of resource configurations.

  ## Returns

  list() - Updated list with embedded resource configurations added.

  ## Examples

      iex> embedded_resource({:users, MyApp.User, :ctx}, [])
      [%Resource{name: :users__profile, ...}]
  """
  @spec embedded_resource(tuple(), list()) :: list()
  def embedded_resource({_parent_name, schema_module, _type} = parent_resource, result) do
    :embeds
    |> schema_module.__schema__()
    |> Enum.map(&schema_module.__schema__(:embed, &1))
    |> Enum.reduce(result, &embedded_resource_config(parent_resource, &1, &2))
  end

  ## PRIVATE

  # Maps an Elixir type to a field type, handling associations
  @spec field_type(atom(), map() | nil) :: atom()
  defp field_type({:parameterized, {Ecto.Enum, %{}}}, _association_or_embed), do: :string

  defp field_type(_type, %Embedded{cardinality: :one} = _embed), do: :embeds_one

  defp field_type(_type, %Embedded{cardinality: :many} = _embed), do: :embeds_many

  defp field_type(:id, nil), do: :integer

  defp field_type(type, nil), do: type

  defp field_type(nil, %AssociationHas{cardinality: :many} = _association),
    do: :one_to_many_association

  defp field_type(nil, %AssociationBelongsTo{cardinality: :one} = _association),
    do: :many_to_one_association

  # Maps an Elixir type to an HTML input type
  @spec field_html_type(atom(), map() | nil) :: atom()
  defp field_html_type({:parameterized, {Ecto.Enum, %{}}}, _association_or_embed), do: :select

  defp field_html_type(nil, %Embedded{cardinality: :one} = _embed), do: :embeds_one

  defp field_html_type(nil, %Embedded{cardinality: :many} = _embed), do: :embeds_many

  defp field_html_type(type, association),
    do: CommonFieldsParser.field_html_type(type, association)

  # Formats a display label from a field name - capitalizes and replaces underscores
  @spec field_label(atom() | nil, atom() | nil, map() | nil) :: binary()
  defp field_label(name, resource_name \\ nil, association_or_embed \\ nil)

  defp field_label(name, resource_name, %Embedded{}) do
    resource_name
    |> field_embedded_resource(name)
    |> CommonHelpers.capitalize()
  end

  defp field_label(name, resource_name, association_or_embed),
    do: CommonFieldsParser.field_label(name, resource_name, association_or_embed)

  # Determines the default placeholder text for a field based on its type
  @spec field_placeholder(atom(), atom()) :: binary()
  defp field_placeholder(name, type), do: CommonFieldsParser.field_placeholder(name, type)

  # Determines the display length for a field based on its type
  @spec field_length(atom()) :: integer()
  defp field_length(Ecto.UUID), do: 34

  defp field_length({:parameterized, {Ecto.Enum, %{mappings: opts}}}) do
    opts
    |> Enum.map(fn {_key, text} -> String.length(text) end)
    |> Enum.max()
  end

  defp field_length(type), do: CommonFieldsParser.field_length(type)

  # Gets the numeric precision for number fields
  @spec field_precision(atom()) :: integer()
  defp field_precision(type), do: CommonFieldsParser.field_precision(type)

  # Gets the numeric scale for decimal/float fields
  @spec field_scale(atom()) :: integer()
  defp field_scale(type), do: CommonFieldsParser.field_scale(type)

  # Checks if a field should be disabled by default
  @spec field_disabled(atom()) :: boolean()
  defp field_disabled(key), do: CommonFieldsParser.field_disabled(key)

  # Checks if a field should be omitted from forms
  @spec field_omitted(atom()) :: boolean()
  defp field_omitted(key), do: CommonFieldsParser.field_omitted(key)

  # Determines if a field should be hidden from display
  @spec field_hidden(atom()) :: boolean()
  defp field_hidden(key), do: CommonFieldsParser.field_hidden(key)

  # Determines if a field should be filterable in queries
  @spec field_filterable(atom()) :: boolean()
  defp field_filterable(type), do: CommonFieldsParser.field_filterable(type)

  # Extracts metadata for association fields
  @spec field_data(module(), atom(), map() | nil, atom(), atom()) :: map()
  defp field_data(
         _resource_schema,
         _field_key,
         association_or_embed,
         resource_name \\ nil,
         type \\ nil
       )

  defp field_data(
         _resource_schema,
         _field_key,
         _association_or_embed,
         _resource_name,
         {:parameterized, {Ecto.Enum, %{mappings: opts}}}
       ) do
    opts = Enum.map(opts, fn {key, text} -> {field_label(text), key} end)
    %{select: %{opts: opts, multiple: false}}
  end

  defp field_data(_resource_schema, _field_key, %Embedded{} = embedded, resource_name, _type) do
    %{
      related: embedded.related,
      owner: embedded.owner,
      resource: field_embedded_resource(resource_name, embedded)
    }
  end

  defp field_data(_resource_schema, _field_key, %{} = association, _resource_name, _type),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  defp field_data(resource_schema, field_key, association_or_embed, resource_name, type),
    do:
      CommonFieldsParser.field_data(
        resource_schema,
        field_key,
        association_or_embed,
        resource_name,
        type
      )

  # Generates a unique resource identifier for embedded fields
  @spec field_embedded_resource(atom(), map() | atom()) :: atom()
  defp field_embedded_resource(parent_resource_name, %Embedded{field: field}),
    do: field_embedded_resource(parent_resource_name, field)

  defp field_embedded_resource(parent_resource_name, field) do
    String.to_atom("#{parent_resource_name}__#{field}")
  end

  # Finds matching resource for an association
  # Returns resource name if found, nil if not
  @spec field_resource(map() | nil, list()) :: atom() | nil
  defp field_resource(nil, _resources), do: nil

  defp field_resource(association, resources) do
    resources
    |> Enum.find({nil, nil}, fn {_resource_name, resource} ->
      resource.schema == association.related
    end)
    |> elem(0)
  end

  @spec embedded_resource_config(tuple(), map(), list()) :: list()
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
end
