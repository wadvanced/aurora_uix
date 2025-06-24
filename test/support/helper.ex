defmodule Aurora.Uix.Test.Support.Helper do
  @moduledoc """
  Helper functions for test data generation.

  ## Key Features
  - Utilities to create sample records for testing purposes.
  - Generates products, product locations, and transactions for test scenarios.
  """

  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductLocation
  alias Aurora.Uix.Test.Inventory.ProductTransaction
  alias Aurora.Uix.Test.Repo

  require Logger

  @doc """
  Creates a sequence of sample products with incremental IDs.

  ## Parameters
  - `count` (integer()) - Number of products to create.
  - `prefix` (atom() | nil) - Prefix to use in the reference of the product.
  - `attrs` (map()) - Attributes to override defaults.

  ## Returns
  map() - Map of product IDs with atom keys in the format `id_n`.
  """
  @spec create_sample_products(integer(), atom() | nil, map()) :: map()
  def create_sample_products(count, prefix \\ nil, attrs \\ %{}) do
    length = count |> to_string() |> String.length()

    1..count
    |> Enum.map(fn index ->
      reference_id = reference_id(prefix, index, length)
      reference = "item_#{reference_id}"
      name = "Item #{reference_id}"
      description = "This is the item #{reference_id} as described."
      cost = index / 100 + 123

      %Product{reference: reference, name: name, description: description, cost: cost}
      |> struct(attrs)
      |> Repo.insert()
      |> elem(1)
      |> then(&{"id_#{reference_id}", &1})
    end)
    |> Map.new()
  end

  @doc """
  Creates sample products with associated transactions.

  ## Parameters
  - `product_count` (integer()) - Number of products to create.
  - `transactions_count` (integer()) - Number of transactions per product.
  - `prefix` (atom() | nil) - Prefix for product references.

  ## Returns
  map() - Map of product IDs with associated transactions.
  """
  @spec create_sample_products_with_transactions(integer(), integer(), atom() | nil) :: map()
  def create_sample_products_with_transactions(product_count, transactions_count, prefix \\ nil) do
    product_count
    |> create_sample_products(prefix)
    |> Enum.map(&create_sample_product_transactions(&1, transactions_count))
  end

  @doc """
  Creates sample product locations.

  ## Parameters
  - `locations_count` (integer()) - Number of locations to create.

  ## Returns
  list(ProductLocation.t()) - List of created product locations.
  """
  @spec create_sample_product_locations(integer()) :: list(ProductLocation.t())
  def create_sample_product_locations(locations_count) do
    1..locations_count
    |> Enum.map(fn index ->
      %ProductLocation{
        reference: "test-reference-#{index}",
        name: "test-name-#{index}",
        type: "test-type-#{index}"
      }
      |> Repo.insert()
      |> elem(1)
      |> then(&{"id_#{index}", &1})
    end)
    |> Map.new()
  end

  @spec create_sample_product_transactions({binary(), Ecto.Schema.t()}, integer()) ::
          {binary(), Ecto.Schema.t()}
  defp create_sample_product_transactions(product, transactions_count) do
    1..transactions_count
    |> Enum.map(fn index ->
      Repo.insert(%ProductTransaction{
        product: elem(product, 1),
        type: "enter",
        quantity: index * 2,
        cost: index / 100 + 456
      })
    end)
    |> then(fn _ -> product end)
  end

  @spec reference_id(atom() | binary() | nil, integer(), integer()) :: binary()
  defp reference_id(nil, index, length), do: reference_id("", index, length)

  defp reference_id(prefix, index, length) when is_atom(prefix),
    do: prefix |> to_string() |> reference_id(index, length)

  defp reference_id(prefix, index, length) when is_binary(prefix) do
    prefix_with_hyphen = if prefix == "", do: "", else: "#{prefix}-"

    index
    |> to_string()
    |> String.length()
    |> then(&(length - &1))
    |> then(&String.duplicate("0", &1))
    |> then(&"#{prefix_with_hyphen}#{&1}#{index}")
  end
end
