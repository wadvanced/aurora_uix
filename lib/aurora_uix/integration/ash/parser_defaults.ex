defmodule Aurora.Uix.Integration.Ash.ParserDefaults do
  @moduledoc """
  Provides parsing functionality for ash-based resource configurations.

  Automatically detects and configures context-related functions for resources, such as
  listing, getting, creating, updating, and deleting elements. Infers function names
  based on context and schema module conventions.

  ## Implemented Options

  * `:list_function` - Function reference for reading all elements (default: list_<source>/1).
  * `:list_function_paginated` - Function reference for reading elements using pagination.
  * `:get_function` - Function reference for getting one element (default: get_<module>/2).
  * `:delete_function` - Function reference for deleting an element (default: delete_<module>/1).
  * `:create_function` - Function reference for creating elements (default: create_<module>/1).
  * `:update_function` - Function reference for updating elements (default: update_<module>/2).
  * `:change_function` - Function reference for creating changesets (default: change_<module>/2).
  * `:new_function` - Function reference for creating new changesets (default: new_<module>/2).

  All functions use the ash resource naming conventions to automatically
  discover implementations. Functions are resolved with the appropriate arity from the
  configured ash resource or ash domain.
  """
  alias Ash.Resource.Actions
  alias Ash.Resource.Info

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

  def default_value(
        %{source: _source, module: _module},
        %{context: ash_domain, schema: ash_resource},
        :list_function
      ) do
    ash_domain
    |> get_proper_actions(ash_resource, :read)
    |> maybe_get_primary_action()
    |> create_function_reference(ash_domain, ash_resource)
  end

  def default_value(
        %{source: _source, module: _module},
        %{context: ash_domain, schema: ash_resource},
        :list_function_paginated
      ) do
    ash_domain
    |> get_proper_actions(ash_resource, :read)
    |> Enum.filter(& &1.pagination)
    |> maybe_get_primary_action()
    |> create_function_reference(ash_domain, ash_resource)
  end

  # def default_value(%{module: module}, %{context: context}, :get_function) do
  #   create_function_reference(context, ["get_#{module}", "get_#{module}!"], 2)
  # end
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

  @spec get_proper_actions(nil | module(), nil | module(), atom()) :: list()
  defp get_proper_actions(nil, nil, _action_type), do: []

  defp get_proper_actions(nil, ash_resource, action_type) do
    action_module = action_module(action_type)

    ash_resource
    |> Info.actions()
    |> Enum.filter(&(&1.__struct__ == action_module))
  end

  @spec action_module(atom()) :: module()
  defp action_module(:read), do: Actions.Read
  # defp action_module(:create), do: Actions.Create
  # defp action_module(:update), do: Actions.Update
  # defp action_module(:destroy), do: Actions.Destroy

  @spec create_function_reference(atom(), module() | nil, module() | nil) :: function()
  defp create_function_reference(nil, _ash_domain, _ash_resource),
    do: &__MODULE__.undefined_function/2

  defp create_function_reference(action, nil, ash_resource), do: {:ash, action, ash_resource}

  @spec maybe_get_primary_action(list()) :: nil | struct()
  defp maybe_get_primary_action(actions) do
    actions
    |> Enum.filter(& &1.primary?)
    |> get_first_valid(actions)
  end

  @spec get_first_valid(list(), list()) :: nil | struct()
  defp get_first_valid([], []), do: nil
  defp get_first_valid([], [first_action | _rest]), do: first_action

  defp get_first_valid([filtered_first_action | _rest_filtered], _actions),
    do: filtered_first_action
end
