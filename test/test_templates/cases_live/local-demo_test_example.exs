defmodule Aurora.UixWeb.Test.LocalDemoTest do
  @moduledoc """
  Use this module as a reference to create local, not versioned, tests.
  """
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory

  alias Aurora.Uix.Guides.Inventory.Product
  # alias Aurora.Uix.Guides.Inventory.ProductLocation
  # alias Aurora.Uix.Guides.Inventory.ProductTransaction

  # auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  # auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # This link is already routed in test/support/app_web/routes.ex as:
  # live("/local-demo-products", LocalDemoTest.TestModule.Product.Index, :index)
  # live("/local-demo-products/new", LocalDemoTest.TestModule.Product.Index, :new)
  # live("/local-demo-products/:id/edit", LocalDemoTest.TestModule.Product.Index, :edit)
  # live("/local-demo-products/:id", LocalDemoTest.TestModule.Product.Show, :show)
  # live("/local-demo-products/:id/show/edit", LocalDemoTest.TestModule.Product.Show, :edit)
  #
  # live("/local-demo-product_transactions", LocalDemoTest.TestModule.ProductTransaction.Index, :index)
  # live("/local-demo-product_transactions/new", LocalDemoTest.TestModule.ProductTransaction.Index, :new)
  # live("/local-demo-product_transactions/:id/edit", LocalDemoTest.TestModule.ProductTransaction.Index, :edit)
  # live("/local-demo-product_transactions/:id", LocalDemoTest.TestModule.ProductTransaction.Show, :show)
  # live("/local-demo-product_transactions/:id/show/edit", LocalDemoTest.TestModule.ProductTransaction.Show, :edit)
  #
  # live("/local-demo-product_locations", LocalDemoTest.TestModule.ProductLocation.Index, :index)
  # live("/local-demo-product_locations/new", LocalDemoTest.TestModule.ProductLocation.Index, :new)
  # live("/local-demo-product_locations/:id/edit", LocalDemoTest.TestModule.ProductLocation.Index, :edit)
  # live("/local-demo-product_locations/:id", LocalDemoTest.TestModule.ProductLocation.Show, :show)
  # live("/local-demo-product_locations/:id/show/edit", LocalDemoTest.TestModule.ProductLocation.Show, :edit)
  auix_create_ui(link_prefix: "local-demo-")

  test "Local empty_test", %{conn: conn} do
    live(conn, "/local-demo-products")
  end
end
