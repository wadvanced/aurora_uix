defmodule Aurora.UixWeb.Test.CompatibilityTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  use Aurora.Uix.CoreComponentsImporter

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  @path "/compatibility-products"

  @spec compat_form_footer(map()) :: Rendered.t()
  def compat_form_footer(assigns) do
    ~H"""
    <div name="compat-form-footer">
      <span name="compat-note">{@auix[:compat_note]}</span>
      <button type="button" name="compat-notify-form" phx-click="compat_notify" phx-target={@auix._myself}>Notify</button>
    </div>
    """
  end

  @spec compat_show_footer(map()) :: Rendered.t()
  def compat_show_footer(assigns) do
    ~H"""
    <div name="compat-show-footer">
      <button type="button" name="compat-back" phx-click="compat_back" phx-target={@auix._myself}>Back</button>
      <button type="button" name="compat-go" phx-click="compat_go" phx-target={@auix._myself}>Go</button>
    </div>
    """
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  auix_create_ui do
    index_columns(:product, [:reference, :name],
      handler_module: Aurora.UixWeb.Test.Compatibility.IndexHandler
    )

    edit_layout :product,
      edit_handler_module: Aurora.UixWeb.Test.Compatibility.FormHandler,
      add_footer_action: {:compat_form_footer, &__MODULE__.compat_form_footer/1} do
      stacked([:reference, :name, :description, :quantity_initial])
    end

    show_layout :product,
      show_handler_module: Aurora.UixWeb.Test.Compatibility.ShowHandler,
      add_footer_action: {:compat_show_footer, &__MODULE__.compat_show_footer/1} do
      stacked([:reference, :name, :description, :quantity_initial])
    end
  end

  setup do
    Process.register(self(), :auix_compat_probe)
    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(3, :test)
    %{id: product.id}
  end

  test "index callbacks run with super in the LiveView process", %{conn: conn, id: id} do
    {:ok, view, _} = live(conn, @path)
    pid = view.pid

    assert_receive {:compat, :auix_mount, ^pid}
    assert_receive {:compat, :auix_handle_params, ^pid}
    assert_receive {:compat, :apply_action, ^pid}
    assert has_element?(view, "tr[id^='products-#{id}']")
  end

  test "untargeted index events and async results reach the index handler", %{conn: conn} do
    {:ok, view, _} = live(conn, @path)
    pid = view.pid

    render_click(view, "compat_ping", %{})
    assert_receive {:compat, :auix_handle_event, ^pid}
    assert_receive {:compat, :auix_handle_async, ^pid}
    assert is_binary(render_click(view, "filter-toggle", %{}))
  end

  test "a targeted form event notifies the index through send(self())", %{conn: conn, id: id} do
    {:ok, view, _} = live(conn, "#{@path}/#{id}/edit")
    pid = view.pid

    view |> element("button[name='compat-notify-form']") |> render_click()
    assert_receive {:compat, {:form_event, "compat_notify"}, ^pid}
    assert_receive {:compat, {:auix_handle_info, :form}, ^pid}
  end

  test "custom auix keys survive later events and rejected fields are hidden", %{
    conn: conn,
    id: id
  } do
    {:ok, view, _} = live(conn, "#{@path}/#{id}/edit")

    assert has_element?(view, "[name='compat-note']", "kept")
    refute has_element?(view, "input[name='product[description]']")
    assert has_element?(view, "input[name='product[name]']")

    view |> element("button[name='compat-notify-form']") |> render_click()
    assert has_element?(view, "[name='compat-note']", "kept")
  end

  test "targeted show events route back and navigate", %{conn: conn, id: id} do
    {:ok, view, _} = live(conn, "#{@path}/#{id}/show")

    view |> element("button[name='compat-back']") |> render_click()
    assert assert_patch(view) =~ ~r"^/compatibility-products\?routing_stack="

    {:ok, remounted, _} = live(conn, "#{@path}/#{id}/show")

    {:error, {:live_redirect, %{to: to}}} =
      remounted |> element("button[name='compat-go']") |> render_click()

    assert to == "#{@path}/#{id}/edit"
  end

  test "a Phoenix update override runs before auix_update", %{conn: conn, id: id} do
    {:ok, view, _} = live(conn, "#{@path}/#{id}/edit")
    pid = view.pid

    render(view)
    {:messages, messages} = Process.info(self(), :messages)
    names = for {:compat, name, ^pid} <- messages, name in [:update, :auix_update], do: name

    assert Enum.take(names, 2) == [:update, :auix_update]
  end

  test "an unknown message is ignored through super", %{conn: conn, id: id} do
    {:ok, view, _} = live(conn, @path)

    send(view.pid, :compat_unknown)
    assert has_element?(view, "tr[id^='products-#{id}']")
  end
end
