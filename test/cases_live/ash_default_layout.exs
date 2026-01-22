defmodule Aurora.UixWeb.Test.AshDefaultLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  # alias Aurora.Uix.Guides.Blog
  alias Aurora.Uix.Guides.Blog.Author
  # alias Aurora.Uix.Guides.Blog.Category
  # alias Aurora.Uix.Guides.Blog.Post

  auix_resource_metadata(:author, schema: Author, order_by: [:bio])

  auix_create_ui()

  test "Default layout index", %{conn: conn} do
    delete_all_blog_data()
    create_sample_authors(5)

    {:ok, _view, html} = live(conn, "/ash-default-layout-authors")
    assert html =~ "Listing Authors"
    assert html =~ "New Author"
  end
end
