defmodule Aurora.Uix.Guides.Inventory do
  @moduledoc """
  Inventory context for guides and test support.

  Provides CRUD operations for products, product transactions, and product locations.
  This module and its children are excluded from package builds and documentation.

  ## Key Features

  - CRUD operations for products, product transactions, and product locations
  - Schema registration for use in guides and tests
  - Association preloading support for product relationships

  ## Key Constraints

  - Only for test and development environments
  - Not included in production builds
  """

  use Aurora.Ctx

  alias Aurora.Uix.Guides.Inventory.{Product, ProductLocation, ProductTransaction}
  alias Aurora.Uix.Repo

  @doc """
  Lists all products.

  ## Returns
  list(Product.t()) - List of all products.
  """
  @spec list_products() :: [Product.t()]
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Creates a product with the given attributes.

  ## Parameters
  - `attrs` (map()) - Attributes for the new product. Defaults to `%{}`.

  ## Returns
  {:ok, Product.t()} | {:error, Ecto.Changeset.t()} - Result tuple with created product or error.
  """
  @spec create_product(map()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a changeset for a product.

  ## Parameters
  - `product` (Product.t()) - The product struct.
  - `attrs` (map()) - Attributes to update. Defaults to `%{}`.

  ## Returns
  Ecto.Changeset.t() - The changeset for the product.
  """
  @spec change_product(Product.t(), map()) :: Ecto.Changeset.t()
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  @doc """
  Updates a product with the given attributes.

  ## Parameters
  - `product` (Product.t()) - The product struct.
  - `attrs` (map()) - Attributes to update.

  ## Returns
  {:ok, Product.t()} | {:error, Ecto.Changeset.t()} - Result tuple with updated product or error.
  """
  @spec update_product(Product.t(), map()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a product by ID and preloads associations.

  ## Parameters
  - `id` (binary()) - The product ID.

  ## Returns
  Product.t() | nil - The product struct or nil if not found.
  """
  @spec get_product!(binary()) :: nil | Product.t()
  def get_product!(id) do
    Product |> Repo.get!(id) |> Repo.preload(product_transactions: [:product_location, :product])
  end

  @doc """
  Deletes a product.

  ## Parameters
  - `product` (Product.t()) - The product to delete.

  ## Returns
  {:ok, Product.t()} | {:error, Ecto.Changeset.t()} - Result tuple with deleted product or error.
  """
  @spec delete_product(Product.t()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def delete_product(%Product{} = product), do: Repo.delete(product)

  ctx_register_schema(Product, Repo)
  ctx_register_schema(ProductTransaction, Repo)
  ctx_register_schema(ProductLocation, Repo)
end
