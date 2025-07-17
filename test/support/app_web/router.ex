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

    # Tests with required CRUD links for testing
    Web.register_crud(
      CreateUIDefaultLayoutTest.Product,
      "create-ui-default-layout-products"
    )

    Web.register_crud(
      CreateUIDefaultLayoutInlineTest.Product,
      "create-ui-default-layout-inline-products"
    )

    Web.register_crud(
      CreateUILayoutTest.Product,
      "create-ui-layout-products"
    )

    Web.register_crud(
      GroupUILayoutTest.Product,
      "group-ui-layout-products"
    )

    Web.register_crud(
      SectionUILayoutTest.Product,
      "section-ui-layout-products"
    )

    Web.register_crud(
      NestedSectionsUILayoutTest.Product,
      "nested-sections-ui-layout-products"
    )

    Web.register_crud(
      SpecialFieldsUITest.Product,
      "special-fields-ui-products"
    )

    Web.register_crud(
      SeparatedSingleResourceUITest.Product,
      "separated-single-resource-products"
    )

    Web.register_product_crud(
      SeparatedMultipleResourcesUITest,
      "separated-multiple-resources-"
    )

    Web.register_product_crud(
      UnseparatedMultipleResourcesUITest,
      "unseparated-multiple-resources-"
    )

    Web.register_product_crud(
      AssociationOne2ManyUILayoutTest,
      "association-one_to_many-layout-"
    )

    Web.register_product_crud(
      AssociationMany2OneUILayoutTest,
      "association-many_to_one-layout-"
    )

    Web.register_product_crud(
      AssociationMany2OneParentUILayoutTest,
      "association-many_to_one_parent-layout-"
    )

    Web.register_product_crud(
      AssociationMany2OneSelectorUILayoutTest,
      "association-many_to_one_selector-layout-"
    )

    Web.register_product_crud(
      AssociationMany2OneSelectorAtomTest,
      "association-many_to_one_selector-atom-"
    )

    Web.register_product_crud(
      AssociationMany2OneSelectorFunctionTest,
      "association-many_to_one_selector-function-"
    )

    Web.register_product_crud(
      AssociationMany2OneSelectorAssignsTest,
      "association-many_to_one_selector-assigns-"
    )

    Web.register_product_crud(
      CreateUIActionsIndexTest,
      "create-ui-actions-index-"
    )

    Web.register_product_crud(
      CreateUIActionsShowTest,
      "create-ui-actions-show-"
    )

    Web.register_product_crud(
      CreateUIActionsFormTest,
      "create-ui-actions-form-"
    )

    Web.register_product_crud(
      AssociationOne2ManyUIActionsTest,
      "association-one_to_many-actions-"
    )

    Web.register_product_crud(
      HandlerHooksIndexTest,
      "handler-hooks-index-"
    )

    Web.register_product_crud(
      HandlerHooksShowTest,
      "handler-hooks-show-"
    )

    Web.register_product_crud(
      HandlerHooksFormTest,
      "handler-hooks-form-"
    )

    Web.register_product_crud(
      OrderByMetadataTest,
      "order-by-metadata-"
    )

    Web.register_product_crud(
      OrderByLayoutTest,
      "order-by-layout-"
    )

    Web.register_product_crud(
      WhereLayoutTest,
      "where-layout-"
    )

    ## You can create a file test/cases_live/-local-demo_test.exs
    ## With Aurora.Uix.Test.Web.LocalDemoTest module
    ## And then test its output in /local-demo-products
    ## You can use
    Web.register_product_crud(
      LocalDemoTest,
      "local-demo-"
    )
  end
end
