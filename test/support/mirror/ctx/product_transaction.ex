defmodule Aurora.Uix.Test.MirrorCtx.ProductTransaction do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Aurora.Uix.Test.MirrorCtx.Product

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
  @foreign_key_type :binary_id
  @schema_prefix "mirror"
  @timestamps_opts [type: :utc_datetime_usec]

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
