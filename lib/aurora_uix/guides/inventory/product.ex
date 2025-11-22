defmodule Aurora.Uix.Inventory.Product do
  @moduledoc """
  Ecto schema for products in test inventory scenarios.

  ## Key Features
  - Used for testing inventory-related features.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Aurora.Uix.Inventory.{ProductLocation, ProductTransaction}

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          reference: binary() | nil,
          name: binary() | nil,
          description: binary() | nil,
          product_location_id: Ecto.UUID.t() | nil,
          quantity_at_hand: Decimal.t() | nil,
          quantity_initial: Decimal.t() | nil,
          quantity_entries: Decimal.t() | nil,
          quantity_exits: Decimal.t() | nil,
          cost: Decimal.t() | nil,
          msrp: Decimal.t() | nil,
          rrp: Decimal.t() | nil,
          list_price: Decimal.t() | nil,
          discounted_price: Decimal.t() | nil,
          weight: Decimal.t() | nil,
          length: Decimal.t() | nil,
          width: Decimal.t() | nil,
          height: Decimal.t() | nil,
          image: binary() | nil,
          thumbnail: binary() | nil,
          status: binary() | nil,
          deleted: boolean() | nil,
          inactive: boolean() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          product_transactions: list(ProductTransaction.t()) | Ecto.Association.NotLoaded.t()
        }

  schema "products" do
    field(:reference, :string)
    field(:name, :string)
    field(:description, :string)
    field(:quantity_at_hand, :decimal)
    field(:quantity_initial, :decimal)
    field(:quantity_entries, :decimal)
    field(:quantity_exits, :decimal)
    field(:cost, :decimal)
    field(:msrp, :decimal)
    field(:rrp, :decimal)
    field(:list_price, :decimal)
    field(:discounted_price, :decimal)
    field(:weight, :decimal)
    field(:length, :decimal)
    field(:width, :decimal)
    field(:height, :decimal)
    field(:image, :binary)
    field(:thumbnail, :binary)
    field(:status, :string, default: "in_stock")
    field(:deleted, :boolean, default: false)
    field(:inactive, :boolean, default: false)

    has_many(:product_transactions, ProductTransaction)
    belongs_to(:product_location, ProductLocation, type: :binary_id)

    timestamps()
  end

  @doc """
  Generates a changeset for a product schema.

  ## Parameters
  - `product` (t() | Ecto.Changeset.t()) - The product struct or changeset.
  - `attrs` (map()) - Attributes to update.

  ## Returns
  Ecto.Changeset.t() - The changeset for the product.
  """
  @spec changeset(__MODULE__.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :reference,
      :name,
      :description,
      :product_location_id,
      :status,
      :quantity_at_hand,
      :quantity_initial,
      :quantity_entries,
      :quantity_exits,
      :cost,
      :msrp,
      :rrp,
      :list_price,
      :discounted_price,
      :weight,
      :length,
      :width,
      :height,
      :image,
      :thumbnail,
      :deleted,
      :inactive
    ])
    |> validate_required([:name, :status, :quantity_initial])
    |> validate_length(:reference, max: 30)
    |> validate_length(:status, max: 20)
    |> validate_number(:quantity_at_hand, greater_than_or_equal_to: 0)
    |> validate_number(:quantity_initial, greater_than_or_equal_to: 0)
    |> validate_number(:cost, greater_than_or_equal_to: 0)
    |> validate_number(:msrp, greater_than_or_equal_to: 0)
    |> validate_number(:rrp, greater_than_or_equal_to: 0)
    |> validate_number(:list_price, greater_than_or_equal_to: 0)
    |> validate_number(:discounted_price, greater_than_or_equal_to: 0)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_number(:length, greater_than_or_equal_to: 0)
    |> validate_number(:width, greater_than_or_equal_to: 0)
    |> validate_number(:height, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:product_location_id)
  end
end
