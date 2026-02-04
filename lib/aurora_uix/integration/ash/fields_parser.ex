defmodule Aurora.Uix.Integration.Ash.FieldsParser do
  @moduledoc """
  Helper functions for converting Ash Framework types to Ecto types.

  Facilitates type mapping between Ash resources and Ecto schemas, enabling proper field
  type resolution for layout and form generation.

  ## Key Features

  - Comprehensive mapping of Ash types to Ecto-compatible types
  - Support for both parameterized Ash types and their EctoType variants
  - Fallback handling for unknown or custom types
  - Direct passthrough for native Ecto types
  - HTML5 input type mapping for form generation
  - Field metadata extraction for select/enum types

  ## Key Constraints

  - Only handles parameterized Ash types in tuple format `{:parameterized, {type, opts}}`
  - Unknown parameterized types default to `:string`
  - Requires Ash Framework type structure
  """

  alias Ash.Resource.Info, as: AshResourceInfo

  alias Aurora.Uix.Field
  alias Aurora.Uix.Helpers.Common, as: CommonHelpers
  alias Aurora.Uix.Integration.FieldsParser, as: CommonFieldsParser
  alias Aurora.Uix.Resource

  alias Ecto.Association.BelongsTo, as: AssociationBelongsTo
  alias Ecto.Association.Has, as: AssociationHas

  @on_test [:embeds_one, :embeds_many]

  # Parses schema fields into Field structs with metadata.
  # Returns empty list if schema isn't available or compiled.
  @spec parse_fields(module() | nil, atom()) :: list()
  def parse_fields(nil, _resource_name), do: []

  def parse_fields(resource_schema, resource_name) do
    Code.ensure_compiled(resource_schema)

    attributes =
      resource_schema
      |> Ash.Resource.Info.attributes()
      |> Map.new(&{&1.name, &1})

    attributes
    |> Map.keys()
    |> Enum.map(&parse_field(resource_schema, resource_name, &1, attributes))
    |> List.flatten()

    # |> IO.inspect(label: "********* attrs", limit: :infinity)
  end

  @doc """
  Parses field metadata from an Elixir type and association information.

  Generates a field configuration including display attributes, HTML input types,
  validation constraints, and association metadata.

  ## Parameters
  - `resource_schema` (module()) - The schema module for the resource.
  - `resource_name` (atom()) - The name of the resource this field belongs to.
  - `field_key` (atom()) - The field identifier.
  - `attributes` (map()) - List of attributes and theirs specification.
  - `associations` (map()) - List of relationships with their configuration.

  ## Returns
  Field.t() - A fully configured field struct.
  """
  @spec parse_field(module(), atom(), atom(), map(), map()) :: Field.t()
  def parse_field(
        resource_schema,
        resource_name,
        schema_field_key,
        attributes \\ %{},
        associations \\ %{}
      ) do
    {field_key, type} =
      case schema_field_key do
        {field_key, type} ->
          {field_key, type}

        field_key ->
          {field_key, get_in(attributes, [field_key, Access.key!(:type)]) || :undefined}
      end

    association_or_embed = Ash.Resource.Info.relationship(resource_schema, field_key)

    embedded? = embedded_resource?(type)

    attribute =
      attributes
      |> Map.get(field_key, %{})
      |> Map.from_struct()
      |> Map.merge(%{
        resource_schema: resource_schema,
        embedded?: embedded?,
        association_or_embed: association_or_embed
      })

    if field_key in @on_test do
      IO.inspect(attribute,
        label: "********** attribute for #{field_key}",
        limit: :infinity
      )
    end

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

    if field_key in @on_test do
      IO.inspect(attrs, label: "************ attrs for: #{field_key}", limit: :infinity)
    end

    Field.new(attrs)
  end

  def parse_associations(resource_schema, resource_name, resources, fields) do
    associations =
      resource_schema
      |> Ash.Resource.Info.relationships()
      |> Map.new(&{&1.name, &1})
      |> IO.inspect(label: "********** associations")

    associations
    |> Enum.reduce(
      Enum.reverse(fields),
      &parse_association(resource_schema, resource_name, resources, &1, &2)
    )
    |> Enum.reverse()
  end

  @doc """
  Converts a schema association into a Field struct.

  Extracts association metadata from the schema and creates a field configuration
  with proper association type and relationship information.

  ## Parameters

  - `schema` (module()) - The schema module containing the association.
  - `resource_name` (atom()) - The name of the resource.
  - `resources` (list()) - List of available resources for reference lookup.
  - `association` (atom()) - The association to be processed.
  - `fields` (map()) - Existing fields map to append to.

  ## Returns

  list() - Updated list with the association field added.
  """
  @spec parse_association(module(), atom(), list(), map(), map()) ::
          list(Resource.t())
  def parse_association(
        schema,
        resource_name,
        resources,
        association,
        fields
      ) do
    association
    |> then(
      &Field.new(
        key: association.name,
        type: field_type(nil, &1),
        html_type: field_html_type(nil, &1),
        data:
          Map.put(
            field_data(%{resource_schema: schema, key: association.name}, &1),
            :resource,
            field_resource(&1, resources)
          ),
        resource: resource_name
      )
    )
    |> then(&[&1 | fields])
  end

  @doc """
  Processes embedded resources from an Ash resource schema.

  Recursively discovers and configures embedded resources from the parent resource,
  creating new resource configurations for each embedded field found.

  ## Parameters

  - `parent_resource` (tuple()) - Tuple containing parent resource name, schema module,
  and type.
  - `result` (list()) - Accumulator list of resource configurations.

  ## Returns

  list() - Updated list with embedded resource configurations added.

  ## Examples

      iex> embedded_resource({:users, MyApp.User, :ash}, [])
      [%Resource{name: :users__profile, ...}]
  """
  @spec embedded_resource(tuple(), list()) :: list()
  def embedded_resource({_parent_name, schema_module, _type} = parent_resource, result) do
    schema_module
    |> AshResourceInfo.attributes()
    |> Enum.filter(&embedded_resource?/1)
    |> Enum.reduce(result, &embedded_resource_config(parent_resource, &1, &2))
  end

  ## PRIVATE

  # Converts an Ash type to its corresponding Ecto type
  @spec field_type(map(), map()) :: map()
  defp field_type(_attrs, %{type: type})
       when type in [
              Ash.Type.Atom,
              Ash.Type.Atom.EctoType,
              Ash.Type.String,
              Ash.Type.String.EctoType,
              Ash.Type.CiString,
              Ash.Type.CiString.EctoType,
              Ash.Type.DurationName,
              Ash.Type.DurationName.EctoType,
              Ash.Type.Enum,
              Ash.Type.Enum.EctoType
            ],
       do: :string

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.UUID, Ash.Type.UUID.EctoType],
       do: :binary_id

  defp field_type(_attrs, %{type: type})
       when type in [
              Ash.Type.Integer,
              Ash.Type.Integer.EctoType
            ],
       do: :integer

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.Float, Ash.Type.Float.EctoType],
       do: :float

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.Decimal, Ash.Type.Decimal.EctoType],
       do: :decimal

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType],
       do: :boolean

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.Date, Ash.Type.Date.EctoType],
       do: :date

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.TimeUsec, Ash.Type.TimeUsec.EctoType],
       do: :time_usec

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.Time, Ash.Type.Time.EctoType],
       do: :time

  defp field_type(_attrs, %{type: type})
       when type in [
              Ash.Type.DateTime,
              Ash.Type.DateTime.EctoType,
              Ash.Type.UtcDatetime,
              Ash.Type.UtcDatetime.EctoType
            ],
       do: :utc_datetime

  defp field_type(_attrs, %{type: type})
       when type in [
              Ash.Type.UtcDatetimeUsec,
              Ash.Type.UtcDatetimeUsec.EctoType
            ],
       do: :utc_datetime_usec

  defp field_type(_attrs, %{type: type})
       when type in [
              Ash.Type.NaiveDatetime,
              Ash.Type.NaiveDatetime.EctoType
            ],
       do: :naive_datetime

  defp field_type(_attrs, %{type: type})
       when type in [Ash.Type.Binary, Ash.Type.Binary.EctoType],
       do: :binary

  defp field_type(_attrs, %{type: type})
       when type in [
              Ash.Type.UrlEncodedBinary,
              Ash.Type.UrlEncodedBinary.EctoType
            ],
       do: :binary

  defp field_type(_attrs, %{type: type})
       when type in [
              Ash.Type.Map,
              Ash.Type.Map.EctoType,
              Ash.Type.Keyword,
              Ash.Type.Keyword.EctoType,
              Ash.Type.Term,
              Ash.Type.Term.EctoType,
              Ash.Type.Tuple,
              Ash.Type.Tuple.EctoType,
              Ash.Type.Struct,
              Ash.Type.Struct.EctoType,
              Ash.Type.Union,
              Ash.Type.Union.EctoType
            ],
       do: :map

  defp field_type(_attrs, %{type: Ash.Type.Duration}), do: :duration

  # Fallback for other parameterized types
  defp field_type(_attrs, %{type: {:array, _type}, embedded?: true}), do: :embeds_many

  defp field_type(_attrs, %{embedded?: true}), do: :embeds_one

  # Direct type passthrough
  defp field_type(_attrs, %{type: type}), do: type

  # Maps an Ash type to an HTML input type
  @spec field_html_type(map(), map()) :: atom()
  defp field_html_type(attrs, attribute \\ %{})

  defp field_html_type(_attrs, %{
         type: resource_type,
         constraints: constraints
       })
       when resource_type in [Ash.Type.Atom, Ash.Type.Atom.EctoType] do
    if Keyword.has_key?(constraints, :one_of), do: :select, else: :string
  end

  defp field_html_type(_attrs, %{embedded?: true}), do: :unimplemented

  defp field_html_type(%{type: ecto_type}, %{association_or_embed: association_or_embed}),
    do: CommonFieldsParser.field_html_type(ecto_type, association_or_embed)

  # Formats a display label from a field name - capitalizes and replaces underscores
  @spec field_label(map(), map()) :: binary()
  defp field_label(%{key: name, resource: resource_name}, %{embedded?: true}) do
    resource_name
    |> field_embedded_resource(name)
    |> CommonHelpers.capitalize()
  end

  defp field_label(%{key: name, resource: resource_name}, %{
         association_or_embed: association_or_embed
       }),
       do: CommonFieldsParser.field_label(name, resource_name, association_or_embed)

  # Determines default placeholder text for a field based on its type
  @spec field_placeholder(map(), map()) :: binary()
  defp field_placeholder(%{html_type: :select}, _attribute), do: ""

  defp field_placeholder(%{key: name, type: ecto_type}, _attribute),
    do: CommonFieldsParser.field_placeholder(name, ecto_type)

  # Determines the display length for an Ash field based on its type
  @spec field_length(map(), map()) :: integer()
  defp field_length(%{type: ecto_type}, %{type: resource_type, constraints: constraints})
       when resource_type in [
              Ash.Type.Atom,
              Ash.Type.Atom.EctoType,
              Ash.Type.String,
              Ash.Type.String.EctoType,
              Ash.Type.Enum,
              Ash.Type.Enum.EctoType
            ] do
    if Keyword.has_key?(constraints, :one_of) do
      constraints[:one_of]
      |> Enum.map(&(&1 |> to_string() |> String.length()))
      |> Enum.max()
    else
      CommonFieldsParser.field_length(ecto_type)
    end
  end

  defp field_length(%{type: ecto_type}, _attribute),
    do: CommonFieldsParser.field_length(ecto_type)

  # Gets the numeric precision for Ash number fields

  @spec field_precision(map(), map()) :: integer()
  defp field_precision(%{type: ecto_type}, _attribute),
    do: CommonFieldsParser.field_precision(ecto_type)

  @spec field_scale(map(), map()) :: integer()
  defp field_scale(%{type: ecto_type}, _attribute), do: CommonFieldsParser.field_scale(ecto_type)

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
  defp field_filterable(%{type: ecto_type}, _attribute),
    do: CommonFieldsParser.field_filterable(ecto_type)

  # Extracts metadata for Ash field types
  @spec field_data(map(), map()) :: map()
  defp field_data(attrs, attribute \\ %{})

  defp field_data(
         _attrs,
         %{type: resource_type, constraints: constraints}
       )
       when resource_type in [
              Ash.Type.Atom,
              Ash.Type.Atom.EctoType,
              Ash.Type.String,
              Ash.Type.String.EctoType,
              Ash.Type.Enum,
              Ash.Type.Enum.EctoType
            ] do
    if Keyword.has_key?(constraints, :one_of) do
      constraints[:one_of]
      |> Enum.map(&{CommonHelpers.capitalize(&1), &1})
      |> then(&%{select: %{opts: &1, multiple: false}})
    else
      %{}
    end
  end

  defp field_data(attrs, %{type: {:array, related_schema}, embedded?: true} = attribute),
    do: field_data(attrs, Map.put(attribute, :type, related_schema))

  defp field_data(%{resource: parent_resource_name}, %{
         type: related_schema,
         name: related_field,
         resource_schema: parent_schema,
         embedded?: true
       }) do
    %{
      owner: parent_schema,
      resource: field_embedded_resource(parent_resource_name, related_field),
      related: related_schema
    }
  end

  defp field_data(%{resource: parent_resource_name}, %{
         type: {:array, related_schema},
         name: related_field,
         resource_schema: parent_schema,
         embedded?: true
       }) do
    %{
      owner: parent_schema,
      resource: field_embedded_resource(parent_resource_name, related_field),
      related: related_schema
    }
  end

  defp field_data(
         %{
           key: field_key,
           resource: resource_name,
           type: ecto_type
         },
         %{
           resource_schema: resource_schema,
           association_or_embed: association_or_embed
         }
       ),
       do:
         CommonFieldsParser.field_data(
           resource_schema,
           field_key,
           association_or_embed,
           resource_name,
           ecto_type
         )

  # Generates a unique resource identifier for embedded fields
  @spec field_embedded_resource(atom(), map() | atom()) :: atom()
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

  ## PRIVATE

  @spec embedded_resource_config(tuple(), map(), list()) :: list()
  defp embedded_resource_config(
         {parent_resource_name, schema_module, type},
         %{type: resource_type, name: field},
         result
       ) do
    resource_name = field_embedded_resource(parent_resource_name, field)

    embed_schema =
      case resource_type do
        {:array, child_schema} -> child_schema
        child_schema when is_atom(child_schema) -> child_schema
      end

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

  @spec embedded_resource?(term()) :: boolean()
  defp embedded_resource?({:array, {:parameterized, {child_resource, _opts}}}),
    do: embedded_resource?(child_resource)

  defp embedded_resource?({:parameterized, {child_resource, _opts}}),
    do: embedded_resource?(child_resource)

  defp embedded_resource?(%{type: {:array, child_resource}}),
    do: embedded_resource?(child_resource)

  defp embedded_resource?(%{type: child_resource}),
    do: embedded_resource?(child_resource)

  defp embedded_resource?(child_resource) do
    child_resource_no_ecto = remove_ecto_type(child_resource)

    AshResourceInfo.resource?(child_resource_no_ecto) and
      AshResourceInfo.embedded?(child_resource_no_ecto)
  end

  @spec remove_ecto_type(module()) :: module()
  defp remove_ecto_type({:array, resource_schema}), do: remove_ecto_type(resource_schema)

  defp remove_ecto_type(resource_schema) do
    resource_schema
    |> Module.split()
    |> Enum.reverse()
    |> maybe_remove_ecto_type()
    |> Enum.reverse()
    |> Module.concat()
  end

  @spec maybe_remove_ecto_type(list()) :: list()
  defp maybe_remove_ecto_type(["EctoType" | rest]), do: rest
  defp maybe_remove_ecto_type(list), do: list

  @spec set(map(), function(), atom(), map()) :: map()
  defp set(attrs, function, attr_key, attribute) do
    if attribute.name in @on_test do
      IO.inspect({attrs, attribute}, label: "******** params before call: field_#{attr_key}")
    end

    attrs
    |> function.(attribute)
    |> then(&Map.put(attrs, attr_key, &1))
  end
end
