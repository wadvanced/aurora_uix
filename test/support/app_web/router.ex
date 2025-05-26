defmodule Aurora.Uix.Web.Test.Router do
  use Aurora.Uix.Web.Test, :router

  alias Aurora.Uix.Web.Test

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {Aurora.Uix.Web.Test.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Aurora.Uix.Web.Test do
    pipe_through(:browser)
    Test.register_crud(Inventory.Views.Product, "products")
    Test.register_crud(Inventory.Views.ProductTransaction, "product_transactions")

    # Tests with required CRUD links for testing
    Test.register_crud(
      CreateUIDefaultLayoutTest.TestModule.Product,
      "create-ui-default-layout-products"
    )

    Test.register_crud(
      CreateUIDefaultLayoutInlineTest.TestModule.Product,
      "create-ui-default-layout-inline-products"
    )

    Test.register_crud(
      CreateUILayoutTest.TestModule.Product,
      "create-ui-layout-products"
    )

    Test.register_crud(
      GroupUILayoutTest.TestModule.Product,
      "group-ui-layout-products"
    )

    Test.register_crud(
      SectionUILayoutTest.TestModule.Product,
      "section-ui-layout-products"
    )

    Test.register_crud(
      NestedSectionsUILayoutTest.TestModule.Product,
      "nested-sections-ui-layout-products"
    )

    Test.register_crud(
      SpecialFieldsUITest.TestModule.Product,
      "special-fields-ui-products"
    )

    Test.register_crud(
      SeparatedSingleResourceUITest.TestModule.Product,
      "separated-single-resource-products"
    )

    Test.register_crud(
      SeparatedMultipleResourcesUITest.TestModule.Product,
      "separated-multiple-resources-products"
    )

    Test.register_crud(
      SeparatedMultipleResourcesUITest.TestModule.ProductTransaction,
      "separated-multiple-resources-product_transactions"
    )

    Test.register_crud(
      UnseparatedMultipleResourcesUITest.TestModule.Product,
      "unseparated-multiple-resources-products"
    )

    Test.register_crud(
      UnseparatedMultipleResourcesUITest.TestModule.ProductTransaction,
      "unseparated-multiple-resources-product_transactions"
    )

    Test.register_crud(
      AssociationMany2oneUILayoutTest.TestModule.Product,
      "association-many-layout-products"
    )

    Test.register_crud(
      AssociationMany2oneUILayoutTest.TestModule.ProductTransaction,
      "association-many-layout-product_transactions"
    )

    Test.register_crud(
      AssociationMany2oneUILayoutTest.TestModule.ProductLocation,
      "association-many-layout-product_locations"
    )
  end
end
