defmodule Aurora.UixWeb.Test.AssociationMany2OneSelectorAtomTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  @test_names [
    "test-name-many2-20",
    "test-name-many2-19",
    "test-name-many2-18",
    "test-name-many2-17",
    "test-name-many2-16",
    "test-name-many2-15",
    "test-name-many2-14",
    "test-name-many2-13",
    "test-name-many2-12",
    "test-name-many2-11",
    "test-name-many2-10",
    "test-name-many2-09",
    "test-name-many2-08",
    "test-name-many2-07",
    "test-name-many2-06",
    "test-name-many2-05",
    "test-name-many2-04",
    "test-name-many2-03",
    "test-name-many2-02",
    "test-name-many2-01"
  ]

  auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation do
    field(:products, omitted: true)
  end

  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction) do
    field(:product, option_label: :name)
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product) do
    field(:product_location_id, option_label: :name, order_by: [desc: :name])
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    edit_layout :product_location do
      inline([:reference, :name, :type])
    end

    edit_layout :product do
      stacked([
        :reference,
        :name,
        :description,
        :quantity_initial,
        :product_location_id
      ])
    end
  end

  test "check_listing", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/association-many_to_one_selector-atom-products"
      )

    assert html =~ "Listing Products"
  end

  test "check_show", %{conn: conn} do
    delete_all_inventory_data()
    locations = create_sample_product_locations(5)
    location_id = get_in(locations, ["id_1", Access.key!(:id)])

    product_id =
      1
      |> create_sample_products(:test, %{product_location_id: location_id})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, view, html} =
      live(
        conn,
        "/association-many_to_one_selector-atom-products/#{product_id}/show"
      )

    assert html =~ "Product\n"

    assert has_element?(
             view,
             "select[id^='auix-field-product-product_location_id-'][id$='-show'] option[selected][value='#{location_id}']"
           )
  end

  test "check_edit", %{conn: conn} do
    delete_all_inventory_data()
    locations = create_sample_product_locations(5)
    location_id_1 = get_in(locations, ["id_1", Access.key!(:id)])
    location_id_2 = get_in(locations, ["id_2", Access.key!(:id)])
    name_1 = get_in(locations, ["id_1", Access.key!(:name)])
    name_2 = get_in(locations, ["id_2", Access.key!(:name)])

    product_id =
      1
      |> create_sample_products(:test, %{product_location_id: location_id_1})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, view, html} =
      live(
        conn,
        "/association-many_to_one_selector-atom-products/#{product_id}/edit"
      )

    assert html =~ "Edit Product"

    assert has_element?(
             view,
             "select[id^='auix-field-product-product_location_id-'][id$='-form'] option[selected][value='#{location_id_1}']",
             name_1
           )

    view
    |> form("#auix-product-form", %{
      "product[product_location_id]" => location_id_2
    })
    |> render_submit()

    assert has_element?(
             view,
             "select[id^='auix-field-product-product_location_id-'][id$='-form'] option[selected][value='#{location_id_2}']",
             name_2
           )
  end

  test "Test selector order by", %{conn: conn} do
    delete_all_inventory_data()

    location_id =
      20
      |> create_sample_product_locations(:many2)
      |> get_in(["id_1", Access.key!(:id)])

    product_id =
      1
      |> create_sample_products(:test, %{product_location_id: location_id})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, _view, html} =
      live(
        conn,
        "/association-many_to_one_selector-atom-products/#{product_id}/edit"
      )

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "select[id^='auix-field-product-product_location_id-'][id$='-form'] option"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
           |> Enum.filter(&String.starts_with?(&1, "test-name-many2-")) == @test_names
  end
end
