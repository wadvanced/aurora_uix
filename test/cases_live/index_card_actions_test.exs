defmodule Aurora.UixWeb.Test.IndexCardActionsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Phoenix.LiveView.Rendered

  @spec archive_action(map()) :: Rendered.t()
  def archive_action(assigns) do
    ~H"""
    <a href="#" name="auix-archive-product">A</a>
    """
  end

  @spec copy_action(map()) :: Rendered.t()
  def copy_action(assigns) do
    ~H"""
    <a href="#" name="auix-copy-product">C</a>
    """
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name],
      insert_row_action: {:archive, &__MODULE__.archive_action/1, destructive?: true},
      add_row_action: {:copy, &__MODULE__.copy_action/1}
    )
  end

  test "extra row actions move into the menu", %{conn: conn} do
    m = "#auix-table-index-card-actions-products-index-mobile"
    delete_all_inventory_data()
    create_sample_products(1, :test)
    {:ok, view, _html} = live(conn, "/index-card-actions-products")

    assert has_element?(
             view,
             "#{m} [name='auix-card-actions-leading'] a[name='auix-archive-product']"
           )

    assert has_element?(
             view,
             "#{m} [name='auix-card-actions-trailing'] > .auix-items-card-action a[name='auix-show-product']"
           )

    assert has_element?(
             view,
             "#{m} [name='auix-card-actions-trailing'] > .auix-items-card-action a[name='auix-edit-product']"
           )

    assert has_element?(view, "#{m} [name='auix-card-menu-list'] a[name='auix-delete-product']")
    assert has_element?(view, "#{m} [name='auix-card-menu-list'] a[name='auix-copy-product']")

    assert has_element?(
             view,
             "#{m} button[name='auix-card-menu-toggle'][aria-label='More actions'][aria-expanded='false']"
           )
  end
end
