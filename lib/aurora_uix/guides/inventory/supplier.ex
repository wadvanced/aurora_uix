defmodule Aurora.Uix.Guides.Inventory.Supplier do
  @moduledoc """
  Ecto schema for suppliers in test inventory scenarios.

  Represents a company that supplies products. The relationship with products is many-to-many in
  both directions: a product may be sourced from several suppliers, and a supplier supplies many
  products. The linkage lives in the `product_suppliers` join table.

  ## Key Features

  - Many to many products relationship through a join table
  - Name and country fields for identification
  - Timestamp tracking for audit purposes

  ## Key Constraints

  - Only for guides and test scenarios
  - Requires a name
  - Name limited to 60 characters, country to 40
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "suppliers" do
    field(:name, :string)
    field(:country, :string)

    many_to_many(:products, Aurora.Uix.Guides.Inventory.Product,
      join_through: "product_suppliers"
    )

    timestamps()
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: binary() | nil,
          country: binary() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  Creates a changeset for Supplier.

  ## Parameters
  - `supplier` (t()) - The supplier struct.
  - `attrs` (map()) - The attributes to apply.

  ## Returns
  Ecto.Changeset.t() - The resulting changeset.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(supplier, attrs) do
    supplier
    |> cast(attrs, [
      :name,
      :country
    ])
    |> validate_required([:name])
    |> validate_length(:name, max: 60)
    |> validate_length(:country, max: 40)
  end
end
