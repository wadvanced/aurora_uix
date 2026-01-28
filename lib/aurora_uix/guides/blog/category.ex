defmodule Aurora.Uix.Guides.Blog.Category do
  @moduledoc """
  Ash resource representing blog categories for guides and examples.

  ## Key Features
  - Has many posts relationship
  - Name and description fields

  ## Key Constraints
  - Only for guides and test scenarios
  """
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

  actions do
    defaults [:read, :destroy, update: :*]

    create :create do
      accept [:name, :description]
    end
  end

  relationships do
    has_many(:posts, Aurora.Uix.Guides.Blog.Post)
  end
end
