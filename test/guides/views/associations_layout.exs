defmodule Aurora.UixWeb.Test.GuidesCapture.AssociationsLayout do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductBarcode
  alias Aurora.Uix.Guides.Inventory.Supplier

  auix_resource_metadata(:supplier, context: Inventory, schema: Supplier)
  auix_resource_metadata(:product__product_barcode, context: Inventory, schema: ProductBarcode)

  auix_resource_metadata :product do
    context Inventory
    schema(Product)
    field(:suppliers, option_label: :name)
  end

  auix_create_ui do
    index_columns(:product, [:reference, :name], order_by: :reference)

    edit_layout :product do
      stacked([:name, :product_barcode, :suppliers])
    end

    edit_layout :product__product_barcode do
      stacked([:code, :symbology, :registered_at])
    end
  end
end
