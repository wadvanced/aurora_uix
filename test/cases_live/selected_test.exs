defmodule Aurora.UixWeb.Test.SelectedTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "selected-") do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_initial])
  end

  test "Test select / deselect all", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(35, :test)

    {:ok, view, _html} = live(conn, "/selected-products")

    assert view
           |> selected_states()
           |> Enum.all?(&(!&1))

    # Test check all button
    view
    |> element("button[name='auix-selected_check_all-product']")
    |> render_click()

    assert view
           |> selected_states()
           |> Enum.all?(& &1)

    assert has_element?(view, "#auix-delete-all-button-product>button", "Delete selected")

    # Test uncheck all button
    view
    |> element("button[name='auix-selected-uncheck_all-product']")
    |> render_click()

    assert view
           |> selected_states()
           |> Enum.all?(&(!&1))
  end

  test "Test delete_all selected", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(35, :test)

    {:ok, view, _html} = live(conn, "/selected-products")

    assert view
           |> selected_states()
           |> Enum.all?(&(!&1))

    # Check all
    view
    |> element("button[name='auix-selected_check_all-product']")
    |> render_click()

    render_async(view, 1000)

    # Lets delete them
    view
    |> element("#auix-delete-all-button-product>button")
    |> render_click()

    view
    |> element(
      "#auix-delete-all-button-product-modal-content button.auix-confirm-button--accept-action"
    )
    |> render_click()

    assert view
           |> selected_states()
           |> Enum.count() == 0
  end

  @spec selected_states(map()) :: [boolean()]
  defp selected_states(view) do
    view
    |> render_async(1000)
    |> LazyHTML.from_document()
    |> LazyHTML.query("table tbody tr td input[type='checkbox']")
    |> LazyHTML.attribute("name")
    |> Enum.map(fn name ->
      if has_element?(view, "table tbody tr td input[name='#{name}'][type='checkbox'][checked]") do
        true
      else
        false
      end
    end)
  end
end
