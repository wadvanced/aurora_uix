defmodule Aurora.UixWeb.Test.FormDiscardGuardTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product do
      stacked([:reference, :name, :quantity_initial])
    end
  end

  @spec seed() :: binary()
  defp seed do
    delete_all_inventory_data()

    1
    |> create_sample_products(:test)
    |> get_in([Access.key!("id_test-1"), Access.key!(:id)])
  end

  @spec open_changed_edit(Plug.Conn.t()) :: {Phoenix.LiveViewTest.View.t(), binary()}
  defp open_changed_edit(conn) do
    id = seed()
    {:ok, view, _html} = live(conn, "/form-discard-guard-products/#{id}/edit")

    view
    |> form("#auix-product-form", product: %{name: "Changed name"})
    |> render_change()

    {view, id}
  end

  # The form component root is the only element carrying `data-phx-component`; the form id
  # itself is not a component root, so `with_target/2` cannot resolve it.
  @spec request_close(Phoenix.LiveViewTest.View.t(), atom()) :: term()
  defp request_close(view, live_action \\ :edit) do
    view
    |> with_target("#auix-product-#{live_action}-modal [data-phx-component]")
    |> render_click("auix_request_close", %{})
  end

  test "form modal cancel asks the form component; show modal routes back", %{conn: conn} do
    id = seed()
    {:ok, view, _html} = live(conn, "/form-discard-guard-products/#{id}/edit")

    assert has_element?(view, "#auix-product-edit-modal[data-cancel*='auix_request_close']")
    refute has_element?(view, "#auix-product-edit-modal[data-cancel*='phx-remove']")

    {:ok, show_view, _html} = live(conn, "/form-discard-guard-products/#{id}/show")
    assert has_element?(show_view, "#auix-product-show-modal[data-cancel*='auix_route_back']")
  end

  test "a clean form closes without a prompt", %{conn: conn} do
    id = seed()
    {:ok, view, _html} = live(conn, "/form-discard-guard-products/#{id}/edit")

    request_close(view)

    refute has_element?(view, "#auix-product-edit-modal")
    refute has_element?(view, "#auix-product-discard-confirm-modal")
  end

  test "a changed form opens the discard dialog", %{conn: conn} do
    {view, _id} = open_changed_edit(conn)

    request_close(view)

    assert has_element?(view, "#auix-product-edit-modal")

    assert has_element?(
             view,
             "#auix-product-discard-confirm-modal button[name='auix-keep-editing']"
           )

    assert has_element?(
             view,
             "#auix-product-discard-confirm-modal button[name='auix-discard-changes']"
           )
  end

  test "keep editing closes the dialog and keeps the changes", %{conn: conn} do
    {view, _id} = open_changed_edit(conn)
    request_close(view)

    view |> element("button[name='auix-keep-editing']") |> render_click()

    refute has_element?(view, "#auix-product-discard-confirm-modal")

    assert has_element?(
             view,
             "#auix-product-edit-modal input[name='product[name]'][value='Changed name']"
           )
  end

  test "discard changes closes the modal without saving", %{conn: conn} do
    {view, id} = open_changed_edit(conn)
    request_close(view)

    view |> element("button[name='auix-discard-changes']") |> render_click()

    refute has_element?(view, "#auix-product-edit-modal")
    assert Inventory.get_product!(id).name == "Item test-1"
  end

  test "a close request while the dialog is open keeps editing", %{conn: conn} do
    {view, _id} = open_changed_edit(conn)
    request_close(view)

    request_close(view)

    refute has_element?(view, "#auix-product-discard-confirm-modal")
    assert has_element?(view, "#auix-product-edit-modal")
  end

  test "a changed new form opens the discard dialog", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = live(conn, "/form-discard-guard-products/new")

    view
    |> form("#auix-product-form", product: %{name: "Brand new"})
    |> render_change()

    request_close(view, :new)

    assert has_element?(view, "#auix-product-new-modal")
    assert has_element?(view, "#auix-product-discard-confirm-modal")
  end

  test "a clean new form closes without a prompt", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = live(conn, "/form-discard-guard-products/new")

    request_close(view, :new)

    {path, _flash} = assert_redirect(view)
    assert String.starts_with?(path, "/form-discard-guard-products?")
  end
end
