Code.require_file("test/support/aurora_uix_test_web.exs")

defmodule AuroraUixTestWeb.Router do
  use AuroraUixTestWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {AuroraUixTestWeb.Layout, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AuroraUixTestWeb do
    pipe_through(:browser)
    AuroraUixTestWeb.register_crud(Inventory.Views.Product, "products")
    AuroraUixTestWeb.register_crud(Inventory.Views.ProductTransaction, "product_transactions")

    # Tests with required CRUD links for testing
    AuroraUixTestWeb.register_crud(
      CreateUILayoutTest.TestModule.Product,
      "create-ui-layout-products"
    )

    AuroraUixTestWeb.register_crud(
      GroupUILayoutTest.TestModule.Product,
      "group-ui-layout-products"
    )

    AuroraUixTestWeb.register_crud(
      SectionUILayoutTest.TestModule.Product,
      "section-ui-layout-products"
    )

    AuroraUixTestWeb.register_crud(
      NestedSectionsUILayoutTest.TestModule.Product,
      "nested-sections-ui-layout-products"
    )

    AuroraUixTestWeb.register_crud(
      SpecialFieldsUITest.TestModule.Product,
      "special-fields-ui-products"
    )
  end
end
