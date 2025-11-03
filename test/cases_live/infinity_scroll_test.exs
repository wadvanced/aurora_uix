defmodule Aurora.UixWeb.Test.InfinityScrollTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Layout.Options.Index
  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  auix_resource_metadata(:product,
    context: Inventory,
    schema: Product,
    order_by: :reference
  )

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "infinity-scroll-") do
    index_columns(:product, [:id, :reference, :name, :cost],
      order_by: :name,
      pagination_disabled?: true
    )
  end

  test "Test UI page bar needed", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(1000, :test)

    {:ok, view, html} = live(conn, "/infinity-scroll-products")
    assert html =~ "Listing Products"

    refute has_element?(view, "div[name='auix-pages_bar-products']")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-table-infinity-scroll-products-index tr")
           |> Enum.count() == Index.default_infinity_scroll_items_load()
  end
end
