defmodule Aurora.Uix.Integration.Ash.Crud do
  @moduledoc """
  Ash Framework implementation of CRUD operations.

  Provides CRUD operations for Ash resources using the Ash Framework API. Supports both
  paginated and non-paginated listing, along with standard create, read, update, delete
  operations.

  ## Key Features

  - Automatic action discovery and execution for Ash resources
  - Support for paginated and non-paginated queries
  - Query parsing with filters, sorting, and preloading
  - Primary action detection with fallback to first available action
  - AshPhoenix form integration for changesets
  - Actor threading for policy-protected resources via `socket_opts/2` (see
    "Authorization" below)

  ## Key Constraints

  - Requires valid Ash resource module with defined actions
  - Pagination requires Ash action configured with `pagination` option
  - Preloading handled differently: via Ash.Query.load for queries, Ecto repo for new structs

  ## Authorization

  Every CRUD call accepts an optional `:actor` keyword in its `opts`. When present
  (and non-nil) the actor is forwarded to the underlying Ash call (`Ash.read/2`,
  `Ash.get/3`, `Ash.create/3`, `Ash.update/3`, `Ash.destroy/2`, `Ash.load/3`,
  `AshPhoenix.Form.for_update/3`). When absent, no `actor:` is added — the host's
  Ash domain `authorize` config (default `:by_default`) decides whether policies run.

  `authorize?:` is **never** set explicitly by this module. The actor is resolved at
  the call site by `socket_opts/2`, which reads `CrudSpec.actor_assign` (the atom
  configured via `auix_resource_metadata ..., ash_actor_assign: :current_user`) and
  pulls the actor from `socket.assigns`.

  ### Resolution example

  Given `auix_resource_metadata :template, ash_resource: Tpl, ash_actor_assign: :current_user`
  and a LiveView with `socket.assigns.current_user = %User{id: 1}`:

      iex> socket_opts(crud_spec, socket)
      [actor: %User{id: 1}]

  Handlers extending Aurora UIX should not call `socket_opts/2` directly — use
  `Aurora.Uix.Templates.Basic.Helpers.backend_socket_opts/2` instead, which is
  backend-agnostic and accepts both full sockets and bare assigns maps.

  See the [Ash integration guide — Authorization &amp; policies](ash_integration.html#authorization--policies)
  for the end-to-end worked example, alias (`:actor_assign`), behaviour matrix,
  and troubleshooting.
  """
  @behaviour Aurora.Uix.Integration.Crud

  alias Ash.Page.Offset
  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Integration.Ash.CrudSpec
  alias Aurora.Uix.Integration.Ash.QueryParser

  @doc """
  Lists resources from an Ash action with optional query parameters.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing resource and action configuration.
  - `opts` (keyword()) - Query options:
    * `:actor` (term()) - Actor forwarded to `Ash.Query.for_read/3` and `Ash.read/2`
      for policy-protected resources.
    * `:where` (list()) - Filter clauses.
    * `:order_by` (term()) - Sort specification.
    * `:preload` (term()) - Associations to load.
    * `:paginate` (Pagination.t()) - Pagination configuration (for paginated action).

  ## Returns

  Pagination.t() - `%Pagination{}` structure containing query results and metadata.

  ## Examples

      iex> crud_spec = %CrudSpec{resource: MyApp.User, action: %{name: :read, pagination: false}}
      iex> list(crud_spec, where: [{:status, :eq, "active"}])
      %Pagination{entries: [...], pages_count: 1, per_page: :infinity}

      iex> crud_spec = %CrudSpec{resource: MyApp.Post, action: %{name: :read, pagination: true},
      ...>   auix_action_name: :list_function_paginated}
      iex> list(crud_spec, paginate: %Pagination{page: 1, per_page: 20})
      %Pagination{entries: [...], page: 1, pages_count: 5, per_page: 20}
  """
  @impl true
  @spec list(CrudSpec.t(), keyword()) :: Pagination.t()
  def list(definition, opts \\ [])

  def list(
        %CrudSpec{action: %{name: action_name}, auix_action_name: :list_function} = crud_spec,
        opts
      ) do
    actor_opt = actor_opt(opts)

    read_result =
      crud_spec.resource
      |> Ash.Query.for_read(action_name, %{}, actor_opt)
      |> QueryParser.parse(opts)
      |> Ash.read(actor_opt)

    case read_result do
      {:ok, results} -> results
      # Policy-protected resources without a satisfying actor surface as Forbidden;
      # the LiveView should render an empty index, not crash. Other errors propagate.
      {:error, %Ash.Error.Forbidden{}} -> []
    end
  end

  def list(%CrudSpec{auix_action_name: :list_function_paginated} = crud_spec, opts) do
    paginate = Keyword.get(opts, :paginate, %Pagination{})

    case read_paginated(
           crud_spec.resource,
           crud_spec.action,
           opts,
           paginate.page,
           paginate.per_page,
           true
         ) do
      {:ok, %Offset{} = offset} ->
        pages_count =
          case Integer.mod(offset.count, paginate.per_page) do
            0 -> Integer.floor_div(offset.count, paginate.per_page)
            _ -> Integer.floor_div(offset.count, paginate.per_page) + 1
          end

        %Pagination{
          entries: offset.results,
          entries_count: offset.count,
          page: paginate.page,
          pages_count: pages_count,
          per_page: paginate.per_page
        }

      # Forbidden reads surface as an empty page so the index renders empty.
      {:error, %Ash.Error.Forbidden{}} ->
        %Pagination{
          entries: [],
          entries_count: 0,
          page: paginate.page,
          pages_count: 0,
          per_page: paginate.per_page
        }
    end
  end

  @doc """
  Loads a specific page of results for paginated data.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec (currently unused for page bounds checking).
  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The page number to load (must be >= 1 and <= pages_count).
  - `opts` (keyword()) - Additional options. Honours `:actor` for policy-protected reads.

  ## Returns

  Pagination.t() - Updated `%Pagination{}` structure with the requested page data, or
  unchanged pagination if page is out of bounds.

  ## Examples

      iex> crud_spec = %CrudSpec{resource: MyApp.User, action: %{name: :read}}
      iex> to_page(crud_spec, %Pagination{page: 1, pages_count: 5, per_page: 20}, 3)
      %Pagination{entries: [...], page: 3, pages_count: 5, per_page: 20}

      iex> to_page(crud_spec, %Pagination{page: 1, pages_count: 5}, 10)
      %Pagination{page: 1, pages_count: 5}
  """
  @impl true
  @spec to_page(CrudSpec.t(), Pagination.t(), integer(), keyword()) :: Pagination.t()
  def to_page(crud_spec, pagination, page, opts \\ [])

  def to_page(_crud_spec, pagination, page, _opts) when page < 1, do: pagination

  def to_page(_crud_spec, %{pages_count: pages_count} = pagination, page, _opts)
      when page > pages_count,
      do: pagination

  def to_page(%CrudSpec{} = crud_spec, %Pagination{} = pagination, page, opts) do
    merged_opts = Keyword.merge(pagination.opts || [], opts)

    case read_paginated(
           crud_spec.resource,
           crud_spec.action,
           merged_opts,
           page,
           pagination.per_page,
           true
         ) do
      {:ok, %Offset{} = offset} ->
        %Pagination{
          entries: offset.results,
          entries_count: pagination.entries_count,
          page: page,
          pages_count: pagination.pages_count,
          per_page: pagination.per_page
        }

      {:error, %Ash.Error.Forbidden{}} ->
        %{pagination | entries: [], page: page}
    end
  end

  @doc """
  Retrieves a single resource by ID.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing resource and action configuration.
  - `id` (term()) - The resource identifier.
  - `opts` (keyword()) - Query options:
    * `:actor` (term()) - Actor forwarded to `Ash.get/3` and `Ash.load/3`.
    * `:preload` (term()) - Associations to load.

  ## Returns

  struct() | nil - The matching resource or `nil` if not found or error occurs.

  ## Examples

      iex> crud_spec = %CrudSpec{resource: MyApp.User, action: %{name: :read}}
      iex> get(crud_spec, "123", preload: [:posts])
      %MyApp.User{id: "123", ...}

      iex> get(crud_spec, "missing-id", [])
      nil
  """
  @impl true
  @spec get(CrudSpec.t(), term(), keyword()) :: struct() | nil
  def get(%CrudSpec{action: %{name: action_name}} = crud_spec, id, opts) do
    parsed_opts =
      Keyword.merge(
        [action: action_name, load: Keyword.get(opts, :preload, [])],
        actor_opt(opts)
      )

    case Ash.get(crud_spec.resource, id, parsed_opts) do
      {:ok, item} -> item
      {:error, _} -> nil
    end
  end

  @doc """
  Creates an AshPhoenix form for updating an entity.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing action configuration.
  - `entity` (struct()) - The Ash resource struct to update.
  - `form_name` (atom() | binary()) - Underlying form name.
  - `attrs` (map()) - Attributes to apply to the form.
  - `opts` (keyword()) - Additional options:
    * `:actor` (term()) - Actor forwarded to `AshPhoenix.Form.for_update/3`.

  ## Returns

  AshPhoenix.Form.t() - The form structure for the update operation.

  ## Examples

      iex> crud_spec = %CrudSpec{action: %{name: :update}}
      iex> change(crud_spec, %MyApp.User{}, "user", %{name: "John"})
      %AshPhoenix.Form{...}
  """
  @impl true
  @spec change(CrudSpec.t(), struct(), atom() | binary(), map(), keyword()) ::
          AshPhoenix.Form.t()
  def change(crud_spec, entity, form_name, attrs, opts \\ [])

  def change(%CrudSpec{action: %{name: action_name}}, entity, form_name, attrs, opts) do
    binary_form_name = to_string(form_name)

    form_opts =
      Keyword.merge(
        [params: attrs, as: binary_form_name],
        actor_opt(opts)
      )

    AshPhoenix.Form.for_update(entity, action_name, form_opts)
  end

  @doc """
  Creates a new Ash resource struct with optional preloading.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing resource configuration.
  - `attrs` (map()) - Initial attributes for the new resource.
  - `opts` (keyword()) - Options:
    * `:actor` (term()) - Actor forwarded to `Ash.load/3` during preload.
    * `:preload` (list()) - Associations to preload.

  ## Returns

  struct() - A new resource struct with the provided attributes and preloaded associations.

  ## Examples

      iex> crud_spec = %CrudSpec{resource: MyApp.User}
      iex> new(crud_spec, %{name: "Jane"}, preload: [:profile])
      %MyApp.User{name: "Jane", profile: %MyApp.Profile{}}

      iex> new(crud_spec, %{title: "Hello"}, [])
      %MyApp.Post{title: "Hello"}
  """
  @impl true
  @spec new(CrudSpec.t(), map(), keyword()) :: struct()
  def new(%CrudSpec{resource: resource, action: action}, attrs, opts) do
    attrs
    |> action.(opts)
    |> then(&struct(resource, &1))
    |> maybe_apply_preload(opts)
  end

  @doc """
  Creates a new resource in the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing resource and action configuration.
  - `params` (map()) - Parameters for the new resource.
  - `opts` (keyword()) - Additional options:
    * `:actor` (term()) - Actor forwarded to `Ash.create/3`.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{resource: MyApp.User, action: %{name: :create}}
      iex> create(crud_spec, %{name: "Alice", email: "alice@example.com"})
      {:ok, %MyApp.User{name: "Alice", email: "alice@example.com"}}
  """
  @impl true
  @spec create(CrudSpec.t(), map(), keyword()) :: tuple()
  def create(crud_spec, params, opts \\ [])

  def create(%CrudSpec{resource: resource, action: %{name: action_name}}, params, opts) do
    Ash.create(resource, params, [action: action_name] ++ actor_opt(opts))
  end

  @doc """
  Updates an existing resource in the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing action configuration.
  - `entity` (struct()) - The resource to update.
  - `params` (map()) - Parameters to update.
  - `opts` (keyword()) - Additional options:
    * `:actor` (term()) - Actor forwarded to `Ash.update/3`.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{action: %{name: :update}}
      iex> update(crud_spec, %MyApp.User{id: 1}, %{name: "Bob"})
      {:ok, %MyApp.User{id: 1, name: "Bob"}}
  """
  @impl true
  @spec update(CrudSpec.t(), struct(), map(), keyword()) :: tuple()
  def update(crud_spec, entity, params, opts \\ [])

  def update(%CrudSpec{action: %{name: action_name}}, entity, params, opts) do
    Ash.update(entity, params, [action: action_name] ++ actor_opt(opts))
  end

  @doc """
  Deletes a resource from the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing action configuration.
  - `entity` (struct()) - The resource to delete.
  - `opts` (keyword()) - Additional options:
    * `:actor` (term()) - Actor forwarded to `Ash.destroy/2`.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{action: %{name: :destroy}}
      iex> delete(crud_spec, %MyApp.User{id: 1})
      {:ok, %MyApp.User{id: 1}}
  """
  @impl true
  @spec delete(CrudSpec.t(), struct(), keyword()) :: tuple()
  def delete(crud_spec, entity, opts \\ [])

  def delete(%CrudSpec{action: %{name: action_name}}, entity, opts) do
    Ash.destroy(
      entity,
      [action: action_name, return_destroyed?: true] ++ actor_opt(opts)
    )
  end

  @doc """
  Resolves per-call options from a LiveView socket for a given Ash CrudSpec.

  Reads `crud_spec.actor_assign`, looks up that key on `socket.assigns`, and returns
  `[actor: actor]` when the assign holds a non-nil value. Otherwise returns `[]`.

  Safe to merge into any CRUD call's opts via `++`.

  ## Parameters

  - `crud_spec` (CrudSpec.t() | term()) - The CrudSpec carrying `:actor_assign`. Non
    `%CrudSpec{}` values are treated as not-applicable and return `[]`.
  - `socket` (Phoenix.LiveView.Socket.t() | map()) - A LiveView socket or any map with
    an `:assigns` field.

  ## Returns

  keyword() - `[actor: actor]` when configured and resolved, otherwise `[]`.

  ## Examples

      iex> socket_opts(%CrudSpec{actor_assign: nil}, %{assigns: %{current_user: %{id: 1}}})
      []

      iex> socket_opts(%CrudSpec{actor_assign: :current_user},
      ...>   %{assigns: %{current_user: %{id: 1}}})
      [actor: %{id: 1}]

      iex> socket_opts(%CrudSpec{actor_assign: :current_user}, %{assigns: %{}})
      []
  """
  @impl true
  @spec socket_opts(CrudSpec.t() | term(), Phoenix.LiveView.Socket.t() | map()) :: keyword()
  def socket_opts(%CrudSpec{actor_assign: nil}, _socket), do: []

  def socket_opts(%CrudSpec{actor_assign: key}, %{assigns: assigns}) when is_atom(key) do
    case Map.get(assigns, key) do
      nil -> []
      actor -> [actor: actor]
    end
  end

  def socket_opts(_crud_spec, _socket), do: []

  @doc """
  Default new function for initializing Ash resource structs.

  Returns the entity struct as-is without modifications. This function serves as the
  default implementation for the `:new_function` operation when no custom function is
  provided via `:ash_new_function` option.

  ## Parameters

  - `entity` (struct()) - The Ash resource struct to initialize.
  - `opts` (keyword()) - Options (currently unused).

  ## Returns

  struct() - The unmodified entity struct.

  ## Examples

      iex> post = %Post{status: :draft}
      iex> default_new_function(post, [])
      %Post{status: :draft}
  """
  @spec default_new_function(struct(), keyword()) :: struct()
  def default_new_function(entity, _opts) do
    entity
  end

  ## PRIVATE

  # Builds `[actor: actor]` when present, otherwise `[]`. Centralised so every Ash call
  # site uses the same shape and the actor never leaks as `nil`.
  @spec actor_opt(keyword()) :: keyword()
  defp actor_opt(opts) do
    case Keyword.get(opts, :actor) do
      nil -> []
      actor -> [actor: actor]
    end
  end

  # Reads paginated results from an Ash action.
  @spec read_paginated(module(), map(), keyword(), integer(), integer(), boolean()) ::
          {:ok, Ash.Page.Offset.t()} | {:error, term()}
  defp read_paginated(action_module, %{name: action_name}, opts, page, per_page, count?) do
    actor_opt = actor_opt(opts)

    action_module
    |> Ash.Query.for_read(action_name, %{}, actor_opt)
    |> Ash.Query.page(
      limit: per_page,
      offset: per_page * (page - 1),
      count: count?
    )
    |> QueryParser.parse(opts)
    |> Ash.read(actor_opt)
  end

  # Applies Ecto preload to a struct if repository and preload option are present.
  @spec maybe_apply_preload(struct(), keyword()) :: struct()
  defp maybe_apply_preload(entity, opts) do
    case opts[:preload] do
      nil -> entity
      preload -> apply_preload(entity, preload, opts)
    end
  end

  @spec apply_preload(struct(), term(), keyword()) :: struct()
  defp apply_preload(entity, preload, opts) do
    case Ash.load(entity, preload, actor_opt(opts)) do
      {:ok, entity_loaded} -> entity_loaded
      _ -> entity
    end
  end
end
