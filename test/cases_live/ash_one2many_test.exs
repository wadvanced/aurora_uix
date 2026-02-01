defmodule Aurora.UixWeb.Test.AshOne2ManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Post

  auix_resource_metadata(:author, schema: Author, order_by: [:bio])
  auix_resource_metadata(:post, schema: Post, order_by: [published_at: :desc])

  auix_create_ui do
    edit_layout :author do
      stacked([:name, :email, :posts])
    end
  end

  test "Test add posts", %{conn: conn} do
    delete_all_blog_data()

    {:ok, view, html} = live(conn, "/ash-one2many-posts/new")
  end
end
