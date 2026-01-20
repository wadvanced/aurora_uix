defmodule Aurora.Uix.Guides.Blog.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table("posts")
    repo(Aurora.Uix.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:title, :string)
    attribute(:content, :string)
    attribute(:published_at, :utc_datetime)

    attribute :status, :atom do
      constraints one_of: [:draft, :published, :archived]
      default :draft
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:author, Aurora.Uix.Guides.Blog.Author)
    belongs_to(:category, Aurora.Uix.Guides.Blog.Category)
  end
end
