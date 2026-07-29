defmodule Aurora.Uix.Repo.Migrations.AddLabelsToProducts do
  use Ecto.Migration

  def change do
    alter table("products") do
      add(:labels, {:array, :string})
    end
  end
end
