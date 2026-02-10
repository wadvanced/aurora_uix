defmodule Aurora.Uix.Integration.Ctx.ContextParserDefaults do
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

  @list_function :list_function
  @list_function_paginated :list_function_paginated
  @get_function :get_function
  @delete_function :delete_function
  @create_function :create_function
  @update_function :update_function
  @change_function :change_function
  @new_function :new_function

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
  - `auix_action_name` (atom()) - The Aurora UIX action key (e.g., `:list_function`,
    `:get_function`).

  ## Returns

  Connector.t() - A `%Connector{}` struct wrapping the `%CrudSpec{}` and function reference.

  ## Examples

      iex> default_value(%{source: "users", module: "user"}, %{context: MyApp.Accounts},
      ...>   :list_function)
      %Connector{type: :ctx, crud_spec: %CrudSpec{function_spec: &MyApp.Accounts.list_users/1}}

      iex> default_value(%{module: "post"}, %{context: MyApp.Blog}, :get_function)
      %Connector{type: :ctx, crud_spec: %CrudSpec{function_spec: &MyApp.Blog.get_post/2}}
  """
  @spec option_value(map(), map(), keyword(), atom()) :: Connector.t()
  def option_value(
        %{source: source, module: module},
        %{context: context, name: resource_name},
        opts,
        @list_function = auix_action_name
      ) do
    function_ref =
      Keyword.get(opts, @list_function)

    create_connector(
      context,
      function_ref,
      ["list_#{source}", "list_#{module}"],
      1,
      resource_name,
      auix_action_name
    )
  end

  def option_value(
        %{source: source, module: module},
        %{context: context, name: resource_name},
        opts,
        @list_function_paginated = auix_action_name
      ) do
    function_ref = Keyword.get(opts, @list_function_paginated)

    create_connector(
      context,
      function_ref,
      ["list_#{source}_paginated", "list_#{module}_paginated"],
      1,
      resource_name,
      auix_action_name
    )
  end

  def option_value(
        %{module: module},
        %{context: context, name: resource_name},
        opts,
        @get_function = auix_action_name
      ) do
    function_ref = Keyword.get(opts, @get_function)

    create_connector(
      context,
      function_ref,
      ["get_#{module}", "get_#{module}!"],
      2,
      resource_name,
      auix_action_name
    )
  end

  def option_value(
        %{module: module},
        %{context: context, name: resource_name},
        opts,
        @delete_function = auix_action_name
      ) do
    function_ref = Keyword.get(opts, @delete_function)

    create_connector(
      context,
      function_ref,
      ["delete_#{module}", "delete_#{module}!"],
      1,
      resource_name,
      auix_action_name
    )
  end

  def option_value(
        %{module: module},
        %{context: context, name: resource_name},
        opts,
        @create_function = auix_action_name
      ) do
    function_ref = Keyword.get(opts, @create_function)

    create_connector(
      context,
      function_ref,
      ["create_#{module}"],
      1,
      resource_name,
      auix_action_name
    )
  end

  def option_value(
        %{module: module},
        %{context: context, name: resource_name},
        opts,
        :update_function = auix_action_name
      ) do
    function_ref = Keyword.get(opts, @update_function)

    create_connector(
      context,
      function_ref,
      ["update_#{module}"],
      2,
      resource_name,
      auix_action_name
    )
  end

  def option_value(
        %{module: module},
        %{context: context, name: resource_name},
        opts,
        :change_function = auix_action_name
      ) do
    function_ref = Keyword.get(opts, @change_function)

    create_connector(
      context,
      function_ref,
      ["change_#{module}"],
      2,
      resource_name,
      auix_action_name
    )
  end

  def option_value(
        %{module: module},
        %{context: context, name: resource_name},
        opts,
        :new_function = auix_action_name
      ) do
    function_ref = Keyword.get(opts, @new_function)
    create_connector(context, function_ref, ["new_#{module}"], 2, resource_name, auix_action_name)
  end

  @doc false
  # Placeholder function used when no valid function reference is found.
  @spec undefined_function(term(), term()) :: nil
  def undefined_function(_arg1 \\ nil, _arg2 \\ nil), do: nil

  ## PRIVATE

  # Creates a Connector wrapping a CrudSpec with the discovered function reference.
  @spec create_connector(nil | module(), nil | function(), list(), integer(), atom(), atom()) ::
          Connector.t()
  defp create_connector(
         context,
         function_in_opts,
         functions,
         arity,
         resource_name,
         auix_action_name
       ) do
    context
    |> create_function_reference(function_in_opts, functions, arity)
    |> notify_error(resource_name, auix_action_name, arity)
    |> CrudSpec.new(auix_action_name)
    |> Connector.new(:ctx)
  end

  # Discovers and creates a function reference from the context module.
  @spec create_function_reference(nil | module(), nil | function(), list(), integer()) ::
          nil | function()
  defp create_function_reference(nil, nil, _functions, expected_arity) do
    {function_ref, _} =
      Code.eval_string("&#{__MODULE__}.undefined_function/#{expected_arity}")

    function_ref
  end

  defp create_function_reference(context, nil, functions, expected_arity) do
    implemented_functions =
      :functions
      |> context.__info__()
      |> Enum.filter(fn {_name, arity} -> arity == expected_arity end)
      |> Enum.map(&(&1 |> elem(0) |> to_string()))

    auix_action_name =
      functions
      |> Enum.filter(&(&1 in implemented_functions))
      |> List.first()

    if auix_action_name do
      context
      |> Module.concat(nil)
      |> then(&"&#{&1}.#{auix_action_name}/#{expected_arity}")
      |> Code.eval_string()
      |> elem(0)
    else
      nil
    end
  end

  defp create_function_reference(_context, function_in_opts, _functions, expected_arity)
       when is_function(function_in_opts, expected_arity), do: function_in_opts

  @spec notify_error(nil | function(), atom(), atom(), integer) :: function()
  defp notify_error(nil, resource_name, auix_action_name, arity),
    do:
      raise(
        "Function reference error in option ':#{auix_action_name}' of resource ':#{resource_name}', expected a valid and existing function of arity '#{arity}'"
      )

  defp notify_error(function_ref, _resource_name, _auix_action_name, _arity), do: function_ref
end
