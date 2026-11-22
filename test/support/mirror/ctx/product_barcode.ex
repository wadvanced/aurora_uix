defmodule Aurora.Uix.Test.MirrorCtx.ProductBarcode do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "mirror"
  @timestamps_opts [type: :utc_datetime_usec]
  schema "product_barcodes" do
    field(:code, :string)
    field(:symbology, :string, default: "EAN-13")
    field(:registered_at, :date)

    belongs_to(:product, Aurora.Uix.Test.MirrorCtx.Product)

    timestamps()
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          code: binary() | nil,
          symbology: binary() | nil,
          registered_at: Date.t() | nil,
          product_id: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  Creates a changeset for ProductBarcode.

  ## Parameters
  - `product_barcode` (t()) - The product barcode struct.
  - `attrs` (map()) - The attributes to apply.

  ## Returns
  Ecto.Changeset.t() - The resulting changeset.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(product_barcode, attrs) do
    product_barcode
    |> cast(attrs, [
      :code,
      :symbology,
      :registered_at,
      :product_id
    ])
    |> validate_required([:code])
    |> validate_length(:code, max: 20)
    |> validate_length(:symbology, max: 20)
    |> unique_constraint(:code)
    |> unique_constraint(:product_id)
  end
end
