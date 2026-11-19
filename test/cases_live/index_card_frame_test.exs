defmodule Aurora.UixWeb.Test.IndexCardFrameTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Templates.Basic.Themes.Base
  alias Aurora.UixWeb.Test.NavigationHelper

  @mobile "#auix-table-index-card-frame-products-index-mobile"

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name, :quantity_at_hand])
  end

  describe "card frame" do
    setup %{conn: conn} do
      delete_all_inventory_data()
      products = create_sample_products(3, :test)
      {:ok, view, _html} = live(conn, "/index-card-frame-products")
      %{view: view, products: products}
    end

    test "a card has a header, a body and labelled rows", %{view: view} do
      m = @mobile

      assert has_element?(
               view,
               "#{m} [name='auix-card'] .auix-items-card-select input[type='checkbox']"
             )

      assert has_element?(view, "#{m} [name='auix-card-title']", "item_test-1")

      assert has_element?(
               view,
               "#{m} [name='auix-card-body'] .auix-items-card-item-fieldset .auix-items-card-item-label",
               "Name"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-body'] .auix-items-card-item-fieldset .auix-items-card-item-label",
               "Quantity At Hand"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-body'] [name='auix-column-value']",
               "Item test-1"
             )
    end

    test "default row actions sit in the header menu", %{view: view} do
      m = @mobile

      refute has_element?(view, "#{m} [name='auix-card-actions']")

      assert has_element?(
               view,
               "#{m} [name='auix-card'] > .auix-items-card-item-group > .auix-items-card-select + .auix-items-card-heading + [name='auix-card-menu']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-actions'] a[name='auix-edit-product'][title='Edit'][aria-label='Edit']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-destructive'] a[name='auix-delete-product'][title='Delete'][aria-label='Delete']"
             )

      refute has_element?(view, "#{m} [name='auix-card-menu-list'] a[name='auix-show-product']")
    end

    test "tapping a card runs its show action", %{view: view, products: products} do
      m = @mobile
      id = products["id_test-1"].id

      assert has_element?(
               view,
               "#{m} [name='auix-card'] > [name='auix-card-show']:first-child a[name='auix-show-product'][title='Show'][aria-label='Show']"
             )

      view
      |> element("#{m} [name='auix-card-show'] a[phx-value-route_path$='/#{id}/show']")
      |> render_click()

      {path, _query, _stack} = view |> assert_patch() |> NavigationHelper.decode_route()
      assert path == "/index-card-frame-products/#{id}/show"
    end

    test "an empty list shows no card", %{conn: conn} do
      m = @mobile
      delete_all_inventory_data()
      {:ok, view, _html} = live(conn, "/index-card-frame-products")

      refute has_element?(view, "#{m} [name='auix-card']")

      assert has_element?(
               view,
               "[name='auix-items-card'] .auix-items-card-empty",
               "No items to show"
             )
    end

    test "cards have no stripes and no italic values", %{view: view} do
      refute has_element?(view, "[class*='auix-items-card-item-content--']")
      refute Base.rule(:auix_items_card_item_value) =~ "font-style"
      assert Base.rule(:auix_items_card_item_content__even) == ""
    end
  end
end
