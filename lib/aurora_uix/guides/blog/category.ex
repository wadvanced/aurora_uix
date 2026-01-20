defmodule Aurora.Uix.Guides.Blog.Category do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table("categories")
    repo(Aurora.Uix.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string)
    attribute(:description, :string)
    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    has_many(:posts, Aurora.Uix.Guides.Blog.Post)
  end
end
