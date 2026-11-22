defmodule Aurora.Uix.Repo.Migrations.CreateMirrorFixture do
  use Ecto.Migration

  def up do
    execute("CREATE SCHEMA IF NOT EXISTS mirror")

    create table(:product_locations, prefix: "mirror", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:reference, :string, size: 30)
      add(:name, :string)
      add(:type, :string, size: 20)

      timestamps(type: :utc_datetime_usec)
    end

    create table(:products, prefix: "mirror", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:reference, :string, size: 30)
      add(:name, :string)
      add(:description, :text)
      add(:status, :string, size: 20, default: "in_stock")
      add(:grade, :string)
      add(:labels, {:array, :string})
      add(:quantity_at_hand, :numeric, precision: 14, scale: 6)
      add(:quantity_initial, :numeric, precision: 14, scale: 6)
      add(:quantity_entries, :numeric, precision: 14, scale: 6)
      add(:quantity_exits, :numeric, precision: 14, scale: 6)
      add(:cost, :numeric, precision: 14, scale: 6)
      add(:weight, :numeric, precision: 14, scale: 6)
      add(:length, :numeric, precision: 14, scale: 6)
      add(:width, :numeric, precision: 14, scale: 6)
      add(:height, :numeric, precision: 14, scale: 6)
      add(:msrp, :numeric, precision: 12, scale: 2)
      add(:rrp, :numeric, precision: 12, scale: 2)
      add(:list_price, :numeric, precision: 12, scale: 2)
      add(:discounted_price, :numeric, precision: 12, scale: 2)
      add(:units_per_box, :integer)
      add(:margin, :float)
      add(:released_on, :date)
      add(:opens_at, :time)
      add(:audited_at, :naive_datetime)
      add(:discontinued_at, :utc_datetime)
      add(:image, :binary)
      add(:thumbnail, :binary)
      add(:deleted, :boolean, default: false)
      add(:inactive, :boolean, default: false)
      add(:packaging, :map)
      add(:contacts, {:array, :map})

      add(
        :product_location_id,
        references("product_locations", type: :uuid, prefix: "mirror", on_delete: :nilify_all)
      )

      timestamps(type: :utc_datetime_usec)
    end

    create table(:product_transactions, prefix: "mirror", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:type, :string, size: 20)
      add(:quantity, :numeric, precision: 14, scale: 6)
      add(:cost, :numeric, precision: 14, scale: 6)

      add(
        :product_id,
        references("products", type: :uuid, prefix: "mirror", on_delete: :delete_all)
      )

      timestamps(type: :utc_datetime_usec)
    end

    create table(:product_barcodes, prefix: "mirror", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:code, :string, size: 20)
      add(:symbology, :string, size: 20, default: "EAN-13")
      add(:registered_at, :date)

      add(
        :product_id,
        references("products", type: :uuid, prefix: "mirror", on_delete: :delete_all)
      )

      timestamps(type: :utc_datetime_usec)
    end

    create table(:suppliers, prefix: "mirror", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, size: 60)
      add(:country, :string, size: 40)

      timestamps(type: :utc_datetime_usec)
    end

    create table(:product_suppliers, prefix: "mirror", primary_key: false) do
      add(
        :product_id,
        references("products", type: :uuid, prefix: "mirror", on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(
        :supplier_id,
        references("suppliers", type: :uuid, prefix: "mirror", on_delete: :delete_all),
        null: false,
        primary_key: true
      )
    end

    create(unique_index(:products, [:reference], prefix: "mirror"))
    create(index(:products, [:product_location_id], prefix: "mirror"))
    create(index(:product_transactions, [:product_id], prefix: "mirror"))
    create(unique_index(:product_barcodes, [:code], prefix: "mirror"))
    create(unique_index(:product_barcodes, [:product_id], prefix: "mirror"))
    create(index(:product_suppliers, [:supplier_id], prefix: "mirror"))
  end

  def down do
    execute("DROP SCHEMA mirror CASCADE")
  end
end
