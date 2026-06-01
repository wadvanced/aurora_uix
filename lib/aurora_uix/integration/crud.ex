defmodule Aurora.Uix.Integration.Crud do
  @moduledoc """
  Behaviour defining unified CRUD operations with polymorphic dispatch.

  Provides a consistent interface for CRUD operations across multiple backend implementations
  (Ash Framework and Context-based Ecto). Acts as both a behaviour specification and a
  dispatcher that routes operations to the appropriate implementation based on connector type.

  ## Key Features

  - Behaviour contract with 9 callbacks for CRUD operations (8 data callbacks plus
    `socket_opts/2` for per-call options resolved from `socket.assigns`)
  - Polymorphic dispatch to backend-specific implementations
  - Runtime module resolution via application configuration
  - Consistent interface across Ash and Context backends
  - Type-safe connector-based routing
  - Backend-specific extraction of socket-derived options (e.g. the Ash backend
    pulls an `actor:` from `socket.assigns` for policy-protected resources)

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

  - Implementation modules must implement all 9 callbacks
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
  - `opts` (keyword()) - Query options passed to the backend implementation. The Ash
    backend honours `:actor` to forward an actor on `Ash.Query.for_read/3` and
    `Ash.read/2`.

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
  - `opts` (keyword()) - Additional options. The Ash backend honours `:actor`.

  ## Returns

  Pagination.t() - Updated pagination structure with the requested page data.
  """
  @callback to_page(term(), Pagination.t(), integer(), keyword()) :: Pagination.t()

  @doc """
  Retrieves a single resource by ID.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `id` (term()) - The resource identifier.
  - `opts` (keyword()) - Additional query options. The Ash backend honours `:actor`
    (forwarded to `Ash.get/3` and `Ash.load/3`) and `:preload`.

  ## Returns

  struct() | nil - The retrieved resource or `nil` if not found.
  """
  @callback get(term(), term(), keyword()) :: struct() | nil

  @doc """
  Creates a changeset or form for updating a resource.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `entity` (struct()) - The resource to create a changeset for.
  - `form_name` (atom() | binary()) - The name of the underlying form.
  - `attrs` (map()) - Attributes to apply.
  - `opts` (keyword()) - Additional options. The Ash backend forwards `:actor` to
    `AshPhoenix.Form.for_update/3`.

  ## Returns

  struct() - A changeset or form structure.
  """
  @callback change(term(), struct(), atom() | binary(), map(), keyword()) :: struct()

  @doc """
  Creates a new resource struct with optional preloading.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `attrs` (map()) - Initial attributes for the new resource.
  - `opts` (keyword()) - Additional options. The Ash backend honours `:actor` when
    preloading associations via `Ash.load/3`.

  ## Returns

  struct() - A new resource struct.
  """
  @callback new(term(), map(), keyword()) :: struct()

  @doc """
  Creates a new resource in the database.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `params` (map()) - Parameters for the new resource.
  - `opts` (keyword()) - Additional options. The Ash backend forwards `:actor` to
    `Ash.create/3`.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.
  """
  @callback create(term(), map(), keyword()) :: tuple()

  @doc """
  Updates an existing resource in the database.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `entity` (struct()) - The resource to update.
  - `params` (map()) - Parameters to update.
  - `opts` (keyword()) - Additional options. The Ash backend forwards `:actor` to
    `Ash.update/3`.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.
  """
  @callback update(term(), struct(), map(), keyword()) :: tuple()

  @doc """
  Deletes a resource from the database.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `entity` (struct()) - The resource to delete.
  - `opts` (keyword()) - Additional options. The Ash backend forwards `:actor` to
    `Ash.destroy/2`.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.
  """
  @callback delete(term(), struct(), keyword()) :: tuple()

  @doc """
  Resolves per-call options from a LiveView socket for a given crud_spec.

  Each backend decides — using only its own crud_spec — what (if anything) should be
  pulled from `socket.assigns` and forwarded as opts to subsequent CRUD calls. The Ash
  backend reads `crud_spec.actor_assign` and returns `[actor: socket.assigns[<assign>]]`
  when the named assign holds a non-nil value; the Ctx backend returns `[]`.

  ## Parameters

  - `crud_spec` (term()) - Backend-specific CRUD specification.
  - `socket` (Phoenix.LiveView.Socket.t() | map()) - A LiveView socket (or any map with
    an `:assigns` field).

  ## Returns

  keyword() - Options to merge into subsequent CRUD calls (e.g. `[actor: %User{}]`).
  Returns `[]` when nothing applies.

  See the [Ash integration guide — Authorization &amp; policies](ash_integration.html#authorization--policies)
  for the end-user-facing configuration that drives this callback.
  """
  @callback socket_opts(term(), Phoenix.LiveView.Socket.t() | map()) :: keyword()

  @doc """
  Applies a list operation using the provided Connector.

  ## Parameters

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `opts` (keyword()) - Query options passed to the backend implementation.

  ## Returns

  Pagination.t() - `%Pagination{}` structure containing query results.

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

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `pagination` (Pagination.t()) - The current `%Pagination{}` structure.
  - `page` (integer()) - The target page number.
  - `opts` (keyword()) - Additional options. Defaults to `[]`. Forwarded to the backend.

  ## Returns

  Pagination.t() - Updated `%Pagination{}` structure with the requested page data.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_to_page(connector, %Pagination{page: 1, pages_count: 5}, 2)
      %Pagination{page: 2, entries: [...]}
  """
  @spec apply_to_page(Connector.t(), Pagination.t(), integer(), keyword()) :: Pagination.t()
  def apply_to_page(%Connector{type: type, crud_spec: crud_spec}, pagination, page, opts \\ []),
    do: get_crud_module(type).to_page(crud_spec, pagination, page, opts)

  @doc """
  Retrieves a single entity by ID using the provided Connector.

  ## Parameters

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `id` (term()) - The entity identifier.
  - `opts` (keyword()) - Options:
    * `:actor` (term()) - Actor for Ash policy authorization (Ash only).
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

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `entity` (struct()) - The entity to create a changeset for.
  - `form_name` (atom() | binary()) - The name of the underlying form.
  - `attrs` (map()) - Attributes to apply to the changeset. Defaults to `%{}`.
  - `opts` (keyword()) - Additional options. Defaults to `[]`. Forwarded to the backend
    (the Ash backend honours `:actor`).

  ## Returns

  struct() - A changeset structure (e.g., `%AshPhoenix.Form{}` or `%Ecto.Changeset{}`).

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_change_function(connector, %MyApp.User{}, "user", %{name: "John"})
      %AshPhoenix.Form{...}

      iex> connector = %Connector{type: :ctx, crud_spec: %CrudSpec{...}}
      iex> apply_change_function(connector, %MyContext.Item{}, "item", %{status: "active"})
      %Ecto.Changeset{...}
  """
  @spec apply_change_function(Connector.t(), struct(), atom() | binary(), map(), keyword()) ::
          struct()
  def apply_change_function(
        %Connector{type: type, crud_spec: crud_spec} = _function_ref,
        entity,
        form_name,
        attrs \\ %{},
        opts \\ []
      ) do
    get_crud_module(type).change(crud_spec, entity, form_name, attrs, opts)
  end

  @doc """
  Creates a new entity struct using the provided Connector.

  ## Parameters

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `attrs` (map()) - Initial attributes for the new entity.
  - `opts` (keyword()) - Options:
    * `:actor` (term()) - Actor for Ash policy authorization (Ash only, used during
      preloading).
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

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `entity` (struct()) - The resource to update.
  - `params` (map()) - Parameters to update.
  - `opts` (keyword()) - Additional options. Defaults to `[]`. Forwarded to the backend
    (the Ash backend honours `:actor`).

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_update_function(connector, %MyApp.User{id: 1}, %{name: "Bob"})
      {:ok, %MyApp.User{id: 1, name: "Bob"}}
  """
  @spec apply_update_function(Connector.t(), struct(), map(), keyword()) :: tuple()
  def apply_update_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity,
        params,
        opts \\ []
      ),
      do: get_crud_module(type).update(crud_spec, entity, params, opts)

  @doc """
  Creates a new resource in the database.

  ## Parameters

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `params` (map()) - Parameters for the new resource.
  - `opts` (keyword()) - Additional options. Defaults to `[]`. Forwarded to the backend
    (the Ash backend honours `:actor`).

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> connector = %Connector{type: :ctx, crud_spec: %CrudSpec{...}}
      iex> apply_create_function(connector, %{name: "Alice", email: "alice@example.com"})
      {:ok, %MyApp.User{name: "Alice"}}
  """
  @spec apply_create_function(Connector.t(), map(), keyword()) :: tuple()
  def apply_create_function(
        %Connector{type: type, crud_spec: crud_spec},
        params,
        opts \\ []
      ),
      do: get_crud_module(type).create(crud_spec, params, opts)

  @doc """
  Deletes a resource from the database.

  ## Parameters

  - `connector` (Connector.t()) - The `%Connector{}` containing type and crud_spec.
  - `entity` (struct()) - The resource to delete.
  - `opts` (keyword()) - Additional options. Defaults to `[]`. Forwarded to the backend
    (the Ash backend honours `:actor`).

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> connector = %Connector{type: :ash, crud_spec: %CrudSpec{...}}
      iex> apply_delete_function(connector, %MyApp.User{id: 1})
      {:ok, %MyApp.User{id: 1}}
  """
  @spec apply_delete_function(Connector.t(), struct(), keyword()) :: tuple()
  def apply_delete_function(
        %Connector{type: type, crud_spec: crud_spec},
        entity,
        opts \\ []
      ),
      do: get_crud_module(type).delete(crud_spec, entity, opts)

  @doc """
  Resolves per-call options from a LiveView socket for the given Connector.

  Polymorphic over connector type — delegates to the backend's `socket_opts/2`
  callback, which inspects its own crud_spec. The Ash backend returns
  `[actor: socket.assigns[crud_spec.actor_assign]]` when configured; the Ctx backend
  returns `[]`.

  Always returns a keyword list, safe to merge into per-call opts via `++`.

  ## Parameters

  - `connector` (Connector.t() | nil) - The `%Connector{}` to extract opts for; a nil
    connector returns `[]`.
  - `socket` (Phoenix.LiveView.Socket.t() | map()) - The LiveView socket (or any map
    with an `:assigns` key).

  ## Returns

  keyword() - Options to merge into the next CRUD call.

  ## Examples

      iex> apply_socket_opts(nil, socket)
      []

      iex> apply_socket_opts(%Connector{type: :ash, crud_spec: %CrudSpec{actor_assign: :current_user}},
      ...>   %{assigns: %{current_user: %{id: 1}}})
      [actor: %{id: 1}]

      iex> apply_socket_opts(%Connector{type: :ctx, crud_spec: %CtxCrudSpec{}}, socket)
      []
  """
  @spec apply_socket_opts(Connector.t() | nil, Phoenix.LiveView.Socket.t() | map()) :: keyword()
  def apply_socket_opts(nil, _socket), do: []

  def apply_socket_opts(%Connector{type: type, crud_spec: crud_spec}, socket),
    do: get_crud_module(type).socket_opts(crud_spec, socket)

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
