defmodule Aurora.Uix.Test.Web.Router do
  use Aurora.Uix.Test.Web, :router

  alias Aurora.Uix.Test.Web

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {Web.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Aurora.Uix.Test.Web do
    pipe_through(:browser)
    Web.register_crud(Inventory.Views.Product, "products")
    Web.register_crud(Inventory.Views.ProductTransaction, "product_transactions")

    # Tests with required CRUD links for testing
    Web.register_crud(
      CreateUIDefaultLayoutTest.TestModule.Product,
      "create-ui-default-layout-products"
    )

    Web.register_crud(
      CreateUIDefaultLayoutInlineTest.TestModule.Product,
      "create-ui-default-layout-inline-products"
    )

    Web.register_crud(
      CreateUILayoutTest.TestModule.Product,
      "create-ui-layout-products"
    )

    Web.register_crud(
      GroupUILayoutTest.TestModule.Product,
      "group-ui-layout-products"
    )

    Web.register_crud(
      SectionUILayoutTest.TestModule.Product,
      "section-ui-layout-products"
    )

    Web.register_crud(
      NestedSectionsUILayoutTest.TestModule.Product,
      "nested-sections-ui-layout-products"
    )

    Web.register_crud(
      SpecialFieldsUITest.TestModule.Product,
      "special-fields-ui-products"
    )

    Web.register_crud(
      SeparatedSingleResourceUITest.TestModule.Product,
      "separated-single-resource-products"
    )

    Web.register_crud(
      SeparatedMultipleResourcesUITest.TestModule.Product,
      "separated-multiple-resources-products"
    )

    Web.register_crud(
      SeparatedMultipleResourcesUITest.TestModule.ProductTransaction,
      "separated-multiple-resources-product_transactions"
    )

    Web.register_crud(
      UnseparatedMultipleResourcesUITest.TestModule.Product,
      "unseparated-multiple-resources-products"
    )

    Web.register_crud(
      UnseparatedMultipleResourcesUITest.TestModule.ProductTransaction,
      "unseparated-multiple-resources-product_transactions"
    )

    Web.register_crud(
      AssociationMany2oneUILayoutTest.TestModule.Product,
      "association-many-layout-products"
    )

    Web.register_crud(
      AssociationMany2oneUILayoutTest.TestModule.ProductTransaction,
      "association-many-layout-product_transactions"
    )

    Web.register_crud(
      AssociationMany2oneUILayoutTest.TestModule.ProductLocation,
      "association-many-layout-product_locations"
    )
  end
end
