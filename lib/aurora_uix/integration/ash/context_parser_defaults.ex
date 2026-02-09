defmodule Aurora.Uix.Integration.Ash.ContextParserDefaults do
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
  alias Aurora.Uix.Integration.Ash.Crud, as: AshCrud
  alias Aurora.Uix.Integration.Ash.CrudSpec
  alias Aurora.Uix.Integration.Connector

  @list_function_aliases [:list_function, :ash_read_action]
  @list_function_paginated_aliases [:list_function_paginated, :ash_read_action_paginated]
  @get_function_aliases [:get_function, :ash_get_action]
  @delete_function_aliases [:delete_function, :ash_destroy_action]
  @create_function_aliases [:create_function, :ash_create_action]
  @update_function_aliases [:update_function, :ash_update_action]
  @change_function_aliases [:change_function, :ash_change_action]
  @new_function_aliases [:new_function, :ash_new_function]

  @error_action_type "Does not exists or it is of the wrong type"
  @error_action_needs_pagination "#{@error_action_type}, or pagination is not supported"
  @error_new_function_invalid "The function reference is nil or invalid, should be a function with 2 arity (attrs, opts)"

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
    `:list_function_paginated`, `:get_function`, `:change_function`, `:create_function`,
    `:update_function`, `:delete_function`, `:new_function`).

  ## Returns

  Connector.t() | nil - Returns `%Connector{}` struct with `%CrudSpec{}` if action
  found, otherwise returns `nil` for unhandled keys.

  ## Examples

      iex> default_value(%{}, %{context: MyApp.Accounts, schema: MyApp.User}, :list_function)
      %Connector{type: :ash, crud_spec: %CrudSpec{...}}

      iex> default_value(%{}, %{context: nil, schema: MyApp.Post}, :get_function)
      %Connector{type: :ash, crud_spec: %CrudSpec{...}}
  """
  @spec option_value(map(), map(), keyword(), atom()) :: Connector.t() | nil
  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        auix_action
      )
      when auix_action in @list_function_aliases do
    ash_action_type = :read

    ash_action_name = get_option(opts, @list_function_aliases, ash_action_type)

    ash_domain
    |> get_proper_actions(ash_resource, ash_action_type, ash_action_name)
    |> maybe_get_primary_action()
    |> notify_action_error(@error_action_type, resource_name, ash_action_type, ash_action_name)
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        auix_action
      )
      when auix_action in @list_function_paginated_aliases do
    ash_action_type = :read
    ash_action_name = get_option(opts, @list_function_paginated_aliases, ash_action_type)

    ash_domain
    |> get_proper_actions(ash_resource, ash_action_type, ash_action_name)
    |> Enum.filter(& &1.pagination)
    |> maybe_get_primary_action()
    |> notify_action_error(
      @error_action_needs_pagination,
      resource_name,
      ash_action_type,
      ash_action_name
    )
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        auix_action
      )
      when auix_action in @get_function_aliases do
    ash_action_type = :read
    ash_action_name = get_option(opts, @get_function_aliases, ash_action_type)

    ash_domain
    |> get_proper_actions(ash_resource, ash_action_type, ash_action_name)
    |> maybe_get_primary_action()
    |> notify_action_error(@error_action_type, resource_name, ash_action_type, ash_action_name)
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        auix_action
      )
      when auix_action in @delete_function_aliases do
    ash_action_type = :destroy
    ash_action_name = get_option(opts, @delete_function_aliases, ash_action_type)

    ash_domain
    |> get_proper_actions(ash_resource, ash_action_type, ash_action_name)
    |> maybe_get_primary_action()
    |> notify_action_error(@error_action_type, resource_name, ash_action_type, ash_action_name)
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        auix_action
      )
      when auix_action in @create_function_aliases do
    ash_action_type = :create
    ash_action_name = get_option(opts, @create_function_aliases, ash_action_type)

    ash_domain
    |> get_proper_actions(ash_resource, ash_action_type, ash_action_name)
    |> maybe_get_primary_action()
    |> notify_action_error(@error_action_type, resource_name, ash_action_type, ash_action_name)
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        :update_function = auix_action
      )
      when auix_action in @update_function_aliases do
    ash_action_type = :update
    ash_action_name = get_option(opts, @update_function_aliases, ash_action_type)

    ash_domain
    |> get_proper_actions(ash_resource, ash_action_type, ash_action_name)
    |> maybe_get_primary_action()
    |> notify_action_error(@error_action_type, resource_name, ash_action_type, ash_action_name)
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        auix_action
      )
      when auix_action in @change_function_aliases do
    ash_action_type = :update
    ash_action_name = get_option(opts, @change_function_aliases, ash_action_type)

    ash_domain
    |> get_proper_actions(ash_resource, ash_action_type, ash_action_name)
    |> maybe_get_primary_action()
    |> notify_action_error(@error_action_type, resource_name, ash_action_type, ash_action_name)
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(
        _parsed_opts,
        %{context: ash_domain, schema: ash_resource, name: resource_name},
        opts,
        auix_action
      )
      when auix_action in @new_function_aliases do
    opts
    |> get_option(@new_function_aliases, &AshCrud.default_new_function/2)
    |> notify_error(@error_new_function_invalid, resource_name)
    |> create_function_reference(ash_domain, ash_resource, auix_action)
  end

  def option_value(_parsed_opts, _resource_config, _key), do: nil

  @doc false
  # Placeholder function used when no valid function reference is found.
  @spec undefined_function(term(), term()) :: nil
  def undefined_function(_arg1, _arg2 \\ nil), do: nil

  ## PRIVATE

  # Retrieves actions for a specific action type from Ash resource.
  @spec get_proper_actions(nil | module(), nil | module(), nil | atom(), atom()) :: list(struct())
  defp get_proper_actions(ash_domain, ash_resource, action_type, selected_action_name \\ nil)
  defp get_proper_actions(nil, nil, _action_type, _selected_action_name), do: []

  defp get_proper_actions(nil, ash_resource, action_type, selected_action_name) do
    action_module = action_module(action_type)

    ash_resource
    |> Info.actions()
    |> Enum.filter(&(&1.__struct__ == action_module))
    |> filter_selected_action(selected_action_name)
  end

  @spec filter_selected_action(list(), nil | atom()) :: list()
  defp filter_selected_action(actions, nil), do: actions

  defp filter_selected_action(actions, selected_action_name) do
    Enum.filter(actions, &(&1.name == selected_action_name))
  end

  # Maps action type atom to Ash action module.
  @spec action_module(atom()) :: module()
  defp action_module(:read), do: Actions.Read
  defp action_module(:create), do: Actions.Create
  defp action_module(:update), do: Actions.Update
  defp action_module(:destroy), do: Actions.Destroy

  # Creates function reference tuple for Ash actions.
  @spec create_function_reference(struct() | nil, module() | nil, module() | nil, atom()) ::
          Connector.t()

  defp create_function_reference(ash_action, ash_domain, ash_resource, auix_action_name) do
    definition =
      case {ash_domain, ash_resource} do
        {nil, nil} ->
          CrudSpec.new()

        {ash_domain, nil} ->
          resource = get_resource(ash_action, ash_domain)

          CrudSpec.new(
            ash_domain,
            resource,
            ash_action,
            auix_action_name
          )

        {ash_domain, ash_resource} ->
          CrudSpec.new(ash_domain, ash_resource, ash_action, auix_action_name)
      end

    Connector.new(definition, :ash)
  end

  # Retrieves Ash resource module from domain by action name.
  @spec get_resource(atom() | nil, module()) :: module() | nil
  defp get_resource(action, domain) do
    resource =
      domain
      |> Ash.Domain.Info.resource_references()
      |> Enum.filter(fn resource_reference ->
        Enum.any?(resource_reference.definitions, &(&1.name == action))
      end)
      |> List.first()

    if resource, do: resource.resource, else: nil
  end

  # Selects primary action or falls back to first available action.
  @spec maybe_get_primary_action(list(struct())) :: struct() | nil
  defp maybe_get_primary_action(actions) do
    actions
    |> Enum.filter(& &1.primary?)
    |> get_first_valid(actions)
  end

  @spec notify_action_error(nil | struct(), binary(), atom(), atom(), atom()) :: struct()
  defp notify_action_error(nil, message, resource_name, ash_action_type, ash_action_name),
    do:
      raise(
        "Error processing action ':#{ash_action_name}' of resource ':#{resource_name}' with expected type ':#{ash_action_type}' : #{message}"
      )

  defp notify_action_error(action, _message, _resource_name, _ash_action_type, _ash_action_name),
    do: action

  defp notify_error(function_ref, _message, _resource_name) when is_function(function_ref),
    do: function_ref

  defp notify_error(_function_ref, message, resource_name),
    do: raise("Error processing resource '#{resource_name}' options : #{message}")

  # Returns first valid action from filtered or fallback list.
  @spec get_first_valid(list(struct()), list(struct())) :: struct() | nil
  defp get_first_valid([], []), do: nil
  defp get_first_valid([], [first_action | _rest]), do: first_action

  defp get_first_valid([filtered_first_action | _rest_filtered], _actions),
    do: filtered_first_action

  defp get_option(opts, keys, default_value) do
    keys
    |> Enum.map(&Keyword.get(opts, &1))
    |> Enum.reject(&is_nil/1)
    |> List.first(default_value)
  end
end
