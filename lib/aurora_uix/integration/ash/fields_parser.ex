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

  alias Aurora.Uix.Helpers.Common, as: CommonHelpers
  alias Aurora.Uix.Resource

  alias Ecto.Association.BelongsTo, as: AssociationBelongsTo
  alias Ecto.Association.Has, as: AssociationHas
  alias Ecto.Embedded

  @doc """
  Formats a display label from a field name.

  Converts an atom field name to a human-readable label by capitalizing it and
  replacing underscores with spaces.

  ## Parameters
  - `resource_type` - Type of resource (:ash, :ctx)
  - `name` (`atom()` | `nil`) - The field name to format.
  - `association_or_embed` (`map()` | `nil`) - The optional association.

  ## Returns
  `binary()` - The formatted display label.
  """
  @spec field_label(atom() | nil, atom() | nil, map() | nil) :: binary()

  def field_label(name, resource_name \\ nil, association_or_embed \\ nil)

  def field_label(nil, _resource_name, _association_or_embed), do: ""

  def field_label(name, resource_name, %Embedded{cardinality: :many}) do
    CommonHelpers.capitalize("#{resource_name} #{name}")
  end

  def field_label(name, _resource_name, _association_or_embed),
    do: CommonHelpers.capitalize(name)

  @doc """
  Determines the default placeholder text for a field based on its type.

  Provides contextually appropriate placeholder text to help users understand
  the expected input format.

  ## Parameters
  - `name` (`atom()`) - The field name, used as a fallback for text fields.
  - `type` (`atom()`) - The Elixir type that determines the placeholder format.

  ## Returns
  `binary()` - The default placeholder text.
  """
  @spec field_placeholder(atom(), atom()) :: binary()
  def field_placeholder(_, type) when type in [:id, :integer, :float, :decimal], do: "0"

  def field_placeholder(_, type)
      when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
      do: "yyyy/MM/dd HH:mm:ss"

  def field_placeholder(_, type) when type in [:time, :time_usec], do: "HH:mm:ss"
  def field_placeholder(name, _type), do: CommonHelpers.capitalize(name)

  @doc """
  Converts an Ash type to its corresponding Ecto type.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash type to convert.
  - `_association_or_embed` (map() | nil) - Association or embedding metadata (currently unused).

  ## Returns
  atom() - The corresponding Ecto type atom.

  ## Examples
      iex> field_type({:parameterized, {Ash.Type.String, []}}, nil)
      :string

      iex> field_type({:parameterized, {Ash.Type.Integer, []}}, nil)
      :integer

      iex> field_type({:parameterized, {Ash.Type.UUID, []}}, nil)
      :binary_id

      iex> field_type(:string, nil)
      :string
  """
  @spec field_type(tuple() | atom(), map() | nil) :: atom()
  def field_type(nil, %AssociationHas{cardinality: :many} = _association),
    do: :one_to_many_association

  def field_type(nil, %AssociationBelongsTo{cardinality: :one} = _association),
    do: :many_to_one_association

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.String,
             Ash.Type.String.EctoType,
             Ash.Type.CiString,
             Ash.Type.CiString.EctoType,
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.DurationName,
             Ash.Type.DurationName.EctoType,
             Ash.Type.Enum,
             Ash.Type.Enum.EctoType
           ],
      do: :string

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.UUID, Ash.Type.UUID.EctoType],
      do: :binary_id

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.Integer,
             Ash.Type.Integer.EctoType
           ],
      do: :integer

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Float, Ash.Type.Float.EctoType],
      do: :float

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Decimal, Ash.Type.Decimal.EctoType],
      do: :decimal

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType],
      do: :boolean

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Date, Ash.Type.Date.EctoType],
      do: :date

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Time, Ash.Type.Time.EctoType],
      do: :time

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.DateTime,
             Ash.Type.DateTime.EctoType,
             Ash.Type.UtcDatetime,
             Ash.Type.UtcDatetime.EctoType
           ],
      do: :utc_datetime

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.UtcDatetimeUsec,
             Ash.Type.UtcDatetimeUsec.EctoType
           ],
      do: :utc_datetime_usec

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.NaiveDatetime,
             Ash.Type.NaiveDatetime.EctoType
           ],
      do: :naive_datetime

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Binary, Ash.Type.Binary.EctoType],
      do: :binary

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.UrlEncodedBinary,
             Ash.Type.UrlEncodedBinary.EctoType
           ],
      do: :binary

  def field_type({:parameterized, {type, _opts}}, _association_or_embed)
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

  # Fallback for other parameterized types
  def field_type({:parameterized, {_other_types, _opts}}, _association_or_embed), do: :string

  def field_type({:array, {:parameterized, {_ecto_type, _opts}}}, _association_or_embed) do
    :embeds_many
  end

  # Direct type passthrough
  def field_type(type, nil), do: type

  @doc """
  Maps an Ash type to an HTML input type.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash type to map.
  - `_association_or_embed` (map() | nil) - Association or embedding metadata (currently unused).

  ## Returns
  atom() - The HTML5 input type.

  ## Examples
      iex> field_html_type({:parameterized, {Ash.Type.String, []}}, nil)
      :text

      iex> field_html_type({:parameterized, {Ash.Type.Integer, []}}, nil)
      :number

      iex> field_html_type({:parameterized, {Ash.Type.Boolean, []}}, nil)
      :checkbox

      iex> field_html_type({:parameterized, {Ash.Type.DateTime, []}}, nil)
      :"datetime-local"
  """
  @spec field_html_type(tuple() | atom(), map() | nil) :: atom()
  def field_html_type(nil, %AssociationHas{cardinality: :many} = _association),
    do: :one_to_many_association

  def field_html_type(nil, %AssociationBelongsTo{cardinality: :one} = _association),
    do: :many_to_one_association

  def field_html_type({:parameterized, {type, opts}}, _association_or_embed)
      when type in [
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.String,
             Ash.Type.String.EctoType
           ] do
    if Keyword.has_key?(opts, :one_of), do: :select, else: :text
  end

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.CiString,
             Ash.Type.CiString.EctoType,
             Ash.Type.UUID,
             Ash.Type.UUID.EctoType,
             Ash.Type.Binary,
             Ash.Type.Binary.EctoType,
             Ash.Type.UrlEncodedBinary,
             Ash.Type.UrlEncodedBinary.EctoType,
             Ash.Type.DurationName,
             Ash.Type.DurationName.EctoType
           ],
      do: :text

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.Integer,
             Ash.Type.Integer.EctoType,
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: :number

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType],
      do: :checkbox

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Date, Ash.Type.Date.EctoType],
      do: :date

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Time, Ash.Type.Time.EctoType],
      do: :time

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [
             Ash.Type.DateTime,
             Ash.Type.DateTime.EctoType,
             Ash.Type.UtcDatetime,
             Ash.Type.UtcDatetime.EctoType,
             Ash.Type.UtcDatetimeUsec,
             Ash.Type.UtcDatetimeUsec.EctoType,
             Ash.Type.NaiveDatetime,
             Ash.Type.NaiveDatetime.EctoType
           ],
      do: :"datetime-local"

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
      when type in [Ash.Type.Enum, Ash.Type.Enum.EctoType],
      do: :select

  def field_html_type({:parameterized, {type, _opts}}, _association_or_embed)
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
      do: :textarea

  # Fallback for other parameterized types
  def field_html_type({:parameterized, {_other_types, _opts}}, _association_or_embed), do: :text

  def field_html_type({:array, {:parameterized, {_ecto_type, _opts}}}, _association_or_embed) do
    :unimplemented
  end

  def field_html_type(:boolean, _association), do: :checkbox

  # Direct type passthrough
  def field_html_type(type, nil), do: type

  @doc """
  Determines the display length for an Ash field based on its type.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash type to determine the length for.

  ## Returns
  integer() - The suggested display length in characters.

  ## Examples
      iex> field_length({:parameterized, {Ash.Type.String, []}})
      255

      iex> field_length({:parameterized, {Ash.Type.Integer, []}})
      10

      iex> field_length({:parameterized, {Ash.Type.Boolean, []}})
      5
  """
  @spec field_length(tuple() | atom()) :: integer()
  def field_length({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.String,
             Ash.Type.String.EctoType,
             Ash.Type.CiString,
             Ash.Type.CiString.EctoType,
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.Binary,
             Ash.Type.Binary.EctoType
           ],
      do: 255

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.UUID, Ash.Type.UUID.EctoType],
      do: 36

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Integer, Ash.Type.Integer.EctoType],
      do: 10

  def field_length({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: 12

  def field_length({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.DateTime,
             Ash.Type.DateTime.EctoType,
             Ash.Type.UtcDatetime,
             Ash.Type.UtcDatetime.EctoType,
             Ash.Type.UtcDatetimeUsec,
             Ash.Type.UtcDatetimeUsec.EctoType,
             Ash.Type.NaiveDatetime,
             Ash.Type.NaiveDatetime.EctoType
           ],
      do: 20

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Time, Ash.Type.Time.EctoType],
      do: 10

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Date, Ash.Type.Date.EctoType],
      do: 10

  def field_length({:parameterized, {type, _opts}})
      when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType],
      do: 5

  def field_length({:parameterized, {_type, _opts}}), do: 50

  def field_length(_type), do: 50

  @doc """
  Gets the numeric precision for Ash number fields.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash field type to check.

  ## Returns
  integer() - The numeric precision, or `0` for non-numeric types.

  ## Examples
      iex> field_precision({:parameterized, {Ash.Type.Integer, []}})
      10

      iex> field_precision({:parameterized, {Ash.Type.Decimal, []}})
      10

      iex> field_precision({:parameterized, {Ash.Type.String, []}})
      0
  """
  @spec field_precision(tuple() | atom()) :: integer()
  def field_precision({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Integer,
             Ash.Type.Integer.EctoType,
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: 10

  def field_precision({:parameterized, {_type, _opts}}), do: 0

  def field_precision(_type), do: 0

  @doc """
  Gets the numeric scale for Ash decimal/float fields.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash field type to check.

  ## Returns
  integer() - The numeric scale, or `0` for non-decimal types.

  ## Examples
      iex> field_scale({:parameterized, {Ash.Type.Float, []}})
      2

      iex> field_scale({:parameterized, {Ash.Type.Decimal, []}})
      2

      iex> field_scale({:parameterized, {Ash.Type.Integer, []}})
      0
  """
  @spec field_scale(tuple() | atom()) :: integer()
  def field_scale({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Float,
             Ash.Type.Float.EctoType,
             Ash.Type.Decimal,
             Ash.Type.Decimal.EctoType
           ],
      do: 2

  def field_scale({:parameterized, {_type, _opts}}), do: 0

  def field_scale(_type), do: 0

  @doc """
  Checks if a field should be disabled by default.

  Certain fields like primary keys and system fields are typically not editable
  by users and should be disabled in forms.

  ## Parameters
  - `key` (`atom()`) - The field key to check.

  ## Returns
  `boolean()` - `true` if the field should be disabled, otherwise `false`.
  """
  @spec field_disabled(atom()) :: boolean()
  def field_disabled(key) when key in [:id, :deleted, :inactive],
    do: true

  def field_disabled(_field), do: false

  @doc """
  Checks if a field should be omitted from forms.

  System-managed fields like timestamps are usually not included in user-facing
  forms as they are automatically managed.

  ## Parameters
  - `key` (`atom()`) - The field key to check.

  ## Returns
  `boolean()` - `true` if the field should be omitted, otherwise `false`.
  """
  @spec field_omitted(atom()) :: boolean()
  def field_omitted(key) when key in [:inserted_at, :updated_at],
    do: true

  def field_omitted(_field), do: false

  @doc """
  Determines if a field should be hidden from display.

  This function can be used to implement conditional field visibility logic.

  ## Parameters
  - `field` (`atom()`) - The field key to check.

  ## Returns
  `boolean()` - `true` if the field should be hidden, otherwise `false`.
  """
  @spec field_hidden(atom()) :: boolean()
  def field_hidden(_field), do: false

  @doc """
  Determines if an Ash field should be filterable in queries.

  ## Parameters
  - `type` (tuple() | atom()) - The Ash field type to check.

  ## Returns
  boolean() - Returns `true` if the field supports filtering, otherwise `false`.

  ## Examples
      iex> field_filterable({:parameterized, {Ash.Type.String, []}})
      true

      iex> field_filterable({:parameterized, {Ash.Type.Map, []}})
      false
  """
  @spec field_filterable(tuple() | atom()) :: boolean()
  def field_filterable({:parameterized, {type, _opts}})
      when type in [
             Ash.Type.Map,
             Ash.Type.Map.EctoType,
             Ash.Type.Term,
             Ash.Type.Term.EctoType,
             Ash.Type.Tuple,
             Ash.Type.Tuple.EctoType,
             Ash.Type.Struct,
             Ash.Type.Struct.EctoType,
             Ash.Type.Union,
             Ash.Type.Union.EctoType
           ],
      do: false

  def field_filterable({:parameterized, {_type, _opts}}), do: true

  def field_filterable(_type), do: true

  @doc """
  Extracts metadata for Ash field types.

  ## Parameters
  - `_association_or_embed` (map() | nil) - Association or embed metadata (unused).
  - `_resource_name` (atom() | nil) - The resource name (unused).
  - `type` (tuple() | atom()) - The Ash field type.

  ## Returns
  map() - A metadata map with select options for constrained types, empty map otherwise.

  ## Examples
      iex> field_data(nil, nil, {:parameterized, {Ash.Type.Atom, [one_of: [:active, :inactive]]}})
      %{select: %{opts: [active: "Active", inactive: "Inactive"], multiple: false}}

      iex> field_data(nil, nil, {:parameterized, {Ash.Type.String, [one_of: ["red", "blue"]]}})
      %{select: %{opts: [{"red", "Red"}, {"blue", "Blue"}], multiple: false}}

      iex> field_data(nil, nil, {:parameterized, {Ash.Type.Integer, []}})
      %{}
  """
  @spec field_data(module(), atom(), map() | nil, atom() | nil, tuple() | atom()) :: map()
  def field_data(
        _resource_schema,
        _field_key,
        association_or_embed,
        resource_name \\ nil,
        type \\ nil
      )

  def field_data(
        _resource_schema,
        __field_key,
        _association_or_embed,
        _resource_name,
        {:parameterized, {type, opts}}
      )
      when type in [
             Ash.Type.Atom,
             Ash.Type.Atom.EctoType,
             Ash.Type.String,
             Ash.Type.String.EctoType
           ] do
    if Keyword.has_key?(opts, :one_of) do
      opts[:one_of]
      |> Enum.map(&{&1, CommonHelpers.capitalize(&1)})
      |> then(&%{select: %{opts: &1, multiple: false}})
    else
      %{}
    end
  end

  def field_data(
        resource_schema,
        field_key,
        _association_or_embed,
        resource_name,
        {:array, {:parameterized, {related_resource, _opts}}}
      ) do
    related =
      related_resource
      |> Module.split()
      |> Enum.reverse()
      |> maybe_remove_ecto_type()
      |> Enum.reverse()
      |> Module.concat()

    %{
      owner: resource_schema,
      resource: String.to_atom("#{resource_name}__#{field_key}"),
      related: related
    }
  end

  def field_data(_resource_schema, _field_key, %{} = association, _resource_name, _type),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  def field_data(_resource_schema, _field_key, _association_or_embed, _resource_name, _type),
    do: %{}

  @doc """
  Generates a unique resource identifier for embedded fields.

  ## Parameters
  - `parent_resource_name` (`atom()`) - The name of the parent resource.
  - `field` (`map()` | `atom()`) - The embedded field (%Ecto.Embedded) or the field name.

  ## Returns
  `binary()` - A unique identifier for the embedded resource.
  """
  @spec field_embedded_resource(atom(), map() | atom()) :: atom()
  def field_embedded_resource(parent_resource_name, field) do
    String.to_atom("#{parent_resource_name}__#{field}")
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

  @spec embedded_resource_config(tuple(), map(), list()) :: list()
  defp embedded_resource_config(
         {parent_resource_name, schema_module, type},
         %{type: ash_type, name: field},
         result
       ) do
    resource_name = field_embedded_resource(parent_resource_name, field)

    embed_schema =
      case ash_type do
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
  defp embedded_resource?(%{type: {:array, child_resource}}),
    do: embedded_resource?(child_resource)

  defp embedded_resource?(%{type: child_resource}),
    do: embedded_resource?(child_resource)

  defp embedded_resource?(child_resource) do
    AshResourceInfo.resource?(child_resource) and AshResourceInfo.embedded?(child_resource)
  end

  @spec maybe_remove_ecto_type(list()) :: list()
  defp maybe_remove_ecto_type(["EctoType" | rest]), do: rest
  defp maybe_remove_ecto_type(list), do: list
end
