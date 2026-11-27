defmodule Aurora.UixWeb.Test.GuidesCapture.EmbedsLayout do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Comment
  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.Tag

  auix_resource_metadata(:post__comment, ash_resource: Comment)
  auix_resource_metadata(:tag, ash_resource: Tag)

  auix_resource_metadata :post do
    ash_resource(Post)
    field(:tags, resource: :tag, expanded: true)
  end

  auix_create_ui do
    index_columns(:post, [:title], order_by: :title)

    edit_layout :post do
      stacked([:title, :comment, :tags])
    end
  end
end
