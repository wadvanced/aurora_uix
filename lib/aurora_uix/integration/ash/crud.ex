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

  ## Key Constraints

  - Requires valid Ash resource module with defined actions
  - Pagination requires Ash action configured with `pagination` option
  - Preloading handled differently: via Ash.Query.load for queries, Ecto repo for new structs
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
    {:ok, results} =
      crud_spec.resource
      |> Ash.Query.for_read(action_name)
      |> QueryParser.parse(opts)
      |> Ash.read()

    results
  end

  def list(%CrudSpec{auix_action_name: :list_function_paginated} = crud_spec, opts) do
    paginate = Keyword.get(opts, :paginate, %Pagination{})

    {:ok, %Offset{} = offset} =
      read_paginated(
        crud_spec.resource,
        crud_spec.action,
        opts,
        paginate.page,
        paginate.per_page,
        true
      )

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
  end

  @doc """
  Loads a specific page of results for paginated data.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec (currently unused for page bounds checking).
  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The page number to load (must be >= 1 and <= pages_count).

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
  @spec to_page(CrudSpec.t(), Pagination.t(), integer()) :: Pagination.t()
  def to_page(_crud_spec, pagination, page) when page < 1, do: pagination

  def to_page(_crud_spec, %{pages_count: pages_count} = pagination, page)
      when page > pages_count,
      do: pagination

  def to_page(%CrudSpec{} = crud_spec, pagination, page) do
    {:ok, %Offset{} = offset} =
      read_paginated(
        crud_spec.resource,
        crud_spec.action,
        pagination.opts,
        page,
        pagination.per_page,
        true
      )

    %Pagination{
      entries: offset.results,
      entries_count: pagination.entries_count,
      page: page,
      pages_count: pagination.pages_count,
      per_page: pagination.per_page
    }
  end

  @doc """
  Retrieves a single resource by ID.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing resource and action configuration.
  - `id` (term()) - The resource identifier.
  - `opts` (keyword()) - Query options:
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
    parsed_opts = [action: action_name, load: Keyword.get(opts, :preload, [])]

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
  - `attrs` (map()) - Attributes to apply to the form.

  ## Returns

  AshPhoenix.Form.t() - The form structure for the update operation.

  ## Examples

      iex> crud_spec = %CrudSpec{action: %{name: :update}}
      iex> change(crud_spec, %MyApp.User{}, %{name: "John"})
      %AshPhoenix.Form{...}
  """
  @impl true
  @spec change(CrudSpec.t(), struct(), atom() | binary(), map()) :: AshPhoenix.Form.t()
  def change(%CrudSpec{action: %{name: action_name}}, entity, form_name, attrs) do
    binary_form_name = to_string(form_name)
    AshPhoenix.Form.for_update(entity, action_name, params: attrs, as: binary_form_name)
  end

  @doc """
  Creates a new Ash resource struct with optional preloading.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing resource configuration.
  - `attrs` (map()) - Initial attributes for the new resource.
  - `opts` (keyword()) - Options:
    * `:preload` (list()) - Associations to preload via Ecto repository.

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
  def new(%CrudSpec{resource: resource}, attrs, opts) do
    resource
    |> struct(attrs)
    |> maybe_apply_preload(opts)
  end

  @doc """
  Creates a new resource in the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing resource and action configuration.
  - `params` (map()) - Parameters for the new resource.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{resource: MyApp.User, action: %{name: :create}}
      iex> create(crud_spec, %{name: "Alice", email: "alice@example.com"})
      {:ok, %MyApp.User{name: "Alice", email: "alice@example.com"}}
  """
  @impl true
  @spec create(CrudSpec.t(), map()) :: tuple()
  def create(%CrudSpec{resource: resource, action: %{name: action_name}}, params) do
    Ash.create(resource, params, action: action_name)
  end

  @doc """
  Updates an existing resource in the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing action configuration.
  - `entity` (struct()) - The resource to update.
  - `params` (map()) - Parameters to update.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{action: %{name: :update}}
      iex> update(crud_spec, %MyApp.User{id: 1}, %{name: "Bob"})
      {:ok, %MyApp.User{id: 1, name: "Bob"}}
  """
  @impl true
  @spec update(CrudSpec.t(), struct(), map()) :: tuple()
  def update(%CrudSpec{action: %{name: action_name}}, entity, params) do
    Ash.update(entity, params, action: action_name)
  end

  @doc """
  Deletes a resource from the database.

  ## Parameters

  - `crud_spec` (CrudSpec.t()) - The CrudSpec containing action configuration.
  - `entity` (struct()) - The resource to delete.

  ## Returns

  tuple() - Result tuple, typically `{:ok, struct()}` or `{:error, struct()}`.

  ## Examples

      iex> crud_spec = %CrudSpec{action: %{name: :destroy}}
      iex> delete(crud_spec, %MyApp.User{id: 1})
      {:ok, %MyApp.User{id: 1}}
  """
  @impl true
  @spec delete(CrudSpec.t(), struct()) :: tuple()
  def delete(%CrudSpec{action: %{name: action_name}}, entity) do
    Ash.destroy(entity, action: action_name, return_destroyed?: true)
  end

  ## PRIVATE

  # Reads paginated results from an Ash action.
  @spec read_paginated(module(), map(), keyword(), integer(), integer(), boolean()) ::
          {:ok, Ash.Page.Offset.t()} | {:error, term()}
  defp read_paginated(action_module, %{name: action_name}, opts, page, per_page, count?) do
    action_module
    |> Ash.Query.for_read(action_name)
    |> Ash.Query.page(
      limit: per_page,
      offset: per_page * (page - 1),
      count: count?
    )
    |> QueryParser.parse(opts)
    |> Ash.read()
  end

  # Applies Ecto preload to a struct if repository and preload option are present.
  @spec maybe_apply_preload(struct(), keyword()) :: struct()
  defp maybe_apply_preload(entity, opts) do
    case opts[:preload] do
      nil -> entity
      preload -> apply_preload(entity, preload)
    end
  end

  @spec apply_preload(struct(), term()) :: struct()
  defp apply_preload(entity, preload) do
    case Ash.load(entity, preload) do
      {:ok, entity_loaded} -> entity_loaded
      _ -> entity
    end
  end
end
