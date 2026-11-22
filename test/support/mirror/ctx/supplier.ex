defmodule Aurora.Uix.Test.MirrorCtx.Supplier do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Aurora.Uix.Test.MirrorCtx.Product
  alias Aurora.Uix.Test.MirrorCtx.ProductSupplier

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "mirror"
  @timestamps_opts [type: :utc_datetime_usec]
  schema "suppliers" do
    field(:name, :string)
    field(:country, :string)

    many_to_many(:products, Product, join_through: ProductSupplier)

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
