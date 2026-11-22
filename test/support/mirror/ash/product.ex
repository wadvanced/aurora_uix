defmodule Aurora.Uix.Test.MirrorAsh.Product do
  @moduledoc false

  use Ash.Resource, data_layer: AshPostgres.DataLayer, domain: Aurora.Uix.Test.MirrorAsh

  alias Aurora.Uix.Test.MirrorAsh.{
    Contact,
    Packaging,
    ProductBarcode,
    ProductLocation,
    ProductSupplier,
    ProductTransaction,
    Supplier
  }

  postgres do
    table "products"
    schema "mirror"
    repo(Aurora.Uix.Repo)
    migrate?(false)
  end

  attributes do
    uuid_primary_key :id

    attribute :reference, :string, constraints: [max_length: 30], public?: true
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :description, :string, public?: true

    attribute :status, :string,
      allow_nil?: false,
      default: "in_stock",
      constraints: [max_length: 20],
      public?: true

    attribute :grade, :atom,
      constraints: [one_of: [:standard, :premium, :clearance]],
      public?: true

    attribute :labels, {:array, :atom},
      constraints: [nil_items?: true, items: [one_of: [:fragile, :perishable, :hazardous]]],
      public?: true

    attribute :quantity_initial, :decimal,
      allow_nil?: false,
      constraints: [min: 0],
      public?: true

    attribute :quantity_at_hand, :decimal, constraints: [min: 0], public?: true
    attribute :cost, :decimal, constraints: [min: 0], public?: true
    attribute :msrp, :decimal, constraints: [min: 0], public?: true
    attribute :rrp, :decimal, constraints: [min: 0], public?: true
    attribute :list_price, :decimal, constraints: [min: 0], public?: true
    attribute :discounted_price, :decimal, constraints: [min: 0], public?: true
    attribute :weight, :decimal, constraints: [min: 0], public?: true
    attribute :length, :decimal, constraints: [min: 0], public?: true
    attribute :width, :decimal, constraints: [min: 0], public?: true
    attribute :height, :decimal, constraints: [min: 0], public?: true
    attribute :quantity_entries, :decimal, public?: true
    attribute :quantity_exits, :decimal, public?: true
    attribute :units_per_box, :integer, public?: true
    attribute :margin, :float, public?: true
    attribute :released_on, :date, public?: true
    attribute :opens_at, :time, public?: true
    attribute :audited_at, :naive_datetime, public?: true
    attribute :discontinued_at, :utc_datetime, public?: true
    attribute :image, :binary, public?: true
    attribute :thumbnail, :binary, public?: true
    attribute :deleted, :boolean, default: false, public?: true
    attribute :inactive, :boolean, default: false, public?: true
    attribute :packaging, Packaging, public?: true
    attribute :contacts, {:array, Contact}, public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :product_location, ProductLocation, public?: true
    has_many :product_transactions, ProductTransaction
    has_one :product_barcode, ProductBarcode

    many_to_many :suppliers, Supplier do
      through ProductSupplier
      source_attribute_on_join_resource :product_id
      destination_attribute_on_join_resource :supplier_id
    end
  end

  actions do
    default_accept [
      :reference,
      :name,
      :description,
      :status,
      :grade,
      :labels,
      :quantity_initial,
      :quantity_at_hand,
      :cost,
      :msrp,
      :rrp,
      :list_price,
      :discounted_price,
      :weight,
      :length,
      :width,
      :height,
      :quantity_entries,
      :quantity_exits,
      :units_per_box,
      :margin,
      :released_on,
      :opens_at,
      :audited_at,
      :discontinued_at,
      :image,
      :thumbnail,
      :deleted,
      :inactive,
      :packaging,
      :contacts,
      :product_location_id
    ]

    defaults [:destroy]

    create :create do
      primary? true
      argument :suppliers, {:array, :uuid}, allow_nil?: true, constraints: [nil_items?: true]
      argument :product_barcode, :map, allow_nil?: true
      change &__MODULE__.reject_blank_suppliers/2
      change &__MODULE__.reject_blank_labels/2
      change manage_relationship(:suppliers, :suppliers, type: :append_and_remove)
      change manage_relationship(:product_barcode, :product_barcode, type: :direct_control)
    end

    update :update do
      primary? true
      # manage_relationship cannot run on Ash's atomic update path.
      require_atomic? false
      argument :suppliers, {:array, :uuid}, allow_nil?: true, constraints: [nil_items?: true]
      argument :product_barcode, :map, allow_nil?: true
      change &__MODULE__.reject_blank_suppliers/2
      change &__MODULE__.reject_blank_labels/2
      change manage_relationship(:suppliers, :suppliers, type: :append_and_remove)
      change manage_relationship(:product_barcode, :product_barcode, type: :direct_control)
    end

    read :read do
      primary? true
      pagination required?: false, offset?: true
    end
  end

  calculations do
    calculate :summary, :string, expr(name <> " is " <> status)
  end

  @doc false
  @spec reject_blank_suppliers(Ash.Changeset.t(), term()) :: Ash.Changeset.t()
  def reject_blank_suppliers(changeset, _context) do
    case Ash.Changeset.fetch_argument(changeset, :suppliers) do
      {:ok, suppliers} when is_list(suppliers) ->
        Ash.Changeset.set_argument(
          changeset,
          :suppliers,
          Enum.reject(suppliers, &(is_nil(&1) or &1 == ""))
        )

      _other ->
        changeset
    end
  end

  @doc false
  @spec reject_blank_labels(Ash.Changeset.t(), term()) :: Ash.Changeset.t()
  def reject_blank_labels(changeset, _context) do
    case Ash.Changeset.fetch_change(changeset, :labels) do
      {:ok, labels} when is_list(labels) ->
        Ash.Changeset.force_change_attribute(
          changeset,
          :labels,
          Enum.reject(labels, &(is_nil(&1) or &1 == ""))
        )

      _other ->
        changeset
    end
  end
end
