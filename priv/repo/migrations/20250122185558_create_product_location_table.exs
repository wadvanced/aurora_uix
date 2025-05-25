defmodule Aurora.Uix.Test.Repo.Migrations.CreateProductLocationTable do
  use Ecto.Migration

  def change do
    execute "create extension if not exists \"uuid-ossp\""

    create table "product_locations", primary_key: false do
      add :id, :uuid, default: fragment("uuid_generate_v4()"), primary_key: true
      add :reference, :string, size: 30
      add :name, :string
      add :type, :string, size: 20
      add :quantity_at_hand, :numeric, precision: 14, scale: 6
      add :quantity_initial, :numeric, precision: 14, scale: 6
      add :quantity_entries, :numeric, precision: 14, scale: 6
      add :quantity_exits, :numeric, precision: 14, scale: 6
      add :product_id, references("products", type: :uuid)
      timestamps()
    end


  end
end
