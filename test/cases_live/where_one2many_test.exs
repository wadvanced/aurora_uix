defmodule Aurora.UixWeb.Test.WhereOne2ManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    edit_layout :product do
      stacked([
        :reference,
        :name,
        :description,
        :quantity_initial,
        product_transactions: [order_by: [desc: :quantity], where: {:quantity, :between, 8, 16}]
      ])
    end
  end

  test "Test where", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products_with_transactions(10, :one2)
      |> List.first()
      |> elem(1)
      |> Map.get(:id)

    expected_result =
      [
        order_by: [desc: :quantity],
        where: [[product_id: product_id], {:quantity, :between, 8, 16}]
      ]
      |> Inventory.list_product_transactions()
      |> Enum.map(&(&1 |> Map.get(:quantity) |> to_string()))

    {:ok, _view, html} = live(conn, "/where-one_to_many-products/#{product_id}")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("tbody#product__product_transactions-show tr td:nth-of-type(3)")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == expected_result
  end
end
