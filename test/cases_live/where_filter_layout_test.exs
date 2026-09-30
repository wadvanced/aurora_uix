defmodule Aurora.UixWeb.Test.WhereFilterLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Phoenix.LiveViewTest.View

  auix_resource_metadata(:product, context: Inventory, schema: Product, order_by: :reference)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui do
    index_columns(:product, [:reference, :name],
      where: [{:reference, :between, "item_group_2b", "item_group_3d"}]
    )
  end

  test "a submitted filter narrows the layout where instead of replacing it", %{conn: conn} do
    view = prepare_filters_test(conn)
    set_filter_change(view, :filter_condition, :reference, :ge)
    set_filter_change(view, :filter_from, :reference, "item_group_1a-2")

    assert submitted_row_count(view) == 5
  end

  test "the in-list condition passes a list to Ecto", %{conn: conn} do
    view = prepare_filters_test(conn)
    set_filter_change(view, :filter_condition, :reference, :in)

    set_filter_change(
      view,
      :filter_from,
      :reference,
      "item_group_1a-1,item_group_2b-1,item_group_3c-2"
    )

    assert submitted_row_count(view) == 2
  end

  test "submitting without a filter keeps the layout where", %{conn: conn} do
    view = prepare_filters_test(conn)

    assert submitted_row_count(view) == 5
  end

  test "submitted filters survive auix_route_back from the show modal", %{conn: conn} do
    view = prepare_filters_test(conn)
    set_filter_change(view, :filter_condition, :reference, :ge)
    set_filter_change(view, :filter_from, :reference, "item_group_3c-1")
    assert submitted_row_count(view) == 2
    open_first_row_show(view)

    render_click(view, "auix_route_back", %{})

    assert "/where-filter-layout-products?" <> _ = assert_patch(view)
    assert row_count(view) == 2
  end

  test "in-list entries are trimmed and empty entries dropped", %{conn: conn} do
    view = prepare_filters_test(conn)
    set_filter_change(view, :filter_condition, :reference, :in)
    set_filter_change(view, :filter_from, :reference, " item_group_2b-1 ,item_group_3c-1,")

    assert submitted_row_count(view) == 2
  end

  @spec prepare_filters_test(Plug.Conn.t()) :: View.t()
  defp prepare_filters_test(conn) do
    delete_all_inventory_data()
    create_sample_products(2, :group_1a)
    create_sample_products(3, :group_2b)
    create_sample_products(2, :group_3c)
    create_sample_products(4, :group_3d)

    {:ok, view, _html} = live(conn, "/where-filter-layout-products")

    view |> element("[name='auix-filter_toggle_open']") |> render_click()

    view
  end

  @spec set_filter_change(View.t(), atom(), atom(), atom() | binary()) :: View.t()
  defp set_filter_change(view, element, field, value) do
    render_change(view, "index-layout-change", %{
      "_target" => ["#{element}__#{field}"],
      "#{element}__#{field}" => "#{value}"
    })

    view
  end

  @spec row_count(View.t()) :: non_neg_integer()
  defp row_count(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#auix-table-where-filter-layout-products-index tr")
    |> Enum.count()
  end

  @spec submitted_row_count(View.t()) :: non_neg_integer()
  defp submitted_row_count(view) do
    view
    |> element("[name='auix-index-header-actions'] [name='auix-filters_submit-product']")
    |> render_click()

    row_count(view)
  end

  @spec open_first_row_show(View.t()) :: binary()
  defp open_first_row_show(view) do
    view
    |> element(
      "#auix-table-where-filter-layout-products-index tr:first-child td:nth-child(2) a[name='auix-show-product']"
    )
    |> render_click()

    show_path = assert_patch(view)
    assert "/where-filter-layout-products/" <> _ = show_path
    show_path
  end
end
