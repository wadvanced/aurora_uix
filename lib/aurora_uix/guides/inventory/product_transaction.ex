defmodule Aurora.Uix.Guides.Inventory.ProductTransaction do
  @moduledoc """
  Ecto schema for product transactions in test inventory scenarios.

  Represents inventory movements tracking quantity and cost changes for products.

  ## Key Features

  - Tracks transaction type, quantity, and cost
  - Belongs to product relationship
  - Timestamp tracking for audit purposes

  ## Key Constraints

  - Only for guides and test scenarios
  - Requires type, quantity, cost, and product_id
  - Quantity and cost must be non-negative
  - Type limited to 20 characters
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Aurora.Uix.Guides.Inventory.Product

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          type: binary(),
          quantity: Decimal.t(),
          cost: Decimal.t(),
          product_id: Ecto.UUID.t() | nil,
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

    timestamps()
  end

  @doc """
  Creates a changeset for ProductTransaction.

  ## Parameters
  - `product_transaction` (t()) - The product transaction struct.
  - `attrs` (map()) - The attributes to apply.

  ## Returns
  Ecto.Changeset.t() - The resulting changeset.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(product_transaction, attrs) do
    product_transaction
    |> cast(attrs, [:type, :quantity, :cost, :product_id])
    |> validate_required([:type, :quantity, :cost, :product_id])
    |> validate_length(:type, max: 20)
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> validate_number(:cost, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:product_id)
  end
end
