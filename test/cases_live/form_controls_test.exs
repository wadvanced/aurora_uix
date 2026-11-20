defmodule Aurora.UixWeb.Test.FormControlsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    edit_layout :product do
      stacked([:reference, :name, :description, :quantity_initial])
    end

    show_layout :product do
      stacked([:reference, :name, :description])
    end
  end

  setup do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    %{product_id: product_id}
  end

  test "form inputs and show inputs carry the classes the theme targets", %{
    conn: conn,
    product_id: product_id
  } do
    {:ok, edit_view, _html} = live(conn, "/form-controls-products/#{product_id}/edit")

    assert has_element?(
             edit_view,
             ".auix-form-field-container input.auix-input[name='product[name]']"
           )

    {:ok, show_view, _html} = live(conn, "/form-controls-products/#{product_id}/show")

    assert has_element?(show_view, ".auix-show-content input.auix-input[disabled]")
  end

  test "a blank required field shows the error message", %{conn: conn, product_id: product_id} do
    {:ok, view, _html} = live(conn, "/form-controls-products/#{product_id}/edit")

    view
    |> form("#auix-product-form", product: %{name: ""})
    |> render_submit()

    assert has_element?(view, "#auix-product-form .auix-error-message")
  end
end
