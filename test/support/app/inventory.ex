defmodule AuroraUixTest.Inventory do
  @moduledoc """
  The context.
  """

  use Aurora.Ctx

  alias AuroraUixTest.Inventory.{Product, ProductLocation, ProductTransaction}
  alias AuroraUixTest.Repo

  @spec list_products() :: [Product.t()]
  def list_products do
    Repo.all(Product)
  end

  @spec create_product(map) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @spec change_product(Product.t() | Ecto.Changeset.t(), map) :: Ecto.Changeset.t()
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end

  @spec update_product(Product.t() | Ecto.Changeset.t(), map) ::
          {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @spec get_product!(binary) :: nil | Product.t()
  def get_product!(id) do
    Product |> Repo.get!(id) |> Repo.preload(product_transactions: [:product_location, :product])
  end

  @spec delete_product(Product.t()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def delete_product(%Product{} = product), do: Repo.delete(product)

  ctx_register_schema(Product)
  ctx_register_schema(ProductTransaction)
  ctx_register_schema(ProductLocation)
end
