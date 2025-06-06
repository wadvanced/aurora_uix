defmodule Aurora.Uix.Test.Repo.Migrations.CreateProductInputTable do
  use Ecto.Migration

  def change do
    execute "create extension if not exists \"uuid-ossp\""

    create table "product_transactions", primary_key: false do
      add :id, :uuid, default: fragment("uuid_generate_v4()"), primary_key: true
      add :type, :string, size: 20
      add :quantity, :numeric, precision: 14, scale: 6
      add :cost, :numeric, precision: 14, scale: 6
      add :product_id, references("products", type: :uuid, on_delete: :delete_all)
      add :product_location_id, references("product_locations", type: :uuid, on_delete: :nilify_all)
      timestamps()
    end
  end
end
