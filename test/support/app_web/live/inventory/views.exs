Code.require_file("test/support/aurora_uix_test_web.exs")
Code.require_file("test/support/app_web/router.exs")

defmodule AuroraUixTestWeb.Inventory.Views do
  # Makes the modules attributes persistent.
  use AuroraUixTestWeb, :aurora_uix_for_test

  alias AuroraUixTest.Inventory
  alias AuroraUixTest.Inventory.Product
  alias AuroraUixTest.Inventory.ProductTransaction

  auix_resource_config(:product, context: Inventory, schema: Product) do
    field(:reference, length: 100)
    fields([:name, :description], length: 40)
  end

  auix_resource_config(:product_transaction, context: Inventory, schema: ProductTransaction)

  auix_create_ui do
    index_columns(:product, [:name, :description])
    index_columns(:product, [:list_price])

    edit_layout :product, a: "a-test" do
      inline(name: [], reference: [readonly: true], description: [])

      inline do
        group "Prices" do
          inline([:list_price, :rrp])
          inline([:msrp])
        end

        group "Shipping Details" do
          stacked do
            inline([:length, :width, :height])
            inline([:weight])
          end
        end
      end
    end
  end
end
