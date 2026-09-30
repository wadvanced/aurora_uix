defmodule Aurora.UixWeb.Test.FormDiscardGuardDisabledTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product, unsaved_changes_guard_disabled?: true do
      stacked([:reference, :name, :quantity_initial])
    end
  end

  test "a changed form closes without a prompt when the guard is disabled", %{conn: conn} do
    delete_all_inventory_data()

    id =
      1
      |> create_sample_products(:test)
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, view, _html} = live(conn, "/form-discard-guard-disabled-products/#{id}/edit")

    view
    |> form("#auix-product-form", product: %{name: "Changed name"})
    |> render_change()

    view
    |> with_target("#auix-product-edit-modal [data-phx-component]")
    |> render_click("auix_request_close", %{})

    refute has_element?(view, "#auix-product-discard-confirm-modal")
    refute has_element?(view, "#auix-product-edit-modal")
  end
end
