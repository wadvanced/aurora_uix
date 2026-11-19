defmodule Aurora.UixWeb.Test.IndexCardFrameTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Templates.Basic.Themes.Base

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
      create_sample_products(3, :test)
      {:ok, view, _html} = live(conn, "/index-card-frame-products")
      %{view: view}
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

    test "default row actions sit in the footer bar", %{view: view} do
      m = @mobile

      assert has_element?(
               view,
               "#{m} [name='auix-card-actions-leading'] a[name='auix-delete-product'][title='Delete'][aria-label='Delete']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-actions-trailing'] a[name='auix-show-product'][title='Show'][aria-label='Show']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-actions-trailing'] a[name='auix-edit-product'][title='Edit'][aria-label='Edit']"
             )

      refute has_element?(view, "#{m} [name='auix-card-menu']")
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
