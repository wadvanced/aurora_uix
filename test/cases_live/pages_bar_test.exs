defmodule Aurora.UixWeb.PagesBarTest do
  use Aurora.UixWeb, :aurora_uix_for_test
  use Aurora.UixWeb.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  auix_resource_metadata(:product,
    context: Inventory,
    schema: Product,
    order_by: :reference
  )

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "pages-bar-") do
    index_columns(:product, [:id, :reference, :name, :cost], order_by: :name)
  end

  test "Test UI page bar not needed", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(30, :test)

    {:ok, view, html} = live(conn, "/pages-bar-products")
    assert html =~ "Listing Products"

    refute has_element?(view, "div[name='auix-pages_bar-products']")
  end

  test "Test UI page bar needed", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(1000, :test)

    {:ok, view, html} = live(conn, "/pages-bar-products")
    assert html =~ "Listing Products"

    assert has_element?(view, "div[name='auix-pages_bar-products']")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-pages-bar-products-index tr")
           |> Enum.count() == 40

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-products-md'] [name^='auix-pages_bar_page-']"
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
    {:ok, view_direct, html_direct} = live(conn, "/pages-bar-products?page=12")

    assert html_direct
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-products-md'] [name^='auix-pages_bar_page-']"
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
           |> LazyHTML.query("#auix-table-pages-bar-products-index tr")
           |> Enum.count() == 40

    # Navigate to a page by click
    view_direct
    |> element("div[name='auix-pages_bar-products-md'] a[name='auix-pages_bar_page-10']")
    |> render_click()

    assert view_direct
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-pages_bar-products-md'] [name^='auix-pages_bar_page-']"
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
           |> LazyHTML.query("#auix-table-pages-bar-products-index tr")
           |> Enum.count() == 40
  end
end
