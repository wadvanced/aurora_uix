defmodule Aurora.UixWeb.Test.GuidesCapture.RenderersLayout do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product do
    context Inventory
    schema(Product)

    field(:deleted, label: "Toggle switch", renderer: :toggle_switch)
    field(:description, label: "Color", renderer: :color)
    field(:status, label: "Badge", renderer: :badge)
    field(:quantity_at_hand, label: "Progress bar", renderer: :progress_bar)
    field(:reference, label: "URL", renderer: :url)
    field(:quantity_entries, label: "Rating", renderer: :rating)
  end

  auix_create_ui do
    index_columns(:product, [:reference, :name], order_by: :reference)

    show_layout :product do
      stacked([
        :deleted,
        :description,
        :status,
        :quantity_at_hand,
        :reference,
        :quantity_entries
      ])
    end
  end
end
