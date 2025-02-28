Code.require_file("test/support/aurora_uix_test_web.exs")
Code.require_file("test/support/app_web/router.exs")

defmodule AuroraUixTestWeb.Inventory.Views do
  # Makes the modules attributes persistent.
  use AuroraUixTestWeb, :aurora_uix_for_test

  alias AuroraUixTest.Inventory
  alias AuroraUixTest.Inventory.Product
  # alias AuroraUixTest.Inventory.ProductTransaction

  auix_resource_config(:product, context: Inventory, schema: Product)
  # auix_resource_config(:product_transaction, context: Inventory, schema: ProductTransaction)

  auix_create_ui do
    layout :product, a: "a-test" do
      inline([:name, :description])
      inline([:list_price, :rrp])
    end

    #
    #    layout :product_transaction, b: "b-test" do
    #      inline([:product_id, :inserted_at])
    #      inline([:type, :quantity])
    #    end
  end
end
