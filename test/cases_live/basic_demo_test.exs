defmodule Aurora.Uix.Test.Web.BasicDemoTest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product
    alias Aurora.Uix.Test.Inventory.ProductLocation
    alias Aurora.Uix.Test.Inventory.ProductTransaction

    auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

    auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

    auix_resource_metadata(:product, context: Inventory, schema: Product) do
      field(:product_location_id, option_label: :name)
    end

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(link_prefix: "basic-demo-") do
      index_columns(:product, [:reference, :name, :description, :quantity_at_hand])
      index_columns(:product_transaction, [:type, :quantity, :cost])

      edit_layout :product_location do
        inline([:reference, :name, :type])
      end

      show_layout :product do
        stacked do
          inline([:reference, :name, :description])
          inline([:description])
          inline([:product_location])
        end
      end

      edit_layout :product do
        stacked do
          inline([:reference])

          sections do
            section "Description" do
              stacked([:name, :description])
            end

            section "Quantities" do
              stacked([:quantity_initial, :quantity_entries, :quantities_exits])
            end
          end

          inline([:product_transactions])
        end
      end
    end
  end

  test "empty_test", %{conn: _conn} do
  end
end
