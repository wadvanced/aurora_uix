defmodule Aurora.Uix.Parsers.ContextParser do
  @moduledoc """
  Provides parsing functionality for context-based resource configurations in Elixir applications.

  This module is designed to automatically detect and configure context-related functions
  for resources, such as listing, getting, creating, updating, and deleting elements.

  ## Key Features
  - Automatically infers function names based on context and schema module conventions
  - Supports custom function name overrides through options
  - Handles different function arities for various resource operations

  ## Function Detection Strategy
  The module attempts to find appropriate functions in the following order:
  1. User-provided custom function names
  2. Conventionally named functions following the pattern:
     - `list_<source>` or `list_<schema_module>`
     - `get_<module>` or `get_<module>!`
     - `delete_<module>` or `delete_<module>!`
     - `create_<module>`
     - `update_<module>`
     - `change_<module>`

  ## Example
      resource_config = %{
        context: MyApp.Context,
        schema: MyApp.Schema
      }

      parsed_opts = ContextParser.parse(%{}, resource_config)
  """
  use Aurora.Uix.Parsers.ParserCore

  @doc """
    Parse module and :index options.

    ## Parameters
      - `parsed_opts` (`map`) - Map (accumulator) for parsed options.
      - `resource_config` (map): Contains all the modules' configuration. Should have keys: :context and :schema
      - `opts` (keyword): List of options for handling valid context.

    ## Options
      - `:list_function` - Name of the function for reading all the elements of the resource.
        The name MUST be an atom, and the arity of the function is always 0.
        The function is expected to return a list of elements.
        By default, is list_<source>/0 or list_<schema_module>. The source, for ecto schema, is the name of the table,
        while the schema_module is the name of the ecto schema module.

      - `:get_function` - Name of the function for getting one element of the resource.
        Its arity is always 1 and accepts the id of the element as the only argument.
        The function is expected to return a single element or nil.
        By default, is get_<schema_module>/1 or get_<schema_module>!/1.
        The schema_module is the name of the ecto schema module (the last part).

      - `:delete_function` - Name of the function for deleting a element of the resource.
        Its arity is always 1 and accepts the id of the element as the only argument.
        By default, is delete_<schema_module>/1 or delete_<schema_module>!/1.
        The function is expected to return a tuple {:ok, <deleted_element>} or {:error, <changeset or relevant info>}

      - `:create_function` - Insert a new element to the resource.
        Its arity is always 1 and accepts a map of the element fields with their value, as the only argument.
        By default, is create_<schema_module>/2.
        The function is expected to return a tuple {:ok, <created_element>} or {:error, <changeset or relevant info>}

      - `:update_function` - Updates an existing element in the resource.
        Its arity is always 2 and accepts a changeset or an element instance as the first argument,
        and a map with the changes to be applied.
        By default, is change_<schema_module>/1.
        The function is expected to return tuple {:ok, <updated_element>} or {:error, <changeset or relevant info>}

      - `:change_function` - Creates a changeset of changes.
        Its arity is always 2 and accepts a changeset or an element instance as the first argument,
        and a map with the changes to be applied.
        By default, is change_<schema_module>/2.
        The function should return a Changeset.


  """
  @spec parse(map, map, keyword) :: map
  def parse(parsed_opts, resource_config, opts \\ [])

  def parse(parsed_opts, %{context: context} = _resource_config, _opts) when is_nil(context),
    do: parsed_opts

  def parse(parsed_opts, resource_config, opts) do
    parsed_opts
    |> add_opt(resource_config, opts, :list_function)
    |> add_opt(resource_config, opts, :get_function)
    |> add_opt(resource_config, opts, :delete_function)
    |> add_opt(resource_config, opts, :update_function)
    |> add_opt(resource_config, opts, :create_function)
    |> add_opt(resource_config, opts, :change_function)
    |> add_opt(resource_config, opts, :new_function)
  end

  @doc """
  Resolves default values for context-derived properties.

  ### Parameters
    - `parsed_opts` (`map`) - Map (accumulator) for parsed options.
    - `resource_config` (`map`) -  contains all the modules' configuration.
    - `key` (`atom`) -  Key value to produce the value from.

  """
  @spec default_value(map, map, atom) :: any
  def default_value(%{source: source, module: module}, %{context: context}, :list_function) do
    filter_function(context, ["list_#{source}", "list_#{module}"], 0)
  end

  def default_value(%{module: module}, %{context: context}, :get_function) do
    filter_function(context, ["get_#{module}", "get_#{module}!"], 1)
  end

  def default_value(%{module: module}, %{context: context}, :delete_function) do
    filter_function(context, ["delete_#{module}", "delete_#{module}!"], 1)
  end

  def default_value(%{module: module}, %{context: context}, :create_function) do
    filter_function(context, ["create_#{module}"], 2)
  end

  def default_value(%{module: module}, %{context: context}, :update_function) do
    filter_function(context, ["update_#{module}"], 2)
  end

  def default_value(%{module: module}, %{context: context}, :change_function) do
    filter_function(context, ["change_#{module}"], 2)
  end

  def default_value(%{module: module}, %{context: context}, :new_function) do
    filter_function(context, ["new_#{module}"], 1)
  end

  def default_value(_parsed_opts, _resource_config, _key), do: nil

  @spec filter_function(module, list, integer) :: atom
  defp filter_function(context, [first_selected | _rest] = functions, expected_arity) do
    implemented_functions =
      :functions
      |> context.__info__()
      |> Enum.filter(fn {_name, arity} -> arity == expected_arity end)
      |> Enum.map(&(&1 |> elem(0) |> to_string()))

    functions
    |> Enum.filter(&(&1 in implemented_functions))
    |> List.first(first_selected)
    |> to_atom()
  end

  @spec to_atom(binary | nil) :: atom
  defp to_atom(nil), do: nil
  defp to_atom(function_name), do: String.to_atom(function_name)
end
