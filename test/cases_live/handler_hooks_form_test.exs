defmodule Aurora.UixWeb.Test.HandlerHooksFormTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  use Aurora.Uix.CoreComponentsImporter
  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  @spec hooks_footer_action(map()) :: Rendered.t()
  def hooks_footer_action(assigns) do
    ~H"""
    <button type="button" name="hooks-hide-description" phx-click="hooks_hide_description" phx-target={@auix._myself}>
      Hide description
    </button>
    """
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])

    show_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end

    edit_layout :product,
      edit_handler_module: Aurora.UixWeb.FormHandlerHook,
      add_footer_action: {:hooks_hide_description, &__MODULE__.hooks_footer_action/1} do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = live(conn, "/handler-hooks-form-products/new")

    reference =
      :nanosecond
      |> System.system_time()
      |> to_string()
      |> then(&"test-#{&1}")

    assert view
           |> element("div#auix-product-new-modal header")
           |> render() =~ "New Product"

    view
    |> form("#auix-product-form",
      product: %{reference: reference, name: "This is the first test", quantity_initial: 11}
    )
    |> render_submit()

    {:ok, _view, new_html} = live(conn, "/handler-hooks-form-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ reference
  end

  test "Test main edit link", %{conn: conn} do
    delete_all_inventory_data()

    product =
      1
      |> create_sample_products(:test)
      |> Map.get("id_test-1")

    unique_name =
      :nanosecond
      |> System.system_time()
      |> to_string()
      |> then(&"name-#{&1}")

    {:ok, view, _html} = live(conn, "/handler-hooks-form-products")

    view
    |> element(
      "tr[id^='products'] a[name='auix-edit-product'][phx-value-route_path$='#{product.id}/edit']"
    )
    |> render_click()
    |> tap(&assert &1 =~ "auix-save-product")

    view
    |> form("#auix-product-form",
      product: %{name: unique_name, quantity_initial: 11}
    )
    |> render_submit()

    refute product.id
           |> Inventory.get_product()
           |> Map.get(:name) == unique_name

    assert product.id
           |> Inventory.get_product()
           |> Map.get(:name) == product.name
  end

  test "update and auix_update overrides hide their fields", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(1, :test)
    {:ok, view, _html} = live(conn, "/handler-hooks-form-products/#{product.id}/edit")

    refute has_element?(view, "[name='product[rrp]']")
    refute has_element?(view, "[name='product[list_price]']")
    assert has_element?(view, "[name='product[description]']")
  end

  test "a targeted custom event reaches the form handler", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(1, :test)
    {:ok, view, _html} = live(conn, "/handler-hooks-form-products/#{product.id}/edit")

    view |> element("button[name='hooks-hide-description']") |> render_click()

    refute has_element?(view, "[name='product[description]']")
    refute has_element?(view, "[name='product[rrp]']")
    refute has_element?(view, "[name='product[list_price]']")
    assert has_element?(view, "[name='product[name]']")
  end

  test "a built-in form event falls through to super", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(1, :test)
    {:ok, view, _html} = live(conn, "/handler-hooks-form-products/#{product.id}/edit")

    view
    |> with_target("#auix-product-edit-modal [data-phx-component]")
    |> render_click("auix_request_close", %{})

    patched_uri = view |> assert_patch() |> URI.parse()
    assert patched_uri.path == "/handler-hooks-form-products"
  end
end

defmodule Aurora.UixWeb.FormHandlerHook do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3]

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  alias Phoenix.LiveView.Socket

  @impl FormImpl
  @spec save_entity(map(), Socket.t()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def save_entity(%{assigns: %{action: :edit, auix: auix}}, _entity_params) do
    {:ok, auix.entity}
  end

  def save_entity(socket, entity_params), do: super(socket, entity_params)

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, socket} = super(assigns, socket)
    rejected = [:list_price | socket.assigns.auix.fields_to_reject]

    {:ok, assign_auix(socket, :fields_to_reject, rejected)}
  end

  @impl FormImpl
  def auix_update(assigns, socket) do
    {:ok, socket} = super(assigns, socket)

    {:ok, assign_auix(socket, :fields_to_reject, [:rrp])}
  end

  @impl FormImpl
  def auix_handle_event("hooks_hide_description", _params, %{assigns: %{auix: auix}} = socket) do
    {:noreply, assign_auix(socket, :fields_to_reject, [:description | auix.fields_to_reject])}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
