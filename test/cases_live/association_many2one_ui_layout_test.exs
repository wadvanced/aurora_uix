defmodule Aurora.Uix.Test.Web.AssociationMany2OneUILayoutTest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product
    alias Aurora.Uix.Test.Inventory.ProductLocation
    alias Aurora.Uix.Test.Inventory.ProductTransaction

    auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation do
      field(:products, omitted: true)
    end

    auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(link_prefix: "association-many_to_one-layout-") do
      edit_layout :product do
        stacked([
          :reference,
          :name,
          :description,
          :quantity_initial,
          {:product_location, :name},
          product_location: :type
        ])
      end
    end
  end

  test "Test many-to-one relationship UI workflow", %{conn: conn} do
    {:ok, _view, _html} = live(conn, "/association-many_to_one-layout-products/new")
  end
end
