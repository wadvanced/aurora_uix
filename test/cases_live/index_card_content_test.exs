defmodule Aurora.UixWeb.Test.IndexCardContentTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns :product, [:reference, :name, :description, :quantity_at_hand] do
      card title: :name, subtitle: :reference do
        group "Stock" do
          field(:quantity_at_hand, label: "On hand")
        end
      end
    end
  end

  test "a declared card renders its title, subtitle and body", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(3, :test)
    {:ok, view, _html} = live(conn, "/index-card-content-products")

    m = "#auix-table-index-card-content-products-index-mobile"

    assert has_element?(
             view,
             "#{m} [name='auix-card-title'] a[name='auix-show-product']",
             "Item test-1"
           )

    assert has_element?(view, "#{m} [name='auix-card-subtitle']", "item_test-1")

    assert has_element?(
             view,
             "#{m} [name='auix-card-body'] .auix-group-container .auix-group-title",
             "Stock"
           )

    assert has_element?(
             view,
             "#{m} [name='auix-card-body'] .auix-items-card-item-label",
             "On hand"
           )

    refute has_element?(view, "#{m} .auix-items-card-item-label", "Description")

    assert has_element?(
             view,
             "[name='auix-items-table'] th[name='auix-column-label']",
             "Quantity At Hand"
           )

    assert has_element?(view, ".auix-items-mobile [name='auix-items-card']")
    refute has_element?(view, ".auix-index-sort-action--always")
  end
end
