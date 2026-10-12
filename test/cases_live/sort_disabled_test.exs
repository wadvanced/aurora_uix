defmodule Aurora.UixWeb.Test.SortDisabledTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Phoenix.LiveViewTest.View

  auix_resource_metadata(:product, context: Inventory, schema: Product, order_by: :reference)

  auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation do
    field(:reference, sortable?: false)
    field(:name, sortable?: false)
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name], sort_disabled?: true)
    index_columns(:product_location, [:reference, :name])
  end

  test "sort_disabled? removes every column sort button", %{conn: conn} do
    view = prepare_sort_test(conn)

    refute has_element?(view, "button[name^='auix-sort-']")
    refute has_element?(view, "th[aria-sort]")
  end

  test "a forged index-sort event is ignored when sorting is disabled", %{conn: conn} do
    view = prepare_sort_test(conn)
    render_click(view, "index-sort", %{"key" => "name"})
    render_click(view, "index-sort", %{"sort" => "name"})
    render_click(view, "index-sort-direction", %{})

    assert name_cells(view) == ["Charlie", "Alpha", "Bravo"]
    refute has_element?(view, "th[aria-sort]")
  end

  test "sort_disabled? removes the card sort control", %{conn: conn} do
    view = prepare_sort_test(conn)

    refute has_element?(view, "#auix-sort-form-product")
    refute has_element?(view, "[name='auix-sort_action-product']")
  end

  test "an index without sortable fields renders no card sort control", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/sort-disabled-product-locations")

    refute has_element?(view, "[name='auix-sort_action-product_location']")
  end

  @spec prepare_sort_test(Plug.Conn.t()) :: View.t()
  defp prepare_sort_test(conn) do
    delete_all_inventory_data()
    create_sample_products(1, :srt_1, %{name: "Charlie"})
    create_sample_products(1, :srt_2, %{name: "Alpha"})
    create_sample_products(1, :srt_3, %{name: "Bravo"})

    {:ok, view, _html} = live(conn, "/sort-disabled-products")
    view
  end

  @spec name_cells(View.t()) :: list(binary())
  defp name_cells(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#auix-table-sort-disabled-products-index tr td:nth-of-type(3)")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
