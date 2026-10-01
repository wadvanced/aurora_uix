defmodule Aurora.UixWeb.Test.SortableColumnsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Phoenix.LiveViewTest.View

  auix_resource_metadata :product, context: Inventory, schema: Product, order_by: :reference do
    field(:cost, sortable?: false)

    field(:image,
      sortable?: true,
      data: %{upload: %{allow: [accept: ~w(.png)], consume: &Function.identity/1}}
    )
  end

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name, :cost, :image, description: [sortable?: false]])
  end

  test "sortable columns carry a sort button, opted-out columns do not", %{conn: conn} do
    view = prepare_sort_test(conn)

    for key <- [:reference, :name],
        do: assert(has_element?(view, "th[aria-sort='none'] button[name='auix-sort-#{key}']"))

    for key <- [:cost, :description, :image, :selected_check__],
        do: refute(has_element?(view, "button[name='auix-sort-#{key}']"))
  end

  test "a header click sorts ascending, a second click descending", %{conn: conn} do
    view = conn |> prepare_sort_test() |> click_sort(:name)

    assert name_cells(view) == ["Alpha", "Bravo", "Charlie"]
    assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")

    click_sort(view, :name)

    assert name_cells(view) == ["Charlie", "Bravo", "Alpha"]
    assert has_element?(view, "th[aria-sort='descending'] button[name='auix-sort-name']")
  end

  test "sorting keeps the submitted filters", %{conn: conn} do
    view = prepare_sort_test(conn)

    view
    |> element("[name='auix-filter_toggle_open']")
    |> render_click()

    view
    |> set_filter_change(:filter_condition, :reference, :ge)
    |> set_filter_change(:filter_from, :reference, "item_srt_2")
    |> element("[name='auix-index-header-actions'] [name='auix-filters_submit-product']")
    |> render_click()

    view
    |> click_sort(:name)
    |> click_sort(:name)

    assert name_cells(view) == ["Bravo", "Alpha"]
  end

  test "the sort survives auix_route_back from the show modal", %{conn: conn} do
    view = conn |> prepare_sort_test() |> click_sort(:name)
    assert name_cells(view) == ["Alpha", "Bravo", "Charlie"]

    open_first_row_show(view)
    render_click(view, "auix_route_back", %{})

    assert "/sortable-columns-products?" <> _ = assert_patch(view)
    assert name_cells(view) == ["Alpha", "Bravo", "Charlie"]
    assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")
  end

  test "an opted-out or unknown key leaves the order unchanged", %{conn: conn} do
    view = prepare_sort_test(conn)

    render_click(view, "index-sort", %{"key" => "cost"})
    render_click(view, "index-sort", %{"key" => "image"})
    render_click(view, "index-sort", %{"key" => "not_a_column"})

    assert name_cells(view) == ["Charlie", "Alpha", "Bravo"]
    refute has_element?(view, "th[aria-sort='ascending']")
  end

  @spec prepare_sort_test(Plug.Conn.t()) :: View.t()
  defp prepare_sort_test(conn) do
    delete_all_inventory_data()
    create_sample_products(1, :srt_1, %{name: "Charlie"})
    create_sample_products(1, :srt_2, %{name: "Alpha"})
    create_sample_products(1, :srt_3, %{name: "Bravo"})

    {:ok, view, _html} = live(conn, "/sortable-columns-products")
    view
  end

  @spec click_sort(View.t(), atom()) :: View.t()
  defp click_sort(view, key) do
    view
    |> element("button[name='auix-sort-#{key}']")
    |> render_click()

    view
  end

  @spec name_cells(View.t()) :: list(binary())
  defp name_cells(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#auix-table-sortable-columns-products-index tr td:nth-of-type(3)")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end

  @spec open_first_row_show(View.t()) :: binary()
  defp open_first_row_show(view) do
    view
    |> element(
      "#auix-table-sortable-columns-products-index tr:first-child td:nth-child(2) a[name='auix-show-product']"
    )
    |> render_click()

    show_path = assert_patch(view)
    assert "/sortable-columns-products/" <> _ = show_path
    show_path
  end

  @spec set_filter_change(View.t(), atom(), atom(), atom() | binary()) :: View.t()
  defp set_filter_change(view, element, field, value) do
    render_change(view, "index-layout-change", %{
      "_target" => ["#{element}__#{field}"],
      "#{element}__#{field}" => "#{value}"
    })

    view
  end
end
