defmodule Aurora.UixWeb.Test.ActionIconsFormShowTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  auix_create_ui do
    edit_layout :product, action_icons: [default_save: "hero-bolt"] do
      inline([:reference, :name])
    end

    show_layout :product, action_icons: [default_back: "←"] do
      inline([:reference, :name])
    end
  end

  setup do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test)
      |> get_in(["id_test-1", Access.key!(:id)])

    %{product_id: product_id}
  end

  test "the save action shows its icon and keeps its label", %{conn: conn, product_id: id} do
    {:ok, view, _html} = live(conn, "/action-icons-form-show-products/#{id}/edit")

    assert has_element?(
             view,
             "button[name='auix-save-product'][title='Save Product'][aria-label='Save Product'] span.auix-action-icon span.hero-bolt"
           )

    assert has_element?(
             view,
             "button[name='auix-save-product'] span.auix-action-label",
             "Save Product"
           )
  end

  test "the edit and back actions show their icons and keep their labels", %{
    conn: conn,
    product_id: id
  } do
    {:ok, view, _html} = live(conn, "/action-icons-form-show-products/#{id}/show")

    assert has_element?(
             view,
             "a[name='auix-edit-product'][title='Edit Product'] span.auix-action-icon span.hero-pencil"
           )

    assert has_element?(
             view,
             "div[name='auix-show-navigate-back'] a[title='Back to Products'] span.auix-action-icon-text",
             "←"
           )

    assert has_element?(
             view,
             "div[name='auix-show-navigate-back'] a span.auix-action-label",
             "Back to Products"
           )
  end
end
