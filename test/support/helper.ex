defmodule Aurora.Uix.Test.Support.Helper do
  @moduledoc """
  Helper functions for test data generation.
  Provides utilities to create sample records for testing purposes.
  """

  alias AuroraUixTest.Repo
  alias AuroraUixTest.Inventory.Product

  require Logger

  @doc """
  Creates a sequence of sample products with incremental IDs.

  ## Parameters
    * `context` - The context module containing product CRUD functions
    * `to` - Number of products to create (integer)

  ## Returns
    Map of product IDs with atom keys in the format `id_n`

  ## Example
      # Create 3 sample products
      products = create_sample_products(MyApp.Inventory, 3)

      # Access product IDs
      products.id_1  # => 1
      products.id_2  # => 2
      products.id_3  # => 3
  """
  @spec create_sample_products(integer) :: list()
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
