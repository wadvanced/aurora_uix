defmodule Aurora.Uix.Test.Web.PagesBarTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

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
           |> Floki.find("#auix-table-pages-bar-products-index tr")
           |> Enum.count() == 40

    assert html
           |> Floki.find("div[name='auix-pages_bar-products-sm'] [name^='auix-pages_bar_page-']")
           |> Enum.map(&(&1 |> Floki.text() |> String.trim())) == [
             "1",
             "2",
             "3",
             "4",
             "5",
             "25",
             ""
           ]

    # Direct navigation
    {:ok, view_direct, html_direct} = live(conn, "/pages-bar-products?page=12")

    assert html_direct
           |> Floki.find("div[name='auix-pages_bar-products-sm'] [name^='auix-pages_bar_page-']")
           |> Enum.map(&(&1 |> Floki.text() |> String.trim())) == [
             "",
             "1",
             "10",
             "11",
             "12",
             "13",
             "14",
             "25",
             ""
           ]

    assert html_direct
           |> Floki.find("#auix-table-pages-bar-products-index tr")
           |> Enum.count() == 40

    # Navigate to a page by click
    view_direct
    |> element("div[name='auix-pages_bar-products-sm'] a[name='auix-pages_bar_page-10]")
    |> render_click()

    assert view_direct
           |> render()
           |> Floki.find("div[name='auix-pages_bar-products-sm'] [name^='auix-pages_bar_page-']")
           |> Enum.map(&(&1 |> Floki.text() |> String.trim())) == [
             "",
             "1",
             "8",
             "9",
             "10",
             "11",
             "12",
             "25",
             ""
           ]

    assert view_direct
           |> render()
           |> Floki.find("#auix-table-pages-bar-products-index tr")
           |> Enum.count() == 40
  end
end
