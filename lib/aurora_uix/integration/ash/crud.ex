defmodule Aurora.Uix.Integration.Ash.Crud do
  @moduledoc """
  CRUD operations for Ash resources with pagination support.

  Wraps Ash query operations and returns results in Aurora pagination structures,
  enabling consistent data handling across the application.

  ## Key Features

  - Query parsing with filters, sorting, and preloading
  - Automatic pagination structure creation
  - Integration with Ash read actions
  - Support for paginated and non-paginated list operations
  - Page navigation for paginated results

  ## Key Constraints

  - Currently only supports read/list/get operations
  - Non-paginated results return single-page with `:infinity` per_page value
  - Expects successful Ash.read/1 responses (raises on errors)
  - Page numbers must be within valid range (1 to pages_count)
  """
  alias Ash.Page.Offset
  alias AshPostgres.DataLayer.Info, as: PostgresDataLayerInfo
  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Integration.Ash.CrudSpec
  alias Aurora.Uix.Integration.Ash.QueryParser

  @doc """
  Lists resources from an Ash action with optional query parameters.

  ## Parameters

  - `auix_action` (atom()) - The Aurora UIX action (`:list_function` or
    `:list_function_paginated`).
  - `action_module` (module()) - The Ash resource module.
  - `action` (Ash.Resource.Actions.Read.t()) - The read action struct.
  - `opts` (keyword()) - Query options:
    * `:where` (list()) - Filter clauses.
    * `:order_by` (term()) - Sort specification.
    * `:preload` (term()) - Associations to load.
    * `:paginate` (Pagination.t()) - Pagination configuration (for paginated action).

  ## Returns

  Pagination.t() - Pagination structure containing query results and metadata.

  ## Examples

      iex> list(:list_function, MyApp.User, %Ash.Resource.Actions.Read{name: :read,
      ...>   pagination: false}, where: [{:status, :eq, "active"}])
      %Pagination{entries: [...], pages_count: 1, per_page: :infinity}

      iex> list(:list_function_paginated, MyApp.Post, %Ash.Resource.Actions.Read{name: :read,
      ...>   pagination: true}, paginate: %Pagination{page: 1, per_page: 20})
      %Pagination{entries: [...], page: 1, pages_count: 5, per_page: 20}
  """
  @spec list(CrudSpec.t(), keyword()) :: Pagination.t()
  def list(definition, opts \\ [])

  def list(%CrudSpec{action: %{name: action_name, pagination: false}} = crud_spec, opts) do
    {:ok, result} =
      crud_spec.resource
      |> Ash.Query.for_read(action_name)
      |> QueryParser.parse(opts)
      |> Ash.read()

    %Pagination{
      entries: result,
      entries_count: Enum.count(result),
      pages_count: 1,
      per_page: :infinity
    }
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

  - `list_function` (tuple()) - Tuple with format
    `{:ash, action, action_module, auix_action}`.
  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The page number to load (must be >= 1 and <= pages_count).

  ## Returns

  Pagination.t() - Updated pagination structure with the requested page data, or
  unchanged pagination if page is out of bounds.

  ## Examples

      iex> to_page({:ash, %Ash.Resource.Actions.Read{}, MyApp.User, :list_function_paginated},
      ...>   %Pagination{page: 1, pages_count: 5, per_page: 20}, 3)
      %Pagination{entries: [...], page: 3, pages_count: 5, per_page: 20}

      iex> to_page({:ash, %Ash.Resource.Actions.Read{}, MyApp.User, :list_function_paginated},
      ...>   %Pagination{page: 1, pages_count: 5}, 10)
      %Pagination{page: 1, pages_count: 5}
  """
  @spec to_page(tuple(), Pagination.t(), integer()) :: Pagination.t()
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

  - `get_function` (tuple()) - Tuple with format
    `{:ash, action, action_module, :get_function}`.
  - `id` (term()) - The resource identifier.
  - `opts` (keyword()) - Query options:
    * `:preload` (term()) - Associations to load.

  ## Returns

  struct() | nil - The matching resource or `nil` if not found or error occurs.

  ## Examples

      iex> get({:ash, %Ash.Resource.Actions.Read{name: :read}, MyApp.User, :get_function},
      ...>   "123", preload: [:posts])
      %MyApp.User{id: "123", ...}

      iex> get({:ash, %Ash.Resource.Actions.Read{name: :read}, MyApp.Post, :get_function},
      ...>   "missing-id", [])
      nil
  """
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

  - `change_function` (tuple()) - Tuple with format
    `{:ash, action, action_module, :change_function}`.
  - `entity` (struct()) - The Ash resource struct to update.
  - `attrs` (map()) - Attributes to apply to the form.

  ## Returns

  AshPhoenix.Form.t() - The form structure for the update operation.

  ## Examples

      iex> change({:ash, %Ash.Resource.Actions.Update{name: :update}, MyApp.User,
      ...>   :change_function}, %MyApp.User{}, %{name: "John"})
      %AshPhoenix.Form{...}
  """
  @spec change(CrudSpec.t(), struct(), map()) :: AshPhoenix.Form.t()
  def change(%CrudSpec{action: %{name: action_name}}, entity, attrs),
    do: AshPhoenix.Form.for_update(entity, action_name, params: attrs)

  @doc """
  Creates a new Ash resource struct with optional preloading.

  ## Parameters

  - `new_function` (tuple()) - Tuple with format
    `{:ash, action, action_module, :new_function}`.
  - `attrs` (map()) - Initial attributes for the new resource.
  - `opts` (keyword()) - Options:
    * `:preload` (list()) - Associations to preload via Ecto repository.

  ## Returns

  struct() - A new resource struct with the provided attributes and preloaded associations.

  ## Examples

      iex> new({:ash, %Ash.Resource.Actions.Create{}, MyApp.User, :new_function},
      ...>   %{name: "Jane"}, preload: [:profile])
      %MyApp.User{name: "Jane", profile: %MyApp.Profile{}}

      iex> new({:ash, %Ash.Resource.Actions.Create{}, MyApp.Post, :new_function},
      ...>   %{title: "Hello"}, [])
      %MyApp.Post{title: "Hello"}
  """
  @spec new(CrudSpec.t(), map(), keyword()) :: struct()
  def new(%CrudSpec{resource: resource}, attrs, opts) do
    repo = PostgresDataLayerInfo.repo(resource)

    resource
    |> struct(attrs)
    |> maybe_apply_preload(repo, opts)
  end

  ## PRIVATE

  # Reads paginated results from an Ash action.
  @spec read_paginated(module(), map(), keyword(), integer(), integer(), boolean()) ::
          {:ok, Offset.t()} | {:error, term()}
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
  @spec maybe_apply_preload(struct(), nil | module(), keyword()) :: struct()
  defp maybe_apply_preload(schema, nil, _opts), do: schema

  defp maybe_apply_preload(schema, repo, opts) do
    case opts[:preload] do
      nil -> schema
      preload -> repo.preload(schema, preload)
    end
  end
end
