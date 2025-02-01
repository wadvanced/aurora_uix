defmodule AuroraUixTest.Inventory.Product do
  @moduledoc """
  Represents a product in the inventory.

  This schema corresponds to the `products` table and includes fields
  such as quantities, prices, dimensions, and status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          reference: String.t() | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          quantity_at_hand: Decimal.t() | nil,
          quantity_initial: Decimal.t() | nil,
          quantity_entries: Decimal.t() | nil,
          quantity_exits: Decimal.t() | nil,
          cost: Decimal.t() | nil,
          rrp: Decimal.t() | nil,
          list_price: Decimal.t() | nil,
          discounted_price: Decimal.t() | nil,
          weight: Decimal.t() | nil,
          length: Decimal.t() | nil,
          width: Decimal.t() | nil,
          height: Decimal.t() | nil,
          image: binary() | nil,
          thumbnail: binary() | nil,
          status: String.t() | nil,
          deleted: boolean() | nil,
          inactive: boolean() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
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
    field(:rrp, :decimal)
    field(:list_price, :decimal)
    field(:discounted_price, :decimal)
    field(:weight, :decimal)
    field(:length, :decimal)
    field(:width, :decimal)
    field(:height, :decimal)
    field(:image, :binary)
    field(:thumbnail, :binary)
    field(:status, :string)
    field(:deleted, :boolean, default: false)
    field(:inactive, :boolean, default: false)

    has_many(:product_transactions, AuroraUixTest.Inventory.ProductTransaction)

    timestamps()
  end

  @doc """
  Generates a changeset for a product schema.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(product, attrs) do
    product
    |> cast(attrs, [
      :reference,
      :name,
      :description,
      :status,
      :quantity_at_hand,
      :quantity_initial,
      :quantity_entries,
      :quantity_exits,
      :cost,
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
    |> validate_number(:rrp, greater_than_or_equal_to: 0)
    |> validate_number(:list_price, greater_than_or_equal_to: 0)
    |> validate_number(:discounted_price, greater_than_or_equal_to: 0)
    |> validate_number(:weight, greater_than_or_equal_to: 0)
    |> validate_number(:length, greater_than_or_equal_to: 0)
    |> validate_number(:width, greater_than_or_equal_to: 0)
    |> validate_number(:height, greater_than_or_equal_to: 0)
  end
end
