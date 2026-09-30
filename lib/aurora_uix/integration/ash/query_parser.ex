defmodule Aurora.Uix.Integration.Ash.QueryParser do
  @moduledoc """
  Parses and applies query options to Ash queries.

  Transforms keyword list options into Ash query operations, supporting filtering,
  sorting, preloading, and other query modifications. Handles various comparison
  operators and automatically translates them to Ash-compatible formats.

  ## Key Features

  - Supports `:order_by` in both the `Aurora.Ctx.QueryBuilder` direction-first form (`[desc: :title]`, `*_nulls_first` / `*_nulls_last`) and Ash's field-first form (`[title: :desc]`)
  - Handles `:where` clauses with multiple operators (`:eq`, `:in`, `:between`, `:like`,
    `:ilike`, `:gte`, `:lte`)
  - Supports `:preload` for loading associations
  - Automatically translates operation aliases (`:ge`, `:le`, `:equal_to`)

  ## Key Constraints

  - Only processes `:order_by`, `:where`, and `:preload` options; other options are
    ignored
  - The `:in` operator accepts a list of values only; any other value makes the query invalid
  - The `:between` operator requires start and end values
  - `:ilike` (and `:like`) are passed through as-is to `Ash.Query.filter/2`, resolved via
    `AshPostgres.Functions.ILike`. This is an AshPostgres data-layer function: on a
    non-Postgres Ash data layer the filter raises rather than silently matching wrong rows
  - `:where` accepts a single condition tuple as well as a list; `dynamic/2` expressions are Ecto-only and are not supported
  """
  require Ash.Query

  @query_builder_directions [
    :asc,
    :desc,
    :asc_nulls_first,
    :asc_nulls_last,
    :desc_nulls_first,
    :desc_nulls_last
  ]

  @ash_sort_directions [
    :asc,
    :desc,
    :asc_nils_first,
    :asc_nils_last,
    :desc_nils_first,
    :desc_nils_last
  ]

  @doc """
  Parses and applies query options to an Ash query.

  ## Parameters

  - `query` (Ash.Query.t()) - The base Ash query to modify.
  - `opts` (keyword()) - Options:
    * `:order_by` (term()) - Sorting specification; direction-first entries are translated before `Ash.Query.sort/2`.
    * `:where` (list()) - List of filter clauses.
    * `:preload` (term()) - Associations to load.

  ## Returns

  Ash.Query.t() - The modified query with applied options.

  ## Examples

      iex> query = Ash.Query.new(MyApp.Post)
      iex> parse(query, where: [{:status, :eq, "published"}], order_by: [inserted_at: :desc])
      #Ash.Query<...>

      iex> query = Ash.Query.new(MyApp.User)
      iex> parse(query, where: [{:age, :between, 18, 65}])
      #Ash.Query<...>

      iex> query = Ash.Query.new(MyApp.Product)
      iex> parse(query, where: [{:category, :in, ["electronics", "books"]}])
      #Ash.Query<...>
  """
  @spec parse(Ash.Query.t(), keyword()) :: Ash.Query.t()
  def parse(query, opts \\ []) do
    Enum.reduce(opts, query, &process_option/2)
  end

  ## PRIVATE

  # Applies :order_by option to sort the query.
  @spec process_option(tuple(), Ash.Query.t()) :: Ash.Query.t()
  defp process_option({:order_by, values}, query) do
    values
    |> List.wrap()
    |> Enum.map(&translate_sort/1)
    |> then(&Ash.Query.sort(query, &1))
  end

  # Applies :where option by processing each filter clause.
  defp process_option({:where, values}, query) do
    values |> List.wrap() |> Enum.reduce(query, &process_where_clause/2)
  end

  # Applies :preload option to load associations.
  defp process_option({:preload, values}, query) do
    Ash.Query.load(query, values)
  end

  # Ignores unrecognized options.
  defp process_option(_option, query),
    do: query

  # Handles empty where clause.
  @spec process_where_clause(term(), Ash.Query.t()) :: Ash.Query.t()
  defp process_where_clause([], query), do: query

  # Converts 2-tuple format to 3-tuple with default :eq operator.
  defp process_where_clause({field, value}, query),
    do: process_where_clause({field, :eq, value}, query)

  # Handles :in operator with list values.
  defp process_where_clause({field, :in, values}, query) when is_list(values),
    do: Ash.Query.filter(query, {^field, {:in, ^values}})

  # Handles standard comparison operations.
  defp process_where_clause({field, operation, value}, query) do
    operation
    |> translate_operation()
    |> then(&Ash.Query.filter(query, {^field, {^&1, ^value}}))
  end

  # Handles :between operator by creating :gte and :lte filters.
  defp process_where_clause({field, :between, start_value, end_value}, query) do
    Enum.reduce(
      [{field, :gte, start_value}, {field, :lte, end_value}],
      query,
      &process_where_clause/2
    )
  end

  # `Aurora.Ctx.QueryBuilder` sorts are direction-first (`desc: :title`); Ash's are field-first
  # (`title: :desc`). An entry whose second element is an Ash direction is already Ash-shaped.
  @spec translate_sort(term()) :: term()
  defp translate_sort({direction, field})
       when direction in @query_builder_directions and is_atom(field) and
              field not in @ash_sort_directions,
       do: {field, ash_sort_direction(direction)}

  defp translate_sort(sort), do: sort

  @spec ash_sort_direction(atom()) :: atom()
  defp ash_sort_direction(:asc_nulls_first), do: :asc_nils_first
  defp ash_sort_direction(:asc_nulls_last), do: :asc_nils_last
  defp ash_sort_direction(:desc_nulls_first), do: :desc_nils_first
  defp ash_sort_direction(:desc_nulls_last), do: :desc_nils_last
  defp ash_sort_direction(direction), do: direction

  # Translates operation aliases to standard Ash operators.
  @spec translate_operation(atom()) :: atom()
  defp translate_operation(operation) when operation in [:ge, :greater_equal_than], do: :gte
  defp translate_operation(operation) when operation in [:le, :less_equal_than], do: :lte
  defp translate_operation(:equal_to), do: :eq
  defp translate_operation(operation), do: operation
end
