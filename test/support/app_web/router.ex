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
      AssociationOne2ManyUILayoutTest.TestModule.Product,
      "association-one_to_many-layout-products"
    )

    Web.register_crud(
      AssociationOne2ManyUILayoutTest.TestModule.ProductTransaction,
      "association-one_to_many-layout-product_transactions"
    )

    Web.register_crud(
      AssociationOne2ManyUILayoutTest.TestModule.ProductLocation,
      "association-one_to_many-layout-product_locations"
    )

    Web.register_crud(
      AssociationMany2OneUILayoutTest.TestModule.Product,
      "association-many_to_one-layout-products"
    )

    Web.register_crud(
      AssociationMany2OneUILayoutTest.TestModule.ProductTransaction,
      "association-many_to_one-layout-product_transactions"
    )

    Web.register_crud(
      AssociationMany2OneUILayoutTest.TestModule.ProductLocation,
      "association-many_to_one-layout-product_locations"
    )

    Web.register_crud(
      AssociationMany2OneParentUILayoutTest.TestModule.Product,
      "association-many_to_one_parent-layout-products"
    )

    Web.register_crud(
      AssociationMany2OneParentUILayoutTest.TestModule.ProductTransaction,
      "association-many_to_one_parent-layout-product_transactions"
    )

    Web.register_crud(
      AssociationMany2OneParentUILayoutTest.TestModule.ProductLocation,
      "association-many_to_one_parent-layout-product_locations"
    )
  end
end
