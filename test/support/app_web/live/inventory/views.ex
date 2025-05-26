defmodule Aurora.Uix.Test.Web.Inventory.Views do
  @moduledoc """
  UI configuration for Inventory management.

  Defines:
  - Product metadata with field length constraints
  - ProductTransaction metadata linkage
  - Index column configurations for products
  - Edit form layout with sections for:
    - Basic information (stacked)
    - Quantities (default section)
    - Prices (inline fields)
    - Shipping details (mixed layout)
  """

  # Makes the modules attributes persistent.
  use Aurora.Uix.Test.Web, :aurora_uix_for_test

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductTransaction

  # Product metadata configuration with field constraints
  auix_resource_metadata(:product, context: Inventory, schema: Product) do
    field(:reference, length: 100)
    fields([:name, :description], length: 40)
  end

  # Product transaction metadata configuration
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

  # UI layout configuration for product management
  auix_create_ui do
    index_columns(:product, [:name, :description])
    index_columns(:product, [:list_price])

    edit_layout :product, a: "a-test" do
      stacked(name: [label: "P.Name"], reference: [], description: [])

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
