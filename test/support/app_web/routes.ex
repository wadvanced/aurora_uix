defmodule Aurora.UixWeb.Test.Routes do
  @moduledoc """
  Provides test routes for the application.

  This module defines a `__using__/1` macro that injects a comprehensive set of
  test routes into the router. These routes are used for testing various
  features and scenarios of the Aurora.Uix framework.
  """
  alias Aurora.UixWeb.Test.RoutesHelper

  @doc """
  Injects all test routes into the calling module.
  """
  @spec load_test_routes() :: Macro.t()
  defmacro load_test_routes do
    routes =
      quote do
        require Aurora.UixWeb.Test.RoutesHelper

        # Tests with required CRUD links for testing
        RoutesHelper.register_crud(
          CreateUIDefaultLayoutTest.Product,
          "create-ui-default-layout-products"
        )

        RoutesHelper.register_crud(
          CreateUIDefaultLayoutInlineTest.Product,
          "create-ui-default-layout-inline-products"
        )

        RoutesHelper.register_crud(
          CreateUILayoutTest.Product,
          "create-ui-layout-products"
        )

        RoutesHelper.register_crud(
          GroupUILayoutTest.Product,
          "group-ui-layout-products"
        )

        RoutesHelper.register_crud(
          SectionUILayoutTest.Product,
          "section-ui-layout-products"
        )

        RoutesHelper.register_crud(
          NestedSectionsUILayoutTest.Product,
          "nested-sections-ui-layout-products"
        )

        RoutesHelper.register_crud(
          SpecialFieldsUITest.Product,
          "special-fields-ui-products"
        )

        RoutesHelper.register_crud(
          SeparatedSingleResourceUITest.Product,
          "separated-single-resource-products"
        )

        RoutesHelper.register_product_crud(
          SeparatedMultipleResourcesUITest,
          "separated-multiple-resources-"
        )

        RoutesHelper.register_product_crud(
          UnseparatedMultipleResourcesUITest,
          "unseparated-multiple-resources-"
        )

        RoutesHelper.register_product_crud(
          AssociationOne2ManyUILayoutTest,
          "association-one_to_many-layout-"
        )

        RoutesHelper.register_product_crud(
          AssociationMany2OneUILayoutTest,
          "association-many_to_one-layout-"
        )

        RoutesHelper.register_product_crud(
          AssociationMany2OneParentUILayoutTest,
          "association-many_to_one_parent-layout-"
        )

        RoutesHelper.register_product_crud(
          AssociationMany2OneSelectorUILayoutTest,
          "association-many_to_one_selector-layout-"
        )

        RoutesHelper.register_product_crud(
          AssociationMany2OneSelectorAtomTest,
          "association-many_to_one_selector-atom-"
        )

        RoutesHelper.register_product_crud(
          AssociationMany2OneSelectorFunctionTest,
          "association-many_to_one_selector-function-"
        )

        RoutesHelper.register_product_crud(
          AssociationMany2OneSelectorAssignsTest,
          "association-many_to_one_selector-assigns-"
        )

        RoutesHelper.register_product_crud(
          CreateUIActionsIndexTest,
          "create-ui-actions-index-"
        )

        RoutesHelper.register_product_crud(
          CreateUIActionsShowTest,
          "create-ui-actions-show-"
        )

        RoutesHelper.register_product_crud(
          CreateUIActionsFormTest,
          "create-ui-actions-form-"
        )

        RoutesHelper.register_product_crud(
          AssociationOne2ManyUIActionsTest,
          "association-one_to_many-actions-"
        )

        RoutesHelper.register_product_crud(
          HandlerHooksIndexTest,
          "handler-hooks-index-"
        )

        RoutesHelper.register_product_crud(
          HandlerHooksShowTest,
          "handler-hooks-show-"
        )

        RoutesHelper.register_product_crud(
          HandlerHooksFormTest,
          "handler-hooks-form-"
        )

        RoutesHelper.register_product_crud(
          OrderByMetadataTest,
          "order-by-metadata-"
        )

        RoutesHelper.register_product_crud(
          OrderByLayoutTest,
          "order-by-layout-"
        )

        RoutesHelper.register_product_crud(
          WhereLayoutTest,
          "where-layout-"
        )

        RoutesHelper.register_product_crud(
          WhereOne2ManyTest,
          "where-one_to_many-"
        )

        RoutesHelper.register_product_crud(
          WhereMany2OneTest,
          "where-many_to_one-"
        )

        RoutesHelper.register_product_crud(
          PagesBarTest,
          "pages-bar-"
        )

        RoutesHelper.register_product_crud(
          InfinityScrollTest,
          "infinity-scroll-"
        )

        RoutesHelper.register_product_crud(
          ManualResourceTest,
          "manual-resource-"
        )

        RoutesHelper.register_product_crud(
          ManualUITest,
          "manual-ui-"
        )

        RoutesHelper.register_product_crud(
          ManualLayoutsTest,
          "manual-layouts-"
        )

        RoutesHelper.register_product_crud(
          ManualTreesTest,
          "manual-trees-"
        )

        RoutesHelper.register_product_crud(
          SelectedTest,
          "selected-"
        )

        RoutesHelper.register_user_crud(
          EmbedsOneTest,
          "embeds-one-"
        )

        RoutesHelper.register_user_crud(
          EmbedsManyTest,
          "embeds-many-"
        )
      end

    ## You can create a file test/cases_live/-local-demo_test.exs
    ## With Aurora.Uix.Test.LocalDemoTest module
    ## And then test its output in /local-demo-products
    ## You can use
    local_demo_route =
      if File.exists?("test/cases_live/-local-demo_test.exs") do
        quote do
          RoutesHelper.register_product_crud(
            LocalDemoTest,
            "local-demo-"
          )
        end
      end

    quote do
      unquote(routes)
      unquote(local_demo_route)
    end
  end
end
