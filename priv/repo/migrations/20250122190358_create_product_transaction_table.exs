defmodule Aurora.Uix.Repo.Migrations.CreateProductInputTable do
  use Ecto.Migration

  def change do
    execute "create extension if not exists \"uuid-ossp\""

    create table "product_transactions", primary_key: false do
      add :id, :uuid, default: fragment("uuid_generate_v4()"), primary_key: true
      add :type, :string, size: 20
      add :quantity, :numeric, precision: 14, scale: 6
      add :cost, :numeric, precision: 14, scale: 6
      timestamps()
    end
  end
end
