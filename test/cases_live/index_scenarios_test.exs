defmodule Aurora.UixWeb.Test.IndexScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Layout.Options.Index
  alias Aurora.Uix.Repo
  alias Aurora.Uix.Selection
  alias Aurora.Uix.Templates.Basic.Actions
  alias Aurora.Uix.Templates.Basic.CoreComponents
  alias Aurora.Uix.Templates.Basic.Handlers.IndexList
  alias Aurora.Uix.Test.MirrorCtx
  alias Aurora.UixWeb.Test.NavigationHelper
  alias Phoenix.LiveViewTest.View

  @shuffled_references ~w(test_order-11 test_order-03 test_order-20 test_order-08 test_order-14
                          test_order-05 test_order-19 test_order-17 test_order-02 test_order-10
                          test_order-16 test_order-07 test_order-12 test_order-09 test_order-18
                          test_order-04 test_order-13 test_order-06 test_order-01 test_order-15)

  @spec name_icon(map()) :: binary()
  def name_icon(%{auix: %{name: name}}), do: "hero-#{name}"

  test "the table shows one cell per field type", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_1" => location} = create_sample_product_locations(2, :test)

      create_sample_products(5, :test, fn index ->
        %{
          product_location_id: location.id,
          status: "discontinued",
          grade: :premium,
          labels: [:fragile, :hazardous],
          inactive: index == 1
        }
      end)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))
      t = table(backend, "index", "products")

      assert has_element?(view, ".auix-header-title", "Listing Products")
      assert has_element?(view, ".auix-index-container")
      assert has_element?(view, ".auix-items-table")
      assert has_element?(view, ".auix-items-table-header")
      assert count(view, "#{t} .auix-items-table-row") == 5
      assert has_element?(view, ".auix-items-card-container")

      cells = texts(view, "#{t} tr:first-child td")

      assert Enum.at(cells, 1) == "item_test-1"
      assert Enum.at(cells, 3) == "123.010000"
      assert Enum.at(cells, 7) == "true"
      assert Enum.at(cells, 9) == "Fragile, Hazardous"
      assert has_element?(view, "[name='auix-show-product']", "Fragile, Hazardous")

      # A many-to-one cell renders `option_label` of the related record, as the form select does.
      # A single select renders the label of the selected option: declared opts
      # (`status`), and the opts each backend derives from an enum (`grade`: `Ecto.Enum` on ctx, an
      # `:atom` with `one_of` on Ash).
      assert Enum.at(cells, 5) == "test-name-test-1"
      assert Enum.at(cells, 6) == "Discontinued"
      assert Enum.at(cells, 10) == "Premium"
    end)
  end

  test "column headers sort, reverse and return to the backend order", %{conn: conn} do
    each_backend(fn backend ->
      seed_sort_products()

      view = mount_index(conn, backend)

      for key <- [:reference, :name],
          do: assert(has_element?(view, "th[aria-sort='none'] button[name='auix-sort-#{key}']"))

      for key <- [:cost, :description, :image, :selected_check__],
          do: refute(has_element?(view, "button[name='auix-sort-#{key}']"))

      view = conn |> mount_index(backend) |> click_sort(:name)

      assert name_cells(view, backend) == ["Alpha", "Bravo", "Charlie"]
      assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")

      click_sort(view, :name)

      assert name_cells(view, backend) == ["Charlie", "Bravo", "Alpha"]
      assert has_element?(view, "th[aria-sort='descending'] button[name='auix-sort-name']")

      click_sort(view, :name)

      assert name_cells(view, backend) == ["Charlie", "Alpha", "Bravo"]
      assert has_element?(view, "th[aria-sort='none'] button[name='auix-sort-name']")

      view = mount_index(conn, backend)

      render_click(view, "index-sort", %{"key" => "cost"})
      render_click(view, "index-sort", %{"key" => "image"})
      render_click(view, "index-sort", %{"key" => "not_a_column"})

      assert name_cells(view, backend) == ["Charlie", "Alpha", "Bravo"]
      refute has_element?(view, "th[aria-sort='ascending']")
    end)
  end

  test "the sort survives a submitted filter and the return from the show modal", %{conn: conn} do
    each_backend(fn backend ->
      seed_sort_products()

      view = mount_index(conn, backend)
      open_filters(view)

      view
      |> set_filter_change(:filter_condition, :reference, :ge)
      |> set_filter_change(:filter_from, :reference, "item_srt_2")
      |> submit_filters("product")

      view
      |> click_sort(:name)
      |> click_sort(:name)

      assert name_cells(view, backend) == ["Bravo", "Alpha"]

      view = conn |> mount_index(backend) |> click_sort(:name)
      assert name_cells(view, backend) == ["Alpha", "Bravo", "Charlie"]

      view
      |> element(
        "#{table(backend, "index", "products")} tr:first-child td:nth-child(2) a[name='auix-show-product']"
      )
      |> render_click()

      assert view
             |> assert_patch()
             |> String.starts_with?(mirror_path(backend, "index", "products", "/"))

      render_click(view, "auix_route_back", %{})

      assert view
             |> assert_patch()
             |> String.starts_with?(mirror_path(backend, "index", "products", "?"))

      assert name_cells(view, backend) == ["Alpha", "Bravo", "Charlie"]
      assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")
    end)
  end

  test "the card sort select and the card sort menu sort, reverse and clear", %{conn: conn} do
    each_backend(fn backend ->
      seed_sort_products()
      m = "[name='auix-sort_action-product']"

      view = mount_index(conn, backend)

      for value <- ["", "reference", "name"],
          do:
            assert(
              has_element?(
                view,
                "#auix-sort-form-product select[name='sort'] option[value='#{value}']"
              )
            )

      for value <- ["cost", "description", "image", "selected_check__"],
          do: refute(has_element?(view, "#auix-sort-form-product option[value='#{value}']"))

      assert has_element?(view, "button[name='auix-sort_direction-product'][disabled]")

      view = conn |> mount_index(backend) |> select_sort("name")

      assert mobile_name_cells(view, backend) == ["Alpha", "Bravo", "Charlie"]
      assert has_element?(view, "#auix-sort-form-product option[value='name'][selected]")
      assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")

      assert has_element?(
               view,
               "button[name='auix-sort_direction-product'] span.hero-chevron-up"
             )

      view |> element("button[name='auix-sort_direction-product']") |> render_click()

      assert mobile_name_cells(view, backend) == ["Charlie", "Bravo", "Alpha"]
      assert has_element?(view, "th[aria-sort='descending'] button[name='auix-sort-name']")

      assert has_element?(
               view,
               "button[name='auix-sort_direction-product'] span.hero-chevron-down"
             )

      select_sort(view, "")

      assert mobile_name_cells(view, backend) == ["Charlie", "Alpha", "Bravo"]
      assert has_element?(view, "button[name='auix-sort_direction-product'][disabled]")

      view = mount_index(conn, backend)

      assert has_element?(view, "#{m} .auix-index-sort-select #auix-sort-form-product")

      assert has_element?(
               view,
               "#{m} .auix-index-sort-select > button.auix-index-sort-select-direction[name='auix-sort_direction-product']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-sort_menu'] > button.auix-index-sort-menu-toggle[name='auix-sort_menu_toggle'][title='Sort'][aria-label='Sort'][aria-haspopup='menu'][aria-expanded='false'] span.hero-arrows-up-down"
             )

      refute has_element?(view, "#{m} .auix-index-sort-menu-toggle--active")

      assert has_element?(
               view,
               ~s(#{m} [name='auix-sort_menu'][phx-click*='"toggle_attr"'][phx-click*='"focus_first"'])
             )

      refute has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click*='"toggle"']))
      assert has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click-away*='"set_attr"']))
      refute has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click-away*='"hide"']))

      assert has_element?(
               view,
               "#{m} [name='auix-sort_menu_list'][role='menu'] button[name='auix-sort_menu_default'][role='menuitemradio'][aria-checked='true']",
               "Default order"
             )

      refute has_element?(
               view,
               "#{m} button[name='auix-sort_menu_default'] .auix-index-sort-menu-check--off"
             )

      for {key, label} <- [{"reference", "Reference"}, {"name", "Name"}] do
        option =
          "#{m} button[name='auix-sort_menu_field-#{key}'][role='menuitemradio'][aria-checked='false']"

        assert has_element?(view, option, label)
        assert has_element?(view, "#{option} span.hero-check.auix-index-sort-menu-check--off")
      end

      for key <- ["cost", "description", "image", "selected_check__"],
          do: refute(has_element?(view, "#{m} button[name='auix-sort_menu_field-#{key}']"))

      for {direction, label} <- [{"asc", "Ascending"}, {"desc", "Descending"}] do
        assert has_element?(
                 view,
                 "#{m} button[name='auix-sort_menu_direction-#{direction}'][role='menuitemradio'][aria-checked='false'][disabled]",
                 label
               )
      end

      click_sort_menu(view, "auix-sort_menu_field-name")

      assert mobile_name_cells(view, backend) == ["Alpha", "Bravo", "Charlie"]

      assert has_element?(
               view,
               "#{m} button[name='auix-sort_menu_toggle'].auix-index-sort-menu-toggle.auix-index-sort-menu-toggle--active"
             )

      assert has_element?(
               view,
               "#{m} button[name='auix-sort_menu_field-name'][aria-checked='true']"
             )

      assert has_element?(
               view,
               "#{m} button[name='auix-sort_menu_default'][aria-checked='false']"
             )

      assert has_element?(
               view,
               "#{m} button[name='auix-sort_menu_direction-asc'][aria-checked='true']"
             )

      click_sort_menu(view, "auix-sort_menu_direction-desc")

      assert mobile_name_cells(view, backend) == ["Charlie", "Bravo", "Alpha"]

      assert has_element?(
               view,
               "#{m} button[name='auix-sort_menu_direction-desc'][aria-checked='true']"
             )

      assert has_element?(
               view,
               "#{m} button[name='auix-sort_menu_direction-asc'][aria-checked='false']"
             )

      click_sort_menu(view, "auix-sort_menu_direction-desc")

      assert mobile_name_cells(view, backend) == ["Charlie", "Bravo", "Alpha"]

      click_sort_menu(view, "auix-sort_menu_default")

      assert mobile_name_cells(view, backend) == ["Charlie", "Alpha", "Bravo"]
      refute has_element?(view, "#{m} .auix-index-sort-menu-toggle--active")
      assert has_element?(view, "#{m} button[name='auix-sort_menu_direction-asc'][disabled]")

      view = mount_index(conn, backend)

      render_click(view, "index-sort-direction", %{"direction" => "desc"})

      assert mobile_name_cells(view, backend) == ["Charlie", "Alpha", "Bravo"]

      click_sort_menu(view, "auix-sort_menu_field-name")
      render_click(view, "index-sort-direction", %{"direction" => "sideways"})

      assert mobile_name_cells(view, backend) == ["Alpha", "Bravo", "Charlie"]
    end)
  end

  test "sort_disabled? and an index without sortable fields render no sort control and ignore sort events",
       %{conn: conn} do
    each_backend(fn backend ->
      seed_sort_products()
      create_sample_products_with_suppliers(1, 3)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "suppliers"))

      refute has_element?(view, "button[name^='auix-sort-']")
      refute has_element?(view, "th[aria-sort]")
      refute has_element?(view, "#auix-sort-form-supplier")
      refute has_element?(view, "[name='auix-sort_action-supplier']")
      refute has_element?(view, "[name='auix-sort_menu']")

      names_selector = "#{table(backend, "index", "suppliers")} tr td:nth-of-type(2)"
      names = texts(view, names_selector)

      render_click(view, "index-sort", %{"key" => "name"})
      render_click(view, "index-sort", %{"sort" => "name"})
      render_click(view, "index-sort-direction", %{})
      render_click(view, "index-sort-direction", %{"direction" => "desc"})

      assert texts(view, names_selector) == names
      refute has_element?(view, "th[aria-sort]")

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "product_locations"))

      refute has_element?(view, "[name='auix-sort_action-product_location']")
    end)
  end

  test "order_by comes from the metadata, and the layout overrides it", %{conn: conn} do
    each_backend(fn backend ->
      references = create_shuffled_products(@shuffled_references)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))

      assert texts(view, "#{table(backend, "index", "products")} tr td:nth-of-type(2)") ==
               Enum.sort(references)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-query", "products"))

      assert texts(view, "#{table(backend, "index-query", "products")} tr td:nth-of-type(4)") ==
               Enum.map(1..20, &"Item test_order-#{String.pad_leading("#{&1}", 2, "0")}")
    end)
  end

  test "a runtime where in load_items_options applies from the next sort", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products(20, :test)
      {:ok, view, _html} = live(conn, mirror_path(backend, "index-query", "products"))
      names = "#{table(backend, "index-query", "products")} tr td:nth-of-type(4)"

      assert has_element?(view, names, "Item test-15")

      click_sort(view, :name)

      assert texts(view, names) == Enum.map(1..5, &"Item test-0#{&1}")
      refute has_element?(view, names, "Item test-15")
    end)
  end

  test "the filter bar filters by each condition", %{conn: conn} do
    each_backend(fn backend ->
      locations = seed_filter_products()

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))

      refute has_element?(view, "[name='auix-filters_submit-product']")
      refute has_element?(view, "[name='auix-filters_clear-product']")

      open_filters(view)

      assert has_element?(view, "[name='auix-filters_submit-product']")
      assert has_element?(view, "[name='auix-filters_clear-product']")
      assert has_element?(view, ".auix-filter-card")

      view = mount_filters(conn, backend)
      set_filter_change(view, :filter_condition, :name, :eq)
      set_filter_change(view, :filter_from, :name, "Item group_3d-1")

      assert has_element?(view, "input[name='filter_from__name'][value='Item group_3d-1']")
      assert submitted_row_count(view, backend) == 1

      view = mount_filters(conn, backend)
      set_filter_change(view, :filter_condition, :name, :ge)
      set_filter_change(view, :filter_from, :name, "Item group_3d-2")

      assert has_element?(view, "input[name='filter_from__name'][value='Item group_3d-2']")
      assert submitted_row_count(view, backend) == 3

      view = mount_filters(conn, backend)
      set_filter_change(view, :filter_condition, :name, :between)
      set_filter_change(view, :filter_from, :name, "Item group_2b")
      set_filter_change(view, :filter_to, :name, "Item group_3d")

      assert has_element?(view, "input[name='filter_to__name'][value='Item group_3d']")
      assert submitted_row_count(view, backend) == 18

      view = mount_filters(conn, backend)
      location = locations["id_3"]
      set_filter_change(view, :filter_condition, :product_location_id, :eq)
      set_filter_change(view, :filter_from, :product_location_id, location.id)

      assert has_element?(
               view,
               "select[name='filter_from__product_location_id'] option[selected][value='#{location.id}']",
               location.name
             )

      assert submitted_row_count(view, backend) == 7

      view = mount_filters(conn, backend)
      set_filter_change(view, :filter_condition, :name, :contains)

      for value <- ["3d-", "3D-"] do
        set_filter_change(view, :filter_from, :name, value)
        assert submitted_row_count(view, backend) == 4
      end

      for value <- ["%", "a_1"] do
        set_filter_change(view, :filter_from, :name, value)
        assert submitted_row_count(view, backend) == 0
      end

      set_filter_change(view, :filter_from, :name, "")

      assert has_element?(view, "[name='filter_to__name'][readonly][disabled]")
      assert submitted_row_count(view, backend) == 27

      for field <- [:product_location_id, :quantity_at_hand, :inactive] do
        refute has_element?(
                 view,
                 "select[name='filter_condition__#{field}'] option[value='contains']"
               )
      end

      view = mount_filters(conn, backend)
      set_filter_change(view, :filter_condition, :name, :eq)
      set_filter_change(view, :filter_from, :name, "Item group_9z-1")

      assert submitted_row_count(view, backend) == 0
      assert has_element?(view, "div.auix-items-table-empty")
    end)
  end

  test "a layout where narrows with the submitted filters", %{conn: conn} do
    assert IndexList.where_conditions(nil) == []
    assert IndexList.where_conditions([{:a, 1}]) == [{:a, 1}]
    assert IndexList.where_conditions(%{a: 1}) == [a: 1]
    assert IndexList.where_conditions({:a, :lt, 2}) == [{:a, :lt, 2}]

    each_backend(fn backend ->
      create_sample_products(2, :group_1a)
      create_sample_products(3, :group_2b)
      create_sample_products(2, :group_3c)
      create_sample_products(4, :group_3d)
      t = table(backend, "index-where", "products")

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-where", "products"))

      assert texts(view, "#{t} tr td:nth-of-type(3)") == [
               "Item group_2b-1",
               "Item group_2b-2",
               "Item group_2b-3",
               "Item group_3c-1",
               "Item group_3c-2"
             ]

      view = mount_where_filters(conn, backend)
      set_filter_change(view, :filter_condition, :reference, :ge)
      set_filter_change(view, :filter_from, :reference, "item_group_1a-2")

      assert submitted_where_count(view, backend) == 5

      view = mount_where_filters(conn, backend)
      set_filter_change(view, :filter_condition, :reference, :in)

      set_filter_change(
        view,
        :filter_from,
        :reference,
        "item_group_1a-1,item_group_2b-1,item_group_3c-2"
      )

      assert submitted_where_count(view, backend) == 2

      view = mount_where_filters(conn, backend)

      assert submitted_where_count(view, backend) == 5

      view = mount_where_filters(conn, backend)
      set_filter_change(view, :filter_condition, :reference, :in)
      set_filter_change(view, :filter_from, :reference, " item_group_2b-1 ,item_group_3c-1,")

      assert submitted_where_count(view, backend) == 2

      view = mount_where_filters(conn, backend)
      set_filter_change(view, :filter_condition, :reference, :ge)
      set_filter_change(view, :filter_from, :reference, "item_group_3c-1")
      assert submitted_where_count(view, backend) == 2

      view
      |> element("#{t} tr:first-child td:nth-child(2) a[name='auix-show-product']")
      |> render_click()

      assert view
             |> assert_patch()
             |> String.starts_with?(mirror_path(backend, "index-where", "products", "/"))

      render_click(view, "auix_route_back", %{})

      assert view
             |> assert_patch()
             |> String.starts_with?(mirror_path(backend, "index-where", "products", "?"))

      assert count(view, "#{t} tr") == 2
    end)
  end

  test "the pages bar pages through the rows", %{conn: conn} do
    assert IndexList.previous_page(%{page: 1}) == 1
    assert IndexList.previous_page(%{page: 3}) == 2
    assert IndexList.next_page(%{page: 3, pages_count: 3}) == 3
    assert IndexList.next_page(%{page: 2, pages_count: 3}) == 3

    each_backend(fn backend ->
      create_sample_products(100, :test)
      t = table(backend, "index-query", "products")
      pages = "div[name='auix-pages_bar-products-md'] [name^='auix-pages_bar_page-']"

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-query", "products"))

      assert has_element?(view, "div[name='auix-pages_bar-products']")
      assert has_element?(view, ".auix-pagination-container")

      assert has_element?(
               view,
               ".auix-index-container > [name='auix-index-footer-actions'] > .auix-pagination-container"
             )

      assert has_element?(
               view,
               ".auix-index-container > form .auix-items-desktop > .auix-items-table-container"
             )

      assert count(view, "#{t} tr") == 40
      assert texts(view, pages) == ["1", "2", "3", ""]

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "index-query", "products", "?page=2"))

      assert texts(view, pages) == ["", "1", "2", "3", ""]
      assert count(view, "#{t} tr") == 40

      view
      |> element("div[name='auix-pages_bar-products-md'] a[name='auix-pages_bar_page-3']")
      |> render_click()

      assert texts(view, pages) == ["", "1", "2", "3"]
      assert count(view, "#{t} tr") == 20

      delete_all_mirror_data()
      create_sample_products(5, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-query", "products"))

      refute has_element?(view, "div[name='auix-pages_bar-products']")
      refute has_element?(view, ".auix-pagination-container")
      assert has_element?(view, ".auix-items-table-container")
    end)
  end

  test "the index list handles only its own events" do
    assert IndexList.events() == [
             "filter-toggle",
             "filters-clear",
             "filters-submit",
             "index-sort",
             "index-sort-direction",
             "index-layout-change",
             "selected-toggle_all",
             "selected-cancel_toggle_all",
             "selected-delete_all"
           ]

    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, auix: %{}}}

    assert_raise FunctionClauseError, fn -> IndexList.handle_event("delete", %{}, socket) end
  end

  test "infinite scroll loads the first batch without a pages bar", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_product_locations(Index.default_infinity_scroll_items_load() + 10, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-query", "product_locations"))

      refute has_element?(view, "div[name='auix-pages_bar-product_locations']")

      assert count(view, "#{table(backend, "index-query", "product_locations")} tr") ==
               Index.default_infinity_scroll_items_load()
    end)
  end

  test "rows are selected and deselected, one by one and all at once", %{conn: conn} do
    selection =
      Enum.reduce(
        [{"a", 1}, {"b", 2}, {"c", 2}],
        Selection.new(),
        fn {id, page}, acc -> Selection.set_selected(id, acc, true, page) end
      )

    result = Selection.unselect(selection, ["a", "b"])

    assert result.selected == MapSet.new(["c"])
    assert result.selected_in_page == %{1 => MapSet.new(), 2 => MapSet.new(["c"])}

    each_backend(fn backend ->
      create_sample_products(35, :test)

      checked =
        "tr.auix-items-table-row > td.auix-items-table-cell:first-child input.auix-checkbox[checked]"

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))

      assert view |> selected_states() |> Enum.all?(&(!&1))
      refute has_element?(view, checked)

      view |> element("button[name='auix-selected_check_all-product']") |> render_click()

      assert view |> selected_states() |> Enum.all?(& &1)
      assert has_element?(view, checked)

      assert has_element?(
               view,
               "#{table(backend, "index", "products")}-mobile .auix-items-card-item-content > .auix-items-card-item-group > .auix-items-card-select input.auix-checkbox[checked]"
             )

      assert has_element?(view, "#auix-delete-all-button-product>button", "Delete selected")

      view |> element("button[name='auix-selected-uncheck_all-product']") |> render_click()

      assert view |> selected_states() |> Enum.all?(&(!&1))
    end)
  end

  test "delete selected removes the ticked rows", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products(35, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))

      assert view |> selected_states() |> Enum.all?(&(!&1))

      view |> element("button[name='auix-selected_check_all-product']") |> render_click()
      render_async(view, 1000)

      view |> element("#auix-delete-all-button-product>button") |> render_click()

      view
      |> element(
        "#auix-delete-all-button-product-modal-content button.auix-confirm-button--accept-action"
      )
      |> render_click()

      assert view |> selected_states() |> Enum.count() == 0
    end)
  end

  test "a custom bulk action runs on the selection", %{conn: conn} do
    control = "button[name='auix-selected-deactivate-product']"

    each_backend(fn backend ->
      [first, second, third] = seed_bulk_products()

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-actions", "products"))

      refute has_element?(view, control)

      select_row(view, first.id)
      select_row(view, second.id)

      assert has_element?(view, control, "Deactivate selected")

      view |> element(control) |> render_click()

      assert MirrorCtx.get_product!(first.id).inactive
      assert MirrorCtx.get_product!(second.id).inactive
      refute MirrorCtx.get_product!(third.id).inactive
      assert has_element?(view, "#flash-info", "Products deactivated")
      refute has_element?(view, control)

      delete_all_mirror_data()
      products = seed_bulk_products()

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-actions", "products"))

      view |> element("button[name='auix-selected_check_all-product']") |> render_click()
      render_async(view)

      view |> element(control) |> render_click()

      assert Enum.all?(products, &MirrorCtx.get_product!(&1.id).inactive)
    end)
  end

  test "a card has a header, a body and labelled rows", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products(3, :test)
      m = "#{table(backend, "index", "products")}-mobile"

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))

      assert has_element?(view, ".auix-items-card-container")
      assert has_element?(view, "#{m} .auix-items-card-title", "item_test-1")

      assert has_element?(
               view,
               "#{m} [name='auix-card'] .auix-items-card-select input[type='checkbox']"
             )

      assert has_element?(view, "#{m} [name='auix-card-title']", "item_test-1")

      for label <- ["Name", "Quantity At Hand"] do
        assert has_element?(
                 view,
                 "#{m} [name='auix-card-body'] .auix-items-card-item-fieldset .auix-items-card-item-label",
                 label
               )
      end

      assert has_element?(
               view,
               "#{m} [name='auix-card-body'] [name='auix-column-value']",
               "Item test-1"
             )

      delete_all_mirror_data()

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))

      refute has_element?(view, "#{m} [name='auix-card']")

      assert has_element?(
               view,
               "[name='auix-items-card'] .auix-items-card-empty",
               "No items to show"
             )
    end)
  end

  test "a declared card renders its title, subtitle and body", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products(3, :test)
      m = "#{table(backend, "index-cards", "products")}-mobile"

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-cards", "products"))

      assert has_element?(
               view,
               "#{m} [name='auix-card-title'] a[name='auix-show-product']",
               "Item test-1"
             )

      assert has_element?(view, "#{m} [name='auix-card-subtitle']", "item_test-1")

      assert has_element?(
               view,
               "#{m} [name='auix-card-body'] .auix-group-container .auix-group-title",
               "Stock"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-body'] .auix-items-card-item-label",
               "On hand"
             )

      refute has_element?(view, "#{m} .auix-items-card-item-label", "Description")

      assert has_element?(
               view,
               "[name='auix-items-table'] th[name='auix-column-label']",
               "Quantity At Hand"
             )

      assert has_element?(view, ".auix-items-mobile [name='auix-items-card']")
      refute has_element?(view, ".auix-index-sort-action--always")
    end)
  end

  test "show_on: :all shows the cards alone", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products_with_transactions(1, 3, :test)
      m = "#{table(backend, "index-cards", "product_transactions")}-mobile"

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-cards", "product_transactions"))

      assert has_element?(view, "#{m} [name='auix-card-title']", "#")
      assert has_element?(view, "#{m} [name='auix-card-subtitle']", "Transaction")
      refute has_element?(view, "[name='auix-items-table']")
      assert has_element?(view, ".auix-items-cards [name='auix-items-card']")
      assert has_element?(view, ".auix-index-sort-action.auix-index-sort-action--always")
      assert has_element?(view, "#auix-sort-form-product_transaction option[value='cost']")

      assert has_element?(
               view,
               "#{m} [name='auix-card-body'] .auix-items-card-item-label",
               "Quantity"
             )

      refute has_element?(
               view,
               "#{m} [name='auix-card-body'] .auix-items-card-item-label",
               "Product"
             )
    end)
  end

  test "the card menu opens, lists the row actions in order, and a tap runs the show action",
       %{conn: conn} do
    each_backend(fn backend ->
      products = create_sample_products(3, :test)
      m = "#{table(backend, "index", "products")}-mobile"
      menu = "#{m} [name='auix-card-menu']"

      {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))

      assert has_element?(view, "#{m} .auix-items-card-menu")
      refute has_element?(view, "#{m} [name='auix-card-actions']")

      assert has_element?(
               view,
               "#{m} [name='auix-card'] > .auix-items-card-item-group > .auix-items-card-select + .auix-items-card-heading + [name='auix-card-menu']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-actions'] > .auix-items-card-menu-item:nth-child(1) a.auix-index-row-action[name='auix-show-product'][title='Show'][aria-label='Show']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-actions'] > .auix-items-card-menu-item:nth-child(2) a.auix-index-row-action[name='auix-edit-product'][title='Edit'][aria-label='Edit']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-destructive'] a.auix-index-row-action[name='auix-delete-product'][title='Delete'][aria-label='Delete']"
             )

      assert has_element?(
               view,
               "#{menu} > button.auix-items-card-menu-toggle[name='auix-card-menu-toggle'][aria-expanded='false']"
             )

      assert has_element?(
               view,
               ~s(#{menu}[phx-click*='"toggle_attr"'][phx-click*='"focus_first"'])
             )

      refute has_element?(view, ~s(#{menu}[phx-click*='"toggle"']))
      assert has_element?(view, ~s(#{menu}[phx-click-away*='"set_attr"']))
      refute has_element?(view, ~s(#{menu}[phx-click-away*='"hide"']))

      id = products["id_test-1"].id

      assert has_element?(
               view,
               "#{m} [name='auix-card'] > [name='auix-card-show']:first-child > a.auix-index-row-action[name='auix-show-product'][title='Show'][aria-label='Show']"
             )

      view
      |> element("#{m} [name='auix-card-show'] a[phx-value-route_path$='/#{id}/show']")
      |> render_click()

      {path, _query, _stack} = view |> assert_patch() |> NavigationHelper.decode_route()
      assert path == mirror_path(backend, "index", "products", "/#{id}/show")

      create_sample_product_locations(1, :test)
      m = "#{table(backend, "index-actions", "product_locations")}-mobile"

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "index-actions", "product_locations"))

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-actions'] > .auix-items-card-menu-item:nth-child(1) a[name='auix-edit-product_location']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-actions'] > .auix-items-card-menu-item:nth-child(2) a[name='auix-copy-product_location']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-destructive'] > .auix-items-card-menu-item:nth-child(1) a[name='auix-archive-product_location']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-destructive'] > .auix-items-card-menu-item:nth-child(2) a[name='auix-delete-product_location']"
             )

      refute has_element?(view, "#{m} [name='auix-card-show']")

      refute has_element?(
               view,
               "#{m} [name='auix-card-menu-list'] a[name='auix-show-product_location']"
             )

      refute has_element?(
               view,
               "#{m} a.auix-index-row-action[name='auix-copy-product_location']"
             )

      refute has_element?(
               view,
               "#{m} a.auix-index-row-action[name='auix-archive-product_location']"
             )

      assert has_element?(
               view,
               "#{m} [name='auix-card-menu-destructive'] > .auix-items-card-menu-item:nth-child(2) a.auix-index-row-action[name='auix-delete-product_location']"
             )

      assert has_element?(
               view,
               "#{m} .auix-items-card-item-group button[name='auix-card-menu-toggle'][aria-label='More actions'][aria-expanded='false']"
             )
    end)
  end

  test "index row, header and footer actions are removed, replaced, added and inserted",
       %{conn: conn} do
    fun = &__MODULE__.name_icon/1

    assert %Action{destructive?: false} = Action.new({:archive, fun})
    assert %Action{destructive?: true} = Action.new({:archive, fun, destructive?: true})
    assert %Action{destructive?: true} = Action.new({:default_row_delete, fun})
    assert %Action{destructive?: true} = Action.new(:default_row_delete, fun)

    assert %Action{destructive?: false} =
             Action.new({:default_row_delete, fun, destructive?: false})

    assert_raise ArgumentError, fn -> Action.new({:archive, fun, destroys: true}) end

    other = &Actions.label_title/1

    assigns = %{
      auix: %{
        layout_tree: %{
          actions: [
            add_row_action: {:archive, fun, destructive?: true},
            replace_row_action: {:default_row_delete, other}
          ]
        },
        index_row_actions: [Action.new(:default_row_delete, fun)]
      }
    }

    result = Actions.modify_actions(assigns, Action.available_actions(:index))

    assert [
             %Action{name: :default_row_delete, destructive?: true, function_component: ^other},
             %Action{name: :archive, destructive?: true}
           ] = result.auix.index_row_actions

    each_backend(fn backend ->
      create_sample_products(3, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-actions", "products"))

      assert has_element?(view, "[name='auix-index-header-actions']")
      assert has_element?(view, "[name='auix-index-footer-actions']")
      assert has_element?(view, ".auix-index-row-action")

      assert texts(view, "tr:nth-of-type(1) a[name^='auix-edit-product']") == [
               "Custom Inserted",
               "Custom Removed and Added",
               "Custom Added"
             ]

      assert texts(view, "div[name='auix-index-header-actions'] a[name^='auix-new-product']") ==
               ["Inserted Product", "New Replaced Product", "Added Product"]

      assert texts(view, "div[name='auix-index-footer-actions'] a[name^='auix-new-product']") ==
               ["Footer Product"]
    end)
  end

  test "a row delete hides the row through an attribute selector", %{conn: conn} do
    assert CoreComponents.uix_id_selector("019b-7dd2") == ~s([id="019b-7dd2"])
    assert CoreComponents.uix_id_selector("modal", "-bg") == ~s([id="modal-bg"])
    assert CoreComponents.uix_id_selector(~s(a"b)) == ~s([id="a\\"b"])

    offenders =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.reject(&String.contains?(&1, "/guides/"))
      |> Enum.flat_map(fn path ->
        path
        |> File.stream!()
        |> Stream.with_index(1)
        |> Enum.filter(fn {line, _} ->
          line =~ ~r/(to|target): *"##\{/ or line =~ ~r/_(show|hide)\("##\{/
        end)
        |> Enum.map(fn {_, n} -> "#{path}:#{n}" end)
      end)

    assert offenders == []

    each_backend(fn backend ->
      create_sample_products(3, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-actions", "products"))

      # An id selector (#<id>) is invalid for ids starting with a digit
      assert has_element?(
               view,
               "tr:nth-of-type(1) a[name='auix-delete-product'][phx-click*='[id=']"
             )
    end)
  end

  test "index actions show their default icons, their replaced icons and the delete-selected badge",
       %{conn: conn} do
    assert Actions.icon(%{}, [], :index, :default_new) == "hero-plus"
    assert Actions.icon(%{}, [default_new: :"hero-bolt"], :index, :default_new) == :"hero-bolt"

    assert Actions.icon(
             %{auix: %{name: "star"}},
             [default_new: &__MODULE__.name_icon/1],
             :index,
             :default_new
           ) == "hero-star"

    assert Action.default_icons(:many_to_many) == []

    assert Actions.label_title("New") == "New"
    assert Actions.label_title(:new) == "new"
    assert Actions.label_title(nil) == nil

    assigns = %{}
    assert Actions.label_title(~H"<b>New</b>") == nil

    each_backend(fn backend ->
      create_sample_products_with_suppliers(1, 2)

      {:ok, view, _html} = live(conn, mirror_path(backend, "index-actions", "suppliers"))

      assert has_element?(
               view,
               "a[name='auix-new-supplier'][title='New Supplier'][aria-label='New Supplier'] span.auix-action-icon span.hero-plus"
             )

      assert has_element?(
               view,
               "a[name='auix-new-supplier'] span.auix-action-label",
               "New Supplier"
             )

      assert has_element?(
               view,
               "button[name='auix-selected_check_all-supplier'][title='Check all'] span.auix-action-icon span.hero-check-circle"
             )

      assert has_element?(view, "a[name='auix-show-supplier'] span.auix-action-icon-text", "★")

      assert has_element?(
               view,
               "a[name='auix-edit-supplier'] img.auix-action-icon-image[src='/images/edit.svg']"
             )

      assert has_element?(view, "a[name='auix-delete-supplier'] span.hero-x-mark")
      refute has_element?(view, "a[name='auix-delete-supplier'] span.hero-trash")

      view |> element("button[name='auix-selected_check_all-supplier']") |> render_click()

      assert has_element?(
               view,
               "#auix-delete-all-button-supplier>button[title='Delete selected'] span.hero-archive-box-x-mark"
             )

      assert has_element?(view, "#auix-delete-all-button-supplier>button span.auix-button-badge")
    end)
  end

  ## PRIVATE

  @spec table(map(), binary(), binary()) :: binary()
  defp table(backend, variant, source),
    do: "#auix-table-mirror-#{backend.slug}-#{variant}-#{source}-index"

  @spec texts(View.t(), binary()) :: list(binary())
  defp texts(view, selector) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end

  @spec count(View.t(), binary()) :: non_neg_integer()
  defp count(view, selector) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> Enum.count()
  end

  @spec seed_sort_products() :: map()
  defp seed_sort_products do
    create_sample_products(1, :srt_1, %{name: "Charlie"})
    create_sample_products(1, :srt_2, %{name: "Alpha"})
    create_sample_products(1, :srt_3, %{name: "Bravo"})
  end

  @spec mount_index(Plug.Conn.t(), map()) :: View.t()
  defp mount_index(conn, backend) do
    {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))
    view
  end

  @spec click_sort(View.t(), atom()) :: View.t()
  defp click_sort(view, key) do
    view
    |> element("button[name='auix-sort-#{key}']")
    |> render_click()

    view
  end

  @spec name_cells(View.t(), map()) :: list(binary())
  defp name_cells(view, backend),
    do: texts(view, "#{table(backend, "index", "products")} tr td:nth-of-type(3)")

  @spec mobile_name_cells(View.t(), map()) :: list(binary())
  defp mobile_name_cells(view, backend) do
    texts(
      view,
      "#{table(backend, "index", "products")}-mobile .auix-items-card-item > div:nth-of-type(1) [name='auix-column-value']"
    )
  end

  @spec select_sort(View.t(), binary()) :: View.t()
  defp select_sort(view, sort) do
    view
    |> form("#auix-sort-form-product", %{"sort" => sort})
    |> render_change()

    view
  end

  @spec click_sort_menu(View.t(), binary()) :: View.t()
  defp click_sort_menu(view, name) do
    view
    |> element("[name='auix-sort_action-product'] button[name='#{name}']")
    |> render_click()

    view
  end

  @spec open_filters(View.t()) :: View.t()
  defp open_filters(view) do
    view
    |> element("[name='auix-filter_toggle_open']")
    |> render_click()

    view
  end

  @spec submit_filters(View.t(), binary()) :: View.t()
  defp submit_filters(view, resource) do
    view
    |> element("[name='auix-index-header-actions'] [name='auix-filters_submit-#{resource}']")
    |> render_click()

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

  @spec create_shuffled_products(list(binary())) :: list(binary())
  defp create_shuffled_products(reference_ids) do
    Enum.map(reference_ids, fn reference_id ->
      reference = Ecto.UUID.generate() |> to_string() |> String.slice(0, 30)

      Repo.insert(%MirrorCtx.Product{
        reference: reference,
        name: "Item #{reference_id}",
        description: "This is the item #{reference_id} as described.",
        cost: :rand.uniform_real() * 100 + 123,
        quantity_initial: :rand.uniform_real() * 20
      })

      reference
    end)
  end

  @spec seed_filter_products() :: map()
  defp seed_filter_products do
    locations = create_sample_product_locations(5, :flt)

    for {count, prefix, inactive, status, location} <- [
          {2, :group_1a, false, "in_stock", "id_3"},
          {1, :group_1b, false, "in_stock", "id_5"},
          {2, :group_2a, true, "discontinued", "id_1"},
          {3, :group_2b, true, "discontinued", "id_3"},
          {6, :group_3a, false, "online_only", "id_1"},
          {7, :group_3b, false, "online_only", "id_4"},
          {2, :group_3c, false, "online_only", "id_3"},
          {4, :group_3d, false, "online_only", "id_2"}
        ] do
      create_sample_products(count, prefix, %{
        inactive: inactive,
        status: status,
        product_location_id: locations[location].id
      })
    end

    locations
  end

  @spec mount_filters(Plug.Conn.t(), map()) :: View.t()
  defp mount_filters(conn, backend) do
    {:ok, view, _html} = live(conn, mirror_path(backend, "index", "products"))
    open_filters(view)
  end

  @spec submitted_row_count(View.t(), map()) :: non_neg_integer()
  defp submitted_row_count(view, backend) do
    submit_filters(view, "product")
    count(view, "#{table(backend, "index", "products")} tr")
  end

  @spec mount_where_filters(Plug.Conn.t(), map()) :: View.t()
  defp mount_where_filters(conn, backend) do
    {:ok, view, _html} = live(conn, mirror_path(backend, "index-where", "products"))
    open_filters(view)
  end

  @spec submitted_where_count(View.t(), map()) :: non_neg_integer()
  defp submitted_where_count(view, backend) do
    submit_filters(view, "product")
    count(view, "#{table(backend, "index-where", "products")} tr")
  end

  @spec selected_states(View.t()) :: [boolean()]
  defp selected_states(view) do
    view
    |> render_async(1000)
    |> LazyHTML.from_document()
    |> LazyHTML.query("table tbody tr td input[type='checkbox']")
    |> LazyHTML.attribute("name")
    |> Enum.map(
      &has_element?(view, "table tbody tr td input[name='#{&1}'][type='checkbox'][checked]")
    )
  end

  @spec seed_bulk_products() :: list(MirrorCtx.Product.t())
  defp seed_bulk_products do
    %{"id_test-1" => first, "id_test-2" => second, "id_test-3" => third} =
      create_sample_products(3, :test, %{quantity_initial: Decimal.new(5)})

    [first, second, third]
  end

  @spec select_row(View.t(), binary()) :: binary()
  defp select_row(view, id),
    do: render_change(view, "index-layout-change", %{"_target" => ["selected_check__#{id}"]})
end
