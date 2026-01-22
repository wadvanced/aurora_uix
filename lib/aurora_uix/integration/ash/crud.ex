defmodule Aurora.Uix.Integration.Ash.Crud do
  @moduledoc """
  Provides CRUD operations for Ash resources with pagination support.

  This module wraps Ash query operations and returns results in Aurora pagination
  structures, enabling consistent data handling across the application.

  ## Key Features
  - Query parsing with filters and sorting options
  - Automatic pagination structure creation
  - Integration with Ash read actions

  ## Key Constraints
  - Currently only supports read/list operations
  - Returns single-page results with `:infinity` per_page value
  - Expects successful Ash.read/1 responses (raises on errors)
  """
  alias Aurora.Uix.Integration.Ash.QueryParser

  @doc """
  Lists resources from an Ash action with optional query parameters.

  ## Parameters
  - `action_module` (module()) - The Ash resource module.
  - `action_name` (atom()) - The name of the read action to invoke.
  - `options` (Keyword.t()) - Query options passed to `QueryParser.parse/2`:
    * `:where` (list()) - Filter clauses.
    * `:order_by` (term()) - Sort specification.

  ## Returns
  Aurora.Ctx.Pagination.t() - Pagination structure containing query results.

  ## Examples
      iex> list(MyApp.Post, :read, where: [{:status, :eq, "published"}])
      %Aurora.Ctx.Pagination{entries: [...], entries_count: 5, pages_count: 1, per_page: :infinity}

      iex> list(MyApp.User, :list_active, order_by: [name: :asc])
      %Aurora.Ctx.Pagination{entries: [...], entries_count: 10, pages_count: 1, per_page: :infinity}
  """
  @spec list(module(), atom(), keyword()) :: Aurora.Ctx.Pagination.t()
  def list(action_module, action_name, options \\ []) do
    {:ok, result} =
      action_module
      |> Ash.Query.for_read(action_name)
      |> QueryParser.parse(options)
      |> Ash.read()

    %Aurora.Ctx.Pagination{
      entries: result,
      entries_count: Enum.count(result),
      pages_count: 1,
      per_page: :infinity
    }
  end
end
