defmodule Aurora.UixWeb.Test.AssociationScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case

  import Ecto.Query, only: [from: 2]

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Templates.Basic.Renderers.OneToMany
  alias Aurora.Uix.Test.MirrorCtx
  alias Phoenix.LiveViewTest.View

  @location_select "select[name='product[product_location_id]']"
  @transactions_form "#auix-one_to_many-product__product_transactions-form"
  @transactions_show "#auix-one_to_many-product__product_transactions-show"
  @checkbox_group ".auix-checkbox-group input[type='checkbox']"
  @toggle_all "input#auix-many-to-many-toggle_all-suppliers"

  @descending_names Enum.map(20..1//-1, &"test-name-many2-#{String.pad_leading("#{&1}", 2, "0")}")
  @where_names Enum.map(14..8//-1, &"test-name-many2-#{String.pad_leading("#{&1}", 2, "0")}")

  test "a many-to-one select lists one option per related record and saves the selection", %{
    conn: conn
  } do
    each_backend(fn backend ->
      locations = create_sample_product_locations(5)
      %{id: location_id_1, name: name_1} = locations["id_1"]
      %{id: location_id_2, name: name_2} = locations["id_2"]

      %{"id_test-1" => product} =
        create_sample_products(1, :test, %{
          product_location_id: location_id_1,
          quantity_initial: 1
        })

      {:ok, view, _html} = live(conn, mirror_path(backend, "many-to-one", "products"))
      assert has_element?(view, ".auix-header-title", "Listing Products")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-one", "products", "/#{product.id}/show"))

      assert has_element?(view, ".auix-header-title", "Product")

      assert has_element?(
               view,
               "select[name='product_location_id'] option[selected][value='#{location_id_1}']"
             )

      edit_path = mirror_path(backend, "many-to-one", "products", "/#{product.id}/edit")
      {:ok, view, _html} = live(conn, edit_path)
      assert has_element?(view, ".auix-header-title", "Edit Product")

      for {_key, location} <- locations do
        assert has_element?(
                 view,
                 "#{@location_select} option[value='#{location.id}']",
                 location.name
               )
      end

      assert has_element?(
               view,
               "#{@location_select} option[selected][value='#{location_id_1}']",
               name_1
             )

      view
      |> form("#auix-product-form", product: %{product_location_id: location_id_2})
      |> render_submit()

      assert Repo.get!(MirrorCtx.Product, product.id).product_location_id == location_id_2

      {:ok, view, _html} = live(conn, edit_path)

      assert has_element?(
               view,
               "#{@location_select} option[selected][value='#{location_id_2}']",
               name_2
             )
    end)
  end

  test "an option label comes from a function of the entity and from a function of the assigns",
       %{
         conn: conn
       } do
    each_backend(fn backend ->
      [{_key, product}] = create_sample_products_with_transactions(1, 1, :one2)
      transaction = Repo.one!(MirrorCtx.ProductTransaction)
      [barcoded] = create_sample_products_with_barcodes(1)
      barcode = Repo.one!(MirrorCtx.ProductBarcode)

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "many-to-one", "product_transactions", "/#{transaction.id}/edit")
        )

      assert has_element?(
               view,
               "select[name='product_transaction[product_id]'] option[selected]",
               "The #{product.name}"
             )

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "many-to-one", "product_barcodes", "/#{barcode.id}/edit")
        )

      assert has_element?(
               view,
               "select[name='product_barcode[product_id]'] option",
               "form: #{barcoded.name}"
             )

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "many-to-one", "product_barcodes", "/#{barcode.id}/show")
        )

      assert has_element?(
               view,
               "select[name='product_id'] option",
               "show: #{barcoded.name}"
             )
    end)
  end

  test "query_opts order and filter the options", %{conn: conn} do
    each_backend(fn backend ->
      locations = create_sample_product_locations(20, :many2)
      location_id = locations["id_1"].id

      %{"id_test-1" => product} =
        create_sample_products(1, :test, %{product_location_id: location_id, quantity_initial: 1})

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-one", "products", "/#{product.id}/edit"))

      assert option_texts(view, @location_select, "test-name-many2-") == @descending_names

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "many-to-one-queries", "products", "/#{product.id}/edit")
        )

      assert option_texts(view, @location_select, "test-name-many2-") == @where_names

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-one-queries", "products", "/new"))

      assert has_element?(view, @location_select)

      assert has_element?(
               view,
               "#{@location_select} option[value='#{locations["id_10"].id}']"
             )
    end)
  end

  test "parent fields of a many-to-one follow the selected record", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "many-to-one", "products"))
      assert has_element?(view, ".auix-header-title", "Listing Products")

      view |> element("a[name='auix-new-product']") |> render_click()
      assert has_element?(view, ".auix-header-title", "New Product")

      view
      |> form("#auix-product-form",
        product: %{reference: "test-001", name: "the product name", quantity_initial: 14.45}
      )
      |> render_submit()

      locations = create_sample_product_locations(2)
      %{id: location_id_1} = locations["id_1"]
      %{id: location_id_2} = locations["id_2"]

      %{"id_test-1" => product} =
        create_sample_products(1, :test, %{
          product_location_id: location_id_1,
          quantity_initial: 1
        })

      edit_path = mirror_path(backend, "many-to-one", "products", "/#{product.id}/edit")
      {:ok, view, _html} = live(conn, edit_path)

      assert view
             |> render()
             |> LazyHTML.from_document()
             |> LazyHTML.query("[name='product[name]']")
             |> Enum.count() == 1

      refute has_element?(view, ".auix-group-title", "Product")
      assert has_element?(view, "input[name='name'][value='test-name-1']")
      assert has_element?(view, "input[name='type'][value='test-type-1']")

      view
      |> form("#auix-product-form", product: %{product_location_id: location_id_2})
      |> render_submit()

      {:ok, view, _html} = live(conn, edit_path)
      assert has_element?(view, "input[name='name'][value='test-name-2']")
      assert has_element?(view, "input[name='type'][value='test-type-2']")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-one", "products", "/#{product.id}/show"))

      assert has_element?(view, "input[name='name'][value='test-name-2']")

      parent_path =
        mirror_path(backend, "many-to-one-queries", "products", "/#{product.id}/edit")

      {:ok, view, _html} = live(conn, parent_path)

      assert view
             |> render()
             |> LazyHTML.from_document()
             |> LazyHTML.query("[name='product[name]']")
             |> Enum.count() == 1

      assert has_element?(view, ".auix-group-title", "Product")
      assert has_element?(view, "input[name='reference'][value='test-reference-2']")
      assert has_element?(view, "input[name='name'][value='test-name-2']")
      assert has_element?(view, "input[name='type'][value='test-type-2']")
    end)
  end

  test "a one-to-many list shows one row per child, and the empty state for none", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(3, :test)
      [{_key, with_rows}] = create_sample_products_with_transactions(1, 3, :rows)

      {:ok, view, _html} = live(conn, mirror_path(backend, "one-to-many", "products"))
      assert has_element?(view, ".auix-header-title", "Listing Products")
      assert has_element?(view, "#auix-table-mirror-#{backend.slug}-one-to-many-products-index")

      view
      |> element("tr[id^='products-#{product.id}'] td:nth-child(2) a[name='auix-show-product']")
      |> render_click()

      assert has_element?(view, @transactions_show)
      assert has_element?(view, "#{@transactions_show} table")

      view
      |> element("#auix-product-show-modal a[name='auix-edit-product']")
      |> render_click()

      {:ok, view, _html} = live(conn, mirror_path(backend, "one-to-many", "products"))
      view |> element("a[name='auix-new-product']") |> render_click()
      refute has_element?(view, "a[name='auix-new-product__product_transactions-form']")

      view
      |> form("#auix-product-form",
        product: %{
          reference: "created-product",
          name: "created product",
          description: "test item",
          quantity_initial: 345.67
        }
      )
      |> render_submit()

      {path, _flash} = assert_redirect(view)
      {:ok, created_view, _html} = live(conn, path)
      created_id = Repo.get_by!(MirrorCtx.Product, reference: "created-product").id
      assert has_element?(created_view, ".auix-one-to-many-field")

      transactions = [
        %{quantity: 10, type: "in", cost: 13.4},
        %{quantity: 15, type: "out", cost: 14.5},
        %{quantity: 20, type: "in", cost: 15.6}
      ]

      form_view =
        Enum.reduce(transactions, created_view, fn transaction, acc_view ->
          add_transaction(conn, acc_view, created_id, transaction)
        end)

      assert has_element?(form_view, "[name='auix-one_to_many-header-actions']")

      for transaction <- transactions do
        assert has_element?(
                 form_view,
                 "#{@transactions_form} table tr",
                 "#{transaction.cost}"
               )
      end

      transactions_query =
        from(t in MirrorCtx.ProductTransaction,
          where: t.product_id == ^created_id,
          order_by: t.id,
          limit: 1
        )

      first_transaction = Repo.one!(transactions_query)

      {:ok, edit_view, _html} =
        form_view
        |> element(
          "#{@transactions_form} table a[name='auix-edit-product__product_transaction-#{first_transaction.id}']"
        )
        |> render_click()
        |> follow_redirect(conn)

      assert has_element?(edit_view, "#auix-product_transaction-edit-modal")

      assert has_element?(
               edit_view,
               "select[name='product_transaction[product_id]'] option[selected][value='#{created_id}']"
             )

      edit_view
      |> form("#auix-product_transaction-form",
        product_transaction: %{quantity: "444", type: "out", cost: 11.5}
      )
      |> render_submit()

      {path, _flash} = assert_redirect(edit_view)
      {:ok, submitted_view, _html} = live(conn, path)

      assert has_element?(submitted_view, "#{@transactions_form} table tr", "444.000")

      delete_link =
        "#{@transactions_form} table a[phx-click*='#{first_transaction.id}'][name^='auix-delete-product__product_transaction-'][data-confirm='Are you sure?']"

      assert has_element?(submitted_view, delete_link)
      submitted_view |> element(delete_link) |> render_click()
      refute has_element?(submitted_view, delete_link)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "one-to-many", "products", "/#{with_rows.id}/edit"))

      c = "div[name='auix-one_to_many-product'] [name='auix-card']"

      assert has_element?(
               view,
               "#{c} > [name='auix-card-show']:first-child > a.auix-index-row-action[name^='auix-show-product__product_transaction-']"
             )

      assert has_element?(
               view,
               "#{c} [name='auix-card-menu-actions'] a.auix-index-row-action[name^='auix-show-product__product_transaction-']"
             )

      assert has_element?(
               view,
               "#{c} [name='auix-card-menu-actions'] a.auix-index-row-action[name^='auix-edit-product__product_transaction-']"
             )

      assert has_element?(
               view,
               "#{c} [name='auix-card-menu-destructive'] a.auix-index-row-action[name^='auix-delete-product__product_transaction-']"
             )

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "one-to-many", "products", "/#{product.id}/show"))

      assert column_texts(view, "tbody#product__product_transactions-show tr td:nth-of-type(1)") ==
               []

      assert has_element?(view, "#{@transactions_show} .auix-items-table-empty")
    end)
  end

  test "layout order_by and where order and filter a one-to-many list", %{conn: conn} do
    each_backend(fn backend ->
      [{_key, product}] = create_sample_products_with_transactions(1, 10, :one2)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "one-to-many", "products", "/#{product.id}/show"))

      quantities =
        view
        |> column_texts("tbody#product__product_transactions-show tr td:nth-of-type(2)")
        |> Enum.map(&(&1 |> Decimal.new() |> Decimal.to_integer()))

      assert quantities == Enum.map(10..1//-1, &(&1 * 2))

      %{id: location_id} =
        1 |> create_sample_product_locations(:test) |> Map.fetch!("id_1")

      create_sample_products(5, :test, %{product_location_id: location_id, quantity_initial: 1})

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "one-to-many", "product_locations", "/#{location_id}/edit")
        )

      assert column_texts(view, "tbody#product_location__products-form tr td:nth-of-type(1)") ==
               ["item_test-4", "item_test-3", "item_test-2"]
    end)
  end

  test "a one-to-many list is the index component of the related resource", %{conn: conn} do
    assert_raise ArgumentError,
                 ~r/the one-to-many field :products needs an index component for :product/,
                 fn ->
                   OneToMany.render(%{
                     field: %{
                       type: :one_to_many_association,
                       key: :products,
                       data: %{resource: :product}
                     },
                     auix: %{configurations: %{product: %{artifacts: %{index_component: nil}}}}
                   })
                 end

    one_to_many = %{
      field: %{key: :products},
      auix: %{entity: %{products: [%{id: 1}]}, layout_tree: %{order_by: nil, where: nil}}
    }

    assert OneToMany.load_rows(one_to_many) == [%{id: 1}]

    assert one_to_many
           |> put_in([:auix, :entity], %{products: %Ecto.Association.NotLoaded{}})
           |> OneToMany.load_rows() == []

    assert one_to_many |> put_in([:auix, :entity], nil) |> OneToMany.load_rows() == []

    each_backend(fn backend ->
      %{id: location_id} = 1 |> create_sample_product_locations(:test) |> Map.fetch!("id_1")

      products =
        create_sample_products(2, :test, %{product_location_id: location_id, quantity_initial: 1})

      product = products["id_test-1"]

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(
            backend,
            "one-to-many-component",
            "product_locations",
            "/#{location_id}/show"
          )
        )

      assert has_element?(
               view,
               "#auix-one_to_many-product_location__products-show.auix-one-to-many-container[data-phx-component]"
             )

      assert has_element?(
               view,
               "div[name='auix-one_to_many-product_location'] th[name='auix-column-label']",
               "Reference"
             )

      refute has_element?(
               view,
               "div[name='auix-one_to_many-product_location'] th[name='auix-column-label']",
               "Description"
             )

      {:error, {:live_redirect, %{to: to}}} =
        view
        |> element(
          "#auix-one_to_many-product_location__products-show table a[name='auix-show-product_location__product-#{product.id}']"
        )
        |> render_click()

      assert String.starts_with?(
               to,
               "/mirror-#{backend.slug}-one-to-many-component-products/#{product.id}/show"
             )
    end)
  end

  test "one-to-many header, row and footer actions are replaced and added", %{conn: conn} do
    each_backend(fn backend ->
      [{_key, product}] = create_sample_products_with_transactions(1, 3, :test)

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "one-to-many-actions", "products", "/#{product.id}/edit")
        )

      assert column_texts(
               view,
               "div[name='auix-one_to_many-product'] [name='auix-one_to_many-header-actions'] a"
             ) == ["", "custom new"]

      assert column_texts(
               view,
               "div[name='auix-one_to_many-product'] tbody tr:nth-of-type(1) a"
             ) == ["", "Custom edit", ""]

      c = "div[name='auix-one_to_many-product'] [name='auix-card']"

      assert has_element?(
               view,
               "#{c} > [name='auix-card-show']:first-child a[name^='auix-show-product__product_transaction-']"
             )

      assert has_element?(
               view,
               "#{c} [name='auix-card-menu-actions'] > .auix-items-card-menu-item:nth-child(1) a[name^='auix-show-product__product_transaction-']"
             )

      assert has_element?(
               view,
               "#{c} [name='auix-card-menu-actions'] > .auix-items-card-menu-item:nth-child(2) a",
               "Custom edit"
             )

      assert has_element?(
               view,
               "#{c} [name='auix-card-menu-destructive'] a[name^='auix-delete-product__product_transaction-']"
             )

      assert column_texts(
               view,
               "div[name='auix-one_to_many-product'] [name='auix-one_to_many-footer_actions'] a"
             ) == ["Custom footer", "Custom footer second"]
    end)
  end

  test "one-to-many actions take the action_icons of the field", %{conn: conn} do
    each_backend(fn backend ->
      %{id: location_id} = 1 |> create_sample_product_locations(:test) |> Map.fetch!("id_1")
      create_sample_products(1, :test, %{product_location_id: location_id, quantity_initial: 1})

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "one-to-many-actions", "product_locations", "/#{location_id}/edit")
        )

      assert has_element?(
               view,
               "div[name='auix-one_to_many-product_location'] [name='auix-one_to_many-header-actions'] a span.hero-sparkles"
             )

      assert has_element?(
               view,
               "div[name='auix-one_to_many-product_location'] tbody tr:nth-of-type(1) a[name^='auix-edit-'] span.hero-pencil-square"
             )

      assert has_element?(
               view,
               "div[name='auix-one_to_many-product_location'] tbody tr:nth-of-type(1) a[name^='auix-show-'] span.hero-eye"
             )
    end)
  end

  test "a one-to-one child is created and updated with its parent", %{conn: conn} do
    each_backend(fn backend ->
      [product | _rest] = create_sample_products_with_barcodes(2)
      create_sample_products(1, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "one-to-one", "products", "/new"))

      assert has_element?(view, "#auix-one-to-one-product_barcode-form")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "blank_code_ref",
          "name" => "Blank code",
          "quantity_initial" => "3",
          "product_barcode" => %{"code" => ""}
        }
      })
      |> render_submit()

      assert has_element?(view, "#auix-product-form")
      assert has_element?(view, ".auix-flash--error")
      assert Repo.get_by(MirrorCtx.Product, reference: "blank_code_ref") == nil

      for field <- ~w(code symbology registered_at) do
        assert has_element?(view, "input[name='product[product_barcode][#{field}]']")
      end

      refute has_element?(view, "select[name='product[product_barcode][product_id]']")
      refute has_element?(view, "input[name='product[product_barcode][product_id]']")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "nested_ref",
          "name" => "Nested product",
          "quantity_initial" => "3",
          "product_barcode" => %{
            "code" => "5901234123457",
            "symbology" => "EAN-13",
            "registered_at" => "2026-03-04"
          }
        }
      })
      |> render_submit()

      created =
        MirrorCtx.Product
        |> Repo.get_by!(reference: "nested_ref")
        |> Repo.preload(:product_barcode)

      assert created.name == "Nested product"
      assert created.product_barcode.code == "5901234123457"
      assert created.product_barcode.registered_at == ~D[2026-03-04]
      assert created.product_barcode.product_id == created.id

      edit_path = mirror_path(backend, "one-to-one", "products", "/#{product.id}/edit")
      {:ok, view, _html} = live(conn, edit_path)

      assert has_element?(
               view,
               "input[name='product[product_barcode][code]'][value='4006381330001']"
             )

      assert has_element?(view, "input[name='product[product_barcode][id]'][type='hidden']")

      barcodes_before = Repo.aggregate(MirrorCtx.ProductBarcode, :count)

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "product_barcode" => %{"code" => "9781234567897", "symbology" => "UPC-A"}
        }
      })
      |> render_submit()

      assert Repo.aggregate(MirrorCtx.ProductBarcode, :count) == barcodes_before

      updated = Repo.get_by!(MirrorCtx.ProductBarcode, product_id: product.id)
      assert updated.code == "9781234567897"
    end)
  end

  test "a one-to-one child is shown read-only and is no index column", %{conn: conn} do
    each_backend(fn backend ->
      [product | _rest] = create_sample_products_with_barcodes(2)
      %{"id_test-1" => bare} = create_sample_products(1, :test)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "one-to-one", "products", "/#{product.id}/show"))

      assert has_element?(view, "#auix-one-to-one-product_barcode-show")

      assert has_element?(
               view,
               "#auix-one-to-one-product_barcode-show input[value='4006381330001']"
             )

      refute has_element?(view, "#auix-one-to-one-product_barcode-show input:not([disabled])")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "one-to-one", "products", "/#{bare.id}/show"))

      assert has_element?(
               view,
               "#auix-one-to-one-product_barcode-show > .auix-header .auix-one-to-one-empty-msg"
             )

      {:ok, view, _html} = live(conn, mirror_path(backend, "one-to-one", "products"))
      refute has_element?(view, "table.auix-items-table thead", "Product Barcode")
    end)
  end

  test "many-to-many membership is selected, toggled and saved", %{conn: conn} do
    each_backend(fn backend ->
      {[product_1, product_2], suppliers} = create_sample_products_with_suppliers(2, 4)
      [first | _rest] = suppliers
      all_ids = suppliers |> Enum.map(& &1.id) |> Enum.sort()
      new_path = mirror_path(backend, "many-to-many", "products", "/new")

      {:ok, view, _html} = live(conn, new_path)
      assert has_element?(view, "input[type='checkbox'][name='product[suppliers][]']")
      assert has_element?(view, "input[type='hidden'][name='product[suppliers][]']")
      assert options_count(view) == 4
      assert checked_ids(view) == []

      {:ok, _} =
        product_1
        |> Repo.preload(:suppliers)
        |> then(&MirrorCtx.update_product(&1, %{"suppliers" => [first.id]}))

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-many", "products", "/#{product_1.id}/edit"))

      assert options_count(view) == 4
      assert checked_ids(view) == [first.id]

      {:ok, view, _html} = live(conn, new_path)
      assert toggle_state(view) == :none
      toggle_all(view, "true")
      assert view |> checked_ids() |> Enum.sort() == all_ids
      assert toggle_state(view) == :all

      edit_2_path = mirror_path(backend, "many-to-many", "products", "/#{product_2.id}/edit")
      {:ok, view, _html} = live(conn, edit_2_path)
      assert toggle_state(view) == :all
      toggle_all(view, "false")
      assert checked_ids(view) == []
      assert toggle_state(view) == :none

      {:ok, view, _html} = live(conn, edit_2_path)

      view
      |> form("#auix-product-form", %{"product" => %{"suppliers" => [first.id]}})
      |> render_change(%{"_target" => ["product", "suppliers"]})

      assert toggle_state(view) == :mixed
      toggle_all(view, "true")
      assert view |> checked_ids() |> Enum.count() == 4
      assert toggle_state(view) == :all

      {:ok, view, _html} = live(conn, new_path)
      chosen = suppliers |> Enum.take(2) |> Enum.map(& &1.id)

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "m2m_ref",
          "name" => "Many suppliers",
          "quantity_initial" => "5",
          "suppliers" => chosen
        }
      })
      |> render_submit()

      added =
        MirrorCtx.Product |> Repo.get_by!(name: "Many suppliers") |> Repo.preload(:suppliers)

      assert Enum.count(added.suppliers) == 2
      assert join_row_count() == 7

      {:ok, view, _html} = live(conn, edit_2_path)

      view
      |> form("#auix-product-form", %{"product" => %{"suppliers" => [first.id]}})
      |> render_submit()

      assert join_row_count() == 4
      assert Repo.aggregate(MirrorCtx.Supplier, :count) == 4

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-many", "products", "/#{product_1.id}/edit"))

      view
      |> form("#auix-product-form", %{"product" => %{"suppliers" => [""]}})
      |> render_submit()

      assert join_row_count() == 3
      assert Repo.aggregate(MirrorCtx.Supplier, :count) == 4

      {:ok, view, _html} = live(conn, new_path)
      toggle_all(view, "true")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "m2m_all",
          "name" => "All suppliers",
          "quantity_initial" => "5"
        }
      })
      |> render_submit()

      assert join_row_count() == 7
    end)
  end

  test "many-to-many membership is shown read-only and is no index column", %{conn: conn} do
    each_backend(fn backend ->
      {[product | _rest], suppliers} = create_sample_products_with_suppliers(2, 4)
      %{"id_test-1" => bare} = create_sample_products(1, :test, %{quantity_initial: 1})

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-many", "products", "/#{product.id}/show"))

      refute has_element?(view, "#auix-many-to-many-suppliers-show input[type='checkbox']")

      for supplier <- suppliers do
        assert has_element?(
                 view,
                 "#auix-many-to-many-suppliers-show-options .auix-selected-list-item",
                 supplier.name
               )
      end

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-many", "products", "/#{bare.id}/show"))

      assert has_element?(
               view,
               "#auix-many-to-many-suppliers-show-options .auix-selected-list-empty-msg",
               "No items to show"
             )

      {:ok, view, _html} = live(conn, mirror_path(backend, "many-to-many", "products"))
      refute has_element?(view, "table.auix-items-table thead", "Supplier")
    end)
  end

  test "many-to-many label, header and footer actions are replaced and added", %{conn: conn} do
    each_backend(fn backend ->
      {[product | _rest], _suppliers} = create_sample_products_with_suppliers(2, 4)

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "many-to-many-actions", "products", "/#{product.id}/edit")
        )

      refute has_element?(view, @toggle_all)

      assert has_element?(
               view,
               ".auix-checkbox-group-label-actions button[name='auix-custom-label-suppliers']"
             )

      assert has_element?(
               view,
               ".auix-checkbox-group-actions button[name='auix-custom-header-suppliers']"
             )

      assert has_element?(
               view,
               "[name='auix-many-to-many-footer-actions-suppliers'] button[name='auix-custom-footer-suppliers']"
             )
    end)
  end

  test "many-to-many options take their label from the related resource", %{conn: conn} do
    each_backend(fn backend ->
      {_products, suppliers} = create_sample_products_with_suppliers(2, 4)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "many-to-many-actions", "products", "/new"))

      assert view |> option_labels() |> Enum.sort() ==
               suppliers |> Enum.map(& &1.name) |> Enum.sort()
    end)
  end

  test "an embeds-one renders and saves its nested fields", %{conn: conn} do
    each_backend(fn backend ->
      [product] = create_sample_products_with_embeds(1)

      {:ok, view, _html} = live(conn, mirror_path(backend, "embeds", "products"))
      refute has_element?(view, "th", "Packaging")
      assert has_element?(view, "th", "Reference")
      assert view |> column_texts("table.auix-items-table tbody tr") |> Enum.count() == 1

      {:ok, view, _html} = live(conn, mirror_path(backend, "embeds", "products", "/new"))
      assert has_element?(view, ".auix-header-title", "Embeds")

      assert has_element?(
               view,
               ".auix-header-subtitle",
               "Creates a new 'Product' record in your database"
             )

      assert has_element?(view, ".auix-embeds-one-container")
      assert has_element?(view, "[name='product[packaging][material]']")
      assert has_element?(view, "[name='product[packaging][fragile]']")
      assert has_element?(view, "[name='product[packaging][notes]']")

      view
      |> form("#auix-product-form",
        product: %{
          reference: "John Test",
          name: "thetest@test.com",
          quantity_initial: 1,
          packaging: %{material: "bag", fragile: true, notes: "friends only"}
        }
      )
      |> render_submit()

      created = Repo.get_by!(MirrorCtx.Product, reference: "John Test")
      assert created.name == "thetest@test.com"
      assert created.packaging.fragile == true
      assert created.packaging.material == :bag

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "embeds", "products", "/#{product.id}/edit"))

      assert has_element?(view, ".auix-embeds-one-container")
      assert has_element?(view, "[name='product[packaging][material]']")
      assert has_element?(view, "[name='product[packaging][fragile]']")
      assert has_element?(view, "[name='product[packaging][notes]'][value='note 1']")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "embeds", "products", "/#{product.id}/show"))

      assert has_element?(view, "div.auix-show-container input[name='notes'][value='note 1']")
    end)
  end

  test "an embeds-many lists its entries and opens expanded", %{conn: conn} do
    each_backend(fn backend ->
      [product] = create_sample_products_with_embeds(1)
      %{"id_test-1" => bare} = create_sample_products(1, :test, %{quantity_initial: 1})

      {:ok, view, _html} = live(conn, mirror_path(backend, "embeds", "products"))
      refute has_element?(view, "th", "Contacts")
      assert has_element?(view, "th", "Reference")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "embeds", "products", "/#{product.id}/show"))

      assert has_element?(view, "div.auix-show-container a[name='auix-edit-product'] button")

      assert has_element?(
               view,
               "div.auix-show-container input[name='reference'][value='#{product.reference}']"
             )

      assert has_element?(
               view,
               "div.auix-show-container input[name='name'][value='#{product.name}']"
             )

      assert has_element?(view, ".auix-embeds-many-container")

      for contact <- product.contacts do
        assert has_element?(
                 view,
                 ".auix-embeds-many-container details input[name='email'][value='#{contact.email}']"
               )

        assert has_element?(
                 view,
                 ".auix-embeds-many-container details input[name='name'][value='#{contact.name}']"
               )
      end

      refute has_element?(view, ".auix-embeds-many-container details[open]")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "embeds", "products", "/#{product.id}/edit"))

      for contact <- product.contacts do
        assert has_element?(
                 view,
                 ".auix-embeds-many-container input[value='#{contact.email}']"
               )
      end

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "embeds", "products", "/#{bare.id}/show"))

      assert has_element?(view, ".auix-embeds-many-container")
      refute has_element?(view, ".auix-embeds-many-container input[name='email']")

      for suffix <- ["show", "edit"] do
        {:ok, view, _html} =
          live(
            conn,
            mirror_path(backend, "embeds-expanded", "products", "/#{product.id}/#{suffix}")
          )

        assert has_element?(view, ".auix-embeds-many-container details[open]")
      end
    end)
  end

  test "embeds-many actions take the action_icons of the field", %{conn: conn} do
    each_backend(fn backend ->
      [product] = create_sample_products_with_embeds(1)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "embeds-expanded", "products", "/#{product.id}/edit"))

      assert has_element?(
               view,
               "div[name='auix-embeds_many-header_actions'] > button[title='Add new entry'] span.hero-sparkles"
             )

      assert has_element?(
               view,
               "div[name='auix-embeds_many-header_actions'] > button span.auix-action-label",
               "Add new entry"
             )

      assert has_element?(
               view,
               "div[name='auix-embeds_many-footer_actions'] button span.hero-plus"
             )

      assert has_element?(view, "#auix-remove-button-0 button span.hero-x-mark")

      view
      |> element(
        "div[name='auix-embeds_many-header_actions'] > button[phx-click='toggle-add-embeds']"
      )
      |> render_click()

      entry = %{"email" => "early@test.com", "name" => "Early"}

      # An add-entry event before the entry form is validated is ignored
      view
      |> with_target(".auix-embeds-many-container")
      |> render_hook("add-embeds-many", entry)

      refute has_element?(view, "div[name='auix-embeds_many-header_actions']")
      refute has_element?(view, ".auix-embeds-many-container input[value='early@test.com']")
    end)
  end

  test "two embeds on one schema save in one submit", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "embeds", "products", "/new"))

      view
      |> form("#auix-product-form")
      |> render_submit(%{
        product: %{
          reference: "two-embeds",
          name: "Two embeds",
          quantity_initial: 1,
          packaging: %{material: "box", fragile: "true", notes: "n"},
          contacts: %{
            "0" => %{email: "a@test.com", name: "A"},
            "1" => %{email: "b@test.com", name: "B"}
          }
        }
      })

      created = Repo.get_by!(MirrorCtx.Product, reference: "two-embeds")
      assert created.packaging.material == :box
      assert created.packaging.fragile == true
      assert created.packaging.notes == "n"

      assert created.contacts |> Enum.map(& &1.email) |> Enum.sort() == [
               "a@test.com",
               "b@test.com"
             ]

      edit_path = mirror_path(backend, "embeds", "products", "/#{created.id}/edit")
      {:ok, view, _html} = live(conn, edit_path)

      # Removing the first saved entry keeps the second one, in the form and once saved (#634)
      view |> element("#auix-remove-button-0 button") |> render_click()

      view
      |> element("#auix-remove-button-0 .auix-confirm-button--actions button:first-of-type")
      |> render_click()

      assert has_element?(view, "input[name='product[contacts][0][email]'][value='b@test.com']")
      refute has_element?(view, "input[name='product[contacts][1][email]']")

      view
      |> form("#auix-product-form")
      |> render_submit(%{
        product: %{
          name: "Two embeds edited",
          packaging: %{material: "bag", fragile: "true", notes: "n"}
        }
      })

      edited = Repo.get!(MirrorCtx.Product, created.id)
      assert edited.name == "Two embeds edited"
      assert edited.packaging.material == :bag
      assert Enum.map(edited.contacts, & &1.email) == ["b@test.com"]

      # Library defect on :ctx (#581): a validation error on a nested record exits the LiveView
      # with a FunctionClauseError
      if backend.name == :ash do
        {:ok, view, _html} = live(conn, edit_path)

        view
        |> form("#auix-product-form")
        |> render_submit(%{
          product: %{
            name: "Invalid contact",
            contacts: %{"0" => %{email: "not-an-email", name: "A"}}
          }
        })

        assert has_element?(view, "#auix-product-form")
        assert has_element?(view, ".auix-flash--error")
        assert Repo.get!(MirrorCtx.Product, created.id).name == "Two embeds edited"
      end
    end)
  end

  @spec add_transaction(Plug.Conn.t(), View.t(), binary(), map()) :: View.t()
  defp add_transaction(conn, view, product_id, transaction) do
    {:ok, new_view, _html} =
      view
      |> element("a[name='auix-new-product__product_transactions-form']")
      |> render_click()
      |> follow_redirect(conn)

    assert has_element?(new_view, "#auix-product_transaction-new-modal")

    assert has_element?(
             new_view,
             "select[name='product_transaction[product_id]'] option[selected][value='#{product_id}']"
           )

    assert new_view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("select[name='product_transaction[product_id]']")
           |> LazyHTML.attribute("readonly") != []

    new_view
    |> form("#auix-product_transaction-form",
      product_transaction: %{
        quantity: "#{transaction.quantity}",
        type: transaction.type,
        cost: transaction.cost
      }
    )
    |> render_submit()

    {path, _flash} = assert_redirect(new_view)
    {:ok, reloaded_view, _html} = live(conn, path)
    reloaded_view
  end

  @spec column_texts(View.t(), binary()) :: [binary()]
  defp column_texts(view, selector) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end

  @spec option_texts(View.t(), binary(), binary()) :: [binary()]
  defp option_texts(view, select, prefix),
    do:
      view
      |> column_texts("#{select} option")
      |> Enum.filter(&String.starts_with?(&1, prefix))

  @spec join_row_count() :: non_neg_integer()
  defp join_row_count, do: Repo.aggregate(MirrorCtx.ProductSupplier, :count)

  @spec options_count(View.t()) :: non_neg_integer()
  defp options_count(view),
    do:
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query(@checkbox_group)
      |> Enum.count()

  @spec option_labels(View.t()) :: [binary()]
  defp option_labels(view), do: column_texts(view, ".auix-checkbox-group-option-label")

  @spec checked_ids(View.t()) :: [binary()]
  defp checked_ids(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#{@checkbox_group}[checked]")
    |> Enum.map(&(&1 |> LazyHTML.attribute("value") |> List.first()))
  end

  @spec toggle_all(View.t(), binary()) :: binary()
  defp toggle_all(view, state) do
    view
    |> form("#auix-product-form", %{"auix_toggle_all__suppliers" => state})
    |> render_change(%{"_target" => ["auix_toggle_all__suppliers"]})
  end

  @spec toggle_state(View.t()) :: :all | :none | :mixed
  defp toggle_state(view) do
    toggle = view |> render() |> LazyHTML.from_document() |> LazyHTML.query(@toggle_all)

    cond do
      LazyHTML.attribute(toggle, "checked") != [] -> :all
      toggle |> LazyHTML.attribute("class") |> to_string() =~ "auix-checkbox--mixed" -> :mixed
      true -> :none
    end
  end
end
