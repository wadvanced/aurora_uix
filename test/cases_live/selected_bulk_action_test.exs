defmodule Aurora.UixWeb.Test.SelectedBulkActionTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Phoenix.LiveView.Rendered

  @control "button[name='auix-selected-deactivate-product']"

  @spec deactivate_selected(map()) :: Rendered.t()
  def deactivate_selected(
        %{auix: %{selection: %{selected_count: count, toggle_all_mode: :none}}} = assigns
      )
      when count > 0 do
    ~H"""
    <.button
      type="button"
      class="auix-index-all-action-button"
      phx-click="deactivate_selected"
      name={"auix-selected-deactivate-#{@auix.module}"}
    >
      Deactivate selected
    </.button>
    """
  end

  def deactivate_selected(assigns), do: ~H""

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  auix_create_ui do
    index_columns(:product, [:reference, :name, :inactive],
      handler_module: Aurora.UixWeb.SelectedBulkActionIndexHandler,
      add_selected_action: {:deactivate_selected, &__MODULE__.deactivate_selected/1}
    )
  end

  setup do
    delete_all_inventory_data()

    %{"id_test-1" => first, "id_test-2" => second, "id_test-3" => third} =
      create_sample_products(3, :test, %{quantity_initial: Decimal.new(5)})

    %{products: [first, second, third]}
  end

  test "the control is hidden while nothing is selected", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/selected-bulk-action-products")

    refute has_element?(view, @control)
  end

  test "the control deactivates the ticked rows and clears the selection", %{
    conn: conn,
    products: [first, second, third]
  } do
    {:ok, view, _html} = live(conn, "/selected-bulk-action-products")
    select_row(view, first.id)
    select_row(view, second.id)

    assert has_element?(view, @control, "Deactivate selected")

    view |> element(@control) |> render_click()

    assert Inventory.get_product!(first.id).inactive
    assert Inventory.get_product!(second.id).inactive
    refute Inventory.get_product!(third.id).inactive
    assert has_element?(view, "#flash-info", "Products deactivated")
    refute has_element?(view, @control)
  end

  test "the control covers every row after Check all", %{conn: conn, products: products} do
    {:ok, view, _html} = live(conn, "/selected-bulk-action-products")

    view |> element("button[name='auix-selected_check_all-product']") |> render_click()
    render_async(view)

    view |> element(@control) |> render_click()

    assert Enum.all?(products, &Inventory.get_product!(&1.id).inactive)
  end

  @spec select_row(term(), term()) :: binary()
  defp select_row(view, id),
    do: render_change(view, "index-layout-change", %{"_target" => ["selected_check__#{id}"]})
end

defmodule Aurora.UixWeb.SelectedBulkActionIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Events
  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("deactivate_selected", _params, socket) do
    Enum.each(socket.assigns.auix.selection.selected, fn id ->
      id |> Inventory.get_product!() |> Inventory.update_product(%{inactive: true})
    end)

    Events.changed(Product)
    Events.reset_selection()

    {:noreply, put_flash(socket, :info, "Products deactivated")}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
