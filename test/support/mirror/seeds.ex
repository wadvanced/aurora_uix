defmodule Aurora.Uix.Test.Mirror.Seeds do
  @moduledoc """
  Seed data for the mirrored fixture shared by the Ecto and the Ash backend.

  ## Key Features

  - Mirrors the inventory seed helpers of `Aurora.UixWeb.Test.Helper` over the `mirror` schema
  - Writes through `Aurora.Uix.Repo` and the `Aurora.Uix.Test.MirrorCtx` schemas, so one seed
    serves both backends
  - Seeds products with embeds, transactions, locations, suppliers and barcodes

  ## Key Constraints

  - Only for test scenarios
  - Requires the `mirror` schema migration to have run
  """

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx
  alias Aurora.Uix.Test.MirrorCtx.Product
  alias Aurora.Uix.Test.MirrorCtx.ProductBarcode
  alias Aurora.Uix.Test.MirrorCtx.ProductLocation
  alias Aurora.Uix.Test.MirrorCtx.ProductSupplier
  alias Aurora.Uix.Test.MirrorCtx.ProductTransaction
  alias Aurora.Uix.Test.MirrorCtx.Supplier

  @transaction_types ~w(entry exit returns move_in move_out)
  @transaction_types_count Enum.count(@transaction_types)

  @doc """
  Creates a sequence of sample products with incremental IDs.

  ## Parameters
  - `count` (integer()) - Number of products to create.
  - `prefix` (atom() | nil) - Prefix to use in the reference of the product.
  - `attrs` (map() | (integer() -> map())) - Attributes to override defaults, or a function
    returning them for each product index.

  ## Returns
  map() - Map of product IDs with atom keys in the format `id_n`.
  """
  @spec create_sample_products(integer(), atom() | nil, map() | (integer() -> map())) :: map()
  def create_sample_products(count, prefix \\ nil, attrs \\ %{}) do
    length = count |> to_string() |> String.length()

    1..count
    |> Enum.map(fn index ->
      reference_id = reference_id(prefix, index, length)
      reference = "item_#{reference_id}"
      name = "Item #{reference_id}"
      description = "This is the item #{reference_id} as described."
      cost = index / 100 + 123
      quantity_at_hand = :rand.uniform(10_000)

      %Product{
        reference: reference,
        name: name,
        description: description,
        cost: cost,
        quantity_at_hand: quantity_at_hand
      }
      |> struct(if is_function(attrs, 1), do: attrs.(index), else: attrs)
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
  - `attrs` (map()) - Attributes to override defaults.

  ## Returns
  map() - Map of product IDs with associated transactions.
  """
  @spec create_sample_products_with_transactions(
          integer(),
          integer(),
          atom() | nil,
          map() | (integer() -> map()) | nil
        ) ::
          map()
  def create_sample_products_with_transactions(
        product_count,
        transactions_count,
        prefix \\ nil,
        attrs \\ %{}
      ) do
    product_count
    |> create_sample_products(prefix, attrs)
    |> Enum.map(&create_sample_product_transactions(&1, transactions_count))
  end

  @doc """
  Creates sample product locations.

  ## Parameters
  - `locations_count` (integer()) - Number of locations to create.
  - `prefix` (atom() | nil) - Prefix for location references.

  ## Returns
  map() - Map of location IDs in the format `id_n`.
  """
  @spec create_sample_product_locations(integer(), atom() | nil) :: map()
  def create_sample_product_locations(locations_count, prefix \\ nil) do
    length = locations_count |> to_string() |> String.length()

    1..locations_count
    |> Enum.map(fn index ->
      reference_id = reference_id(prefix, index, length)

      %ProductLocation{
        reference: "test-reference-#{reference_id}",
        name: "test-name-#{reference_id}",
        type: "test-type-#{reference_id}"
      }
      |> Repo.insert()
      |> elem(1)
      |> then(&{"id_#{index}", &1})
    end)
    |> Map.new()
  end

  @doc """
  Creates suppliers and products, wiring each product to the given number of suppliers.

  Goes through `MirrorCtx.create_product/1` so the fixture exercises the host's `put_assoc` path.

  ## Parameters
  - `product_count` (integer()) - Number of products to create.
  - `supplier_count` (integer()) - Number of suppliers to create and attach to every product.

  ## Returns
  {list(Product.t()), list(Supplier.t())} - The created products and suppliers.
  """
  @spec create_sample_products_with_suppliers(integer(), integer()) :: {list(), list()}
  def create_sample_products_with_suppliers(product_count, supplier_count) do
    suppliers =
      Enum.map(1..supplier_count//1, fn index ->
        %Supplier{name: "Supplier #{index}", country: "Country #{index}"}
        |> Repo.insert()
        |> elem(1)
      end)

    supplier_ids = Enum.map(suppliers, & &1.id)

    products =
      Enum.map(1..product_count//1, fn index ->
        {:ok, product} =
          MirrorCtx.create_product(%{
            reference: "supplied_#{index}",
            name: "Supplied item #{index}",
            status: "in_stock",
            quantity_initial: index,
            suppliers: supplier_ids
          })

        product
      end)

    {products, suppliers}
  end

  @doc """
  Creates sample products, each with its single barcode.

  Goes through `MirrorCtx.create_product/1` so the nested child is built by the host's
  `cast_assoc`.

  ## Parameters
  - `count` (integer()) - Number of products to create.

  ## Returns
  list(Product.t()) - The created products.
  """
  @spec create_sample_products_with_barcodes(integer()) :: list(Product.t())
  def create_sample_products_with_barcodes(count) do
    Enum.map(1..count, fn index ->
      {:ok, product} =
        MirrorCtx.create_product(%{
          reference: "barcoded_#{index}",
          name: "Barcoded item #{index}",
          status: "in_stock",
          quantity_initial: index,
          product_barcode: %{
            code: "400638133#{String.pad_leading(to_string(index), 4, "0")}",
            symbology: "EAN-13",
            registered_at: Date.add(~D[2026-01-01], index)
          }
        })

      product
    end)
  end

  @doc """
  Creates sample products, each with a packaging and two contacts.

  ## Parameters
  - `count` (integer()) - Number of products to create.

  ## Returns
  list(Product.t()) - The created products.
  """
  @spec create_sample_products_with_embeds(integer()) :: [Product.t()]
  def create_sample_products_with_embeds(count) do
    Enum.map(1..count, fn index ->
      %Product{}
      |> Product.changeset(%{
        reference: "item_embeds-#{index}",
        name: "Item embeds-#{index}",
        status: "in_stock",
        quantity_initial: index,
        packaging: %{material: :box, fragile: true, notes: "note #{index}"},
        contacts: [
          %{email: "work#{index}@test.com", name: "Work"},
          %{email: "home#{index}@test.com", name: "Home"}
        ]
      })
      |> Repo.insert!()
    end)
  end

  @doc """
  Deletes every row of the mirrored fixture.

  ## Returns
  :ok
  """
  @spec delete_all_mirror_data() :: :ok
  def delete_all_mirror_data do
    Enum.each(
      [ProductSupplier, ProductTransaction, ProductBarcode, Product, Supplier, ProductLocation],
      &Repo.delete_all/1
    )
  end

  ## PRIVATE ##

  @spec create_sample_product_transactions({binary(), Ecto.Schema.t()}, integer()) ::
          {binary(), Ecto.Schema.t()}
  defp create_sample_product_transactions(product, transactions_count) do
    1..transactions_count
    |> Enum.map(fn index ->
      Repo.insert(%ProductTransaction{
        product: elem(product, 1),
        type: transaction_type(),
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

  @spec transaction_type() :: binary()
  defp transaction_type do
    @transaction_types_count
    |> :rand.uniform()
    |> then(&Enum.at(@transaction_types, &1 - 1))
  end
end
