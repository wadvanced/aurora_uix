defmodule Aurora.Uix.Parsers.ContextParser do
  @moduledoc """
  Provides parsing functionality for context-based resource configurations.

  Automatically detects and configures context-related functions for resources, such as
  listing, getting, creating, updating, and deleting elements. Infers function names
  based on context and schema module conventions.

  ## Supported Options

  * `:list_function` - Function reference for reading all elements (default: list_<source>/1).
  * `:list_function_paginated` - Function reference for reading elements using pagination.
  * `:get_function` - Function reference for getting one element (default: get_<module>/2).
  * `:delete_function` - Function reference for deleting an element (default: delete_<module>/1).
  * `:create_function` - Function reference for creating elements (default: create_<module>/1).
  * `:update_function` - Function reference for updating elements (default: update_<module>/2).
  * `:change_function` - Function reference for creating changesets (default: change_<module>/2).
  * `:new_function` - Function reference for creating new changesets (default: new_<module>/2).

  All functions use the context module and schema module naming conventions to automatically
  discover implementations. Functions are resolved with the appropriate arity from the
  configured context module.
  """

  @behaviour Aurora.Uix.Parser

  @doc """
  Returns the list of supported context option keys.

  ## Returns
  list(atom()) - List of supported option keys for context parsing.
  """
  @spec get_options() :: list(atom())
  def get_options do
    [
      :list_function,
      :list_function_paginated,
      :get_function,
      :delete_function,
      :update_function,
      :create_function,
      :change_function,
      :new_function
    ]
  end

  @doc """
  Resolves default values for context-derived properties.

  Discovers context functions by name convention and arity. Uses source (table name) and
  module (schema module name) to construct expected function names.

  ## Parameters
  - `parsed_opts` (map()) - Map containing resolved options with `:source` and `:module`.
  - `resource_config` (map()) - Contains `:context` (module()) with available functions.
  - `key` (atom()) - Key for which to produce the default value.

  ## Returns
  function() - Function reference if found, otherwise undefined_function/2.
  """
  @spec default_value(map(), map(), atom()) :: term() | nil
  def default_value(%{source: source, module: module}, %{context: context}, :list_function) do
    create_function_reference(context, ["list_#{source}", "list_#{module}"], 1)
  end

  def default_value(
        %{source: source, module: module},
        %{context: context},
        :list_function_paginated
      ) do
    create_function_reference(
      context,
      ["list_#{source}_paginated", "list_#{module}_paginated"],
      1
    )
  end

  def default_value(%{module: module}, %{context: context}, :get_function) do
    create_function_reference(context, ["get_#{module}", "get_#{module}!"], 2)
  end

  def default_value(%{module: module}, %{context: context}, :delete_function) do
    create_function_reference(context, ["delete_#{module}", "delete_#{module}!"], 1)
  end

  def default_value(%{module: module}, %{context: context}, :create_function) do
    create_function_reference(context, ["create_#{module}"], 1)
  end

  def default_value(%{module: module}, %{context: context}, :update_function) do
    create_function_reference(context, ["update_#{module}"], 2)
  end

  def default_value(%{module: module}, %{context: context}, :change_function) do
    create_function_reference(context, ["change_#{module}"], 2)
  end

  def default_value(%{module: module}, %{context: context}, :new_function) do
    create_function_reference(context, ["new_#{module}"], 2)
  end

  def default_value(_parsed_opts, _resource_config, _key), do: nil

  @doc false
  # Placeholder function used when no valid function reference is found.
  @spec undefined_function(any(), any()) :: nil
  def undefined_function(_arg1, _arg2 \\ nil), do: nil

  ## PRIVATE

  @spec create_function_reference(module(), list(binary()), integer()) :: function()

  defp create_function_reference(nil, _functions, _expected_arity),
    do: &__MODULE__.undefined_function/2

  defp create_function_reference(context, [first_selected | _rest] = functions, expected_arity) do
    implemented_functions =
      :functions
      |> context.__info__()
      |> Enum.filter(fn {_name, arity} -> arity == expected_arity end)
      |> Enum.map(&(&1 |> elem(0) |> to_string()))

    function_name =
      functions
      |> Enum.filter(&(&1 in implemented_functions))
      |> List.first(first_selected)

    context
    |> Module.concat(nil)
    |> then(&"&#{&1}.#{function_name}/#{expected_arity}")
    |> Code.eval_string()
    |> elem(0)
  end
end
