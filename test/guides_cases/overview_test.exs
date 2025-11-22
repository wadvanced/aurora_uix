defmodule Aurora.UixWeb.Guides.Overview do
  use Aurora.Uix

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

  auix_resource_metadata(:product, context: Inventory, schema: Product) do
    field(:product_location_id, option_label: :name)
  end

  auix_create_ui(link_prefix: "guide-overview-") do
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
