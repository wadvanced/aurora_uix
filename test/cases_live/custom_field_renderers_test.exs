defmodule Aurora.UixWeb.Test.CustomFieldRenderersTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:reference, renderer: &__MODULE__.renderer/1)

    field(:name,
      index_renderer: &__MODULE__.index_marker/1,
      edit_renderer: &__MODULE__.edit_marker/1,
      show_renderer: &__MODULE__.show_marker/1
    )
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui()

  @doc false
  @spec renderer(map()) :: Phoenix.LiveView.Rendered.t()
  def renderer(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
    <span class="auix-generic-renderer">GENERIC:{@auix.form[@field.key].value}</span>
    """
  end

  def renderer(assigns) do
    ~H"""
    <span class="auix-generic-renderer">GENERIC:{Map.get(@auix.entity || %{}, @field.key)}</span>
    """
  end

  @doc false
  @spec index_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def index_marker(assigns) do
    ~H"""
    <span class="auix-index-marker">IDX:{Map.get(@entity, @field.key)}</span>
    """
  end

  @doc false
  @spec edit_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def edit_marker(assigns) do
    ~H"""
    <span class="auix-edit-marker">EDIT:{@auix.form[@field.key].value}</span>
    """
  end

  @doc false
  @spec show_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def show_marker(assigns) do
    ~H"""
    <span class="auix-show-marker">SHOW:{Map.get(@auix.entity || %{}, @field.key)}</span>
    """
  end

  describe "index layout" do
    test "uses index_renderer for the field it's set on, default rendering for others", %{
      conn: conn
    } do
      delete_all_inventory_data()
      create_sample_products(1, :test)

      {:ok, view, _html} = live(conn, "/custom-field-renderers-products")

      assert has_element?(view, "span.auix-index-marker", "IDX:Item test-1")
      assert has_element?(view, "td", "item_test-1")
      refute has_element?(view, "span.auix-generic-renderer")
    end
  end

  describe "show layout" do
    test "uses show_renderer for the field it's set on", %{conn: conn} do
      delete_all_inventory_data()

      product_id =
        1
        |> create_sample_products(:test)
        |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      {:ok, view, _html} = live(conn, "/custom-field-renderers-products/#{product_id}/show")

      assert has_element?(view, "span.auix-show-marker", "SHOW:Item test-1")
    end

    test "falls back to the generic renderer when show_renderer is not set but renderer is", %{
      conn: conn
    } do
      delete_all_inventory_data()

      product_id =
        1
        |> create_sample_products(:test)
        |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      {:ok, view, _html} = live(conn, "/custom-field-renderers-products/#{product_id}/show")

      assert has_element?(view, "span.auix-generic-renderer", "GENERIC:item_test-1")
    end
  end

  describe "form (edit) layout" do
    test "uses edit_renderer for the field it's set on", %{conn: conn} do
      delete_all_inventory_data()

      product_id =
        1
        |> create_sample_products(:test)
        |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      {:ok, view, _html} = live(conn, "/custom-field-renderers-products/#{product_id}/edit")

      assert has_element?(view, "span.auix-edit-marker", "EDIT:Item test-1")
    end

    test "falls back to the generic renderer when edit_renderer is not set but renderer is", %{
      conn: conn
    } do
      delete_all_inventory_data()

      product_id =
        1
        |> create_sample_products(:test)
        |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      {:ok, view, _html} = live(conn, "/custom-field-renderers-products/#{product_id}/edit")

      assert has_element?(view, "span.auix-generic-renderer", "GENERIC:item_test-1")
    end
  end

  describe "regression: default rendering unaffected" do
    test "fields without any custom renderer still render with default input/display", %{
      conn: conn
    } do
      delete_all_inventory_data()

      product_id =
        1
        |> create_sample_products(:test)
        |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      {:ok, view, _html} = live(conn, "/custom-field-renderers-products/#{product_id}/edit")

      assert has_element?(view, "input[name='product[quantity_initial]']")
    end
  end
end

defmodule Aurora.UixWeb.Test.CustomFieldRenderersIndexColumnsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product,
      reference: [label: "ZZZ_CustomRef"],
      name: [index_renderer: &__MODULE__.index_marker/1]
    )
  end

  @doc false
  @spec index_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def index_marker(assigns) do
    ~H"""
    <span class="auix-index-cols-marker">COL:{Map.get(@entity, @field.key)}</span>
    """
  end

  test "index_columns keyword-list threads index_renderer and other opts into the column", %{
    conn: conn
  } do
    delete_all_inventory_data()
    create_sample_products(1, :test)

    {:ok, view, html} = live(conn, "/custom-field-renderers-index-columns-products")

    # index_renderer applied to the :name column
    assert has_element?(view, "span.auix-index-cols-marker", "COL:Item test-1")
    assert has_element?(view, "td", "item_test-1")
    # a plain per-column option (:label) threads through the same path
    assert html =~ "ZZZ_CustomRef"
  end
end

defmodule Aurora.UixWeb.Test.InlineFieldOptsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product do
      inline(reference: [readonly: true], name: [])
    end
  end

  test "per-field opts set inside an inline layout list take effect", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test)
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, view, _html} = live(conn, "/inline-field-opts-products/#{product_id}/edit")

    assert has_element?(view, "input[name='product[reference]'][readonly]")
  end
end
