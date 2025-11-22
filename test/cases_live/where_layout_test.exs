defmodule Aurora.UixWeb.Test.WhereLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Inventory
  alias Aurora.Uix.Inventory.Product

  @test_references [
    "Item test_order-05",
    "Item test_order-06",
    "Item test_order-07",
    "Item test_order-08",
    "Item test_order-09",
    "Item test_order-10",
    "Item test_order-11",
    "Item test_order-12",
    "Item test_order-13"
  ]

  auix_resource_metadata(:product,
    context: Inventory,
    schema: Product,
    order_by: :reference
  )

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "where-layout-") do
    index_columns(:product, [:id, :reference, :name, :cost],
      order_by: :name,
      where: [{:reference, :between, "item_test_order-05", "item_test_order-13"}]
    )
  end

  test "Test UI default order", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(20, :test_order)

    {:ok, _view, html} = live(conn, "/where-layout-products")
    assert html =~ "Listing Products"

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("table tbody tr td:nth-of-type(4)")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == @test_references
  end
end
