defmodule Aurora.Uix.Test.Web.AssociationMany2oneUILayoutTest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product
    alias Aurora.Uix.Test.Inventory.ProductLocation
    alias Aurora.Uix.Test.Inventory.ProductTransaction

    auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
    auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(link_prefix: "association-many-layout-") do
      edit_layout :product do
        stacked([:reference, :name, :description, :product_transactions])
      end
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    create_sample_products_with_transactions(3, 3, :test)

    {:ok, view, _html} = live(conn, "/association-many-layout-products")

    view
    |> tap(&assert has_element?(&1, "tr[id^='products']:nth-of-type(1)  a[name='show-product']"))
    |> element("tr[id^='products']:nth-of-type(1)  a[name='show-product']")
    |> render_click()
  end
end
