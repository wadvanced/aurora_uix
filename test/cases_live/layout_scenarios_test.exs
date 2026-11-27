defmodule Aurora.UixWeb.Test.LayoutScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.MirrorCtx
  alias Aurora.UixWeb.Test.MirrorAsh, as: AshViews
  alias Aurora.UixWeb.Test.MirrorCtx, as: CtxViews

  @resources [
    {"products", "product", MirrorCtx.Product},
    {"product_locations", "product_location", MirrorCtx.ProductLocation},
    {"product_transactions", "product_transaction", MirrorCtx.ProductTransaction},
    {"product_barcodes", "product_barcode", MirrorCtx.ProductBarcode},
    {"suppliers", "supplier", MirrorCtx.Supplier}
  ]

  test "default layouts mount index, new, show and edit for every resource", %{conn: conn} do
    each_backend(fn backend ->
      for {source, _resource, _schema} <- @resources do
        {:ok, view, _} = live(conn, mirror_path(backend, "default", source))
        assert has_element?(view, ".auix-index-container")
        refute has_element?(view, ".auix-items-table-row")
      end

      create_sample_products_with_transactions(1, 2, :test)
      create_sample_product_locations(1, :test)
      create_sample_products_with_barcodes(1)
      create_sample_products_with_suppliers(1, 2)

      for {source, resource, schema} <- @resources do
        %{id: id} = schema |> Repo.all() |> List.first()

        {:ok, index_view, _} = live(conn, mirror_path(backend, "default", source))
        assert has_element?(index_view, ".auix-index-container")

        for action <- ["new", "edit"] do
          suffix = if action == "new", do: "/new", else: "/#{id}/edit"
          {:ok, form_view, _} = live(conn, mirror_path(backend, "default", source, suffix))
          assert has_element?(form_view, ".auix-index-container")
          assert has_element?(form_view, "#auix-#{resource}-#{action}-modal .auix-form-container")
        end

        {:ok, show_view, _} = live(conn, mirror_path(backend, "default", source, "/#{id}/show"))
        assert has_element?(show_view, ".auix-index-container")
        assert has_element?(show_view, ".auix-show-container")
      end
    end)
  end

  test "the default pages carry their titles, subtitles and containers", %{conn: conn} do
    each_backend(fn backend ->
      product_id =
        3
        |> create_sample_products(:test)
        |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      {:ok, view, _html} = live(conn, mirror_path(backend, "default", "products"))
      assert has_element?(view, ".auix-header-title", "Listing Products")
      assert has_element?(view, "a[name='auix-new-product']", "New Product")

      view |> element("a[name='auix-new-product']") |> render_click()

      assert has_element?(
               view,
               "div#auix-product-new-modal header.auix-header--top-actions .auix-header-title",
               "New Product"
             )

      {:ok, view, _html} = live(conn, mirror_path(backend, "default", "products", "/new"))
      modal_header = "div#auix-product-new-modal header.auix-header--top-actions"
      assert has_element?(view, "#{modal_header} .auix-header-title", "New Product")

      assert has_element?(
               view,
               "#{modal_header} .auix-header-subtitle",
               ~r/Creates a new .Product. record in your database/
             )

      {:ok, show_view, _html} =
        live(conn, mirror_path(backend, "default", "products", "/#{product_id}/show"))

      assert has_element?(show_view, ".auix-show-container")
      assert has_element?(show_view, ".auix-show-content")
      assert has_element?(show_view, ".auix-header-title", "Product")
      assert has_element?(show_view, ".auix-header-subtitle", "Details")

      {:ok, view, _html} = live(conn, mirror_path(backend, "default", "products"))
      edit_link = "tr[id^='products']:nth-of-type(1)  a[name='auix-edit-product']"
      assert has_element?(view, edit_link)
      view |> element(edit_link) |> render_click()

      assert has_element?(view, "[name='auix-save-product']")
      assert has_element?(view, ".auix-form-container")

      assert has_element?(
               view,
               "div#auix-product-edit-modal header .auix-header-title",
               "Edit Product"
             )

      assert has_element?(
               view,
               "div#auix-product-edit-modal header .auix-header-subtitle",
               ~r/Use this form to manage .Products. records in your database/
             )
    end)
  end

  test "the default form lists the fields in declaration order, stacked and inline", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, _view, html} = live(conn, mirror_path(backend, "default", "products", "/new"))

      if backend.name == :ctx do
        config = CtxViews.Default |> resource_configs() |> get_in([Access.key!(:product)])

        declared_fields()
        |> reject_select_fields(config.fields)
        |> assert_container_order(html, "auix-stacked-container")
      end

      {:ok, _view, inline_html} =
        live(conn, mirror_path(backend, "default-inline", "products", "/new"))

      if backend.name == :ctx do
        config = CtxViews.DefaultInline |> resource_configs() |> get_in([Access.key!(:product)])

        declared_fields()
        |> reject_select_fields(config.fields)
        |> assert_container_order(inline_html, "auix-inline-container")
      end
    end)
  end

  test "a product created through the default form appears in the index", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "default", "products", "/new"))

      view
      |> form("#auix-product-form",
        product: %{reference: "test-first", name: "This is the first test"}
      )
      |> render_change()

      assert_blank_error(view, backend)

      view
      |> form("#auix-product-form",
        product: %{
          reference: "test-first",
          name: "This is the first test",
          quantity_initial: 11,
          product_barcode: %{code: "C-1"}
        }
      )
      |> render_submit()

      {:ok, index_view, _html} = live(conn, mirror_path(backend, "default", "products"))
      assert has_element?(index_view, ".auix-header-title", "Listing Products")
      assert has_element?(index_view, ".auix-items-table-cell", "test-first")
    end)
  end

  test "groups lay out the form", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "groups", "products", "/new"))
      assert has_element?(view, ".auix-group-container[id^='auix-group-quantities-']")
      assert has_element?(view, ".auix-group-container[id^='auix-group-sale_prices-']")

      assert has_element?(
               view,
               ~s(div[id^="auix-group-quantities-"] + div[id^="auix-group-sale_prices-"])
             )

      assert has_element?(
               view,
               ~s(div[id^="auix-group-quantities-"] > h3.auix-group-title:first-child)
             )

      assert_group_field(view, "group-quantities", 1, "quantity_at_hand")
      assert_group_field(view, "group-quantities", 2, "quantity_initial")
      assert_group_field(view, "group-sale_prices", 1, "list_price")
      assert_group_field(view, "group-sale_prices", 2, "rrp")
    end)
  end

  test "sections and nested sections show one tab at a time", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "sections", "products", "/new"))
      assert has_element?(view, ".auix-sections-container")
      assert has_element?(view, ".auix-sections-content")
      assert has_element?(view, ".auix-sections-tab-container button[data-button-tab-index='1']")
      assert has_element?(view, ".auix-sections-tab-container button[data-button-tab-index='2']")
      refute has_element?(view, ".auix-sections-tab-container button[data-button-tab-index='3']")

      assert_section_button_is_active(view, "quantities", :tab_index_1)
      refute_section_button_is_active(view, "sale_prices", :tab_index_2)

      assert_field_is_visible_in_section(
        view,
        :product,
        [:quantity_at_hand, :quantity_initial],
        :tab_index_1
      )

      refute_field_is_visible_in_section(view, :product, [:list_price, :rrp], :tab_index_2)

      assert has_element?(
               view,
               ".auix-section-tab.auix-visually-hidden[data-tab-label='Sale Prices']"
             )

      click_section_button(view, "sale_prices", :tab_index_2)

      assert_section_button_is_active(view, "quantities", :tab_index_1)
      assert_section_button_is_active(view, "sale_prices", :tab_index_2)

      refute_field_is_visible_in_section(
        view,
        :product,
        [:quantity_at_hand, :quantity_initial],
        :tab_index_1
      )

      assert_field_is_visible_in_section(view, :product, [:list_price, :rrp], :tab_index_2)

      assert has_element?(
               view,
               ".auix-section-tab.auix-visually-hidden[data-tab-label='Quantities']"
             )

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "nested-sections", "products", "/new"))

      assert has_element?(
               view,
               ".auix-section-tab[data-tab-label='Sale Prices'][data-tab-active='active']"
             )

      assert_nested_sections(view)
    end)
  end

  test "layout options set the page titles and subtitles and replace the index row functions",
       %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products_with_transactions(2, 2, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "products"))
      assert has_element?(view, ".auix-header-title", "The Products Listing")
      assert has_element?(view, "tbody tr[id^='products-'][id$='-row']")
      assert has_element?(view, "div[name='auix-card'][id^='products__mobile-'][id$='-row']")
      assert has_element?(view, "a[name='auix-new-product']", "New Product")
      view |> element("a[name='auix-new-product']") |> render_click()
      assert has_element?(view, "div#auix-product-new-modal .auix-header-title", "Add a Product")

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "products", "/new"))
      assert has_element?(view, "div#auix-product-new-modal header", "Add a Product")

      assert has_element?(
               view,
               "div#auix-product-new-modal .auix-header-subtitle strong",
               "Product's"
             )

      assert has_element?(
               view,
               "div#auix-product-new-modal .auix-header-subtitle",
               "values properly"
             )

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "products"))
      show_link = "tr[id^='products']:nth-of-type(1) td:nth-child(2) a[name='auix-show-product']"
      assert has_element?(view, show_link)
      view |> element(show_link) |> render_click()

      assert has_element?(view, ".auix-header-title", "Details for Product")
      refute has_element?(view, "#auix-product-show-modal .auix-header-subtitle")
      assert has_element?(view, "a[name='auix-edit-product']")
      assert has_element?(view, "div[name='auix-show-navigate-back'] a:nth-of-type(1)")

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "products"))
      edit_link = "tr[id^='products']:nth-of-type(1) a[name='auix-edit-product']"
      assert has_element?(view, edit_link)
      view |> element(edit_link) |> render_click()
      assert has_element?(view, "[name='auix-save-product']")

      assert has_element?(
               view,
               "div#auix-product-edit-modal header .auix-header-title",
               "Modify Product: #item_"
             )

      assert has_element?(
               view,
               "div#auix-product-edit-modal header .auix-header-subtitle",
               "Entries are validated before saving"
             )
    end)
  end

  test "layout and resource preloads load the relationships an index renders", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products_with_transactions(2, 2, :test)
      create_sample_product_locations(3, :test)
      create_sample_products_with_barcodes(1)

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "product_transactions"))
      assert has_element?(view, ".auix-product-marker", "LOADED")
      refute has_element?(view, ".auix-product-marker", "NOT_LOADED")

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "product_locations"))
      assert has_element?(view, ".auix-products-marker", "LOADED")
      refute has_element?(view, ".auix-products-marker", "NOT_LOADED")

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "product_barcodes"))
      assert has_element?(view, ".auix-product-marker", "NOT_LOADED")

      for {source, schema} <- [
            {"product_transactions", MirrorCtx.ProductTransaction},
            {"product_locations", MirrorCtx.ProductLocation},
            {"product_barcodes", MirrorCtx.ProductBarcode}
          ] do
        %{id: id} = schema |> Repo.all() |> List.first()
        assert {:ok, _, _} = live(conn, mirror_path(backend, "options", source, "/new"))
        assert {:ok, _, _} = live(conn, mirror_path(backend, "options", source, "/#{id}/show"))
      end
    end)
  end

  test "a resource where narrows the index", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_product_locations(3, :test)

      {:ok, view, html} = live(conn, mirror_path(backend, "options", "product_locations"))
      assert count(html, ".auix-items-table-row") == 2
      refute has_element?(view, "td", "test-reference-test-3")
    end)
  end

  test "a used form component serves the resource of its host", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_product_locations(1, :test)
      [location] = Repo.all(MirrorCtx.ProductLocation)
      views = views_namespace(backend)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "named", "product_locations", "/#{location.id}/edit"))

      assert has_element?(
               view,
               "#auix-product_location-form input[name='product_location[reference]']"
             )

      assert has_element?(
               view,
               "#auix-product_location-form input[name='product_location[name]']"
             )

      refute has_element?(view, "input[name='product_location[type]']")

      view
      |> form("#auix-product_location-form", product_location: %{name: "Renamed"})
      |> render_submit()

      assert Repo.get!(MirrorCtx.ProductLocation, location.id).name == "Renamed"
      refute views |> Module.concat(Named.ProductLocation.FormComponent) |> Code.ensure_loaded?()
      refute views |> Module.concat(Named.ProductLocation.Index) |> Code.ensure_loaded?()
      assert views |> Module.concat(Named.ProductLocation.Locations) |> Code.ensure_loaded?()
    end)
  end

  test "a local layout replaces the included one", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products(1, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "included", "products", "/new"))
      assert has_element?(view, "input[name='product[reference]']")
      assert has_element?(view, "input[name='product[name]']")
      refute has_element?(view, "input[name='product[description]']")

      [product] = Repo.all(MirrorCtx.Product)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "included", "products", "/#{product.id}/show"))

      assert has_element?(view, "input[name='name']")
      refute has_element?(view, "input[name='reference']")
      refute has_element?(view, "input[name='description']")
    end)
  end

  test "layouts declared with auix_create_layout render the edit and the show page", %{conn: conn} do
    each_backend(fn backend ->
      products = create_sample_products_with_transactions(1, 1, :test)
      create_sample_product_locations(1, :test)
      product_id = products |> Map.new() |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      assert_index_and_new(conn, mirror_path(backend, "manual", "products"))

      {:ok, view, _html} = live(conn, mirror_path(backend, "manual", "products"))
      refute has_element?(view, "div[name='auix-column-label']", "Quantity at hand")

      {:ok, view, _html} = live(conn, mirror_path(backend, "manual", "products", "/new"))
      assert has_element?(view, "div#auix-product-new-modal .auix-header-title", "New Product")
      assert_form_inputs(view)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "manual", "products", "/#{product_id}/show"))

      assert has_element?(view, ".auix-header-title", "Product")
      assert has_element?(view, "input[name='reference']")
      assert has_element?(view, "input[name='name']")
      assert has_element?(view, "input[name='description']")
      assert has_element?(view, "input[name='quantity_at_hand']")
      assert has_element?(view, "input[name='quantity_initial']")
      refute has_element?(view, "input[name='list_price']")
      refute has_element?(view, "input[name='rrp']")
      assert has_element?(view, "select[name='product_location_id']")
      assert has_element?(view, "div[name='auix-one_to_many-product']")

      assert_product_created(conn, backend, mirror_path(backend, "manual", "products"))

      assert_sources_mount(
        conn,
        mirror_path(backend, "manual", "product_transactions"),
        MirrorCtx.ProductTransaction
      )

      assert_sources_mount(
        conn,
        mirror_path(backend, "manual", "product_locations"),
        MirrorCtx.ProductLocation
      )
    end)
  end

  test "resources taken from another module render and save", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products_with_transactions(1, 1, :test)
      create_sample_product_locations(1, :test)

      assert_index_and_new(conn, mirror_path(backend, "separated", "products"))
      assert_product_created(conn, backend, mirror_path(backend, "separated", "products"))

      {:ok, view, _html} = live(conn, mirror_path(backend, "separated", "product_transactions"))
      assert has_element?(view, ".auix-header-title", "Listing Product Transactions")

      assert has_element?(
               view,
               "a[name='auix-new-product_transaction']",
               "New Product Transaction"
             )

      view |> element("a[name='auix-new-product_transaction']") |> render_click()

      assert has_element?(
               view,
               "div#auix-product_transaction-new-modal .auix-header-title",
               "New Product Transaction"
             )

      {:ok, product} =
        MirrorCtx.create_product(%{
          reference: "test-product-001",
          name: "For testing product_transactions",
          quantity_initial: 99
        })

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "separated", "product_transactions", "/new"))

      assert has_element?(
               view,
               "div#auix-product_transaction-new-modal .auix-header-title",
               "New Product Transaction"
             )

      view
      |> form("#auix-product_transaction-form",
        product_transaction: %{type: "test-transaction", quantity: 100}
      )
      |> render_change()

      assert_blank_error(view, backend)

      view
      |> form("#auix-product_transaction-form",
        product_transaction: %{cost: 50, product_id: product.id}
      )
      |> render_submit()

      {:ok, view, _html} = live(conn, mirror_path(backend, "separated", "product_transactions"))
      assert has_element?(view, ".auix-header-title", "Listing Product Transactions")
      assert has_element?(view, ".auix-items-table-cell", "test-transaction")

      %{id: transaction_id} = MirrorCtx.ProductTransaction |> Repo.all() |> List.first()

      assert {:ok, _, _} =
               live(
                 conn,
                 mirror_path(
                   backend,
                   "separated",
                   "product_transactions",
                   "/#{transaction_id}/show"
                 )
               )
    end)
  end

  test "a resource map built by hand renders and saves", %{conn: conn} do
    # A resource map built by hand names a `context:` and a `schema:`, which only `:ctx` has.
    each_backend([:ctx], fn backend ->
      products = create_sample_products_with_transactions(1, 1, :test)
      create_sample_product_locations(1, :test)
      product_id = products |> Map.new() |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

      assert_index_and_new(conn, mirror_path(backend, "manual-resource", "products"))

      {:ok, view, _html} = live(conn, mirror_path(backend, "manual-resource", "products", "/new"))
      assert has_element?(view, "div#auix-product-new-modal .auix-header-title", "New Product")
      assert_form_inputs(view)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "manual-resource", "products", "/#{product_id}/show"))

      assert has_element?(view, ".auix-header-title", "Product")
      assert has_element?(view, "input[name='reference']")
      assert has_element?(view, "input[name='name']")
      assert has_element?(view, "input[name='description']")
      assert has_element?(view, "input[name='quantity_at_hand']")
      assert has_element?(view, "input[name='quantity_initial']")
      assert has_element?(view, "input[name='list_price']")
      assert has_element?(view, "input[name='rrp']")
      assert has_element?(view, "select[name='product_location_id']")
      assert has_element?(view, "div[name='auix-one_to_many-product']")

      assert_product_created(conn, backend, mirror_path(backend, "manual-resource", "products"))

      assert_sources_mount(
        conn,
        mirror_path(backend, "manual-resource", "product_transactions"),
        MirrorCtx.ProductTransaction
      )

      assert_sources_mount(
        conn,
        mirror_path(backend, "manual-resource", "product_locations"),
        MirrorCtx.ProductLocation
      )
    end)
  end

  ## PRIVATE ##

  @spec views_namespace(Aurora.UixWeb.Test.Scenario.backend()) :: module()
  defp views_namespace(%{name: :ash}), do: AshViews
  defp views_namespace(%{name: :ctx}), do: CtxViews

  @spec assert_blank_error(Phoenix.LiveViewTest.View.t(), Aurora.UixWeb.Test.Scenario.backend()) ::
          true
  defp assert_blank_error(view, %{name: :ash}),
    do: assert(has_element?(view, ".auix-error-message", "is required"))

  defp assert_blank_error(view, %{name: :ctx}),
    do: assert(has_element?(view, ".auix-error-message", "can't be blank"))

  # Embeds render nested inputs that no positional comparison counts, so only the fields of the
  # schema remain, in their declaration order.
  @spec declared_fields() :: list(atom())
  defp declared_fields,
    do: MirrorCtx.Product.__schema__(:fields) -- MirrorCtx.Product.__schema__(:embeds)

  @spec count(binary(), binary()) :: non_neg_integer()
  defp count(html, selector),
    do: html |> LazyHTML.from_document() |> LazyHTML.query(selector) |> Enum.count()

  @spec assert_index_and_new(Plug.Conn.t(), binary()) :: true
  defp assert_index_and_new(conn, path) do
    {:ok, view, _html} = live(conn, path)
    assert has_element?(view, ".auix-header-title", "Listing Products")
    assert has_element?(view, "a[name='auix-new-product']", "New Product")
    view |> element("a[name='auix-new-product']") |> render_click()
    assert has_element?(view, "div#auix-product-new-modal .auix-header-title", "New Product")
  end

  @spec assert_form_inputs(Phoenix.LiveViewTest.View.t()) :: true
  defp assert_form_inputs(view) do
    assert has_element?(view, "input[name='product[reference]']")
    assert has_element?(view, "input[name='product[name]']")
    assert has_element?(view, "input[name='product[description]']")
    assert has_element?(view, "input[name='product[quantity_at_hand]']")
    assert has_element?(view, "input[name='product[quantity_initial]']")
    assert has_element?(view, "input[name='product[list_price]']")
    assert has_element?(view, "input[name='product[rrp]']")
    assert has_element?(view, "select[name='product[product_location_id]']")
    assert has_element?(view, "#auix-one_to_many-product__product_transactions-form")
  end

  @spec assert_product_created(Plug.Conn.t(), Aurora.UixWeb.Test.Scenario.backend(), binary()) ::
          true
  defp assert_product_created(conn, backend, index_path) do
    {:ok, view, _html} = live(conn, "#{index_path}/new")
    assert has_element?(view, "div#auix-product-new-modal .auix-header-title", "New Product")

    view
    |> form("#auix-product-form",
      product: %{reference: "test-first", name: "This is the first test"}
    )
    |> render_change()

    assert_blank_error(view, backend)

    view
    |> form("#auix-product-form", product: %{quantity_initial: 11})
    |> render_submit()

    {:ok, index_view, _html} = live(conn, index_path)
    assert has_element?(index_view, ".auix-header-title", "Listing Products")
    assert has_element?(index_view, ".auix-items-table-cell", "test-first")

    MirrorCtx.Product
    |> Repo.get_by!(reference: "test-first")
    |> Repo.delete!()

    true
  end

  @spec assert_sources_mount(Plug.Conn.t(), binary(), module()) :: true
  defp assert_sources_mount(conn, index_path, schema) do
    %{id: id} = schema |> Repo.all() |> List.first()
    assert {:ok, _, _} = live(conn, index_path)
    assert {:ok, _, _} = live(conn, "#{index_path}/new")
    assert {:ok, _, _} = live(conn, "#{index_path}/#{id}/show")
  end

  @spec assert_group_field(Phoenix.LiveViewTest.View.t(), binary(), integer(), binary()) ::
          true
  defp assert_group_field(view, group_name, position, field_name) do
    assert has_element?(
             view,
             ~s|div[id^='auix-#{group_name}-'] > div > div:nth-child(#{position}) input[name='product[#{field_name}]']|
           ),
           "Field: `#{field_name}` not in group `#{group_name}` at #{position}"
  end

  # A single-value select renders as `<select>` and a multi-value one as a group of checkboxes;
  # neither contributes exactly one positional `<input>`, so both would shift the comparison.
  # `scalar_field_name/1` drops them from the other side.
  @spec reject_select_fields(list(), map()) :: list()
  defp reject_select_fields(fields_order, fields),
    do: Enum.reject(fields_order, &(get_in(fields, [&1, Access.key!(:html_type)]) == :select))

  # Keeps only the `product[key]` inputs: a multi-value select renders `product[key][]` boxes plus a
  # toggle named outside the resource scope, and neither has a place in a positional comparison.
  @spec scalar_field_name(LazyHTML.t()) :: list(binary())
  defp scalar_field_name(input) do
    with "product[" <> rest <- input |> LazyHTML.attribute("name") |> List.first(),
         [key, ""] <- String.split(rest, "]") do
      [key]
    else
      _other -> []
    end
  end

  @spec assert_container_order(list(), binary(), binary()) :: :ok
  defp assert_container_order(fields, html, container_class) do
    inputs =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query(
        "form#auix-product-form div.auix-form-container>div.#{container_class} input:not([type='hidden'])"
      )
      |> Enum.flat_map(&scalar_field_name/1)

    fields_as_string = Enum.map(fields, &to_string/1)
    assert_values_order(fields_as_string, inputs)
  end

  @spec assert_nested_sections(Phoenix.LiveViewTest.View.t()) :: true
  defp assert_nested_sections(view) do
    assert_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    refute_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    assert_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    assert_visibility(view, %{
      {:sections_index_1, :tab_index_1, [:reference, :name]} => true,
      {:sections_index_2, :tab_index_1, [:description, :status]} => true,
      {:sections_index_2, :tab_index_2, [:width, :height, :length]} => false,
      {:sections_index_3, :tab_index_1, [:quantity_at_hand, :quantity_initial]} => false,
      {:sections_index_3, :tab_index_2, [:list_price, :rrp]} => false
    })

    click_section_button(view, "information", 2)
    refute_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    assert_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    refute_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    assert_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    assert_visibility(view, %{
      {:sections_index_1, :tab_index_1, [:reference, :name]} => false,
      {:sections_index_2, :tab_index_1, [:description, :status]} => false,
      {:sections_index_2, :tab_index_2, [:width, :height, :length]} => false,
      {:sections_index_3, :tab_index_1, [:quantity_at_hand, :quantity_initial]} => false,
      {:sections_index_3, :tab_index_2, [:list_price, :rrp]} => true
    })

    click_section_button(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    assert_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    refute_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    assert_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    assert_visibility(view, %{
      {:sections_index_1, :tab_index_1, [:reference, :name]} => false,
      {:sections_index_2, :tab_index_1, [:description, :status]} => false,
      {:sections_index_2, :tab_index_2, [:width, :height, :length]} => false,
      {:sections_index_3, :tab_index_1, [:quantity_at_hand, :quantity_initial]} => true,
      {:sections_index_3, :tab_index_2, [:list_price, :rrp]} => false
    })

    click_section_button(view, "references", :sections_index_1, :tab_index_1)
    assert_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    refute_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    assert_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    click_section_button(view, "specifications", :sections_index_2, :tab_index_2)
    assert_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    refute_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    refute_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    assert_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    assert_visibility(view, %{
      {:sections_index_1, :tab_index_1, [:reference, :name]} => true,
      {:sections_index_2, :tab_index_1, [:description, :status]} => false,
      {:sections_index_2, :tab_index_2, [:width, :height, :length]} => true,
      {:sections_index_3, :tab_index_1, [:quantity_at_hand, :quantity_initial]} => false,
      {:sections_index_3, :tab_index_2, [:list_price, :rrp]} => false
    })
  end

  @spec assert_visibility(Phoenix.LiveViewTest.View.t(), map()) :: true
  defp assert_visibility(view, expectations) do
    Enum.each(expectations, fn
      {{sections_index, tab_index, fields}, true} ->
        assert_field_is_visible_in_section(view, :product, fields, sections_index, tab_index)

      {{sections_index, tab_index, fields}, false} ->
        refute_field_is_visible_in_section(view, :product, fields, sections_index, tab_index)
    end)

    true
  end
end
