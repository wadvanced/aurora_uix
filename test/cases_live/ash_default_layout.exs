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
    create_sample_authors(20)

    {:ok, view, html} = live(conn, "/ash-default-layout-authors")
    assert html =~ "Listing Authors"
    assert html =~ "New Author"

    refute has_element?(view, "div[name='auix-pages_bar-authors']")
  end

  test "Pagination navigation test", %{conn: conn} do
    delete_all_blog_data()
    create_sample_authors(1000)
    {:ok, view, html} = live(conn, "/ash-default-layout-authors")
    assert html =~ "Listing Authors"

    assert has_element?(view, "div[name='auix-pages_bar-authors']")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-ash-default-layout-authors-index tr")
           |> Enum.count() == 40

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-authors-md'] [name^='auix-pages_bar_page-']"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "1",
             "2",
             "3",
             "4",
             "5",
             "6",
             "7",
             "8",
             "9",
             "...",
             "25",
             ""
           ]

    # Direct navigation
    {:ok, view_direct, html_direct} = live(conn, "/ash-default-layout-authors?page=12")

    assert html_direct
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-authors-md'] [name^='auix-pages_bar_page-']"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "",
             "1",
             "...",
             "8",
             "9",
             "10",
             "11",
             "12",
             "13",
             "14",
             "15",
             "16",
             "...",
             "25",
             ""
           ]

    assert html_direct
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-ash-default-layout-authors-index tr")
           |> Enum.count() == 40

    # Navigate to a page by click
    view_direct
    |> element("div[name='auix-pages_bar-authors-md'] a[name='auix-pages_bar_page-10']")
    |> render_click()

    assert view_direct
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-authors-md'] [name^='auix-pages_bar_page-']"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "",
             "1",
             "...",
             "6",
             "7",
             "8",
             "9",
             "10",
             "11",
             "12",
             "13",
             "14",
             "...",
             "25",
             ""
           ]

    assert view_direct
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-ash-default-layout-authors-index tr")
           |> Enum.count() == 40
  end
end
