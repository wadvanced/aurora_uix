defmodule Aurora.Uix.Integration.Ash.ParserDefaults do
  @moduledoc """
  Parsing functionality for Ash-based resource configurations.

  Automatically detects and configures context-related functions for resources, such as
  listing, getting, creating, updating, and deleting elements. Infers function names
  based on context and schema module conventions using Ash resource naming conventions.

  ## Key Features

  - Automatic function discovery from Ash domains and resources
  - Primary action detection with fallback to first available action
  - Support for paginated and non-paginated read operations
  - Function reference creation with action metadata

  ## Key Constraints

  - Currently only implements read-related actions (`:list_function`,
    `:list_function_paginated`, `:get_function`)
  - Requires Ash domain and resource configuration
  - Returns placeholder function when no valid action is found
  - Functions are resolved from configured Ash resource or Ash domain

  ## Implemented Options

  - `:list_function` - Function reference for reading all elements
  - `:list_function_paginated` - Function reference for reading elements using pagination
  - `:get_function` - Function reference for getting one element
  """
  alias Ash.Resource.Actions
  alias Ash.Resource.Info

  @doc """
  Resolves default values for context-derived properties.

  Discovers Ash actions from the domain and resource, selecting primary actions when
  available or falling back to the first available action.

  ## Parameters

  - `parsed_opts` (map()) - Map containing resolved options with `:source` and `:module`.
  - `resource_config` (map()) - Map with keys:
    * `:context` (module() | nil) - The Ash domain module.
    * `:schema` (module() | nil) - The Ash resource module.
  - `key` (atom()) - The Aurora UIX action key (`:list_function`,
    `:list_function_paginated`, `:get_function`, `:change_function`).

  ## Returns

  tuple() | function() - Returns `{:ash, action, resource, auix_action}` tuple if action
  found, otherwise returns `&undefined_function/2`.

  ## Examples

      iex> default_value(%{}, %{context: MyApp.Accounts, schema: MyApp.User}, :list_function)
      {:ash, %Ash.Resource.Actions.Read{}, MyApp.User, :list_function}

      iex> default_value(%{}, %{context: nil, schema: MyApp.Post}, :get_function)
      {:ash, %Ash.Resource.Actions.Read{}, MyApp.Post, :get_function}
  """
  @spec default_value(map(), map(), atom()) :: tuple() | function()

  def default_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource},
        :list_function = auix_action
      ) do
    ash_domain
    |> get_proper_actions(ash_resource, :read)
    |> maybe_get_primary_action()
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def default_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource},
        :list_function_paginated = auix_action
      ) do
    ash_domain
    |> get_proper_actions(ash_resource, :read)
    |> Enum.filter(& &1.pagination)
    |> maybe_get_primary_action()
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def default_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource},
        :get_function = auix_action
      ) do
    ash_domain
    |> get_proper_actions(ash_resource, :read)
    |> maybe_get_primary_action()
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  #
  # def default_value(%{module: module}, %{context: context}, :delete_function) do
  #   create_function_reference(context, ["delete_#{module}", "delete_#{module}!"], 1)
  # end
  #
  # def default_value(%{module: module}, %{context: context}, :create_function) do
  #   create_function_reference(context, ["create_#{module}"], 1)
  # end
  #
  # def default_value(%{module: module}, %{context: context}, :update_function) do
  #   create_function_reference(context, ["update_#{module}"], 2)
  # end
  #
  def default_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource},
        :change_function = auix_action
      ) do
    ash_domain
    |> get_proper_actions(ash_resource, :update)
    |> maybe_get_primary_action()
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  # def default_value(%{module: module}, %{context: context}, :change_function) do
  #   create_function_reference(context, ["change_#{module}"], 2)
  # end
  #
  # def default_value(%{module: module}, %{context: context}, :new_function) do
  #   create_function_reference(context, ["new_#{module}"], 2)
  # end

  def default_value(_parsed_opts, _resource_config, _key), do: nil

  @doc false
  # Placeholder function used when no valid function reference is found.
  @spec undefined_function(any(), any()) :: nil
  def undefined_function(_arg1, _arg2 \\ nil), do: nil

  ## PRIVATE

  # Retrieves actions for a specific action type from Ash resource.
  @spec get_proper_actions(nil | module(), nil | module(), atom()) :: list()
  defp get_proper_actions(nil, nil, _action_type), do: []

  defp get_proper_actions(nil, ash_resource, action_type) do
    action_module = action_module(action_type)

    ash_resource
    |> Info.actions()
    |> Enum.filter(&(&1.__struct__ == action_module))
  end

  # Maps action type atom to Ash action module.
  @spec action_module(atom()) :: module()
  defp action_module(:read), do: Actions.Read
  # defp action_module(:create), do: Actions.Create
  defp action_module(:update), do: Actions.Update
  # defp action_module(:destroy), do: Actions.Destroy

  # Creates function reference tuple for Ash actions.
  @spec create_function_reference(nil | struct(), module() | nil, module() | nil, atom()) ::
          function()
  defp create_function_reference(nil, _ash_domain, _ash_resource, _auix_action),
    do: &__MODULE__.undefined_function/2

  defp create_function_reference(ash_action, nil, ash_resource, auix_action),
    do: {:ash, ash_action, ash_resource, auix_action}

  # Selects primary action or falls back to first available action.
  @spec maybe_get_primary_action(list()) :: nil | struct()
  defp maybe_get_primary_action(actions) do
    actions
    |> Enum.filter(& &1.primary?)
    |> get_first_valid(actions)
  end

  # Returns first valid action from filtered or fallback list.
  @spec get_first_valid(list(), list()) :: nil | struct()
  defp get_first_valid([], []), do: nil
  defp get_first_valid([], [first_action | _rest]), do: first_action

  defp get_first_valid([filtered_first_action | _rest_filtered], _actions),
    do: filtered_first_action
end
