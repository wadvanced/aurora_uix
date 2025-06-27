defmodule Aurora.Uix.Test.Web.AssociationMany2OneSelectorAssignsTest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product
    alias Aurora.Uix.Test.Inventory.ProductLocation
    alias Aurora.Uix.Test.Inventory.ProductTransaction

    @spec option_label(map(), term()) :: binary()
    def option_label(assigns, entity), do: "#{assigns._auix._mode}: #{entity.name}"

    auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation do
      field(:products, omitted: true)
    end

    auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction) do
      field(:product, option_label: :name)
    end

    auix_resource_metadata(:product, context: Inventory, schema: Product) do
      field(:product_location_id, option_label: &TestModule.option_label/2)
    end

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(link_prefix: "association-many_to_one_selector-assigns-") do
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
  end

  test "check_listing", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/association-many_to_one_selector-assigns-products"
      )

    assert html =~ "Listing Products"
  end

  test "check_show", %{conn: conn} do
    locations = create_sample_product_locations(5)
    location_id = get_in(locations, ["id_1", Access.key!(:id)])

    product_id =
      1
      |> create_sample_products(:test, %{product_location_id: location_id})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, view, html} =
      live(
        conn,
        "/association-many_to_one_selector-assigns-products/#{product_id}"
      )

    assert html =~ "Product Details"

    assert has_element?(
             view,
             "select[id^='auix-field-product-product_location_id-'][id$='-show'] option[selected][value='#{location_id}']"
           )
  end

  test "check_edit", %{conn: conn} do
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
        "/association-many_to_one_selector-assigns-products/#{product_id}/edit"
      )

    assert html =~ "Edit Product"

    assert has_element?(
             view,
             "select[id^='auix-field-product-product_location_id-'][id$='-form'] option[selected][value=#{location_id_1}]",
             "form: #{name_1}"
           )

    view
    |> form("#auix-product-form", %{
      "product[product_location_id]" => location_id_2
    })
    |> render_submit()

    assert has_element?(
             view,
             "select[id^='auix-field-product-product_location_id-'][id$='-form'] option[selected][value='#{location_id_2}']",
             "form: #{name_2}"
           )
  end
end
