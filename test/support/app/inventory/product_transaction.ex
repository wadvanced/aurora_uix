defmodule Aurora.Uix.Test.Inventory.ProductTransaction do
  @moduledoc """
  Represents a transaction for a product in the inventory.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Aurora.Uix.Test.Inventory.{Product, ProductLocation}

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          type: String.t(),
          quantity: Decimal.t(),
          cost: Decimal.t(),
          product_id: Ecto.UUID.t() | nil,
          product_location_id: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

  schema "product_transactions" do
    field(:type, :string)
    field(:quantity, :decimal)
    field(:cost, :decimal)

    belongs_to(:product, Product, type: :binary_id)
    belongs_to(:product_location, ProductLocation, type: :binary_id)

    timestamps()
  end

  @doc """
  Creates a changeset for a product transaction.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(product_transaction, attrs) do
    product_transaction
    |> cast(attrs, [:type, :quantity, :cost, :product_id, :product_location_id])
    |> validate_required([:type, :quantity, :cost, :product_id])
    |> validate_length(:type, max: 20)
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> validate_number(:cost, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:product_id)
    |> foreign_key_constraint(:product_location_id)
  end
end
