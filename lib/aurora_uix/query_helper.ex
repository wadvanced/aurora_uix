defmodule AuroraUix.QueryHelper do
  @moduledoc """
  Helper module for building Ecto queries with common options like preloading.
  """

  import Ecto.Query

  @doc """
  Applies a list of options to an Ecto query.

  ## Parameters
    - `query` (Ecto.Query.t() | nil): The query to modify
    - `options` (keyword): List of options to apply. Supports {:preload, associations}

  ## Returns
    - `Ecto.Query.t()`: The modified query with options applied
  """
  @spec options(Ecto.Query.t() | nil, keyword) :: Ecto.Query.t()
  def options(query, options \\ [])
  def options(nil, _options), do: nil

  def options(query, options) do
    Enum.reduce(options, query, &option(&2, &1))
  end

  @spec option(Ecto.Query.t(), tuple) :: Ecto.Query.t()
  defp option(%Ecto.Query{} = query, {:preload, preload}),
    do: preload(query, ^preload)

  defp option(query, _option), do: query
end
