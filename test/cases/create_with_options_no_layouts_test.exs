defmodule AuroraUixTest.CreateWithOptionsNoLayoutsTest do
  use AuroraUixTest.UICase

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product
    alias AuroraUixTest.Inventory.ProductTransaction

    auix_schema_configs(:product, context: Inventory, schema: Product)
    auix_schema_configs(:product_transaction, context: Inventory, schema: ProductTransaction)

    auix_create_ui()
  end

  test "Test UI default with schema, context, NO layouts details" do
    layouts = layouts(TestModule)

    assert !is_nil(layouts.product.index.view)
    assert !is_nil(layouts.product.form)
    assert !is_nil(layouts.product_transaction.index.view)
    assert !is_nil(layouts.product_transaction.form)

    assert String.contains?(layouts.product.index.view, "Listing Products")

    assert String.contains?(
             layouts.product_transaction.index.view,
             "Listing Product Transactions"
           )
  end
end
