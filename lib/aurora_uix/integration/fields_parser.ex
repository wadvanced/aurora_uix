defmodule Aurora.Uix.Integration.FieldsParser do
  alias Aurora.Uix.Helpers.Common, as: CommonHelpers

  # Maps an Elixir type to an HTML input type
  @spec field_html_type(atom(), map() | nil) :: atom()
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
  # Formats a display label from a field name - capitalizes and replaces underscores
  @spec field_label(atom() | nil, atom() | nil, map() | nil) :: binary()

  def field_label(nil, _resource_name, _association_or_embed), do: ""

  def field_label(name, _resource_name, _association_or_embed),
    do: CommonHelpers.capitalize(name)

  # Determines the default placeholder text for a field based on its type
  @spec field_placeholder(atom(), atom()) :: binary()
  def field_placeholder(_, type) when type in [:id, :integer, :float, :decimal], do: "0"

  def field_placeholder(_, :binary_id), do: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"

  def field_placeholder(name, type) when type in [:string, :binary, :bitstring],
    do: CommonHelpers.capitalize(name)

  def field_placeholder(_name, _type), do: ""
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

  # Gets the numeric precision for number fields
  @spec field_precision(atom()) :: integer()
  def field_precision(type) when type in [:id, :integer, :float, :decimal], do: 10
  def field_precision(_type), do: 0

  # Gets the numeric scale for decimal/float fields
  @spec field_scale(atom()) :: integer()
  def field_scale(type) when type in [:float, :decimal], do: 2
  def field_scale(_type), do: 0
  # Checks if a field should be disabled by default
  @spec field_disabled(atom()) :: boolean()
  def field_disabled(key) when key in [:id, :deleted, :inactive],
    do: true

  def field_disabled(_field), do: false

  # Checks if a field should be omitted from forms
  @spec field_omitted(atom()) :: boolean()
  def field_omitted(key) when key in [:inserted_at, :updated_at],
    do: true

  def field_omitted(_field), do: false

  # Determines if a field should be hidden from display
  @spec field_hidden(atom()) :: boolean()
  def field_hidden(_field), do: false

  # Determines if a field should be filterable in queries
  @spec field_filterable(atom()) :: boolean()
  def field_filterable(_type), do: true
  # Extracts metadata for association fields
  @spec field_data(module(), atom(), map() | nil, atom(), atom()) :: map()
  def field_data(_resource_schema, _field_key, _association_or_embed, _resource_name, type)
      when type in [:time_usec, :naive_datetime_usec, :utc_datetime_usec], do: %{step: 1}

  def field_data(_resource_schema, _field_key, nil, _resource_name, _type), do: %{}
end
