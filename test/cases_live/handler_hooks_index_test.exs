defmodule Aurora.Uix.Test.Web.HandlerHooksIndexTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "handler-hooks-index-" do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand],
      handler_module: Aurora.Uix.Test.Web.IndexHandlerHook
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
    delete_all_sample_data()
    create_sample_products(20, :test)
    {:ok, _view, html} = live(conn, "/handler-hooks-index-products")

    refute html =~ "item_test-06"
  end
end

defmodule Aurora.Uix.Test.Web.IndexHandlerHook do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, %{assigns: %{auix: auix}} = socket) do
    {:ok,
     stream(
       socket,
       auix.source_key,
       auix.list_function.(where: {:reference, :lt, "item_test-06"})
     )}
  end

  @impl IndexImpl
  def apply_action(socket, params) do
    super(socket, params)
  end
end
