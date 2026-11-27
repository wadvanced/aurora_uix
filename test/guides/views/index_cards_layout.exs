defmodule Aurora.UixWeb.Test.GuidesCapture.IndexCardsLayout do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    index_columns :product, [:reference, :name, :list_price, :status, :quantity_at_hand],
      order_by: :reference,
      pagination_items_per_page: 6 do
      card title: :name, subtitle: :reference, show_on: :all do
        inline([:list_price, :status])
        group("Stock", [:quantity_at_hand])
      end
    end
  end
end
