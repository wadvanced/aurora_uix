defmodule AuroraUixTest.MetadataCase do
  @moduledoc """
  Support for testing schema metadata behaviour.
  """

  alias AuroraUix.Field

  @spec validate_schema(map, atom, map) :: boolean
  def validate_schema(schemas_metadata, schema, fields_checks) do
    metadata = get_in(schemas_metadata, [schema, Access.key!(:fields)])

    Enum.each(fields_checks, fn {field_id, checks} ->
      field =
        Map.get(metadata, field_id)

      validate_field(field, checks)
    end)
  end

  @spec validate_field(Field.t(), map) :: :ok
  def validate_field(field, checks) do
    Enum.each(checks, fn {key, value} ->
      current_value = Map.get(field, key)

      if current_value != value do
        raise(
          current_value == value,
          "Field `#{field.field}`, key: `#{key}`. Expected: `#{value}`, current: `#{current_value}`"
        )
      end
    end)
  end

  @spec schemas_metadata(module) :: map
  def schemas_metadata(module) do
    attributes(module, :_auix_schemas)
  end

  @spec layouts(module) :: map
  def layouts(module) do
    attributes(module, :_auix_layouts)
  end

  @spec attributes(module, atom) :: map
  def attributes(module, attribute) do
    Code.ensure_compiled(module)

    :attributes
    |> module.__info__()
    |> Keyword.get(attribute, [])
    |> Map.new()
  end

  defmacro __using__(_opts) do
    quote do
      use AuroraUixTestWeb.ConnCase
      import AuroraUixTest.MetadataCase
    end
  end
end
