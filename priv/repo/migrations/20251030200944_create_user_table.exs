defmodule Aurora.Uix.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  def change do

    create table "users" do
      add :full_name, :string
      add :email, :string
      add :avatar_url, :string
      add :confirmed_at, :naive_datetime
      add :profile, :map
      timestamps()
    end
  end
end

