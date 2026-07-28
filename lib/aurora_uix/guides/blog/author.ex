defmodule Aurora.Uix.Guides.Blog.Author do
  @moduledoc """
  Ash resource representing blog authors for guides and examples.

  ## Key Features

  - Has many posts relationship
  - Has one author profile, managed inline through the create and update actions
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
    has_one :author_profile, Aurora.Uix.Guides.Blog.AuthorProfile
  end

  actions do
    default_accept [:name, :email, :bio]

    defaults [:read, :destroy]

    create :create do
      accept [:name, :email, :bio]
      argument :author_profile, :map, allow_nil?: true
      change manage_relationship(:author_profile, :author_profile, type: :direct_control)
    end

    update :update do
      accept [:name, :email, :bio]
      # manage_relationship cannot run on Ash's atomic update path.
      require_atomic? false
      argument :author_profile, :map, allow_nil?: true
      change manage_relationship(:author_profile, :author_profile, type: :direct_control)
    end

    read :read_all
  end

  aggregates do
    count :posts_count, :posts
  end
end
