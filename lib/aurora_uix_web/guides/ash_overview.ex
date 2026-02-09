defmodule Aurora.UixWeb.Guides.AshOverview do
  use Aurora.Uix

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Category
  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.Tag

  auix_resource_metadata(:author, ash_resource: Author)
  auix_resource_metadata(:post, ash_resource: Post)
  auix_resource_metadata(:category, ash_resource: Category)
  auix_resource_metadata(:tag, ash_resource: Tag)

  auix_create_ui do
    index_columns(:post, [:title, :author, :status])

    show_layout :post do
      stacked do
        inline([:status])
        inline([:title, :author])
        inline([:comment])
      end
    end

    edit_layout :post do
      stacked do
        inline([:title])
        inline([:author])
        inline([:comment])

        group "details" do
          inline([:status, :published_at])
        end

        inline([:tags])
      end
    end
  end
end
