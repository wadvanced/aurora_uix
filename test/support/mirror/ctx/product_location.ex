defmodule Aurora.Uix.Test.MirrorCtx.ProductLocation do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "mirror"
  @timestamps_opts [type: :utc_datetime_usec]
  schema "product_locations" do
    field(:reference, :string)
    field(:name, :string)
    field(:type, :string)

    has_many(:products, Aurora.Uix.Test.MirrorCtx.Product)

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
  - `product_location` (t()) - The product location struct.
  - `attrs` (map()) - The attributes to apply.

  ## Returns
  Ecto.Changeset.t() - The resulting changeset.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
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
