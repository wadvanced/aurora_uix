defmodule Aurora.Uix.Test.Inventory.ProductLocation do
  @moduledoc """
  Schema for Product Locations in the inventory system.
  Tracks product quantities, location details and inventory movements.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Aurora.Uix.Test.Inventory.Product

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "product_locations" do
    field(:reference, :string)
    field(:name, :string)
    field(:type, :string)
    field(:quantity_at_hand, :decimal)
    field(:quantity_initial, :decimal)
    field(:quantity_entries, :decimal)
    field(:quantity_exits, :decimal)

    belongs_to(:product, Product)

    timestamps()
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          reference: String.t() | nil,
          name: String.t() | nil,
          type: String.t() | nil,
          quantity_at_hand: Decimal.t() | nil,
          quantity_initial: Decimal.t() | nil,
          quantity_entries: Decimal.t() | nil,
          quantity_exits: Decimal.t() | nil,
          product_id: Ecto.UUID.t() | nil,
          product: Aurora.Uix.Test.Product.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  Creates a changeset for ProductLocation.

  - product_location: ProductLocation.t() | Ecto.Changeset.t() - The struct or changeset to update
  - attrs: map() - The attributes to apply

  Returns: Ecto.Changeset.t() - The resulting changeset
  """
  @spec changeset(ProductLocation.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(product_location, attrs) do
    product_location
    |> cast(attrs, [
      :reference,
      :name,
      :type,
      :quantity_at_hand,
      :quantity_initial,
      :quantity_entries,
      :quantity_exits,
      :product_id
    ])
    |> validate_required([:name, :type])
    |> validate_length(:reference, max: 30)
    |> validate_length(:type, max: 20)
    |> foreign_key_constraint(:product_id)
  end
end
