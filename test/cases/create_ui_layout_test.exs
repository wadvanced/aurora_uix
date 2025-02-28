defmodule AuroraUixTestWeb.CreateUILayoutTest do
  use AuroraUixTest.UICase

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product
    # alias AuroraUixTest.Inventory.ProductTransaction

    auix_resource_config(:product, context: Inventory, schema: Product)

    #    auix_resource_config(:product_transaction, context: Inventory, schema: ProductTransaction)

    auix_create_ui link: "ui-layout-products" do
      layout :product, [] do
        inline([:name, :description])
        inline([:list_price, :rrp])
      end
    end
  end

  test "Test UI default with schema, context, basic layout" do
    test_module = AuroraUixTestWeb.CreateUILayoutTest.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)
  end
end
