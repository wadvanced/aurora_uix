defmodule Aurora.Uix.Guides.Blog.Post do
  @moduledoc """
  Ash resource representing blog posts for guides and examples.

  ## Key Features

  - Belongs to author and category
  - Status tracking (draft, published, archived)
  - Publication timestamp support
  - Embedded tags array for categorization

  ## Key Constraints

  - Only for guides and test scenarios
  - Status must be one of: `:draft`, `:published`, `:archived`
  - Default status is `:draft`
  - Stored in PostgreSQL posts table
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Aurora.Uix.Guides.Blog

  postgres do
    table("posts")
    repo(Aurora.Uix.Repo)
  end

  alias Aurora.Uix.Guides.Blog.Comment
  alias Aurora.Uix.Guides.Blog.Tag

  attributes do
    uuid_primary_key(:id)

    attribute(:title, :string)
    attribute(:content, :string)
    attribute(:published_at, :utc_datetime)

    attribute :status, :atom do
      constraints one_of: [:draft, :published, :archived]
      default :draft
    end

    attribute :tags, {:array, Tag} do
      public? true
      default [%Tag{}]
    end

    attribute :comment, Comment do
      public? true
      default %Comment{}
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:author, Aurora.Uix.Guides.Blog.Author)
    belongs_to(:category, Aurora.Uix.Guides.Blog.Category)
  end

  actions do
    default_accept [
      :title,
      :content,
      :status,
      :tags,
      :comment,
      :author_id
    ]

    defaults [:create, :read, :destroy, :update]
  end
end
