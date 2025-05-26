defmodule Aurora.Uix.Web.Test.SeparatedMultipleResourcesUITest do
  use Aurora.Uix.Test.UICase, :phoenix_case
  alias Aurora.Uix.Test.Inventory

  defmodule TestResources do
    use Aurora.Uix.Web.Test, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product
    alias Aurora.Uix.Test.Inventory.ProductTransaction
    auix_resource_metadata(:product, context: Inventory, schema: Product)
    auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
  end

  defmodule TestModule do
    use Aurora.Uix.Web.Test, :aurora_uix_for_test

    @auix_resource_metadata TestResources.auix_resource(:product)
    @auix_resource_metadata TestResources.auix_resource(:product_transaction)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link_prefix: "separated-multiple-resources-" do
      edit_layout :product, [] do
        inline([:reference, :name, :description])
        inline([:quantity_at_hand, :quantity_initial])
        inline([:list_price, :rrp])
      end
    end
  end

  test "Test UI default with schema, context, basic layout for products", %{conn: conn} do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, html} = live(conn, "/separated-multiple-resources-products")
    assert html =~ "Listing Products"
    assert html =~ "New Product"

    assert view
           |> element("#auix-new-product")
           |> render_click() =~ "New Product"
  end

  test "Test CREATE new, context, basic layout for products", %{conn: conn} do
    {:ok, view, html} = live(conn, "/separated-multiple-resources-products/new")

    assert html =~ "New Product"

    assert view
           |> form("#auix-product-form",
             product: %{reference: "test-first", name: "This is the first test"}
           )
           |> render_change() =~ "can&#39;t be blank"

    view
    |> form("#auix-product-form",
      product: %{quantity_initial: 11}
    )
    |> render_submit()

    {:ok, _view, new_html} = live(conn, "/separated-multiple-resources-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end

  test "Test UI default with schema, context, basic layout for product_transactions", %{
    conn: conn
  } do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, html} = live(conn, "/separated-multiple-resources-product_transactions")
    assert html =~ "Listing Product Transactions"
    assert html =~ "New Product Transaction"

    assert view
           |> element("#auix-new-product_transaction")
           |> render_click() =~ "New Product Transaction"
  end

  test "Test CREATE new, context, basic layout for product_transactions", %{conn: conn} do
    {:ok, product} =
      Inventory.create_product(%{
        reference: "test-product-001",
        name: "For testing product_transactions",
        quantity_initial: 99
      })

    {:ok, product_location} =
      Inventory.create_product_location(%{
        reference: "location-001",
        name: "For testing product_transactions",
        type: "dry"
      })

    {:ok, view, html} = live(conn, "/separated-multiple-resources-product_transactions/new")

    assert html =~ "New Product Transaction"

    assert view
           |> form("#auix-product_transaction-form",
             product_transaction: %{type: "test-transaction", quantity: 100}
           )
           |> render_change() =~ "can&#39;t be blank"

    view
    |> form("#auix-product_transaction-form",
      product_transaction: %{
        cost: 50,
        product_id: product.id,
        product_location_id: product_location.id
      }
    )
    |> render_submit()

    {:ok, _view, new_html} = live(conn, "/separated-multiple-resources-product_transactions")

    assert new_html =~ "Listing Product Transactions"
    assert new_html =~ "test-transaction"
  end
end
