defmodule Aurora.UixWeb.Test.BrowserCreateUIDefaultLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  alias Wallaby.Query
  alias Wallaby.Session

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui()

  feature "Test new fallback ", %{session: session} do
    delete_all_inventory_data()
    create_sample_products(5, :test)

    session
    |> visit("/browser-create-ui-default-layout-products/new")
    |> assert_text("New Product")
    |> click(close_modal_button(:new))
    |> assert_current_path("/browser-create-ui-default-layout-products")
  end

  feature "Test show fallback ", %{session: session} do
    delete_all_inventory_data()

    product_id =
      5
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    session
    |> visit("/browser-create-ui-default-layout-products/#{product_id}/show")
    |> assert_text("Back to Products")
    |> click(close_modal_button(:show))
    |> assert_current_path("/browser-create-ui-default-layout-products")
  end

  feature "Test show-edit fallback ", %{session: session} do
    delete_all_inventory_data()

    product_id =
      5
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    session
    |> visit("/browser-create-ui-default-layout-products/#{product_id}/show-edit")
    |> assert_text("Edit Product")
    |> click(close_modal_button(:show_edit))
    |> assert_current_path("/browser-create-ui-default-layout-products")
  end

  feature "Test edit fallback ", %{session: session} do
    delete_all_inventory_data()

    product_id =
      5
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    session
    |> visit("/browser-create-ui-default-layout-products/#{product_id}/edit")
    |> assert_text("Edit Product")
    |> click(close_modal_button(:edit))
    |> assert_current_path("/browser-create-ui-default-layout-products")
  end

  @spec close_modal_button(atom()) :: Query.t()
  defp close_modal_button(type) do
    Query.css("#auix-product-#{type}-modal .auix-modal-close-button")
  end

  @spec assert_current_path(Session.t(), binary(), integer()) :: Session.t()
  defp assert_current_path(session, path, seconds \\ 3)

  defp assert_current_path(_session, path, 0), do: raise("Path: #{path} was not reached")

  defp assert_current_path(session, path, seconds) do
    Process.sleep(1000)
    if current_path(session) != path, do: assert_current_path(session, path, seconds - 1)
    session
  end
end
