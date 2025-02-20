Code.require_file("test/support/app/repo.exs")

defmodule AuroraUixTest.Inventory do
  @moduledoc """
  The context.
  """
  alias AuroraUixTest.Inventory.Product
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
  def change_product(%Product{} = account, attrs \\ %{}) do
    Product.changeset(account, attrs)
  end

  @spec get_product!(binary) :: nil | Product.t()
  def get_product!(id) do
    Repo.get!(Product, id)
  end

  @spec delete_product(Product.t()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def delete_product(%Product{} = product), do: Repo.delete(product)
end
