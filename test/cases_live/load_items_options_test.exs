defmodule Aurora.UixWeb.Test.LoadItemsOptionsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product do
    context Inventory
    schema Product
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns :product, [:id, :reference, :name],
      handler_module: Aurora.UixWeb.LoadItemsOptionsHandler
  end

  setup %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(20, :test)
    {:ok, view, html} = live(conn, "/load-items-options-products")

    %{view: view, html: html}
  end

  test "a runtime where in load_items_options applies from the next sort", %{
    view: view,
    html: html
  } do
    assert html =~ "item_test-15"

    html = view |> element("button[name='auix-sort-name']") |> render_click()

    assert html =~ "item_test-05"
    refute html =~ "item_test-15"
  end
end

defmodule Aurora.UixWeb.LoadItemsOptionsHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  @spec mount(map(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)

    load_items_options =
      Keyword.put(socket.assigns.auix.load_items_options, :where, [
        {:reference, :lt, "item_test-06"}
      ])

    {:ok, assign_auix(socket, :load_items_options, load_items_options)}
  end
end
