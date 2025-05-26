defmodule Aurora.Uix.Test.UICase do
  @moduledoc """
  Support for testing schema metadata behaviour.
  """

  alias Aurora.Uix.Field

  @spec validate_schema(map, atom, map) :: boolean
  def validate_schema(resource_configs, schema, fields_checks) do
    metadata = get_in(resource_configs, [schema, Access.key!(:fields)])

    Enum.each(fields_checks, fn {field_id, checks} ->
      field = Map.get(metadata, field_id)
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

  @spec resource_configs(module) :: map
  def resource_configs(module) do
    attributes(module, :auix_resource_metadata)
  end

  @spec attributes(module, atom) :: map
  def attributes(module, attribute) do
    Code.ensure_compiled(module)

    :attributes
    |> module.__info__()
    |> Keyword.get(attribute, [])
    |> List.first()
  end

  @spec assert_values_order([binary | atom], [binary | atom]) :: :ok
  def assert_values_order(expected_values, current_values) do
    case {expected_values, current_values} do
      {[] = expected_values, current_values} when current_values != expected_values ->
        raise(
          "Expected values is empty, but current values is not: #{inspect(current_values, pretty: true)}"
        )

      {expected_values, [] = current_values} when current_values != expected_values ->
        raise(
          "Current values is empty, but expected values is not: #{inspect(expected_values, pretty: true)}"
        )

      _ ->
        :ok
    end

    case assert_value_order(expected_values, current_values) do
      {false, _} -> :ok
      {true, result} -> raise("Unmatched order: \n#{result}")
    end
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
      use Aurora.Uix.Web.Test.ConnCase
      import Aurora.Uix.Test.UICase
    end
  end

  @doc false
  @spec phoenix_case() :: Macro.t()
  def phoenix_case do
    quote do
      use Aurora.Uix.Web.Test.ConnCase
      import Phoenix.LiveViewTest
      import Aurora.Uix.Test.Support.Helper
      import Aurora.Uix.Test.UICase
      import Aurora.Uix.Web.Test.SectionHelper
    end
  end

  ## PRIVATE
  @spec assert_value_order(list, list, boolean, list) :: {boolean, list}
  defp assert_value_order(expected_values, current_values, unmatched? \\ false, result \\ [])

  defp assert_value_order(_, [], unmatched?, result),
    do: {unmatched?, result |> Enum.reverse() |> Enum.join("\n")}

  defp assert_value_order(
         [value_equal | expected_values],
         [value_equal | current_values],
         unmatched?,
         result
       ),
       do:
         assert_value_order(expected_values, current_values, unmatched?, [
           "#{inspect(value_equal)} == #{inspect(value_equal)}" | result
         ])

  defp assert_value_order(
         [expected_value | expected_values],
         [current_value | current_values],
         _unmatched?,
         result
       ),
       do:
         assert_value_order(expected_values, current_values, true, [
           "#{inspect(expected_value)} != #{inspect(current_value)}" | result
         ])
end
