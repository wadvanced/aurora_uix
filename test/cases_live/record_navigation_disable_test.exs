defmodule Aurora.UixWeb.Test.RecordNavigationDisableTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)

    show_layout :product, record_navigator: :none do
      stacked do
        inline([:reference, :name, :description])
        inline([:quantity_initial, quantity_at_hand])
      end
    end

    edit_layout :product, record_navigator: :bottom do
      stacked do
        inline([:reference, :name, :description])
        inline([:quantity_initial, quantity_at_hand])
      end
    end

    show_layout :product_location, record_navigator: :top do
      stacked([:reference, :name, :type])
    end

    edit_layout :product_location do
      stacked([:reference, :name, :type])
    end
  end

  test "Test NO navigation in product show", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(10, :test)

    {:ok, view, _html} = live(conn, "/record-navigation-disable-products")

    assert view
           |> element("table tbody tr:nth-of-type(2) td:nth-of-type(2) a")
           |> render_click() =~ "Back to Products"

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-product-show-modal-content .auix-record-navigator-bar")
           |> Enum.count() == 0
  end

  test "Test BOTTOM only navigation in product edit", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(10, :test)
    create_sample_product_locations(5, :test)

    {:ok, view, _html} = live(conn, "/record-navigation-disable-products")

    view
    |> element("table tbody tr:nth-of-type(2) td:nth-of-type(2) a")
    |> render_click() =~ "Back to Products"

    assert view
           |> element("div[name='auix-show-header-actions'] a[name='auix-edit-product']")
           |> render_click() =~ "Use this form to manage"

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("#auix-product-show_edit-modal-content .auix-record-navigator-bar")
           |> Enum.count() == 1
  end

  test "Test TOP navigation in product_location show", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_product_locations(5, :test)

    {:ok, view, _html} = live(conn, "/record-navigation-disable-product_locations")

    view
    |> element("table tbody tr:nth-of-type(2) td:nth-of-type(2) a")
    |> render_click() =~ "Back to Product Locations"

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "#auix-product_location-show-modal-content .auix-record-navigator-bar"
           )
           |> Enum.count() == 1
  end

  test "Test ALL navigation in product_location edit", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(10, :test)
    create_sample_product_locations(5, :test)

    {:ok, view, _html} = live(conn, "/record-navigation-disable-product_locations")

    view
    |> element("table tbody tr:nth-of-type(2) td:nth-of-type(2) a")
    |> render_click() =~ "Back to Product Locations"

    assert view
           |> element("div[name='auix-show-header-actions'] a[name='auix-edit-product_location']")
           |> render_click() =~ "Use this form to manage"

    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "#auix-product_location-show_edit-modal-content .auix-record-navigator-bar"
           )
           |> Enum.count() == 2
  end
end
