defmodule Aurora.UixWeb.Test.PreloadMetadataTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product do
    context Inventory
    schema(Product)
    preload([:product_location])
    where [{:reference, :between, "item_test-1", "item_test-2"}]
    field(:name, index_renderer: &__MODULE__.location_marker/1)
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name])
  end

  @doc false
  @spec location_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def location_marker(assigns) do
    ~H"""
    <span class="auix-location-marker">
      {if Ecto.assoc_loaded?(@entity.product_location), do: "LOADED", else: "NOT_LOADED"}
    </span>
    """
  end

  test "the resource preload loads an association the layout does not render", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(3, :test)

    {:ok, view, _html} = live(conn, "/preload-metadata-products")

    assert has_element?(view, "span.auix-location-marker", "LOADED")
    refute has_element?(view, "span.auix-location-marker", "NOT_LOADED")
  end

  test "the resource where filters the index", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(3, :test)

    {:ok, view, _html} = live(conn, "/preload-metadata-products")

    assert has_element?(view, "td", "item_test-1")
    assert has_element?(view, "td", "item_test-2")
    refute has_element?(view, "td", "item_test-3")
  end
end
