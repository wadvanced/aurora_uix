defmodule Aurora.UixWeb.UICase do
  @moduledoc """
  Support for testing schema metadata behaviour.

  ## Key Features
  - Provides helpers for validating schema metadata in tests.
  - Includes macros for test case setup and assertions.
  """

  alias Aurora.Uix.Field

  @doc """
  Validates schema fields against expected checks.

  ## Parameters
  - `resource_configs` (map()) - Resource configuration map.
  - `schema` (atom()) - Schema name.
  - `fields_checks` (map()) - Map of field IDs to check values.

  ## Returns
  boolean() - Returns true if all checks pass, otherwise raises.
  """
  @spec validate_schema(map(), atom(), map()) :: boolean()
  def validate_schema(resource_configs, schema, fields_checks) do
    metadata = get_in(resource_configs, [schema, Access.key!(:fields)])

    Enum.each(fields_checks, fn {field_id, checks} ->
      field = Map.get(metadata, field_id)
      validate_field(field, checks, field_id)
    end)
  end

  @doc """
  Validates a field's value against expected checks.

  ## Parameters
  - `field` (Field.t() | nil) - The field struct or nil.
  - `checks` (map()) - Map of expected key-value pairs.
  - `field_id` (atom()) - Field identifier.

  ## Returns
  :ok - Returns :ok if all checks pass, otherwise raises.
  """
  @spec validate_field(Field.t() | nil, map(), atom()) :: :ok
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

  @doc """
  Returns resource configs for a module.

  ## Parameters
  - `module` (module()) - The module to fetch configs for.

  ## Returns
  map() - Resource configuration map.
  """
  @spec resource_configs(module()) :: map()
  def resource_configs(module) do
    attributes(module, :auix_resource_metadata)
  end

  @doc """
  Returns attributes for a module.

  ## Parameters
  - `module` (module()) - The module.
  - `attribute` (atom()) - The attribute name.

  ## Returns
  map() - Attribute value.
  """
  @spec attributes(module(), atom()) :: map()
  def attributes(module, attribute) do
    Code.ensure_compiled(module)

    :attributes
    |> module.__info__()
    |> Keyword.get(attribute, [])
    |> List.first()
  end

  @doc """
  Asserts that two lists of values are in the expected order.

  ## Parameters
  - `expected_values` (list(binary() | atom())) - The expected values.
  - `current_values` (list(binary() | atom())) - The current values.

  ## Returns
  :ok - Returns :ok if order matches, otherwise raises.
  """
  @spec assert_values_order([binary() | atom()], [binary() | atom()]) :: :ok
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
  Macro for dispatching to the appropriate controller/live_view/etc.

  ## Parameters
  - `which` (atom()) - The component type to dispatch to.

  ## Returns
  Macro.t() - The quoted macro for the specified component.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(_) do
    apply(__MODULE__, :test_case, [])
  end

  @spec test_case() :: Macro.t()
  def test_case do
    quote do
      use Aurora.UixWeb.Test.ConnCase
      import Aurora.UixWeb.UICase
    end
  end

  @spec phoenix_case() :: Macro.t()
  def phoenix_case do
    quote do
      use Aurora.UixWeb.Test.ConnCase
      import Phoenix.LiveViewTest
      import Aurora.Uix.Test.Helper
      import Aurora.UixWeb.UICase
      import Aurora.UixWeb.Test.SectionHelper
    end
  end

  ## PRIVATE
  # Asserts that the order of values matches the expected order.
  @spec assert_value_order(list(), list(), boolean(), list()) :: {boolean(), list()}
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
