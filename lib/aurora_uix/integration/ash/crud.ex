defmodule Aurora.Uix.Integration.Ash.Crud do
  @moduledoc """
  Provides CRUD operations for Ash resources with pagination support.

  This module wraps Ash query operations and returns results in Aurora pagination
  structures, enabling consistent data handling across the application.

  ## Key Features
  - Query parsing with filters and sorting opts
  - Automatic pagination structure creation
  - Integration with Ash read actions

  ## Key Constraints
  - Currently only supports read/list operations
  - Returns single-page results with `:infinity` per_page value
  - Expects successful Ash.read/1 responses (raises on errors)
  """
  alias Ash.Page.Offset
  alias Ash.Resource.Actions
  alias Aurora.Ctx.Pagination
  alias Aurora.Uix.Integration.Ash.QueryParser

  @doc """
  Lists resources from an Ash action with optional query parameters.

  ## Parameters
  - `auix_action` (atom()) - The equivalent aurora uix action.
  - `action_module` (module()) - The Ash resource module.
  - `action` (Actions.Read.t()) - The read action struct.
  - `opts` (keyword()) - Query options:
    * `:where` (list()) - Filter clauses.
    * `:order_by` (term()) - Sort specification.
    * `:paginate` (Pagination.t()) - Pagination configuration.

  ## Returns
  Pagination.t() - Pagination structure containing query results.
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
  - `pagination` (Pagination.t()) - The current pagination structure.
  - `page` (integer()) - The page number to load.
  - `list_function` (tuple()) - Tuple with format `{:ash, action, action_module}`.

  ## Returns
  Pagination.t() - Updated pagination structure with the requested page data.
  """
  @spec load_page(Pagination.t(), integer(), tuple()) :: Pagination.t()
  def load_page(pagination, page, _list_function) when page < 1, do: pagination

  def load_page(%{pages_count: pages_count} = pagination, page, _list_function)
      when page > pages_count,
      do: pagination

  def load_page(pagination, page, {:ash, action, action_module, _auix_action}) do
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
