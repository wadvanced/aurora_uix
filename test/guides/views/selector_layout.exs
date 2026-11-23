defmodule Aurora.UixWeb.Test.GuidesCapture.SelectorLayout do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  auix_resource_metadata :product_location do
    context Inventory
    schema(ProductLocation)
    field(:products, omitted: true)
  end

  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

  auix_resource_metadata :product do
    context Inventory
    schema(Product)
  end

  auix_create_ui do
    edit_layout :product_location do
      inline([:reference, :name, :type])
    end

    edit_layout :product do
      stacked([
        :reference,
        :name,
        :description,
        :quantity_initial,
        :product_location_id,
        :product_location
      ])
    end
  end
end
