defmodule Aurora.Uix.Repo.Migrations.CreateProductTable do
  use Ecto.Migration

  def change do
    execute "create extension if not exists \"uuid-ossp\""

    create table "products", primary_key: false, comment: "Represents an inventory item" do
      add :id, :uuid, default: fragment("uuid_generate_v4()"), primary_key: true
      add :reference, :string, size: 30
      add :name, :string
      add :description, :text
      add :status, :string, size: 20
      add :quantity_at_hand, :numeric, precision: 14, scale: 6
      add :quantity_initial, :numeric, precision: 14, scale: 6
      add :quantity_entries, :numeric, precision: 14, scale: 6
      add :quantity_exits, :numeric, precision: 14, scale: 6
      add :cost, :numeric, precision: 14, scale: 6
      add :msrp, :numeric, precision: 12, scale: 2
      add :rrp, :numeric, precision: 12, scale: 2
      add :list_price, :numeric, precision: 12, scale: 2
      add :discounted_price, :numeric, precision: 12, scale: 2
      add :weight, :numeric, precision: 14, scale: 6
      add :length, :numeric, precision: 14, scale: 6
      add :width, :numeric, precision: 14, scale: 6
      add :height, :numeric, precision: 14, scale: 6
      add :image, :bytea
      add :thumbnail, :bytea
      add :deleted, :boolean
      add :inactive, :boolean
      timestamps()
    end

    create index "products", [:reference], unique: true
  end
end
