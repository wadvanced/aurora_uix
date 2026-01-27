defmodule Aurora.Uix.Integration.Crud do
  @moduledoc """
  Unified CRUD operation interface supporting multiple backend implementations.

  Provides polymorphic dispatch for common CRUD operations, automatically routing to
  appropriate backend implementation (Ash Framework or custom functions) based on the
  function reference type.

  ## Key Features

  - Backend-agnostic CRUD operations (list, get, change)
  - Automatic routing between Ash and custom function implementations
  - Consistent pagination interface across backends
  - Support for both paginated and non-paginated listing operations

  ## Key Constraints

  - Function references must follow specific tuple format for Ash operations:
    `{:ash, action, action_module, auix_action}`
  - Non-Ash operations require function references with matching arities
  - Pagination structure depends on backend implementation
  """
  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Integration.Ash.Crud, as: AshCrud
  alias Aurora.Uix.Integration.Ctx.Crud, as: CtxCrud
  alias Aurora.Uix.Integration.Connector

  @doc """
  Applies a list operation using the provided function reference.

  ## Parameters

  - `list_function` (tuple() | function()) - Either an Ash tuple
    `{:ash, action, action_module, auix_action}` or a custom function reference.
  - `opts` (keyword()) - Query options passed to the backend implementation.

  ## Returns

  Pagination.t() - Pagination structure containing query results.

  ## Examples

      iex> apply_list_function([where: [{:status, :eq, "active"}]],
      ...>   {:ash, %Actions.Read{}, MyApp.User, :list_function})
      %Pagination{entries: [...], pages_count: 1}

      iex> apply_list_function([limit: 10], &MyContext.list_items/1)
      %Pagination{entries: [...]}
  """
  @spec apply_list_function(Connector.t(), keyword()) :: Pagination.t()
  def apply_list_function(%Connector{type: type, crud_spec: crud_spec}, opts) do
    type
    |> get_connector()
    |> apply(:list, [crud_spec, opts])
  end

  @doc """
  Navigates to a specific page in paginated results.

  ## Parameters

  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The target page number.
  - `list_function` (tuple() | function()) - The function reference used for fetching data.

  ## Returns

  Pagination.t() - Updated pagination structure with the requested page data.

  ## Examples

      iex> to_page(%Pagination{page: 1, pages_count: 5},
      ...>   2, {:ash, %Actions.Read{}, MyApp.User, :list_function_paginated})
      %Pagination{page: 2, entries: [...]}

      iex> to_page(%Pagination{page: 1}, 3, &MyContext.list_items/1)
      %Pagination{page: 3, entries: [...]}
  """
  @spec apply_to_page(Connector.t(), Pagination.t(), integer()) :: Pagination.t()
  def apply_to_page(%Connector{type: type, crud_spec: crud_spec}, pagination, page) do
    type
    |> get_connector()
    |> apply(:to_page, [crud_spec, pagination, page])
  end

  @doc """
  Retrieves a single entity by ID using the provided function reference.

  ## Parameters

  - `get_function` (tuple() | function()) - Either an Ash tuple
    `{:ash, action, action_module, :get_function}` or a custom function reference.
  - `id` (term()) - The entity identifier.
  - `opts` (keyword()) - Options:
    * `:where` (list()) - Additional filter clauses (Ash only).
    * `:preload` (term()) - Associations to load (Ash only).

  ## Returns

  struct() | nil - The retrieved entity or `nil` if not found.

  ## Examples

      iex> apply_get_function({:ash, %Actions.Read{}, MyApp.User, :get_function},
      ...>   "123", where: [{:status, :eq, "active"}])
      %MyApp.User{id: "123"}

      iex> apply_get_function(&MyContext.get_item/2, 42, [])
      %MyContext.Item{id: 42}
  """
  @spec apply_get_function(Connector.t(), term(), keyword()) :: struct() | nil
  def apply_get_function(
        %Connector{type: type, crud_spec: crud_spec},
        id,
        opts
      ) do
    type
    |> get_connector()
    |> apply(:get_function, [crud_spec, id, opts])
  end

  def apply_get_function(get_function, id, opts), do: get_function.(id, opts)

  @doc """
  Creates a changeset for updating an entity.

  ## Parameters

  - `entity` (struct()) - The entity to create a changeset for.
  - `change_function` (tuple() | function()) - Either an Ash tuple
    `{:ash, action, action_module, :change_function}` or a custom function reference.
  - `attrs` (map()) - Attributes to apply to the changeset. Defaults to `%{}`.

  ## Returns

  struct() - A changeset structure (e.g., `AshPhoenix.Form.t()` or `Ecto.Changeset.t()`).

  ## Examples

      iex> apply_change_function(%MyApp.User{}, 
      ...>   {:ash, %Actions.Update{}, MyApp.User, :change_function},
      ...>   %{name: "John"})
      %AshPhoenix.Form{...}

      iex> apply_change_function(%MyContext.Item{}, &MyContext.change_item/2, %{status: "active"})
      %Ecto.Changeset{...}
  """
  @spec apply_change_function(Connector.t(), struct(), map()) :: struct()
  def apply_change_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity,
        attrs \\ %{}
      ) do
    type
    |> get_connector()
    |> apply(:change, [crud_spec, entity, attrs])
  end

  @doc """
  Creates a new entity struct using the provided function reference.

  ## Parameters

  - `new_function` (tuple() | function()) - Either an Ash tuple
    `{:ash, action, action_module, :new_function}` or a custom function reference.
  - `attrs` (map()) - Initial attributes for the new entity.
  - `opts` (keyword()) - Options:
    * `:preload` (list()) - Associations to load (Ash only).

  ## Returns

  struct() - A new entity struct with the provided attributes.

  ## Examples

      iex> apply_new_function({:ash, %Ash.Resource.Actions.Create{}, MyApp.User,
      ...>   :new_function}, %{name: "Jane"}, preload: [:profile])
      %MyApp.User{name: "Jane", profile: %MyApp.Profile{}}

      iex> apply_new_function(&MyContext.new_item/2, %{title: "New"}, [])
      %MyContext.Item{title: "New"}
  """
  @spec apply_new_function(Connector.t(), map(), keyword()) :: struct()
  def apply_new_function(
        %Connector{type: type, crud_spec: crud_spec},
        attrs,
        opts
      ) do
    type
    |> get_connector()
    |> apply(:new, [crud_spec, attrs, opts])
  end

  @spec apply_update_function(Connector.t(), struct(), map()) :: struct()
  def apply_update_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity,
        params
      ) do
    type
    |> get_connector()
    |> apply(:update, [crud_spec, entity, params])
  end

  @spec apply_create_function(Connector.t(), map()) :: struct()
  def apply_create_function(
        %Connector{type: type, crud_spec: crud_spec},
        params
      ) do
    type
    |> get_connector()
    |> apply(:create, [crud_spec, params])
  end

  @spec apply_delete_function(Connector.t(), struct()) :: struct()
  def apply_delete_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity
      ) do
    type
    |> get_connector()
    |> apply(:delete, [crud_spec, entity])
  end

  ## PRIVATE
  defp get_connector(:ash), do: AshCrud
  defp get_connector(:ctx), do: CtxCrud
  defp get_connector(nil), do: raise("The type of connector is nil")
  defp get_connector(type), do: raise("Invalid connector module for type: #{inspect(type)}")
end
