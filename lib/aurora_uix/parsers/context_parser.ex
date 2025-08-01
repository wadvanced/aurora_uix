defmodule Aurora.Uix.Parsers.ContextParser do
  @moduledoc """
  Provides parsing functionality for context-based resource configurations in Elixir applications.

  Automatically detects and configures context-related functions for resources, such as listing, getting, creating, updating, and deleting elements.

  ## Key Features
  - Infers function names based on context and schema module conventions.
  - Supports custom function name overrides through options.
  - Handles different function arities for various resource operations.

  ## Key Constraints
  - Expects resource configuration to include `:context` and `:schema` keys.
  - Relies on naming conventions for default function detection unless overridden.

  ## Context Options
  - `:list_function` - Function reference for reading all the elements of the resource.
    By default, is list_<source>/1.
    The source is the name of the table.
    ### Required parameters
    Function should be able to handle the following parameters:
    - `opts` - Query options
    ### Expected return
    Function should be able to produce the following:
    - A list of entities or empty list.

  - `:list_paginated_function` - Function reference for reading elements using pagination.

  - `:get_function` - Function reference for getting one element of the resource.
    By default, is get_<schema_module>/2 or get_<schema_module>!/2.
    The schema_module is the name of the ecto schema module (the last part).
    ### Required parameters
    - `id` - Id of the entity
    - `opts` - Query options
    ### Expected return
    Function should be able to produce the following:
    - A single element or nil.

  - `:delete_function` - Name of the function for deleting a element of the resource.
    By default, is delete_<schema_module>/1 or delete_<schema_module>!/1.
    The schema_module is the name of the ecto schema module (the last part).
    ### Required parameters
    Function should be able to handle the following parameters:
    - `entity` - The entity to be deleted.
    ### Expected return
    Function should be able to produce the following:
    - `{:ok, entity}` - If the deletion was ok.
    - `{:error, changeset}` - If something went wrong.

  - `:create_function` - Insert a new element to the resource.
    By default, is create_<schema_module>/1.
    The schema_module is the name of the ecto schema module (the last part).

    ### Required parameters
    Function should be able to handle the following parameters:
    - `changeset` or `attribute map` - The mapped values for the entities keys.

    ### Expected return
    Function should be able to produce the following:
    - `{:ok, <created_element>}` - If it was properly stored.
    - `{:error, <changeset or relevant info>}` - If something went wrong.

  - `:update_function` - Updates an existing element in the resource.
    By default, is update_<schema_module>/2.
    The schema_module is the name of the ecto schema module (the last part).

    ### Required parameters
    Function should be able to handle the following parameters:
    - `entity or changeset` - The entity or changeset to be updated.
    - `attrs` - Attributes map with the changes.

    ### Expected return
    Function should be able to produce the following:
    - `{:ok, <updated_element>}` - If the update was completed.
    - `{:error, <changeset or relevant info>}` - If any error happened.

  - `:change_function` - Creates a changeset of changes.
    Similar to update_function, but does not perform any repo updates, only affects or produce changeset.
    By default, is change_<schema_module>/2.
    The schema_module is the name of the ecto schema module (the last part).

    ### Required parameters
    Function should be able to handle the following parameters:
    - `entity or changeset` - The entity or Changeset to be updated.
    - `attrs` - Attributes map with the changes to be applied.

    ### Expected return
    Function should be able to produce the following:
    - A Changeset.

  - `:new_function` (atom()) - Creates a changeset of changes.
    Its arity is always 2 and accepts a changeset or an element instance as the first argument,
    and a map with the changes to be applied. By default, is change_<schema_module>/2.
    The function should return a Changeset.
    ### Required parameters
    Function should be able to handle the following parameters:
    - `attrs` - Attribute map with the initial values for the changeset.
    - `opts` - Repo options for the new changeset. Normally used to pass the required preloads.

    ### Expected return
    Function should be able to produce the following:
    - A Changeset.

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

  ## Parameters
  - `parsed_opts` (map()) - Map (accumulator) for parsed options.
  - `resource_config` (map()) - Contains all the modules' configuration. Must include :context and :schema keys.
  - `key` (atom()) - Key for which to produce the default value.

  ## Returns
  term() - The default value for the given key, or nil if not found.

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

  ## PRIVATE

  @spec create_function_reference(module(), list(String.t()), integer()) :: function()
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
