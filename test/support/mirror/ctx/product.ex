defmodule Aurora.Uix.Test.MirrorCtx.Product do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Aurora.Uix.Test.MirrorCtx.{
    ProductBarcode,
    ProductLocation,
    ProductSupplier,
    ProductTransaction,
    Supplier
  }

  alias Aurora.Uix.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "mirror"
  @timestamps_opts [type: :utc_datetime_usec]

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
          grade: atom() | nil,
          labels: list(atom()) | nil,
          units_per_box: integer() | nil,
          margin: float() | nil,
          released_on: Date.t() | nil,
          opens_at: Time.t() | nil,
          audited_at: NaiveDateTime.t() | nil,
          discontinued_at: DateTime.t() | nil,
          deleted: boolean() | nil,
          inactive: boolean() | nil,
          packaging: map() | nil,
          contacts: list(map()),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          product_transactions: list(ProductTransaction.t()) | Ecto.Association.NotLoaded.t(),
          product_barcode: ProductBarcode.t() | Ecto.Association.NotLoaded.t() | nil,
          suppliers: list(Supplier.t()) | Ecto.Association.NotLoaded.t()
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
    field(:grade, Ecto.Enum, values: [:standard, :premium, :clearance])
    field(:labels, {:array, Ecto.Enum}, values: [:fragile, :perishable, :hazardous])
    field(:units_per_box, :integer)
    field(:margin, :float)
    field(:released_on, :date)
    field(:opens_at, :time)
    field(:audited_at, :naive_datetime)
    field(:discontinued_at, :utc_datetime)
    field(:deleted, :boolean, default: false)
    field(:inactive, :boolean, default: false)

    embeds_one :packaging, Packaging, primary_key: false, on_replace: :update do
      field(:material, Ecto.Enum, values: [:box, :bag, :crate])
      field(:fragile, :boolean)
      field(:notes, :string)
    end

    embeds_many :contacts, Contact, primary_key: false, on_replace: :delete do
      field(:email, :string)
      field(:name, :string)
    end

    has_many(:product_transactions, ProductTransaction)
    has_one(:product_barcode, ProductBarcode, on_replace: :update)
    belongs_to(:product_location, ProductLocation, type: :binary_id)

    # `on_replace: :delete` deletes the JOIN rows, never the suppliers themselves.
    many_to_many(:suppliers, Supplier, join_through: ProductSupplier, on_replace: :delete)

    timestamps()
  end

  @doc """
  Generates a changeset for a product schema.

  ## Parameters
  - `product` (t()) - The product struct.
  - `attrs` (map()) - Attributes to update.

  ## Returns
  Ecto.Changeset.t() - The changeset for the product.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(product, attrs) do
    attrs = reject_blank_labels(attrs)

    product
    |> cast(attrs, [
      :reference,
      :name,
      :description,
      :product_location_id,
      :status,
      :labels,
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
      :inactive,
      :grade,
      :units_per_box,
      :margin,
      :released_on,
      :opens_at,
      :audited_at,
      :discontinued_at
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
    |> cast_assoc(:product_barcode, with: &ProductBarcode.changeset/2)
    |> put_suppliers(attrs)
    |> cast_embed(:packaging, with: &packaging_changeset/2)
    |> cast_embed(:contacts, with: &contact_changeset/2)
  end

  @doc """
  Builds a changeset for the embedded packaging.

  ## Parameters
  - `packaging` (Ecto.Schema.t()) - The packaging struct.
  - `attrs` (map()) - Attributes to update.

  ## Returns
  Ecto.Changeset.t() - The changeset for the packaging.
  """
  @spec packaging_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def packaging_changeset(packaging, attrs) do
    cast(packaging, attrs, [:material, :fragile, :notes])
  end

  @doc """
  Builds a changeset for an embedded contact.

  ## Parameters
  - `contact` (Ecto.Schema.t()) - The contact struct.
  - `attrs` (map()) - Attributes to update.

  ## Returns
  Ecto.Changeset.t() - The changeset for the contact.
  """
  @spec contact_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def contact_changeset(contact, attrs) do
    contact
    |> cast(attrs, [:email, :name])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
  end

  # The multi-value select renders an empty-value sentinel so that de-selecting every label still
  # submits the key; without it the field could never be cleared. `{:array, Ecto.Enum}` has no member
  # for a blank, so it is dropped before `cast/3` sees the list.
  @spec reject_blank_labels(map()) :: map()
  defp reject_blank_labels(%{"labels" => labels} = attrs) when is_list(labels),
    do: %{attrs | "labels" => reject_blanks(labels)}

  defp reject_blank_labels(%{labels: labels} = attrs) when is_list(labels),
    do: %{attrs | labels: reject_blanks(labels)}

  defp reject_blank_labels(attrs), do: attrs

  # Many-to-many membership arrives as a list of supplier ids, which `cast/3` cannot handle -- an
  # association is not a field. The library only transports the list; resolving it to records and
  # writing the join rows is the host's job, which is what this does.
  @spec put_suppliers(Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  defp put_suppliers(changeset, attrs) do
    case supplier_ids(attrs) do
      :absent ->
        changeset

      ids ->
        query = from(s in Supplier, where: s.id in ^ids)
        suppliers = Repo.all(query)
        put_assoc(changeset, :suppliers, suppliers)
    end
  end

  # Accepts string keys (form params) and atom keys (test helpers and host code).
  @spec supplier_ids(map()) :: list(binary()) | :absent
  defp supplier_ids(attrs) do
    cond do
      Map.has_key?(attrs, "suppliers") -> reject_blanks(attrs["suppliers"])
      Map.has_key?(attrs, :suppliers) -> reject_blanks(attrs[:suppliers])
      true -> :absent
    end
  end

  @spec reject_blanks(term()) :: list()
  defp reject_blanks(ids) when is_list(ids), do: Enum.reject(ids, &(is_nil(&1) or &1 == ""))
  defp reject_blanks(_ids), do: []
end
