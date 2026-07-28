defmodule Aurora.Uix.Guides.Blog.Topic do
  @moduledoc """
  Ash resource representing blog topics for guides and examples.

  A post covers several topics and a topic covers many posts, so the relationship is many-to-many in
  both directions; the linkage lives in the `post_topics` join resource.

  ## Key Features

  - Many to many posts relationship through a join resource
  - Name and slug fields
  - Standard CRUD actions

  ## Key Constraints

  - Only for guides and test scenarios
  - Slug is unique
  - Stored in PostgreSQL topics table
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table("topics")
    repo(Aurora.Uix.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string)
    attribute(:slug, :string)
    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  identities do
    identity(:unique_slug, [:slug])
  end

  actions do
    default_accept [:name, :slug]

    defaults [:read, :destroy, :create, :update]
  end
end
