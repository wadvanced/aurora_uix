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

        RoutesHelper.register_mirror(ManyToOne, "many-to-one", [
          "products",
          "product_locations",
          "product_transactions",
          "product_barcodes"
        ])

        RoutesHelper.register_mirror(ManyToOneQueries, "many-to-one-queries", [
          "products",
          "product_locations"
        ])

        RoutesHelper.register_mirror(OneToMany, "one-to-many", [
          "products",
          "product_transactions",
          "product_locations"
        ])

        RoutesHelper.register_mirror(OneToManyComponent, "one-to-many-component", [
          "products",
          "product_locations"
        ])

        RoutesHelper.register_mirror(OneToManyActions, "one-to-many-actions", [
          "products",
          "product_transactions",
          "product_locations"
        ])

        RoutesHelper.register_mirror(OneToOne, "one-to-one", ["products", "product_barcodes"])
        RoutesHelper.register_mirror(ManyToMany, "many-to-many", ["products", "suppliers"])

        RoutesHelper.register_mirror(ManyToManyActions, "many-to-many-actions", [
          "products",
          "suppliers"
        ])

        RoutesHelper.register_mirror(Embeds, "embeds", ["products"])
        RoutesHelper.register_mirror(EmbedsExpanded, "embeds-expanded", ["products"])

        RoutesHelper.register_mirror(Navigation, "navigation", [
          "products",
          "product_transactions"
        ])

        RoutesHelper.register_mirror(HooksIndex, "hooks-index", ["products"])
        RoutesHelper.register_mirror(HooksForm, "hooks-form", ["products"])

        RoutesHelper.register_mirror(HooksShow, "hooks-show", ["products", "product_transactions"])

        RoutesHelper.register_mirror(Components, "components", ["products"])

        RoutesHelper.register_mirror(Events, "events", [
          "products",
          "product_locations",
          "product_transactions"
        ])

        RoutesHelper.register_mirror(Gettext, "gettext", ["products"])

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
          BrowserCreateUIDefaultLayoutTest,
          "browser-create-ui-default-layout-"
        )

        RoutesHelper.register_user_crud(
          BrowserEmbedsManyTest,
          "browser-embeds-many-"
        )

        RoutesHelper.register_crud(
          AshActorPolicyTest.PublicItem,
          "ash-actor-public-items"
        )

        require Aurora.Uix.RouteHelper

        RouteHelper.auix_live_resources(
          "/mirror-ash-navigation-only-products",
          MirrorAsh.Navigation.Product,
          only: [:index, :show]
        )

        RouteHelper.auix_live_resources(
          "/mirror-ctx-navigation-only-products",
          MirrorCtx.Navigation.Product,
          only: [:index, :show]
        )

        RouteHelper.auix_live_resources(
          "/mirror-ash-navigation-except-products",
          MirrorAsh.Navigation.Product,
          except: [:new, :edit]
        )

        RouteHelper.auix_live_resources(
          "/mirror-ctx-navigation-except-products",
          MirrorCtx.Navigation.Product,
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
