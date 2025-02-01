defmodule AuroraUixTest.MetadataCase do
  @moduledoc """
  Support for testing schema metadata behaviour.
  """

  alias AuroraUix.Field

  @spec validate_schema(map, atom, map) :: boolean
  def validate_schema(schemas_metadata, schema, fields_checks) do
    metadata = get_in(schemas_metadata, [schema, Access.key!(:fields)])

    Enum.each(fields_checks, fn {field_id, checks} ->
      field = find_field(metadata, field_id)
      validate_field(field, checks, field_id)
    end)
  end

  @spec validate_field(Field.t(), map, atom) :: :ok
  def validate_field(nil, _checks, field_id), do: raise("Field `#{field_id}` was not found")

  def validate_field(field, checks, field_id) do
    Enum.each(checks, fn {key, value} ->
      current_value = Map.get(field, key)

      if current_value != value do
        raise(
          "Field `#{field_id}`, key: `#{key}`. Expected: `#{value}`, current: `#{current_value}`"
        )
      end
    end)
  end

  @spec find_field(map, atom) :: map | nil
  def find_field(schema_metadata, field) do
    Enum.find(schema_metadata, fn
      %{field: ^field} -> true
      _ -> false
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
