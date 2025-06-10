defmodule Aurora.Uix.Test.Repo.Migrations.CreateRelationships do
  use Ecto.Migration

  def change do
    flush()

    alter table "products" do
      add :product_location_id, references("product_locations", type: :uuid, on_delete: :nilify_all)
    end

    alter table "product_transactions" do
      add :product_id, references("products", type: :uuid, on_delete: :delete_all)
    end
  end
end
