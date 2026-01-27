defmodule Aurora.Uix.Integration.Ctx.ParserDefaults do
  @moduledoc """
  Default value resolution for Context-based resource configurations.

  Automatically discovers and configures Context-based function references for CRUD
  operations by introspecting context modules and matching function names based on
  naming conventions. Creates Connector structures wrapping CrudSpec configurations.

  ## Key Features

  - Automatic function discovery from context modules
  - Convention-based function name matching (e.g., `list_users`, `get_user`)
  - Fallback to alternative function names (e.g., `get_user!`)
  - Integration with Connector and CrudSpec structures
  - Support for all standard CRUD operations

  ## Key Constraints

  - Requires context module to be available
  - Function discovery based on naming conventions
  - Returns placeholder function when no valid function is found
  - Expected function arities must match operation requirements

  ## Implemented Options

  - `:list_function` - Lists all resources
  - `:list_function_paginated` - Lists resources with pagination
  - `:get_function` - Retrieves a single resource
  - `:delete_function` - Deletes a resource
  - `:create_function` - Creates a new resource
  - `:update_function` - Updates an existing resource
  - `:change_function` - Creates a changeset for updates
  - `:new_function` - Creates a new resource struct
  """
  alias Aurora.Uix.Integration.Connector
  alias Aurora.Uix.Integration.Ctx.CrudSpec

  @doc """
  Resolves default function references for Context-based operations.

  Discovers functions from the context module using naming conventions, selecting the
  first available match from a list of candidate names.

  ## Parameters

  - `parsed_opts` (map()) - Map containing:
    * `:source` (binary()) - The source name (e.g., "users").
    * `:module` (binary()) - The module name (e.g., "user").
  - `resource_config` (map()) - Map with:
    * `:context` (module()) - The context module to introspect.
  - `function_name` (atom()) - The Aurora UIX action key (e.g., `:list_function`,
    `:get_function`).

  ## Returns

  Connector.t() - A Connector struct wrapping the CrudSpec and function reference.

  ## Examples

      iex> default_value(%{source: "users", module: "user"}, %{context: MyApp.Accounts},
      ...>   :list_function)
      %Connector{type: :ctx, crud_spec: %CrudSpec{function_spec: &MyApp.Accounts.list_users/1}}

      iex> default_value(%{module: "post"}, %{context: MyApp.Blog}, :get_function)
      %Connector{type: :ctx, crud_spec: %CrudSpec{function_spec: &MyApp.Blog.get_post/2}}
  """
  @spec default_value(map(), map(), atom()) :: Connector.t()
  def default_value(
        %{source: source, module: module},
        %{context: context},
        :list_function = function_name
      ) do
    create_connector(context, ["list_#{source}", "list_#{module}"], 1, function_name)
  end

  def default_value(
        %{source: source, module: module},
        %{context: context},
        :list_function_paginated = function_name
      ) do
    create_connector(
      context,
      ["list_#{source}_paginated", "list_#{module}_paginated"],
      1,
      function_name
    )
  end

  def default_value(%{module: module}, %{context: context}, :get_function = function_name) do
    create_connector(context, ["get_#{module}", "get_#{module}!"], 2, function_name)
  end

  def default_value(%{module: module}, %{context: context}, :delete_function = function_name) do
    create_connector(context, ["delete_#{module}", "delete_#{module}!"], 1, function_name)
  end

  def default_value(%{module: module}, %{context: context}, :create_function = function_name) do
    create_connector(context, ["create_#{module}"], 1, function_name)
  end

  def default_value(%{module: module}, %{context: context}, :update_function = function_name) do
    create_connector(context, ["update_#{module}"], 2, function_name)
  end

  def default_value(%{module: module}, %{context: context}, :change_function = function_name) do
    create_connector(context, ["change_#{module}"], 2, function_name)
  end

  def default_value(%{module: module}, %{context: context}, :new_function = function_name) do
    create_connector(context, ["new_#{module}"], 2, function_name)
  end

  @doc false
  # Placeholder function used when no valid function reference is found.
  @spec undefined_function(term(), term()) :: nil
  def undefined_function(_arg1, _arg2 \\ nil), do: nil

  ## PRIVATE

  # Creates a Connector wrapping a CrudSpec with the discovered function reference.
  @spec create_connector(module() | nil, list(), integer(), atom()) :: Connector.t()
  defp create_connector(context, functions, arity, function_name) do
    context
    |> create_function_reference(functions, arity)
    |> CrudSpec.new(function_name)
    |> Connector.new(:ctx)
  end

  # Discovers and creates a function reference from the context module.
  @spec create_function_reference(module() | nil, list(), integer()) :: function()
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
