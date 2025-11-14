defmodule Aurora.Uix.Repo.Migrations.AddEmailsToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add(:emails, :map)
    end
  end
end
