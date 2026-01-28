defmodule Aurora.Uix.Integration.Crud do
  @moduledoc """
  Behaviour defining unified CRUD operations with polymorphic dispatch.

  Provides a consistent interface for CRUD operations across multiple backend implementations
  (Ash Framework and Context-based Ecto). Acts as both a behaviour specification and a
  dispatcher that routes operations to the appropriate implementation based on connector type.

  ## Key Features

  - Behaviour contract with 8 callbacks for CRUD operations
  - Polymorphic dispatch to backend-specific implementations
  - Runtime module resolution via application configuration
  - Consistent interface across Ash and Context backends
  - Type-safe connector-based routing

  ## Implementation Resolution

  The module uses compile-time configuration to build a map of connector types to
  implementation modules. Configuration is read from `:aurora_uix` application:

      config :aurora_uix, :crud_integration_modules,
        ash: Aurora.Uix.Integration.Ash.Crud,
        ctx: Aurora.Uix.Integration.Ctx.Crud

  At runtime, `get_crud_module/1` resolves the appropriate implementation:

  1. Extracts `type` from `%Connector{type: :ash}` or `%Connector{type: :ctx}`
  2. Looks up implementation in `@crud_integration_modules` map
  3. Delegates operation to resolved module (e.g., `AshCrud.list/2`)
  4. Raises error if type is `nil` or not found in configuration

  ## Key Constraints

  - Implementation modules must implement all 8 callbacks
  - Connector type must be configured in application environment
  - Invalid or missing types raise runtime errors
  - Backend implementations are resolved at compile time for performance
  """
  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Integration.Connector

  @crud_integration_modules :aurora_uix
                            |> Application.compile_env(:crud_integration_modules,
                              ash: Aurora.Uix.Integration.Ash.Crud,
                              ctx: Aurora.Uix.Integration.Ctx.Crud
                            )
                            |> Map.new()

  @doc """
  Lists resources with optional query parameters.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `opts` (keyword()) - Query options passed to the backend implementation.

  ## Returns

  Pagination.t() - Pagination structure containing query results and metadata.
  """
  @callback list(term(), keyword()) :: Pagination.t()

  @doc """
  Navigates to a specific page in paginated results.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The target page number.

  ## Returns

  Pagination.t() - Updated pagination structure with the requested page data.
  """
  @callback to_page(term(), Pagination.t(), integer()) :: Pagination.t()

  @doc """
  Retrieves a single resource by ID.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `id` (term()) - The resource identifier.
  - `opts` (keyword()) - Additional query options.

  ## Returns

  struct() | nil - The retrieved resource or `nil` if not found.
  """
  @callback get(term(), term(), keyword()) :: struct() | nil

  @doc """
  Creates a changeset or form for updating a resource.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `entity` (struct()) - The resource to create a changeset for.
  - `attrs` (map()) - Attributes to apply.

  ## Returns

  struct() - A changeset or form structure.
  """
  @callback change(term(), struct(), map()) :: struct()

  @doc """
  Creates a new resource struct with optional preloading.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `attrs` (map()) - Initial attributes for the new resource.
  - `opts` (keyword()) - Additional options.

  ## Returns

  struct() - A new resource struct.
  """
  @callback new(term(), map(), keyword()) :: struct()

  @doc """
  Creates a new resource in the database.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `params` (map()) - Parameters for the new resource.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.
  """
  @callback create(term(), map()) :: tuple()

  @doc """
  Updates an existing resource in the database.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `entity` (struct()) - The resource to update.
  - `params` (map()) - Parameters to update.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.
  """
  @callback update(term(), struct(), map()) :: tuple()

  @doc """
  Deletes a resource from the database.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `entity` (struct()) - The resource to delete.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.
  """
  @callback delete(term(), struct()) :: tuple()

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
    do: get_crud_module(type).list(crud_spec, opts)

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
    do: get_crud_module(type).to_page(crud_spec, pagination, page)

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
      do: get_crud_module(type).get(crud_spec, id, opts)

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
      do: get_crud_module(type).change(crud_spec, entity, attrs)

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
      do: get_crud_module(type).new(crud_spec, attrs, opts)

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
      do: get_crud_module(type).update(crud_spec, entity, params)

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
      do: get_crud_module(type).create(crud_spec, params)

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
      do: get_crud_module(type).delete(crud_spec, entity)

  ## PRIVATE

  # Resolves CRUD implementation module based on connector type.
  #
  # Uses compile-time configuration map to look up the appropriate module.
  # The type must match a key in @crud_integration_modules or an error is raised.
  @spec get_crud_module(atom()) :: module()
  defp get_crud_module(nil), do: raise("The type of connector is nil")

  defp get_crud_module(type) do
    case Map.get(@crud_integration_modules, type) do
      nil -> raise("Invalid connector module for type: #{inspect(type)}")
      crud_module -> crud_module
    end
  end
end
