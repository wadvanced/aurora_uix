defmodule Aurora.Uix.Repo.Migrations.CreateProductLocationTable do
  use Ecto.Migration

  def change do
    execute("create extension if not exists \"uuid-ossp\"")

    create table("product_locations", primary_key: false) do
      add(:id, :uuid, default: fragment("uuid_generate_v4()"), primary_key: true)
      add(:reference, :string, size: 30)
      add(:name, :string)
      add(:type, :string, size: 20)
      timestamps()
    end
  end
end
