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
  alias Ash.Resource.Actions
  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Integration.Ash.QueryParser

  @doc """
  Lists resources from an Ash action with optional query parameters.

  ## Parameters

  - `auix_action` (atom()) - The Aurora UIX action (`:list_function` or
    `:list_function_paginated`).
  - `action_module` (module()) - The Ash resource module.
  - `action` (Actions.Read.t()) - The read action struct.
  - `opts` (keyword()) - Query options:
    * `:where` (list()) - Filter clauses.
    * `:order_by` (term()) - Sort specification.
    * `:preload` (term()) - Associations to load.
    * `:paginate` (Pagination.t()) - Pagination configuration (for paginated action).

  ## Returns

  Pagination.t() - Pagination structure containing query results and metadata.

  ## Examples

      iex> list(:list_function, MyApp.User, %Actions.Read{name: :read, pagination: false},
      ...>      where: [{:status, :eq, "active"}])
      %Pagination{entries: [...], pages_count: 1, per_page: :infinity}

      iex> list(:list_function_paginated, MyApp.Post, %Actions.Read{name: :read,
      ...>      pagination: true}, paginate: %Pagination{page: 1, per_page: 20})
      %Pagination{entries: [...], page: 1, pages_count: 5, per_page: 20}
  """
  @spec list(atom(), module(), Actions.Read.t(), keyword()) :: Pagination.t()
  def list(auix_action, action_module, action, opts \\ [])

  def list(:list_function, action_module, %{name: action_name, pagination: false}, opts) do
    {:ok, result} =
      action_module
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

  def list(:list_function_paginated, action_module, action, opts) do
    paginate = Keyword.get(opts, :paginate, %Pagination{})

    {:ok, %Offset{} = offset} =
      read_paginated(action_module, action, opts, paginate.page, paginate.per_page, true)

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

      iex> to_page({:ash, %Actions.Read{}, MyApp.User, :list_function_paginated},
      ...>         %Pagination{page: 1, pages_count: 5, per_page: 20}, 3)
      %Pagination{entries: [...], page: 3, pages_count: 5, per_page: 20}

      iex> to_page({:ash, %Actions.Read{}, MyApp.User, :list_function_paginated},
      ...>         %Pagination{page: 1, pages_count: 5}, 10)
      %Pagination{page: 1, pages_count: 5}
  """
  @spec to_page(tuple(), Pagination.t(), integer()) :: Pagination.t()
  def to_page(pagination, page, _list_function) when page < 1, do: pagination

  def to_page(_list_function, %{pages_count: pages_count} = pagination, page)
      when page > pages_count,
      do: pagination

  def to_page({:ash, action, action_module, _auix_action}, pagination, page) do
    {:ok, %Offset{} = offset} =
      read_paginated(action_module, action, pagination.opts, page, pagination.per_page, true)

    %Pagination{
      entries: offset.results,
      entries_count: pagination.entries_count,
      page: page,
      pages_count: pagination.pages_count,
      per_page: pagination.per_page
    }
  end

  @doc """
  Retrieves a single resource by applying filters.

  ## Parameters

  - `list_function` (tuple()) - Tuple with format
    `{:ash, action, action_module, :get_function}`.
  - `id` (term()) - The identifier or filter value (currently unused, filters via opts).
  - `opts` (keyword()) - Query options:
    * `:where` (list()) - Filter clauses to locate the resource.
    * `:preload` (term()) - Associations to load.

  ## Returns

  struct() | nil - The first matching resource or `nil` if not found or error occurs.

  ## Examples

      iex> get({:ash, %Actions.Read{name: :read}, MyApp.User, :get_function}, nil,
      ...>     where: [{:id, :eq, "123"}])
      %MyApp.User{id: "123", ...}

      iex> get({:ash, %Actions.Read{name: :read}, MyApp.Post, :get_function}, nil,
      ...>     where: [{:slug, :eq, "missing"}])
      nil
  """
  @spec get(tuple(), term(), keyword()) :: struct() | nil
  def get({:ash, %{name: action_name}, action_module, :get_function}, id, opts) do
    parsed_opts = [action: action_name, load: Keyword.get(opts, :preload, [])]

    case Ash.get(action_module, id, parsed_opts) do
      {:ok, item} -> item
      {:error, _} -> nil
    end
  end

  ## PRIVATE

  # Reads paginated results from an Ash action
  @spec read_paginated(module(), Actions.Read.t(), keyword(), integer(), integer(), boolean()) ::
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
end
