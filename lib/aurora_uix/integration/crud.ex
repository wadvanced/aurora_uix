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
  alias Aurora.Uix.Integration.Connector
  alias Aurora.Uix.Integration.Ctx.Crud, as: CtxCrud

  @doc """
  Applies a list operation using the provided Connector.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `opts` (keyword()) - Query options passed to the backend implementation.

  ## Returns

  Pagination.t() - Pagination structure containing query results.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_list_function(connector, where: [{:status, :eq, "active"}])
      %Pagination{entries: [...], pages_count: 1}

      iex> connector = %Connector{type: :ctx, crud_spec: %CrudSpec{...}}
      iex> apply_list_function(connector, limit: 10)
      %Pagination{entries: [...]}
  """
  @spec apply_list_function(Connector.t(), keyword()) :: Pagination.t()
  def apply_list_function(%Connector{type: type, crud_spec: crud_spec}, opts),
    do: get_connector(type).list(crud_spec, opts)

  @doc """
  Navigates to a specific page in paginated results.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The target page number.

  ## Returns

  Pagination.t() - Updated pagination structure with the requested page data.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_to_page(connector, %Pagination{page: 1, pages_count: 5}, 2)
      %Pagination{page: 2, entries: [...]}
  """
  @spec apply_to_page(Connector.t(), Pagination.t(), integer()) :: Pagination.t()
  def apply_to_page(%Connector{type: type, crud_spec: crud_spec}, pagination, page),
    do: get_connector(type).to_page(crud_spec, pagination, page)

  @doc """
  Retrieves a single entity by ID using the provided Connector.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `id` (term()) - The entity identifier.
  - `opts` (keyword()) - Options:
    * `:where` (list()) - Additional filter clauses (Ash only).
    * `:preload` (term()) - Associations to load.

  ## Returns

  struct() | nil - The retrieved entity or `nil` if not found.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_get_function(connector, "123", preload: [:posts])
      %MyApp.User{id: "123"}

      iex> apply_get_function(connector, "missing-id", [])
      nil
  """
  @spec apply_get_function(Connector.t(), term(), keyword()) :: struct() | nil
  def apply_get_function(
        %Connector{type: type, crud_spec: crud_spec},
        id,
        opts
      ),
      do: get_connector(type).get(crud_spec, id, opts)

  @doc """
  Creates a changeset for updating an entity.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `entity` (struct()) - The entity to create a changeset for.
  - `attrs` (map()) - Attributes to apply to the changeset. Defaults to `%{}`.

  ## Returns

  struct() - A changeset structure (e.g., form or changeset).

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_change_function(connector, %MyApp.User{}, %{name: "John"})
      %AshPhoenix.Form{...}

      iex> connector = %Connector{type: :ctx, crud_spec: %CrudSpec{...}}
      iex> apply_change_function(connector, %MyContext.Item{}, %{status: "active"})
      %Ecto.Changeset{...}
  """
  @spec apply_change_function(Connector.t(), struct(), map()) :: struct()
  def apply_change_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity,
        attrs \\ %{}
      ),
      do: get_connector(type).change(crud_spec, entity, attrs)

  @doc """
  Creates a new entity struct using the provided Connector.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `attrs` (map()) - Initial attributes for the new entity.
  - `opts` (keyword()) - Options:
    * `:preload` (list()) - Associations to load.

  ## Returns

  struct() - A new entity struct with the provided attributes.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_new_function(connector, %{name: "Jane"}, preload: [:profile])
      %MyApp.User{name: "Jane", profile: %MyApp.Profile{}}

      iex> connector = %Connector{type: :ctx, crud_spec: %CrudSpec{...}}
      iex> apply_new_function(connector, %{title: "New"}, [])
      %MyContext.Item{title: "New"}
  """
  @spec apply_new_function(Connector.t(), map(), keyword()) :: struct()
  def apply_new_function(
        %Connector{type: type, crud_spec: crud_spec},
        attrs,
        opts
      ),
      do: get_connector(type).new(crud_spec, attrs, opts)

  @doc """
  Updates an existing resource in the database.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `entity` (struct()) - The resource to update.
  - `params` (map()) - Parameters to update.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_update_function(connector, %MyApp.User{id: 1}, %{name: "Bob"})
      {:ok, %MyApp.User{id: 1, name: "Bob"}}
  """
  @spec apply_update_function(Connector.t(), struct(), map()) :: tuple()
  def apply_update_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity,
        params
      ),
      do: get_connector(type).update(crud_spec, entity, params)

  @doc """
  Creates a new resource in the database.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `params` (map()) - Parameters for the new resource.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> connector = %Connector{type: :ctx, crud_spec: %CrudSpec{...}}
      iex> apply_create_function(connector, %{name: "Alice", email: "alice@example.com"})
      {:ok, %MyApp.User{name: "Alice"}}
  """
  @spec apply_create_function(Connector.t(), map()) :: tuple()
  def apply_create_function(
        %Connector{type: type, crud_spec: crud_spec},
        params
      ),
      do: get_connector(type).create(crud_spec, params)

  @doc """
  Deletes a resource from the database.

  ## Parameters

  - `connector` (Connector.t()) - The Connector containing type and crud_spec.
  - `entity` (struct()) - The resource to delete.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_delete_function(connector, %MyApp.User{id: 1})
      {:ok, %MyApp.User{id: 1}}
  """
  @spec apply_delete_function(Connector.t(), struct()) :: tuple()
  def apply_delete_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity
      ),
      do: get_connector(type).delete(crud_spec, entity)

  ## PRIVATE

  # Returns the appropriate CRUD module based on connector type.
  @spec get_connector(atom()) :: module()
  defp get_connector(:ash), do: AshCrud
  defp get_connector(:ctx), do: CtxCrud
  defp get_connector(nil), do: raise("The type of connector is nil")
  defp get_connector(type), do: raise("Invalid connector module for type: #{inspect(type)}")
end
