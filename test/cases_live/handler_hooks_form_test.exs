defmodule Aurora.Uix.Test.Web.HandlerHooksFormTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case
  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "handler-hooks-form-" do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])

    show_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end

    edit_layout :product, edit_handler_module: Aurora.Uix.Test.Web.FormHandlerHook do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/handler-hooks-form-products/new")

    reference =
      :nanosecond
      |> System.system_time()
      |> to_string()
      |> then(&"test-#{&1}")

    assert view
           |> element("div#auix-product-modal header")
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
end

defmodule Aurora.Uix.Test.Web.FormHandlerHook do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  alias Phoenix.LiveView.Socket

  @impl FormImpl
  @spec save_entity(map(), Socket.t()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def save_entity(%{assigns: %{action: :edit, auix: auix}}, _entity_params) do
    {:ok, auix.entity}
  end

  def save_entity(socket, entity_params), do: super(socket, entity_params)
end
