defmodule Aurora.Uix.Integration.Ash.QueryParser do
  @moduledoc """
  Parses and applies query options to Ash queries.

  This module provides functionality to transform keyword list options into Ash query
  operations, supporting filtering, sorting, and other query modifications. It handles
  various comparison operators and automatically translates them to Ash-compatible
  formats.

  ## Key Features
  - Supports `:order_by` for sorting
  - Handles `:where` clauses with multiple operators (`:eq`, `:in`, `:between`, `:like`,
    `:ilike`, `:gte`, `:lte`)
  - Automatically translates operation aliases (`:ge`, `:le`, `:equal_to`)
  - Comma-separated string parsing for `:in` operations

  ## Key Constraints
  - Only processes `:order_by` and `:where` options; other options are ignored
  - The `:in` operator expects either a list or comma-separated string
  - The `:between` operator requires start and end values
  """
  require Ash.Query

  @doc """
  Parses and applies query options to an Ash query.

  ## Parameters
  - `query` (struct()) - The base Ash query to modify.
  - `opts` (keyword()) - Options:
    * `:order_by` (term()) - Sorting specification passed to `Ash.Query.sort/2`.
    * `:where` (list()) - List of filter clauses.

  ## Returns
  struct() - The modified query with applied options.

  ## Examples
      iex> query = Ash.Query.new(MyApp.Post)
      iex> parse(query, where: [{:status, :eq, "published"}], order_by: [inserted_at: :desc])
      #Ash.Query<...>

      iex> query = Ash.Query.new(MyApp.User)
      iex> parse(query, where: [{:age, :between, 18, 65}])
      #Ash.Query<...>

      iex> query = Ash.Query.new(MyApp.Product)
      iex> parse(query, where: [{:category, :in, "electronics,books"}])
      #Ash.Query<...>
  """
  @spec parse(struct(), keyword()) :: struct()
  def parse(query, opts \\ []) do
    Enum.reduce(opts, query, &process_option/2)
  end

  ## PRIVATE

  # Applies :order_by option to sort the query
  @spec process_option(tuple(), struct()) :: struct()
  defp process_option({:order_by, values}, query) do
    Ash.Query.sort(query, values)
  end

  # Applies :where option by processing each filter clause
  defp process_option({:where, values}, query) do
    Enum.reduce(values, query, &process_where_clause/2)
  end

  # Ignores unrecognized options
  defp process_option(_option, query), do: query

  # Handles empty where clause
  @spec process_where_clause(term(), struct()) :: struct()
  defp process_where_clause([], query), do: query

  # Converts 2-tuple format to 3-tuple with default :eq operator
  defp process_where_clause({field, value}, query),
    do: process_where_clause({field, :eq, value}, query)

  # Handles :in operator with list values
  defp process_where_clause({field, :in, values}, query) when is_list(values),
    do: Ash.Query.filter(query, {^field, {:in, ^values}})

  # Handles :in operator with comma-separated string values
  defp process_where_clause({field, :in, value}, query) do
    values = String.split(value, ",")
    Ash.Query.filter(query, {^field, {:in, ^values}})
  end

  # Handles standard comparison operations
  defp process_where_clause({field, operation, value}, query) do
    operation
    |> translate_operation()
    |> then(&Ash.Query.filter(query, {^field, {^&1, ^value}}))
  end

  # Handles :between operator by creating :gte and :lte filters
  defp process_where_clause({field, :between, start_value, end_value}, query) do
    Enum.reduce(
      [{field, :gte, start_value}, {field, :lte, end_value}],
      query,
      &process_where_clause/2
    )
  end

  # Translates operation aliases to standard Ash operators
  @spec translate_operation(atom()) :: atom()
  defp translate_operation(operation) when operation in [:ge, :greater_equal_than], do: :gte
  defp translate_operation(operation) when operation in [:le, :less_equal_than], do: :lte
  defp translate_operation(:equal_to), do: :eq
  defp translate_operation(:like), do: :eq
  defp translate_operation(:ilike), do: :eq
  defp translate_operation(operation), do: operation
end
