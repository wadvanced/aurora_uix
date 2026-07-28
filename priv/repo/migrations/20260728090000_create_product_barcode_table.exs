defmodule Aurora.Uix.Repo.Migrations.CreateProductBarcodeTable do
  use Ecto.Migration

  def change do
    create table("product_barcodes",
             primary_key: false,
             comment: "Single barcode identifying a product"
           ) do
      add(:id, :uuid, default: fragment("uuid_generate_v4()"), primary_key: true)
      add(:code, :string, size: 20)
      add(:symbology, :string, size: 20, default: "EAN-13")
      add(:registered_at, :date)
      add(:product_id, references("products", type: :uuid, on_delete: :delete_all))

      timestamps()
    end

    create(index("product_barcodes", [:code], unique: true))
    create(index("product_barcodes", [:product_id], unique: true))
  end
end
