defmodule Aurora.UixWeb.Test.ActionIconsIndexTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  @spec delete_icon(map()) :: binary()
  def delete_icon(_assigns), do: "hero-x-mark"

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  auix_create_ui do
    index_columns(:product, [:reference, :name],
      action_icons: [
        default_row_show: "★",
        default_row_edit: "/images/edit.svg",
        default_row_delete: &__MODULE__.delete_icon/1,
        default_selected_delete_all: "hero-archive-box-x-mark"
      ]
    )
  end

  setup %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(3, :test)
    {:ok, view, _html} = live(conn, "/action-icons-index-products")
    %{view: view}
  end

  test "default actions show their default icon and keep their label", %{view: view} do
    assert has_element?(
             view,
             "a[name='auix-new-product'][title='New Product'][aria-label='New Product'] span.auix-action-icon span.hero-plus"
           )

    assert has_element?(view, "a[name='auix-new-product'] span.auix-action-label", "New Product")

    assert has_element?(
             view,
             "button[name='auix-selected_check_all-product'][title='Check all'] span.auix-action-icon span.hero-check-circle"
           )
  end

  test "action_icons replaces the icon of the row actions", %{view: view} do
    assert has_element?(view, "a[name='auix-show-product'] span.auix-action-icon-text", "★")

    assert has_element?(
             view,
             "a[name='auix-edit-product'] img.auix-action-icon-image[src='/images/edit.svg']"
           )

    assert has_element?(view, "a[name='auix-delete-product'] span.hero-x-mark")
    refute has_element?(view, "a[name='auix-delete-product'] span.hero-trash")
  end

  test "Delete selected keeps its badge with an overridden icon", %{view: view} do
    view |> element("button[name='auix-selected_check_all-product']") |> render_click()

    assert has_element?(
             view,
             "#auix-delete-all-button-product>button[title='Delete selected'] span.hero-archive-box-x-mark"
           )

    assert has_element?(view, "#auix-delete-all-button-product>button span.auix-button-badge")
  end
end
