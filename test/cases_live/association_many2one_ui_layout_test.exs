defmodule Aurora.UixWeb.AssociationMany2OneUILayoutTest do
  use Aurora.UixWeb, :aurora_uix_for_test
  use Aurora.UixWeb.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductLocation
  alias Aurora.Uix.Test.Inventory.ProductTransaction

  auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation do
    field(:products, omitted: true)
  end

  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "association-many_to_one-layout-") do
    edit_layout :product do
      stacked([
        :reference,
        :name,
        :description,
        :quantity_initial,
        :product_location_id,
        {:product_location, :name},
        product_location: :type
      ])
    end
  end

  test "Test many-to-one relationship UI workflow", %{conn: conn} do
    {:ok, view, html} = live(conn, "/association-many_to_one-layout-products")

    assert html =~ "Listing Products"

    {conn, view}
    |> create_new_product()
    |> validate_product_locations()
  end

  @spec create_new_product({Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp create_new_product({conn, view}) do
    assert view
           |> element("a[name='auix-new-product']")
           |> render_click() =~ "New Product"

    view
    |> form("#auix-product-form", %{
      "product[reference]" => "test-001",
      "product[name]" => "the product name",
      "product[quantity_initial]" => 14.45
    })
    |> render_submit()

    {conn, view}
  end

  @spec validate_product_locations({Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}) ::
          {Plug.Conn.t(), Phoenix.LiveViewTest.View.t()}
  defp validate_product_locations({conn, _view}) do
    delete_all_sample_data()

    location_id =
      1
      |> create_sample_product_locations()
      |> get_in([Access.key!("id_1"), Access.key!(:id)])

    product_id =
      1
      |> create_sample_products(:test, %{product_location_id: location_id})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, view, html} =
      live(conn, "/association-many_to_one-layout-products/#{product_id}/edit")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("[name='product[name]']")
           |> Enum.count() == 1

    refute has_element?(view, "div[id^='auix-field-product-product_location-'] h3", "Product")

    assert view
           |> element("input[id^='auix-field-product_location-name-'][id$='-show']")
           |> render() =~ "test-name-1"

    assert view
           |> element("input[id^='auix-field-product_location-type-'][id$='-show']")
           |> render() =~ "test-type-1"

    {conn, view}
  end
end
