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

  alias Aurora.Uix.Helpers.Common, as: CommonHelpers

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
  Maps an Elixir type to a field type, handling associations.

  Determines the appropriate field type for UI rendering, with special handling
  for association fields.

  ## Parameters
  - `type` (`atom()`) - The base Elixir type.
  - `association` (`map()` | `nil`) - Association metadata with cardinality info.

  ## Returns
  `atom()` - The mapped field type for UI rendering.
  """
  @spec field_type(atom(), map() | nil) :: atom()
  def field_type({:parameterized, {Ecto.Enum, %{}}}, _association_or_embed), do: :string

  def field_type(_type, %Embedded{cardinality: :one} = _embed), do: :embeds_one

  def field_type(_type, %Embedded{cardinality: :many} = _embed), do: :embeds_many

  def field_type(type, nil), do: type

  def field_type(nil, %AssociationHas{cardinality: :many} = _association),
    do: :one_to_many_association

  def field_type(nil, %AssociationBelongsTo{cardinality: :one} = _association),
    do: :many_to_one_association

  @doc """
  Maps an Elixir type to an HTML input type.

  Provides appropriate HTML5 input types based on the data type, enabling proper
  browser validation and input handling.

  ## Parameters
  - `type` (`atom()`) - The Elixir type to map.
  - `association` (`map()` | `nil`) - Association metadata for relationship fields.

  ## Returns
  `atom()` - The HTML5 input type.
  """
  @spec field_html_type(atom(), map() | nil) :: atom()
  def field_html_type(type, _association)
      when type in [:string, :binary_id, :binary, :bitstring, Ecto.UUID],
      do: :text

  def field_html_type(type, _association) when type in [:id, :integer, :float, :decimal],
    do: :number

  def field_html_type(type, _association)
      when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
      do: :"datetime-local"

  def field_html_type(type, _association) when type in [:time, :time_usec], do: :time

  def field_html_type(:boolean, _association), do: :checkbox

  def field_html_type({:parameterized, {Ecto.Enum, %{}}}, _association_or_embed), do: :select

  def field_html_type(nil, %Embedded{cardinality: :one} = _embed), do: :embeds_one

  def field_html_type(nil, %Embedded{cardinality: :many} = _embed), do: :embeds_many

  def field_html_type(type, nil), do: type

  def field_html_type(nil, %AssociationHas{cardinality: :many} = _association),
    do: :one_to_many_association

  def field_html_type(nil, %AssociationBelongsTo{cardinality: :one} = _association),
    do: :many_to_one_association

  def field_html_type(_type, _association), do: :unimplemented

  @doc """
  Determines the display length for a field based on its type.

  Sets sensible default length constraints that work well for most UI scenarios,
  considering typical data ranges for each type.

  ## Parameters
  - `type` (`atom()`) - The Elixir type to determine the length for.

  ## Returns
  `integer()` - The suggested display length in characters.
  """
  @spec field_length(atom()) :: integer()
  def field_length(type) when type in [:string, :binary_id, :binary, :bitstring], do: 255
  def field_length(type) when type in [:id, :integer], do: 10
  def field_length(type) when type in [:float, :decimal], do: 12

  def field_length(type)
      when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
      do: 20

  def field_length(type) when type in [:time, :time_usec], do: 10
  def field_length(Ecto.UUID), do: 34
  def field_length(:boolean), do: 5
  def field_length(_type), do: 50

  @doc """
  Gets the numeric precision for number fields.

  Returns the total number of significant digits for numeric types.

  ## Parameters
  - `type` (`atom()`) - The field type to check.

  ## Returns
  `integer()` - The numeric precision, or `0` for non-numeric types.
  """
  @spec field_precision(atom()) :: integer()
  def field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  def field_precision(_type), do: 0

  @doc """
  Gets the numeric scale for decimal/float fields.

  Returns the number of digits after the decimal point.

  ## Parameters
  - `type` (`atom()`) - The field type to check.

  ## Returns
  `integer()` - The numeric scale, or `0` for non-decimal types.
  """
  @spec field_scale(atom()) :: integer()
  def field_scale(type) when type in [:float, :decimal], do: 2
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
  Determines if a field should be filterable in queries.

  ## Parameters
  - `type` (`atom()`) - The field type to check.

  ## Returns
  `boolean()` - `true` if the field supports filtering, otherwise `false`.
  """
  @spec field_filterable(atom()) :: boolean()
  def field_filterable(_type), do: true

  @doc """
  Extracts metadata for association fields.

  Builds a metadata map containing relationship information needed for proper
  association handling in forms and queries.

  ## Parameters
  - `association` (`map()` | `nil`) - The association struct from an Ecto schema.

  ## Returns
  `map()` - An association metadata map, or an empty map if there is no association.
  """
  @spec field_data(module(), atom(), map() | nil, atom(), atom()) :: map()
  def field_data(
        _resource_schema,
        _field_key,
        association_or_embed,
        resource_name \\ nil,
        type \\ nil
      )

  def field_data(
        _resource_schema,
        _field_key,
        _association_or_embed,
        _resource_name,
        {:parameterized, {Ecto.Enum, %{on_load: opts}}}
      ) do
    opts = Enum.map(opts, fn {text, key} -> {field_label(text), key} end)
    %{select: %{opts: opts, multiple: false}}
  end

  def field_data(_resource_schema, _field_key, nil, _resource_name, _type), do: %{}

  def field_data(_resource_schema, _field_key, %Embedded{} = embedded, resource_name, _type) do
    %{
      related: embedded.related,
      owner: embedded.owner,
      resource: field_embedded_resource(resource_name, embedded)
    }
  end

  def field_data(_resource_schema, _field_key, %{} = association, _resource_name, _type),
    do: %{
      related: association.related,
      related_key: association.related_key,
      owner_key: association.owner_key
    }

  @doc """
  Generates a unique resource identifier for embedded fields.

  ## Parameters
  - `parent_resource_name` (`atom()`) - The name of the parent resource.
  - `field` (`map()` | `atom()`) - The embedded field (%Ecto.Embedded) or the field name.

  ## Returns
  `binary()` - A unique identifier for the embedded resource.
  """
  @spec field_embedded_resource(atom(), map() | atom()) :: atom()
  def field_embedded_resource(parent_resource_name, %Embedded{field: field}),
    do: field_embedded_resource(parent_resource_name, field)

  def field_embedded_resource(parent_resource_name, field) do
    String.to_atom("#{parent_resource_name}__#{field}")
  end
end
