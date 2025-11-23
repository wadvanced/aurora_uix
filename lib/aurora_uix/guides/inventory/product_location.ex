defmodule Aurora.Uix.Guides.Inventory.ProductLocation do
  @moduledoc """
  Symbolic Ecto schema for product locations in test inventory scenarios.

  ## Key Features
  - Used for testing inventory-related features.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "product_locations" do
    field(:reference, :string)
    field(:name, :string)
    field(:type, :string)

    has_many(:products, Aurora.Uix.Guides.Inventory.Product)

    timestamps()
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          reference: binary() | nil,
          name: binary() | nil,
          type: binary() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  Creates a changeset for ProductLocation.

  ## Parameters
  - `product_location` (ProductLocation.t() | Ecto.Changeset.t()) - The struct or changeset to update.
  - `attrs` (map()) - The attributes to apply.

  ## Returns
  Ecto.Changeset.t() - The resulting changeset.
  """
  @spec changeset(__MODULE__.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(product_location, attrs) do
    product_location
    |> cast(attrs, [
      :reference,
      :name,
      :type
    ])
    |> validate_required([:name, :type])
    |> validate_length(:reference, max: 30)
    |> validate_length(:type, max: 20)
  end
end
