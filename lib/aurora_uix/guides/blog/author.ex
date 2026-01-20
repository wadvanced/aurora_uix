defmodule Aurora.Uix.Guides.Blog.Author do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  # postgres do
  #   table "authors"
  #   repo(Aurora.Uix.Repo)
  # end

  attributes do
    uuid_primary_key :id
    attribute :name, :string
    attribute :email, :string
    attribute :bio, :string
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :posts, Aurora.Uix.Guides.Blog.Post
  end
end
