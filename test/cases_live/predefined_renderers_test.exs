# Predefined renderers gallery.
#
# These modules double as a visual gallery: the routes are mounted, so you can eyeball
# every predefined renderer in a browser. Start the test server and open the routes:
#
#     MIX_ENV=test iex --dot-iex "test/start_test_server.exs" -S mix
#
#   * http://localhost:4001/predefined-renderers-products              (toggle_switch, badge,
#     …/new, …/:id/show, …/:id/edit                                     colour, progress_bar, url)
#   * http://localhost:4001/predefined-renderers-interactive-products  (rating)
#
# Note: the index layout reads only the `index_renderer` slot, so each gallery field sets
# the renderer atom in both `renderer:` (show + form) and `index_renderer:` (index) to
# appear across all three layouts.
#
# Create a record with the "New" form (or `Aurora.Uix.Test.Helper.create_sample_products/3`
# in the iex session) and compare the widgets across the index, show and edit layouts.

defmodule Aurora.UixWeb.Test.PredefinedRenderersTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:inactive,
      renderer: :toggle_switch,
      index_renderer: :toggle_switch,
      label: "Toggle switch"
    )

    field(:status, renderer: :badge, index_renderer: :badge, label: "Badge")
    field(:reference, renderer: :color, index_renderer: :color, label: "Colour")

    field(:quantity_at_hand,
      renderer: :progress_bar,
      index_renderer: :progress_bar,
      data: %{max: 100},
      label: "Progress bar"
    )

    field(:description, renderer: :url, index_renderer: :url, label: "URL")
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui()

  @spec seed(map()) :: binary()
  defp seed(attrs) do
    delete_all_inventory_data()

    1
    |> create_sample_products(:test, attrs)
    |> get_in([Access.key!("id_test-1"), Access.key!(:id)])
  end

  describe "index layout" do
    test "renders every renderer's read-only widget", %{conn: conn} do
      seed(%{inactive: true, status: "shipped", quantity_at_hand: Decimal.new(50)})

      {:ok, view, _html} = live(conn, "/predefined-renderers-products")

      assert has_element?(view, "input[type=checkbox][disabled][checked].auix-toggle-switch")
      assert has_element?(view, "span.auix-badge", "shipped")
      assert has_element?(view, "span.auix-color[style*='background-color']")
      assert has_element?(view, "div.auix-progress .auix-progress-bar")
      assert has_element?(view, "div.auix-progress .auix-progress-label", "50%")
      # :url renders as plain text in :index — no clickable link competing with row navigation.
      refute has_element?(view, "a.auix-url")
    end
  end

  describe "show layout" do
    test "renders every renderer's read-only widget", %{conn: conn} do
      product_id = seed(%{inactive: false, status: "in_stock", quantity_at_hand: Decimal.new(50)})

      {:ok, view, _html} = live(conn, "/predefined-renderers-products/#{product_id}/show")

      assert has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")
      refute has_element?(view, "input[type=checkbox][disabled][checked].auix-toggle-switch")
      assert has_element?(view, "span.auix-badge", "in_stock")
      assert has_element?(view, "span.auix-color", "item_test-1")
      assert has_element?(view, ".auix-show-field .auix-label", "Progress bar")
      assert has_element?(view, "div.auix-progress .auix-progress-label", "50%")
      assert has_element?(view, ".auix-show-field .auix-label", "URL")
      assert has_element?(view, "a.auix-url")
    end
  end

  describe "form (edit) layout" do
    test "renders the interactive widgets and falls back for read-only renderers", %{conn: conn} do
      product_id = seed(%{inactive: true})

      {:ok, view, _html} = live(conn, "/predefined-renderers-products/#{product_id}/edit")

      # Interactive renderers with an edit form.
      assert has_element?(view, "input[type=checkbox].auix-toggle-switch")
      assert has_element?(view, "input[type=color]")

      # Read-only renderers (:badge, :progress_bar, :url) delegate the form layout to the
      # default input — a badge/bar/link would never be an input.
      assert has_element?(view, "[name='product[status]']")
      assert has_element?(view, "[name='product[quantity_at_hand]']")
      assert has_element?(view, "[name='product[description]']")
    end
  end
end

