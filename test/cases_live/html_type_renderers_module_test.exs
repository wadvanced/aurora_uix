defmodule Aurora.UixWeb.Test.HtmlTypeRenderersModuleTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case

  Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
  use Aurora.Uix, renderers: %{checkbox: :toggle_switch}

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui()

  setup do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test, %{inactive: true})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    %{product_id: product_id}
  end

  test "a module-level table renders every checkbox column and keeps row selection", %{
    conn: conn,
    product_id: id
  } do
    {:ok, view, _html} = live(conn, "/html-type-renderers-module-products")

    assert has_element?(view, "input.auix-toggle-switch")
    assert has_element?(view, "input[type=checkbox][name='selected_check__#{id}']")
  end

  test "a module-level table applies to show and form", %{conn: conn, product_id: id} do
    {:ok, view, _html} = live(conn, "/html-type-renderers-module-products/#{id}/show")

    assert has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")

    {:ok, edit_view, _html} = live(conn, "/html-type-renderers-module-products/#{id}/edit")

    assert has_element?(
             edit_view,
             "input[type=checkbox][name='product[inactive]'].auix-toggle-switch"
           )
  end
end
