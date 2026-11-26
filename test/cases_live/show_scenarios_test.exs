defmodule Aurora.UixWeb.Test.ShowScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case

  @show_content ".auix-show-container .auix-show-content"
  @navigator "#auix-product-show-modal-content .auix-record-navigator-bar:nth-of-type(1)"

  test "a missing record redirects the show, edit and show-edit back to the index",
       %{conn: conn} do
    each_backend(fn backend ->
      missing_id = "00000000-0000-0000-0000-000000000000"
      index_path = mirror_path(backend, "form", "products")

      for action <- ["show", "edit", "show-edit"] do
        assert {:error,
                {:live_redirect, %{to: ^index_path, flash: %{"error" => "Item not found"}}}} =
                 live(conn, mirror_path(backend, "form", "products", "/#{missing_id}/#{action}"))
      end
    end)
  end

  test "the show view renders one read-only element per field type", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_1" => location} = create_sample_product_locations(1, :test)

      %{"id_full-1" => full} =
        create_sample_products(1, :full, %{
          quantity_initial: Decimal.new(7),
          units_per_box: 3,
          margin: 1.5,
          list_price: Decimal.new(5),
          released_on: ~D[2024-01-02],
          opens_at: ~T[08:00:00],
          audited_at: ~N[2024-01-02 03:04:05],
          discontinued_at: ~U[2024-02-02 03:04:05Z],
          grade: :premium,
          labels: [:fragile],
          inactive: true,
          product_location_id: location.id
        })

      %{"id_bare-1" => bare} =
        create_sample_products(1, :bare, %{quantity_initial: Decimal.new(1)})

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{full.id}/show"))

      assert has_element?(
               view,
               "#{@show_content} input[type=text][name='reference'][value='item_full-1'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=text][name='name'][value='Item full-1'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} textarea[name='description'][disabled]",
               "This is the item full-1 as described."
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=number][name='quantity_initial'][value='7.000000'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=number][name='units_per_box'][value='3'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=number][name='margin'][value='1.5'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=number][name='list_price'][value='5.00'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=date][name='released_on'][value='2024-01-02'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=time][name='opens_at'][value='08:00:00'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=datetime-local][name='audited_at'][value='2024-01-02T03:04'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=datetime-local][name='discontinued_at'][value='2024-02-02T03:04'][disabled]"
             )

      assert has_element?(
               view,
               "#{@show_content} select[name='status'][disabled] option[selected][value='in_stock']"
             )

      assert has_element?(
               view,
               "#{@show_content} select[name='grade'][disabled] option[selected][value='premium']"
             )

      assert has_element?(
               view,
               "#{@show_content} input[type=checkbox][name='inactive'][checked][disabled]"
             )

      assert has_element?(view, "#{@show_content} input[type=checkbox][name='deleted'][disabled]")
      refute has_element?(view, "#{@show_content} input[type=checkbox][name='deleted'][checked]")
      assert has_element?(view, "#{@show_content} .auix-selected-list-item", "Fragile")

      assert has_element?(
               view,
               "#{@show_content} select[name='product_location_id'][disabled] option[selected]",
               "test-name-test-1"
             )

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{bare.id}/show"))

      assert has_element?(
               view,
               "#{@show_content} input[type=text][name='reference'][value='item_bare-1']"
             )

      assert has_element?(view, "#{@show_content} input[type=number][name='units_per_box']")
      refute has_element?(view, "#{@show_content} input[name='units_per_box'][value]")
      assert has_element?(view, "#{@show_content} input[type=date][name='released_on']")
      refute has_element?(view, "#{@show_content} input[name='released_on'][value]")

      refute has_element?(
               view,
               "#{@show_content} select[name='product_location_id'] option[selected]"
             )

      refute has_element?(view, "#{@show_content} .auix-selected-list-item")
    end)
  end

  test "show header and footer actions are replaced and added", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "show", "products", "/#{product.id}/show"))

      assert has_element?(
               view,
               "div[name='auix-show-header-actions'] a[name='auix-edit-product']",
               "Edit Custom Product"
             )

      assert view
             |> render()
             |> LazyHTML.from_document()
             |> LazyHTML.query(
               "div[name='auix-show-footer-actions'] [name='auix-show-navigate-back']"
             )
             |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
               "Back to Products",
               "Back Custom to Products"
             ]
    end)
  end

  test "a group lays out its fields in the show view", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "show", "products", "/#{product.id}/show"))

      assert has_element?(view, ".auix-show-content .auix-group-container")
      assert has_element?(view, ".auix-group-container", "Quantities")
    end)
  end

  test "sections show one tab at a time in the show view", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "show", "products", "/#{product.id}/show"))

      assert has_element?(view, ".auix-show-content .auix-sections-container")
      assert_section_button_is_active(view, "prices", :tab_index_1)
      refute_section_button_is_active(view, "dimensions", :tab_index_2)
      assert_field_is_visible_in_section(view, :product, [:list_price, :rrp], :tab_index_1)
      refute_field_is_visible_in_section(view, :product, [:width, :height, :length], :tab_index_2)

      click_section_button(view, "dimensions", :tab_index_2)

      assert_section_button_is_active(view, "dimensions", :tab_index_2)
      refute_field_is_visible_in_section(view, :product, [:list_price, :rrp], :tab_index_1)
      assert_field_is_visible_in_section(view, :product, [:width, :height, :length], :tab_index_2)
    end)
  end

  test "the record navigator moves to the previous and the next record, across pages", %{
    conn: conn
  } do
    each_backend(fn backend ->
      create_sample_products(100, :test)
      path = fn suffix -> mirror_path(backend, "show", "products", suffix) end
      row_link = fn n -> "table tbody tr:nth-of-type(#{n}) td:nth-of-type(2) a" end

      reference = fn view, n ->
        has_element?(
          view,
          "input[name='reference'][value='item_test-#{String.pad_leading("#{n}", 3, "0")}']"
        )
      end

      # first record: no previous
      {:ok, view, _html} = live(conn, path.(""))
      assert view |> element(row_link.(1)) |> render_click() =~ "Back to Products"
      assert has_element?(view, "#{@navigator} span.hero-chevron-left.auix-icon-inactive")

      assert has_element?(
               view,
               "#{@navigator} a:nth-of-type(1)[phx-value-index='1'][phx-value-page='1'] .hero-chevron-right"
             )

      # previous in the same page
      {:ok, view, _html} = live(conn, path.(""))
      view |> element(row_link.(5)) |> render_click()
      assert reference.(view, 5)

      assert has_element?(
               view,
               "#{@navigator} a:nth-of-type(2)[phx-value-index='5'][phx-value-page='1'] .hero-chevron-right"
             )

      view
      |> element("#{@navigator} a:nth-of-type(1)[phx-value-index='3'][phx-value-page='1']")
      |> render_click()

      assert reference.(view, 4)

      # next in the same page
      {:ok, view, _html} = live(conn, path.(""))
      view |> element(row_link.(4)) |> render_click()
      assert reference.(view, 4)

      assert has_element?(
               view,
               "#{@navigator} a:nth-of-type(1)[phx-value-index='2'][phx-value-page='1'] .hero-chevron-left"
             )

      assert has_element?(view, "#{@navigator} a:nth-of-type(2) .hero-chevron-right")

      view
      |> element("#{@navigator} a:nth-of-type(2)[phx-value-index='4'][phx-value-page='1']")
      |> render_click()

      assert reference.(view, 5)

      # last record: no next
      {:ok, view, _html} = live(conn, path.("?page=3"))
      assert view |> element(row_link.(20)) |> render_click() =~ "Back to Products"

      assert has_element?(
               view,
               "#{@navigator} a:nth-of-type(1)[phx-value-index='18'][phx-value-page='3'] .hero-chevron-left"
             )

      assert has_element?(view, "#{@navigator} span.hero-chevron-right.auix-icon-inactive")

      assert_cross_page_navigation(conn, path)
    end)
  end

  test "record_navigator places the navigator at the top, at the bottom, at both or nowhere", %{
    conn: conn
  } do
    each_backend(fn backend ->
      create_sample_products(10, :test)
      create_sample_product_locations(5, :test)
      row_link = "table tbody tr:nth-of-type(2) td:nth-of-type(2) a"

      bars = fn view, container ->
        view
        |> render()
        |> LazyHTML.from_document()
        |> LazyHTML.query("#{container} .auix-record-navigator-bar")
        |> Enum.count()
      end

      {:ok, view, _html} = live(conn, mirror_path(backend, "show-navigator", "products"))
      assert view |> element(row_link) |> render_click() =~ "Back to Products"
      assert bars.(view, "#auix-product-show-modal-content") == 0

      assert view
             |> element("div[name='auix-show-header-actions'] a[name='auix-edit-product']")
             |> render_click() =~ "Use this form to manage"

      assert bars.(view, "#auix-product-show_edit-modal-content") == 1

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "show-navigator", "product_locations"))

      assert view |> element(row_link) |> render_click() =~ "Back to Product Locations"
      assert bars.(view, "#auix-product_location-show-modal-content") == 1

      assert view
             |> element(
               "div[name='auix-show-header-actions'] a[name='auix-edit-product_location']"
             )
             |> render_click() =~ "Use this form to manage"

      assert bars.(view, "#auix-product_location-show_edit-modal-content") == 2
    end)
  end

  @spec assert_cross_page_navigation(Plug.Conn.t(), (binary() -> binary())) :: term()
  defp assert_cross_page_navigation(conn, path) do
    row_link = fn n -> "table tbody tr:nth-of-type(#{n}) td:nth-of-type(2) a" end

    reference = fn view, n ->
      has_element?(
        view,
        "input[name='reference'][value='item_test-#{String.pad_leading("#{n}", 3, "0")}']"
      )
    end

    {:ok, view, _html} = live(conn, path.("?page=3"))
    view |> element(row_link.(1)) |> render_click()
    assert reference.(view, 81)
    assert has_element?(view, "#{@navigator} a:nth-of-type(1) .hero-chevron-left")

    assert has_element?(
             view,
             "#{@navigator} a:nth-of-type(2)[phx-value-index='1'][phx-value-page='3'] .hero-chevron-right"
           )

    view
    |> element("#{@navigator} a:nth-of-type(1)[phx-value-index='39'][phx-value-page='2']")
    |> render_click()

    assert reference.(view, 80)

    {:ok, next_view, _html} = live(conn, path.("?page=2"))
    next_view |> element(row_link.(40)) |> render_click()
    assert reference.(next_view, 80)

    assert has_element?(
             next_view,
             "#{@navigator} a:nth-of-type(1)[phx-value-index='38'][phx-value-page='2'] .hero-chevron-left"
           )

    assert has_element?(next_view, "#{@navigator} a:nth-of-type(2) .hero-chevron-right")

    next_view
    |> element("#{@navigator} a:nth-of-type(2)[phx-value-index='0'][phx-value-page='3']")
    |> render_click()

    assert reference.(next_view, 81)
  end
end
