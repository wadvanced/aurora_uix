defmodule Aurora.Uix.Integration.FieldsParser do
  @moduledoc """
  Common field parsing utilities for integration modules.

  Provides shared functions for converting Elixir types to HTML input types, generating
  field labels, placeholders, and determining field metadata such as length, precision,
  and visibility rules. Used by both Ash and Ctx integration field parsers.

  ## Key Features

  - HTML5 input type mapping from Elixir types
  - Field label generation with capitalization
  - Default placeholder text generation
  - Field length and precision calculation
  - Field visibility and editability rules
  - Microsecond timestamp handling

  ## Key Constraints

  - Designed for standard Ecto and Ash types
  - Returns `:unimplemented` for unknown association types
  - Fixed precision/scale values for numeric types
  - Filterable check always returns true (to be specialized by implementations)
  """

  alias Aurora.Uix.Helpers.Common, as: CommonHelpers

  @doc """
  Maps an Elixir type to an HTML input type.

  Converts Elixir/Ecto types to appropriate HTML5 input types for form generation.

  ## Parameters

  - `type` (atom() | tuple()) - The Elixir type (e.g., `:string`, `:integer`, `:datetime`).
  - `association` (map() | nil) - Optional association metadata.

  ## Returns

  atom() - The HTML input type (e.g., `:text`, `:number`, `:checkbox`, `:unimplemented`).
  """
  @spec field_html_type(atom() | tuple(), map() | nil) :: atom()
  def field_html_type(type, _association)
      when type in [:string, :binary_id, :binary, :bitstring, :duration, Ecto.UUID],
      do: :text

  def field_html_type(type, _association) when type in [:id, :integer, :float, :decimal],
    do: :number

  def field_html_type(type, _association)
      when type in [:naive_datetime, :naive_datetime_usec, :utc_datetime, :utc_datetime_usec],
      do: :"datetime-local"

  def field_html_type(type, _association) when type in [:time, :time_usec], do: :time

  def field_html_type(:boolean, _association), do: :checkbox

  def field_html_type({:parameterized, {Ecto.Enum, %{}}}, _association_or_embed), do: :select

  def field_html_type(type, nil), do: type

  def field_html_type(_type, _association), do: :unimplemented

  @doc """
  Formats a display label from a field name.

  Capitalizes field names and replaces underscores with spaces for human-readable labels.

  ## Parameters

  - `name` (atom() | nil) - The field name to format.
  - `resource_name` (atom() | nil) - The resource name (currently unused).
  - `association_or_embed` (map() | nil) - Optional association metadata (currently unused).

  ## Returns

  binary() - The formatted label string, or empty string if name is nil.
  """
  @spec field_label(atom() | nil, atom() | nil, map() | nil) :: binary()
  def field_label(nil, _resource_name, _association_or_embed), do: ""

  def field_label(name, _resource_name, _association_or_embed),
    do: CommonHelpers.capitalize(name)

  @doc """
  Determines the default placeholder text for a field.

  Generates placeholder text based on field type, providing sensible defaults for form
  inputs.

  ## Parameters

  - `name` (atom()) - The field name.
  - `type` (atom()) - The field type (e.g., `:string`, `:integer`, `:binary_id`).

  ## Returns

  binary() - The placeholder text for the field.
  """
  @spec field_placeholder(atom(), atom()) :: binary()
  def field_placeholder(_, type) when type in [:id, :integer, :float, :decimal], do: "0"

  def field_placeholder(_, :binary_id), do: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"

  def field_placeholder(name, type) when type in [:string, :binary, :bitstring],
    do: CommonHelpers.capitalize(name)

  def field_placeholder(_name, _type), do: ""

  @doc """
  Determines the display length for a field.

  Calculates appropriate display width based on field type for form rendering.

  ## Parameters

  - `type` (atom()) - The field type (e.g., `:string`, `:integer`, `:datetime`).

  ## Returns

  integer() - The field display length in characters.
  """
  @spec field_length(atom()) :: integer()
  def field_length(type) when type in [:string, :binary_id, :binary, :bitstring], do: 255
  def field_length(type) when type in [:id, :integer], do: 10
  def field_length(type) when type in [:float, :decimal], do: 12

  def field_length(type)
      when type in [:naive_datetime, :utc_datetime],
      do: 17

  def field_length(type)
      when type in [:naive_datetime_usec, :utc_datetime_usec],
      do: 20

  def field_length(type) when type in [:time, :time_usec], do: 10
  def field_length(:boolean), do: 5
  def field_length(_type), do: 50

  @doc """
  Gets the numeric precision for number fields.

  Returns the total number of digits for numeric types.

  ## Parameters

  - `type` (atom()) - The field type (e.g., `:integer`, `:decimal`).

  ## Returns

  integer() - The precision value, or 0 for non-numeric types.
  """
  @spec field_precision(atom()) :: integer()
  def field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  def field_precision(_type), do: 0

  @doc """
  Gets the numeric scale for decimal/float fields.

  Returns the number of digits after the decimal point for fractional numeric types.

  ## Parameters

  - `type` (atom()) - The field type (e.g., `:float`, `:decimal`).

  ## Returns

  integer() - The scale value, or 0 for non-fractional types.
  """
  @spec field_scale(atom()) :: integer()
  def field_scale(type) when type in [:float, :decimal], do: 2
  def field_scale(_type), do: 0

  @doc """
  Checks if a field should be disabled by default.

  Determines whether a field should be read-only in forms based on its key.

  ## Parameters

  - `key` (atom()) - The field key (e.g., `:id`, `:deleted`).

  ## Returns

  boolean() - True if the field should be disabled, false otherwise.
  """
  @spec field_disabled(atom()) :: boolean()
  def field_disabled(key) when key in [:id, :deleted, :inactive],
    do: true

  def field_disabled(_field), do: false

  @doc """
  Checks if a field should be omitted from forms.

  Determines whether a field should be excluded from form rendering.

  ## Parameters

  - `key` (atom()) - The field key (e.g., `:inserted_at`, `:updated_at`).

  ## Returns

  boolean() - True if the field should be omitted, false otherwise.
  """
  @spec field_omitted(atom()) :: boolean()
  def field_omitted(key) when key in [:inserted_at, :updated_at],
    do: true

  def field_omitted(_field), do: false

  @doc """
  Determines if a field should be hidden from display.

  Checks whether a field should be visible in UI views.

  ## Parameters

  - `key` (atom()) - The field key.

  ## Returns

  boolean() - True if the field should be hidden, false otherwise.
  """
  @spec field_hidden(atom()) :: boolean()
  def field_hidden(_field), do: false

  @doc """
  Determines if a field should be filterable in queries.

  Checks whether a field can be used in filter/search operations.

  ## Parameters

  - `type` (atom()) - The field type.

  ## Returns

  boolean() - True if the field is filterable, false otherwise.
  """
  @spec field_filterable(atom()) :: boolean()
  def field_filterable(_type), do: true

  @doc """
  Extracts metadata for field types.

  Returns additional metadata for fields that require special handling, such as step
  values for microsecond timestamps.

  ## Parameters

  - `resource_schema` (module()) - The schema module.
  - `field_key` (atom()) - The field identifier.
  - `association_or_embed` (map() | nil) - Optional association metadata.
  - `resource_name` (atom()) - The resource name.
  - `type` (term()) - The field type.

  ## Returns

  map() - Field metadata map, or empty map if no special handling needed.
  """
  @spec field_data(module(), atom(), nil | map(), nil | atom(), nil | term()) :: map()
  def field_data(_resource_schema, _field_key, _association_or_embed, _resource_name, type)
      when type in [:time_usec, :naive_datetime_usec, :utc_datetime_usec], do: %{step: 1}

  def field_data(_resource_schema, _field_key, nil, _resource_name, _type), do: %{}
end
