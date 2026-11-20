defmodule Aurora.UixWeb.Test.FlashKindsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name],
      handler_module: Aurora.UixWeb.FlashKindsHandlerHook
    )
  end

  test "success and warning flashes render with their class and icon", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/flash-kinds-products")

    render_click(view, "flash_kinds", %{})

    assert has_element?(view, "#flash-success.auix-flash--success", "Saved")
    assert has_element?(view, "#flash-success .hero-check-circle-mini")
    assert has_element?(view, "#flash-warning.auix-flash--warning", "Check")
    assert has_element?(view, "#flash-warning .hero-exclamation-triangle-mini")
  end

  test "no success or warning flash renders without a message", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/flash-kinds-products")

    refute has_element?(view, "#flash-success")
    refute has_element?(view, "#flash-warning")
  end
end

defmodule Aurora.UixWeb.FlashKindsHandlerHook do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("flash_kinds", _params, socket) do
    {:noreply, socket |> put_flash(:success, "Saved") |> put_flash(:warning, "Check")}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
