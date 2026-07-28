defmodule Aurora.Uix.Guides.Blog.AuthorProfile do
  @moduledoc """
  Ash resource representing an author's profile for guides and examples.

  One author has exactly one profile, and a profile belongs to exactly one author.

  ## Key Features

  - Belongs to an author, with the foreign key held on this side
  - Website, social handle, and years-active fields
  - Standard CRUD actions

  ## Key Constraints

  - Only for guides and test scenarios
  - One profile per author, enforced by the `:unique_author` identity
  - Stored in PostgreSQL author_profiles table
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table("author_profiles")
    repo(Aurora.Uix.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:website, :string)
    attribute(:twitter_handle, :string)
    attribute(:years_active, :integer)
    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:author, Aurora.Uix.Guides.Blog.Author)
  end

  identities do
    identity(:unique_author, [:author_id])
  end

  actions do
    default_accept [:website, :twitter_handle, :years_active, :author_id]

    defaults [:read, :destroy, :create, :update]
  end
end
