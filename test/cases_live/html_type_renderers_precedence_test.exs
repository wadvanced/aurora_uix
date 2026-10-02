defmodule Aurora.UixWeb.Test.HtmlTypeRenderersPrecedenceTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case

  Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
  use Aurora.Uix, renderers: %{number: :progress_bar}

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers

  auix_resource_metadata :product,
    context: Inventory,
    schema: Product,
    renderers: %{text: :badge, number: :rating} do
    field(:deleted, show_renderer: :default_checkbox)
  end

  auix_create_ui renderers: %{
                   checkbox: :toggle_switch,
                   text: :default_text,
                   number: :not_a_renderer
                 } do
    index_columns(:product, [:reference, :inactive, :quantity_at_hand],
      renderers: %{checkbox: :default_checkbox}
    )
  end

  setup do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test, %{inactive: true, quantity_at_hand: Decimal.new(3)})
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    %{product_id: product_id}
  end

  test "show applies the precedence slot > ui > resource > module", %{conn: conn, product_id: id} do
    {:ok, view, _html} = live(conn, "/html-type-renderers-precedence-products/#{id}/show")

    assert has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")
    assert has_element?(view, "input[type=checkbox][name='deleted']")
    assert has_element?(view, "span.auix-rating")
    refute has_element?(view, "div.auix-progress")
    refute has_element?(view, "span.auix-badge")
  end

  test "an index_columns table beats auix_create_ui", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/html-type-renderers-precedence-products")

    refute has_element?(view, ".auix-toggle-switch")
    assert has_element?(view, "span.auix-rating")
  end

  test "a resource absent from the configurations resolves with no tables" do
    assert BasicHelpers.html_type_renderers(
             %{configurations: %{}, resource_name: :missing},
             :show
           ) == []
  end
end
