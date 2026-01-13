defmodule Aurora.UixWeb.Test.RecordNavigationTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)

    edit_layout :product, [] do
      stacked do
        inline([:reference, :name, :description])
        inline([:quantity_initial, quantity_at_hand])
      end
    end
  end

  test "Test previous record first", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(1000, :test)

    {:ok, view, _html} = live(conn, "/record-navigation-products")

    assert view
           |> element("table tbody tr:nth-of-type(1) td:nth-of-type(2) a")
           |> render_click() =~ "Back to Products"

    assert has_element?(
             view,
             "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) span.hero-chevron-left.auix-icon-inactive"
           )

    assert has_element?(
             view,
             "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(1)[phx-value-index='1'][phx-value-page='1'] .hero-chevron-right"
           )
  end

  test "Test previous record in same page", %{conn: conn} do
    delete_all_inventory_data()

    products =
      1000
      |> create_sample_products(:test)
      |> Map.new(&{elem(&1, 0), &1 |> elem(1) |> Map.from_struct()})

    product_4_id = get_in(products, ["id_test-0004", :id])
    product_5_id = get_in(products, ["id_test-0005", :id])

    {:ok, view, _html} = live(conn, "/record-navigation-products")

    view
    |> element("table tbody tr:nth-of-type(5) td:nth-of-type(2) a")
    |> render_click()

    view
    |> tap(
      &assert has_element?(
                &1,
                "input[id^='auix-field-product-reference-'][id$='--#{product_5_id}--show'][value='item_test-0005']"
              )
    )
    |> tap(
      &assert has_element?(
                &1,
                "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(2)[phx-value-index='5'][phx-value-page='1'] .hero-chevron-right"
              )
    )
    |> element(
      "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(1)[phx-value-index='3'][phx-value-page='1']"
    )
    |> render_click()

    assert has_element?(
             view,
             "input[id^='auix-field-product-reference-'][id$='--#{product_4_id}--show'][value='item_test-0004']"
           )
  end

  test "Test previous record in previous page", %{conn: conn} do
    delete_all_inventory_data()

    products =
      1000
      |> create_sample_products(:test)
      |> Map.new(&{elem(&1, 0), &1 |> elem(1) |> Map.from_struct()})

    product_80_id = get_in(products, ["id_test-0080", :id])
    product_81_id = get_in(products, ["id_test-0081", :id])

    {:ok, view, _html} = live(conn, "/record-navigation-products?page=3")

    # Show item in first row of the third page
    view
    |> element("table tbody tr:nth-of-type(1) td:nth-of-type(2) a")
    |> render_click()

    view
    |> tap(
      &assert has_element?(
                &1,
                "input[id^='auix-field-product-reference-'][id$='--#{product_81_id}--show'][value='item_test-0081']"
              )
    )
    |> tap(
      &assert has_element?(
                &1,
                "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(1) .hero-chevron-left"
              )
    )
    |> tap(
      &assert has_element?(
                &1,
                "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(2)[phx-value-index='1'][phx-value-page='3'] .hero-chevron-right"
              )
    )
    |> element(
      "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(1)[phx-value-index='39'][phx-value-page='2']"
    )
    |> render_click()

    assert has_element?(
             view,
             "input[id^='auix-field-product-reference-'][id$='--#{product_80_id}--show'][value='item_test-0080']"
           )
  end

  test "Test next record last page", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(1000, :test)

    {:ok, view, _html} = live(conn, "/record-navigation-products?page=25")

    assert view
           |> element("table tbody tr:nth-of-type(40) td:nth-of-type(2) a")
           |> render_click() =~ "Back to Products"

    assert has_element?(
             view,
             "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(1)[phx-value-index='38'][phx-value-page='25'] .hero-chevron-left"
           )

    assert has_element?(
             view,
             "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) span.hero-chevron-right.auix-icon-inactive"
           )
  end

  test "Test next record in same page", %{conn: conn} do
    delete_all_inventory_data()

    products =
      1000
      |> create_sample_products(:test)
      |> Map.new(&{elem(&1, 0), &1 |> elem(1) |> Map.from_struct()})

    product_4_id = get_in(products, ["id_test-0004", :id])
    product_5_id = get_in(products, ["id_test-0005", :id])

    {:ok, view, _html} = live(conn, "/record-navigation-products")

    view
    |> element("table tbody tr:nth-of-type(4) td:nth-of-type(2) a")
    |> render_click()

    view
    |> tap(
      &assert has_element?(
                &1,
                "input[id^='auix-field-product-reference-'][id$='--#{product_4_id}--show'][value='item_test-0004']"
              )
    )
    |> tap(
      &assert has_element?(
                &1,
                "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(1)[phx-value-index='2'][phx-value-page='1'] .hero-chevron-left"
              )
    )
    |> tap(
      &assert has_element?(
                &1,
                "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(2) .hero-chevron-right"
              )
    )
    |> element(
      "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(2)[phx-value-index='4'][phx-value-page='1']"
    )
    |> render_click()

    assert has_element?(
             view,
             "input[id^='auix-field-product-reference-'][id$='--#{product_5_id}--show'][value='item_test-0005']"
           )
  end

  test "Test next record in next page", %{conn: conn} do
    delete_all_inventory_data()

    products =
      1000
      |> create_sample_products(:test)
      |> Map.new(&{elem(&1, 0), &1 |> elem(1) |> Map.from_struct()})

    product_80_id = get_in(products, ["id_test-0080", :id])
    product_81_id = get_in(products, ["id_test-0081", :id])

    {:ok, view, _html} = live(conn, "/record-navigation-products?page=2")

    # Show item in last row of the second page
    view
    |> element("table tbody tr:nth-of-type(40) td:nth-of-type(2) a")
    |> render_click()

    view
    |> tap(
      &assert has_element?(
                &1,
                "input[id^='auix-field-product-reference-'][id$='--#{product_80_id}--show'][value='item_test-0080']"
              )
    )
    |> tap(
      &assert has_element?(
                &1,
                "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(1)[phx-value-index='38'][phx-value-page='2'] .hero-chevron-left"
              )
    )
    |> tap(
      &assert has_element?(
                &1,
                "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(2) .hero-chevron-right"
              )
    )
    |> element(
      "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1) a:nth-of-type(2)[phx-value-index='0'][phx-value-page='3']"
    )
    |> render_click()

    assert has_element?(
             view,
             "input[id^='auix-field-product-reference-'][id$='--#{product_81_id}--show'][value='item_test-0081']"
           )
  end
end
