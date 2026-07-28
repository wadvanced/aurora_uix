defmodule Aurora.Uix.Repo.Migrations.CreateSupplierTables do
  use Ecto.Migration

  def change do
    create table("suppliers", primary_key: false, comment: "Companies that supply products") do
      add(:id, :uuid, default: fragment("uuid_generate_v4()"), primary_key: true)
      add(:name, :string, size: 60)
      add(:country, :string, size: 40)

      timestamps()
    end

    create table("product_suppliers",
             primary_key: false,
             comment: "Join table linking products and their suppliers"
           ) do
      add(:product_id, references("products", type: :uuid, on_delete: :delete_all), null: false)
      add(:supplier_id, references("suppliers", type: :uuid, on_delete: :delete_all), null: false)
    end

    create(index("product_suppliers", [:product_id, :supplier_id], unique: true))
    create(index("product_suppliers", [:supplier_id]))
  end
end
