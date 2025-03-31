defmodule AuroraUixTestWeb.AssociationMany2oneUILayoutTest do
  use AuroraUixTest.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product
    alias AuroraUixTest.Inventory.ProductTransaction

    auix_resource_config(:product_transaction, context: Inventory, schema: ProductTransaction)
    auix_resource_config(:product, context: Inventory, schema: Product)

    # When you define a link in a test, you must add a line to router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(link_prefix: "association-many-layout-") do
      edit_layout :product do
        stacked([:reference, :name, :description])
        stacked([:product_transactions])
      end
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: _conn} do
  end
end
