defmodule AuroraUixTestWeb.ProductLive.Index do
  use AuroraUixTestWeb, :persist_attributes
  use AuroraUixWeb.Uix

  alias AuroraUixTest.Inventory
  alias AuroraUixTest.Inventory.Product
  #  alias AuroraUixTest.Inventory.ProductTransaction

  uix_schema_metadata :product, context: Inventory, schema: Product do
    field(:id, hidden: true)
  end

  #  uix_schema_metadata(:product_transaction, ProductTransaction, Inventory) do
  #  end
end
