defmodule Aurora.Uix.Guides.Blog.Author do
  @moduledoc """
  Ash resource representing blog authors for guides and examples.

  ## Key Features

  - Has many posts relationship
  - Email and bio fields
  - Standard CRUD actions
  - Custom non-paginated read action

  ## Key Constraints

  - Only for guides and test scenarios
  - Create action requires name, email, and bio
  - Stored in PostgreSQL authors table
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table "authors"
    repo(Aurora.Uix.Repo)
  end

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

  actions do
    default_accept [:name, :email, :bio]

    defaults [:read, :destroy, :update]

    create :create do
      accept [:name, :email, :bio]
    end

    read :read_all
  end
end
