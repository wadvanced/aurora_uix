defmodule Aurora.UixWeb.Test.Routes do
  @moduledoc """
  Provides test routes for the application.

  This module defines a `__using__/1` macro that injects a comprehensive set of
  test routes into the router. These routes are used for testing various
  features and scenarios of the Aurora.Uix framework.
  """
  alias Aurora.Uix.RouteHelper
  alias Aurora.UixWeb.Test.RoutesHelper

  @doc """
  Injects all test routes into the calling module.
  """
  @spec load_test_routes() :: Macro.t()
  defmacro load_test_routes do
    routes =
      quote do
        require Aurora.UixWeb.Test.RoutesHelper

        RoutesHelper.register_mirror(Default, "default", [
          "products",
          "product_locations",
          "product_transactions",
          "product_barcodes",
          "suppliers"
        ])

        RoutesHelper.register_mirror(DefaultInline, "default-inline", ["products"])
        RoutesHelper.register_mirror(Groups, "groups", ["products"])
        RoutesHelper.register_mirror(Sections, "sections", ["products"])
        RoutesHelper.register_mirror(NestedSections, "nested-sections", ["products"])

        RoutesHelper.register_mirror(Options, "options", [
          "products",
          "product_transactions",
          "product_locations",
          "product_barcodes"
        ])

        RoutesHelper.register_mirror(Included, "included", ["products"])

        RoutesHelper.register_mirror(Manual, "manual", [
          "products",
          "product_transactions",
          "product_locations"
        ])

        RoutesHelper.register_mirror(Separated, "separated", ["products", "product_transactions"])

        RoutesHelper.register_mirror(Index, "index", [
          "products",
          "product_locations",
          "suppliers"
        ])

        RoutesHelper.register_mirror(IndexQuery, "index-query", ["products", "product_locations"])
        RoutesHelper.register_mirror(IndexWhere, "index-where", ["products"])

        RoutesHelper.register_mirror(IndexCards, "index-cards", [
          "products",
          "product_transactions"
        ])

        RoutesHelper.register_mirror(IndexActions, "index-actions", [
          "products",
          "product_locations",
          "suppliers"
        ])

        RoutesHelper.register_mirror(Form, "form", ["products", "product_locations"])
        RoutesHelper.register_mirror(Show, "show", ["products"])

        RoutesHelper.register_mirror(ShowNavigator, "show-navigator", [
          "products",
          "product_locations"
        ])

        RoutesHelper.register_mirror(FormOptions, "form-options", ["products"])
        RoutesHelper.register_mirror(Uploads, "uploads", ["products"])
        RoutesHelper.register_mirror(Renderers, "renderers", ["products"])
        RoutesHelper.register_mirror(PredefinedRenderers, "predefined-renderers", ["products"])
        RoutesHelper.register_mirror(RendererModuleTable, "renderer-module-table", ["products"])
        RoutesHelper.register_mirror(RendererPrecedence, "renderer-precedence", ["products"])

        RoutesHelper.register_product_crud(
          MirrorCtx.ManualResource,
          "mirror-ctx-manual-resource-"
        )

        RoutesHelper.register_crud(
          GuidesCapture.DefaultLayout.Product,
          "guides-capture-default-products"
        )

        RoutesHelper.register_product_crud(
          GuidesCapture.SelectorLayout,
          "guides-capture-selector-"
        )

        RoutesHelper.register_crud(
          GuidesCapture.GroupLayout.Product,
          "guides-capture-group-products"
        )

        RoutesHelper.register_crud(
          GuidesCapture.SectionLayout.Product,
          "guides-capture-section-products"
        )

        RoutesHelper.register_crud(
          GuidesCapture.NestedSectionsLayout.Product,
          "guides-capture-nested-sections-products"
        )

        # Tests with required CRUD links for testing

        RoutesHelper.register_crud(
          AshMany2OneSelectTest.Post,
          "ash-many2one-select-posts"
        )

        RoutesHelper.register_crud(
          AshMany2ManyTest.Post,
          "ash-many2many-posts"
        )

        RoutesHelper.register_crud(
          AshMany2ManyTest.Topic,
          "ash-many2many-topics"
        )

        RoutesHelper.register_crud(
          AssociationMany2ManyUILayoutTest.Product,
          "association/many_to_many/layout/products"
        )

        RoutesHelper.register_crud(
          AssociationMany2ManyUILayoutTest.Supplier,
          "association/many_to_many/layout/suppliers"
        )

        RoutesHelper.register_crud(
          AssociationMany2ManyUIActionsTest.Product,
          "association/many_to_many/actions/products"
        )

        RoutesHelper.register_crud(
          AssociationMany2ManyUIActionsTest.Supplier,
          "association/many_to_many/actions/suppliers"
        )

        RoutesHelper.register_crud(
          AshOne2OneTest.Author,
          "ash-one2one-authors"
        )

        RoutesHelper.register_crud(
          AshOne2OneTest.AuthorProfile,
          "ash-one2one-author-profiles"
        )

        RoutesHelper.register_crud(
          AssociationOne2OneUILayoutTest.Product,
          "association/one_to_one/layout/products"
        )

        RoutesHelper.register_crud(
          AssociationOne2OneUILayoutTest.ProductBarcode,
          "association/one_to_one/layout/product_barcodes"
        )

        RoutesHelper.register_crud(
          AshEmbedsTest.Author,
          "ash-embeds-authors"
        )

        RoutesHelper.register_crud(
          AshEmbedsTest.Post,
          "ash-embeds-posts"
        )

        RoutesHelper.register_crud(
          BrowserAshEmbedsTest.Post,
          "browser-ash-embeds-posts"
        )

        RoutesHelper.register_product_crud(
          AssociationOne2ManyUILayoutTest,
          "association/one_to_many/layout/"
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
          GettextDomainTest,
          "gettext-domain-"
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
          WhereOne2ManyTest,
          "where-one_to_many-"
        )

        RoutesHelper.register_product_crud(
          WhereMany2OneTest,
          "where-many_to_one-"
        )

        RoutesHelper.register_product_crud(
          BrowserCreateUIDefaultLayoutTest,
          "browser-create-ui-default-layout-"
        )

        RoutesHelper.register_user_crud(
          EmbedsOneTest,
          "embeds-one-"
        )

        RoutesHelper.register_user_crud(
          EmbedsManyTest,
          "embeds-many-"
        )

        RoutesHelper.register_crud(
          ActionIconsFieldsTest.Product,
          "action-icons-fields-products"
        )

        RoutesHelper.register_crud(
          ActionIconsFieldsTest.ProductTransaction,
          "action-icons-fields-product_transactions"
        )

        RoutesHelper.register_crud(
          ActionIconsFieldsTest.User,
          "action-icons-fields-users"
        )

        RoutesHelper.register_user_crud(
          BrowserEmbedsManyTest,
          "browser-embeds-many-"
        )

        RoutesHelper.register_crud(
          AshActorPolicyTest.PublicItem,
          "ash-actor-public-items"
        )

        RoutesHelper.register_crud(
          AshWhereOne2ManyTest.Author,
          "ash-where-one_to_many-authors"
        )

        RoutesHelper.register_crud(AshWhereMany2OneTest.Post, "ash-where-many_to_one-posts")

        RoutesHelper.register_crud(EventsTest.Product, "events-products")
        RoutesHelper.register_crud(EventsTest.ProductLocation, "events-product-locations")
        RoutesHelper.register_crud(AshEventsTest.Author, "ash-events-authors")

        RoutesHelper.register_crud(NavigationTest.Product, "navigation-products")

        RoutesHelper.register_crud(
          NavigationTest.ProductTransaction,
          "navigation-product_transactions"
        )

        RoutesHelper.register_crud(AshNavigationTest.Author, "ash-navigation-authors")
        RoutesHelper.register_crud(AshNavigationTest.Post, "ash-navigation-posts")

        require Aurora.Uix.RouteHelper

        RouteHelper.auix_live_resources(
          "/navigation-only-products",
          NavigationTest.Product,
          only: [:index, :show]
        )

        RouteHelper.auix_live_resources(
          "/navigation-except-products",
          NavigationTest.Product,
          except: [:new, :edit]
        )

        RouteHelper.auix_live_resources(
          "/mirror-ash-named-product_locations",
          MirrorAsh.Named.ProductLocation,
          index_live: :locations
        )

        RouteHelper.auix_live_resources(
          "/mirror-ctx-named-product_locations",
          MirrorCtx.Named.ProductLocation,
          index_live: :locations
        )

        RoutesHelper.register_crud(
          OneToManyComponentTest.Product,
          "one-to-many-component-products"
        )

        RoutesHelper.register_crud(
          OneToManyComponentTest.ProductLocation,
          "one-to-many-component-product_locations"
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
