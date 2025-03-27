Code.require_file("test/support/conn_case.exs")

defmodule AuroraUixTest.UICase do
  @moduledoc """
  Support for testing schema metadata behaviour.
  """

  alias AuroraUix.Field

  @spec validate_schema(map, atom, map) :: boolean
  def validate_schema(resource_configs, schema, fields_checks) do
    metadata = get_in(resource_configs, [schema, Access.key!(:fields)])

    Enum.each(fields_checks, fn {field_id, checks} ->
      field = locate_field(metadata, field_id)
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

  @spec locate_field(map, atom) :: map | nil
  def locate_field(schema_config, field) do
    Enum.find(schema_config, fn
      %{field: ^field} -> true
      _ -> false
    end)
  end

  @spec resource_configs(module) :: map
  def resource_configs(module) do
    attributes(module, :auix_resource_config)
  end

  @spec attributes(module, atom) :: map
  def attributes(module, attribute) do
    Code.ensure_compiled(module)

    :attributes
    |> module.__info__()
    |> Keyword.get(attribute, [])
    |> List.first()
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(_) do
    apply(__MODULE__, :test_case, [])
  end

  @doc false
  @spec test_case() :: Macro.t()
  def test_case do
    quote do
      use AuroraUixTestWeb.ConnCase
      import AuroraUixTest.UICase
    end
  end

  @doc false
  @spec phoenix_case() :: Macro.t()
  def phoenix_case do
    Code.require_file("test/support/section_helper.exs")

    quote do
      use AuroraUixTestWeb.ConnCase
      import Phoenix.LiveViewTest
      import AuroraUixTestWeb.SectionHelper
    end
  end
end
