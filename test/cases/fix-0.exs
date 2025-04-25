defmodule AuroraUixTest.FixZero do
  use AuroraUixTest.UICase

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product
    alias AuroraUixTest.Inventory.ProductTransaction

    auix_resource_config(:product, context: Inventory, schema: Product) do
      field(:inactive, length: 10)
      field(:inserted_at, hidden: true)
      fields([:weight, :length, :width, :height], precision: 16, scale: 3)
      # :height field properties are changed again, the last one should be the one prevailing
      field(:height, scale: 1)
      field(:data_virtual, field_html_type: :checkbox)
      field(:status, data: [:in_stock, :discontinued, :online_only, :in_store_only])
    end

    auix_resource_config(:product_transaction, context: Inventory, schema: ProductTransaction)

    auix_create_ui do
      index_columns(:product, [:name, :description]) do
        # field_spec :title, title: "The title"
      end
      index_columns(:product, [:list_price])

      edit_layout :product, a: "a-test" do
        stacked(name: [], reference: [], description: [])

        sections do
          section "Quantities", default: true do
            stacked([:quantity_initial, :quantity_at_hand])
          end

          section "Prices" do
            inline([:list_price, :rrp])
            inline([:msrp])
          end

          section "Shipping Details" do
            stacked do
              inline([:length, :width, :height])
              inline([:weight])
            end
          end
        end
      end
    end
  end

  test "Test UI default without options - no schema, no context" do
    index_module = Module.concat(TestModule, Index)
    assert false == Code.ensure_loaded?(index_module)
  end
end
