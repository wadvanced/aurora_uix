defmodule Aurora.UixWeb.Test.HandlerHooksIndexTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand],
      handler_module: Aurora.UixWeb.IndexHandlerHook
    )

    edit_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end

    show_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test index hooks", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(20, :test)
    {:ok, _view, html} = live(conn, "/handler-hooks-index-products")

    refute html =~ "item_test-06"
  end

  test "auix_mount and auix_handle_params overrides keep their auix keys", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/handler-hooks-index-products?filter=abc")

    render_click(view, "hooks_report", %{})
    assert has_element?(view, "#flash-info", "mount=mounted filter=abc")
  end

  test "an async task started by a custom event reaches auix_handle_async", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/handler-hooks-index-products")

    render_click(view, "hooks_async", %{})
    render_async(view)
    assert has_element?(view, "#flash-info", "async done")
  end

  test "a form save reaches auix_handle_info in the index", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(1, :test)
    {:ok, view, _html} = live(conn, "/handler-hooks-index-products/#{product.id}/edit")

    view
    |> form("#auix-product-form", product: %{name: "Renamed", quantity_initial: 11})
    |> render_submit()

    render_click(view, "hooks_report", %{})
    assert has_element?(view, "#flash-info", "saved=Renamed")
  end
end

defmodule Aurora.UixWeb.IndexHandlerHook do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(params, session, %{assigns: %{auix: auix}} = socket) do
    new_socket =
      auix.layout_tree
      |> Map.put(:where, {:reference, :lt, "item_test-06"})
      |> then(&assign_auix(socket, :layout_tree, &1))

    super(params, session, new_socket)
  end

  @impl IndexImpl
  def apply_action(socket, params) do
    super(socket, params)
  end

  @impl IndexImpl
  def auix_mount(params, session, socket) do
    super(params, session, assign_auix(socket, :hooks_mount, "mounted"))
  end

  @impl IndexImpl
  def auix_handle_params(params, url, socket) do
    super(params, url, assign_auix(socket, :hooks_filter, Map.get(params, "filter")))
  end

  @impl IndexImpl
  def auix_handle_event("hooks_report", _params, %{assigns: %{auix: auix}} = socket) do
    saved = Map.get(auix, :hooks_saved)
    report = "mount=#{auix.hooks_mount} filter=#{auix.hooks_filter} saved=#{saved}"

    {:noreply, put_flash(socket, :info, report)}
  end

  def auix_handle_event("hooks_async", _params, socket) do
    {:noreply, start_async(socket, :hooks_async, fn -> "async done" end)}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)

  @impl IndexImpl
  def auix_handle_async(:hooks_async, {:ok, message}, socket) do
    {:noreply, put_flash(socket, :info, message)}
  end

  def auix_handle_async(task, result, socket), do: super(task, result, socket)

  @impl IndexImpl
  def auix_handle_info({_component, {:saved, entity}} = message, socket) do
    super(message, assign_auix(socket, :hooks_saved, entity.name))
  end

  def auix_handle_info(message, socket), do: super(message, socket)
end
