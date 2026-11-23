defmodule Aurora.UixWeb.Test.GuidesCapture.GroupLayout do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product, [] do
      inline([:reference, :name, :description])

      group "Quantities" do
        inline([:quantity_at_hand, :quantity_initial])
      end

      group "Sale Prices" do
        stacked([:list_price, :rrp])
      end
    end
  end
end
