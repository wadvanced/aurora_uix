defmodule Aurora.Uix.Integration.Ash.QueryParser do
  require Ash.Query

  def parse(query, opts \\ []) do
    Enum.reduce(opts, query, &process_option/2)
  end

  defp process_option({:order_by, values}, query) do
    Ash.Query.sort(query, values)
  end

  defp process_option({:where, values}, query) do
    Enum.reduce(values, query, &process_where_clause/2)
  end

  defp process_option(_option, query), do: query

  defp process_where_clause([], query), do: query

  defp process_where_clause({field, value}, query),
    do: process_where_clause({field, :eq, value}, query)

  defp process_where_clause({field, :in, values}, query) when is_list(values),
    do: Ash.Query.filter(query, {^field, {:in, ^values}})

  defp process_where_clause({field, :in, value}, query) do
    values = String.split(value, ",")
    Ash.Query.filter(query, {^field, {:in, ^values}})
  end

  defp process_where_clause({field, operation, value}, query) do
    operation
    |> translate_operation()
    |> then(&Ash.Query.filter(query, {^field, {^&1, ^value}}))
  end

  defp process_where_clause({field, :between, start_value, end_value}, query) do
    Enum.reduce(
      [{field, :gte, start_value}, {field, :lte, end_value}],
      query,
      &process_where_clause/2
    )
  end

  defp translate_operation(operation) when operation in [:ge, :greater_equal_than], do: :gte
  defp translate_operation(operation) when operation in [:le, :less_equal_than], do: :lte
  defp translate_operation(:equal_to), do: :eq
  defp translate_operation(:like), do: :eq
  defp translate_operation(:ilike), do: :eq
  defp translate_operation(operation), do: operation
end