defmodule Aurora.UixWeb.Test.PredefinedRenderersInteractiveTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:cost, renderer: :rating, index_renderer: :rating, data: %{max: 5}, label: "Rating")
  end

  auix_create_ui()

  @spec seed(map()) :: binary()
  defp seed(attrs) do
    delete_all_inventory_data()

    1
    |> create_sample_products(:test, attrs)
    |> get_in([Access.key!("id_test-1"), Access.key!(:id)])
  end

  describe "index layout" do
    test "renders rating read-only", %{conn: conn} do
      seed(%{cost: Decimal.new(3)})

      {:ok, view, _html} = live(conn, "/predefined-renderers-interactive-products")

      assert has_element?(view, "span.auix-rating .auix-rating-star--on")
    end
  end

  describe "show layout" do
    test "renders rating read-only", %{conn: conn} do
      product_id = seed(%{cost: Decimal.new(3)})

      {:ok, view, _html} =
        live(conn, "/predefined-renderers-interactive-products/#{product_id}/show")

      assert has_element?(view, "span.auix-rating .auix-rating-star--on")
      assert has_element?(view, ".auix-show-field .auix-label", "Rating")
    end
  end

  describe "form (edit) layout" do
    test "renders the interactive rating widget", %{conn: conn} do
      product_id = seed(%{cost: Decimal.new(3)})

      {:ok, view, _html} =
        live(conn, "/predefined-renderers-interactive-products/#{product_id}/edit")

      assert has_element?(view, "input[type=radio].auix-rating-radio[value='3']")
      assert has_element?(view, "input[type=radio].auix-rating-radio[value='3'][checked]")
    end
  end
end

defmodule Aurora.UixWeb.Test.PredefinedRenderers.HostToggle do
  @moduledoc false
  use Aurora.Uix.Renderer

  @impl Aurora.Uix.Renderer
  def render(assigns) do
    assigns = assign(assigns, :value, display_value(assigns))

    ~H"""
    <span class="auix-host-toggle">HOST:{@value}</span>
    """
  end
end

defmodule Aurora.UixWeb.Test.PredefinedRenderers.HostRegistrar do
  @moduledoc false
  @behaviour Aurora.Uix.RendererRegistrar

  alias Aurora.UixWeb.Test.PredefinedRenderers.HostToggle

  @impl Aurora.Uix.RendererRegistrar
  def renderers, do: %{toggle_switch: &HostToggle.render/1}
end

defmodule Aurora.UixWeb.Test.PredefinedRenderersResolverTest do
  # async: false — this test mutates the global :aurora_uix, :renderers config.
  use ExUnit.Case, async: false

  alias Aurora.Uix.Field
  alias Aurora.Uix.Renderers
  alias Aurora.Uix.Templates.Basic.Renderers.DefaultRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.Predefined
  alias Aurora.UixWeb.Test.PredefinedRenderers.HostRegistrar
  alias Aurora.UixWeb.Test.PredefinedRenderers.HostToggle

  test "resolves a slot atom to its render function for show and form" do
    field = %Field{renderer: :toggle_switch}

    assert Renderers.resolve(field, :show) == (&Predefined.ToggleSwitch.render/1)
    assert Renderers.resolve(field, :form) == (&Predefined.ToggleSwitch.render/1)
  end

  test "index uses only index_renderer, never the generic renderer" do
    field = %Field{renderer: :toggle_switch, index_renderer: :badge}

    assert Renderers.resolve(field, :index) == (&Predefined.Badge.render/1)
    # generic `renderer` does not span index:
    assert Renderers.resolve(%Field{renderer: :toggle_switch}, :index) ==
             (&DefaultRenderer.render/1)
  end

  test "an unknown atom or an empty slot falls back to the default renderer" do
    assert Renderers.resolve(%Field{renderer: :not_a_renderer}, :show) ==
             (&DefaultRenderer.render/1)

    assert Renderers.resolve(%Field{}, :show) == (&DefaultRenderer.render/1)
  end

  test "a host registrar overrides a built-in and keeps the others" do
    Application.put_env(:aurora_uix, :renderers, HostRegistrar)
    on_exit(fn -> Application.delete_env(:aurora_uix, :renderers) end)

    assert Renderers.resolve(%Field{renderer: :toggle_switch}, :show) == (&HostToggle.render/1)
    assert Renderers.resolve(%Field{renderer: :badge}, :show) == (&Predefined.Badge.render/1)
  end
end
