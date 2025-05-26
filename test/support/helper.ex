defmodule Aurora.Uix.Test.Support.Helper do
  @moduledoc """
  Helper functions for test data generation.
  Provides utilities to create sample records for testing purposes.
  """

  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Repo

  require Logger

  @doc """
  Creates a sequence of sample products with incremental IDs.

  - context: module() - The context module containing product CRUD functions
  - to: integer() - Number of products to create

  Returns: map() - Map of product IDs with atom keys in the format `id_n`
  """
  @spec create_sample_products(integer) :: map()
  def create_sample_products(to) do
    length = to |> to_string() |> String.length()

    1..to
    |> Enum.map(fn index ->
      reference_id = reference_id(index, length)
      reference = "item_#{reference_id}"
      name = "Item #{reference_id}"
      description = "This is the item #{reference_id} as described."
      cost = index / 100 + 123

      %Product{reference: reference, name: name, description: description, cost: cost}
      |> Repo.insert()
      |> elem(1)
      |> then(&{String.to_atom("id_#{reference_id}"), &1})
    end)
    |> Map.new()
  end

  @doc false
  @spec reference_id(integer, integer) :: binary
  defp reference_id(index, length) do
    index
    |> to_string()
    |> String.length()
    |> then(&(length - &1))
    |> then(&String.duplicate("0", &1))
    |> then(&"#{&1}#{index}")
  end
end
