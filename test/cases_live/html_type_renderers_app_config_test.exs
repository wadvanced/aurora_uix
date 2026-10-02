defmodule Aurora.UixWeb.Test.HtmlTypeRenderersAppConfigTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:deleted, renderer: :default_checkbox)
  end

  auix_create_ui()

  setup do
    Application.put_env(:aurora_uix, :html_type_renderers, %{checkbox: :toggle_switch})
    on_exit(fn -> Application.delete_env(:aurora_uix, :html_type_renderers) end)

    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test, %{inactive: true})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    %{product_id: product_id}
  end

  test "index renders the configured checkbox renderer and keeps row selection", %{
    conn: conn,
    product_id: id
  } do
    {:ok, view, _html} = live(conn, "/html-type-renderers-app-config-products")

    assert has_element?(view, "input.auix-toggle-switch")
    assert has_element?(view, "input[type=checkbox][name='selected_check__#{id}']")
  end

  test "show and form render the configured checkbox renderer under the field slot", %{
    conn: conn,
    product_id: id
  } do
    {:ok, view, _html} = live(conn, "/html-type-renderers-app-config-products/#{id}/show")

    assert has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")
    assert has_element?(view, "input[type=checkbox][name='deleted']")

    {:ok, edit_view, _html} = live(conn, "/html-type-renderers-app-config-products/#{id}/edit")

    assert has_element?(
             edit_view,
             "input[type=checkbox][name='product[inactive]'].auix-toggle-switch"
           )
  end
end
