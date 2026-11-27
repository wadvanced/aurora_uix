defmodule Aurora.UixWeb.Test.FormScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case

  import ExUnit.CaptureLog

  alias Aurora.Uix.Field
  alias Aurora.Uix.Field.Upload
  alias Aurora.Uix.Renderers
  alias Aurora.Uix.Renderers.BuiltIn
  alias Aurora.Uix.Repo
  alias Aurora.Uix.Templates.Basic.CoreComponents
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderers.DefaultRenderer
  alias Aurora.Uix.Templates.Basic.Renderers.Predefined
  alias Aurora.Uix.Test.MirrorCtx
  alias Aurora.UixWeb.Test.Mirror.Handlers.HostRegistrar
  alias Aurora.UixWeb.Test.Mirror.Handlers.HostToggle
  alias Phoenix.LiveViewTest.View

  @inactive "#auix-product-form input[type=checkbox][name='product[inactive]']"
  @deleted "#auix-product-form input[type=checkbox][name='product[deleted]']"
  @first_show_link "tr[id^='products']:nth-of-type(1) td:nth-child(2) a[name='auix-show-product']"
  @first_edit_link "tr[id^='products']:nth-of-type(1) a[name='auix-edit-product']"
  @first_delete_link "tr[id^='products']:nth-of-type(1) a[name='auix-delete-product']"
  @download_button "button[phx-click='auix_download_upload']"

  test "a product is created with every field type", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_1" => location} = create_sample_product_locations(2, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products", "/new"))
      assert has_element?(view, ".auix-form-container")
      assert has_element?(view, "[name='auix-form-footer-actions']")
      assert has_element?(view, "textarea[name='product[description]']")

      view
      |> form("#auix-product-form",
        product: %{
          reference: "f-1",
          name: "Form one",
          description: "Long text",
          quantity_initial: "5",
          units_per_box: "12",
          margin: "0.25",
          list_price: "9.99",
          released_on: "2026-01-15",
          opens_at: "08:30",
          audited_at: "2026-01-15T10:00",
          discontinued_at: "2026-02-01T12:00",
          status: "online_only",
          grade: "premium",
          inactive: "true",
          labels: ["", "fragile", "hazardous"],
          product_location_id: location.id
        }
      )
      |> render_submit()

      product = Repo.get_by!(MirrorCtx.Product, reference: "f-1")
      assert Decimal.equal?(product.quantity_initial, Decimal.new("5"))
      assert product.units_per_box == 12
      assert product.margin == 0.25
      assert Decimal.equal?(product.list_price, Decimal.new("9.99"))
      assert product.released_on == ~D[2026-01-15]
      assert product.opens_at == ~T[08:30:00]
      assert product.audited_at == ~N[2026-01-15 10:00:00]
      assert product.discontinued_at == ~U[2026-02-01 12:00:00Z]
      assert product.status == "online_only"
      assert product.grade == :premium
      assert product.inactive == true
      assert product.deleted == false
      assert product.labels == [:fragile, :hazardous]
      assert product.product_location_id == location.id

      {:ok, index_view, _html} = live(conn, mirror_path(backend, "form", "products"))
      assert has_element?(index_view, "td", "f-1")
      assert has_element?(index_view, "td", "Fragile, Hazardous")
    end)
  end

  test "the new form validates, saves and lists the product without a remount", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "products", "/new"))

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

      assert has_element?(view, "div#auix-product-new-modal header", "Add a Product")

      view
      |> form("#auix-product-form",
        product: %{reference: "test-first", name: "This is the first test"}
      )
      |> render_change()

      assert_blank_error(view, backend)

      view
      |> form("#auix-product-form", product: %{quantity_initial: 11})
      |> render_submit()

      {:ok, index_view, _html} = live(conn, mirror_path(backend, "options", "products"))
      assert has_element?(index_view, ".auix-header-title", "The Products Listing")
      assert has_element?(index_view, "td", "test-first")

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "products", "/new"))
      unique_reference = "test-#{System.system_time(:nanosecond)}"

      view
      |> form("#auix-product-form",
        product: %{
          reference: unique_reference,
          name: "This is the second test",
          quantity_initial: 11
        }
      )
      |> render_submit()

      # The parent index only refreshes once it processes the `:saved` handle_info message,
      # which is queued after the "save" event's own reply. A follow-up render/1 call queues
      # behind it in the same process mailbox, so it deterministically observes the refresh.
      _ = render(view)
      refute has_element?(view, ".auix-items-table-empty")
      assert has_element?(view, "td", unique_reference)
    end)
  end

  test "the index lists its columns and its links open the new, show and edit pages", %{
    conn: conn
  } do
    each_backend(fn backend ->
      create_sample_products(5, :test)
      index_path = mirror_path(backend, "options", "products")

      {:ok, view, html} = live(conn, index_path)
      assert has_element?(view, ".auix-header-title", "The Products Listing")
      assert has_element?(view, "a[name='auix-new-product']", "New Product")

      assert html
             |> LazyHTML.from_document()
             |> LazyHTML.query("thead tr th[name='auix-column-label']")
             |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
             |> List.delete_at(0) == [
               "Id",
               "Reference",
               "Name",
               "Description",
               "Quantity At Hand"
             ]

      assert has_element?(view, @first_show_link)
      assert has_element?(view, @first_edit_link)
      assert has_element?(view, @first_delete_link)

      view |> element("a[name='auix-new-product']") |> render_click()
      assert has_element?(view, "[name='auix-save-product']")

      assert has_element?(
               view,
               "div#auix-product-new-modal-container div button[phx-click*='exec']"
             )

      {:ok, view, _html} = live(conn, index_path)
      view |> element(@first_show_link) |> render_click()
      assert has_element?(view, ".auix-header-title", "Details for Product")
      # The show layout sets a nil page_subtitle.
      refute has_element?(view, "#auix-product-show-modal .auix-header-subtitle")
      assert has_element?(view, "a[name='auix-edit-product']")
      assert has_element?(view, "div[name='auix-show-navigate-back'] a:nth-of-type(1)")

      assert has_element?(view, "#auix-product-show-modal a[name='auix-edit-product']")
      view |> element("#auix-product-show-modal a[name='auix-edit-product']") |> render_click()
      assert has_element?(view, "[name='auix-save-product']")

      {:ok, view, _html} = live(conn, index_path)
      view |> element(@first_edit_link) |> render_click()
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

  test "a product is edited from the index and from the show view", %{conn: conn} do
    each_backend(fn backend ->
      products = create_sample_products(3, :test, %{quantity_initial: 1})

      %{"id_1" => _first_location, "id_2" => second_location} =
        create_sample_product_locations(2, :test)

      %{"id_test-1" => first, "id_test-2" => second} = products

      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products"))

      view
      |> element(
        ".auix-items-table-action-cell a[name='auix-edit-product'][phx-value-route_path$='#{first.id}/edit']"
      )
      |> render_click()

      assert has_element?(view, "input[name='product[name]'][value='#{first.name}']")
      assert has_element?(view, "input[name='product[reference]'][value='#{first.reference}']")

      submit_edit(view, second_location.id)
      assert_edited(first.id, second_location.id)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{second.id}/show"))

      view
      |> element("a[name='auix-edit-product'][phx-value-route_path$='#{second.id}/show-edit']")
      |> render_click()

      submit_edit(view, second_location.id)
      assert_edited(second.id, second_location.id)
    end)
  end

  test "a product is deleted from the index", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => first} = create_sample_products(5, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "options", "products"))

      assert has_element?(view, "#{@first_delete_link}[data-confirm*='Are you sure?']")
      assert has_element?(view, "#{@first_delete_link}[phx-click*='event'][phx-click*='delete']")

      render_click(view, "delete", %{"id" => first.id})

      refute has_element?(view, "#products-#{first.id}")
      assert Repo.get(MirrorCtx.Product, first.id) == nil
    end)
  end

  test "a blank required field keeps the form open and marks the field", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products", "/new"))

      view
      |> form("#auix-product-form", product: %{reference: "r", name: ""})
      |> render_submit()

      assert Repo.aggregate(MirrorCtx.Product, :count) == 0

      assert has_element?(view, "#auix-product-form .auix-error-message")
      assert_blank_error(view, backend)

      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{product.id}/edit"))

      view
      |> form("#auix-product-form", product: %{name: ""})
      |> render_submit()

      assert has_element?(view, "#auix-product-form")
      assert Repo.get!(MirrorCtx.Product, product.id).name == "Item test-1"

      assert has_element?(view, "#auix-product-form .auix-error-message")
    end)
  end

  test "form inputs and show inputs carry the classes the theme targets", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, edit_view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{product.id}/edit"))

      assert has_element?(
               edit_view,
               ".auix-form-field-container input.auix-input[name='product[name]']"
             )

      {:ok, show_view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{product.id}/show"))

      assert has_element?(show_view, ".auix-show-content input.auix-input[disabled]")
    end)
  end

  test "a copyable input renders its copy button and warns without an id" do
    html = render_input(%{type: "text", id: "my-field", copyable: true})

    assert html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("[data-auix-copy-target='my-field']")
           |> Enum.any?()

    assert html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query("[phx-hook='AuixCopyToClipboard']")
           |> Enum.any?()

    refute copy_warning?(fn -> render_input(%{type: "text", id: "my-field", copyable: true}) end)

    assert copy_warning?(fn ->
             with_warning_level(fn -> render_input(%{type: "text", id: nil, copyable: true}) end)
           end)

    assert copy_warning?(fn ->
             with_warning_level(fn ->
               render_input(%{type: "textarea", id: nil, copyable: true})
             end)
           end)

    refute copy_warning?(fn ->
             render_input(%{
               type: "checkbox",
               id: nil,
               name: "my-check",
               value: false,
               checked: false,
               copyable: false
             })
           end)
  end

  test "success and warning flashes render with their class and icon", %{conn: conn} do
    each_backend(fn backend ->
      create_sample_products(1, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "form-options", "products"))

      refute has_element?(view, "#flash-success")
      refute has_element?(view, "#flash-warning")

      render_click(view, "flash_kinds", %{})

      assert has_element?(view, "#flash-success.auix-flash--success", "Saved")
      assert has_element?(view, "#flash-success .hero-check-circle-mini")
      assert has_element?(view, "#flash-warning.auix-flash--warning", "Check")
      assert has_element?(view, "#flash-warning .hero-exclamation-triangle-mini")
    end)
  end

  test "the discard guard holds a changed form", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)
      edit_path = mirror_path(backend, "form", "products", "/#{product.id}/edit")

      {:ok, view, _html} = live(conn, edit_path)
      assert has_element?(view, "#auix-product-edit-modal[data-cancel*='auix_request_close']")
      refute has_element?(view, "#auix-product-edit-modal[data-cancel*='phx-remove']")

      {:ok, show_view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{product.id}/show"))

      assert has_element?(show_view, "#auix-product-show-modal[data-cancel*='auix_route_back']")

      {:ok, view, _html} = live(conn, edit_path)
      request_close(view)
      refute has_element?(view, "#auix-product-edit-modal")
      refute has_element?(view, "#auix-product-discard-confirm-modal")
      refute has_element?(view, "button.auix-button--danger")

      view = open_changed_edit(conn, edit_path)
      request_close(view)
      assert has_element?(view, "#auix-product-edit-modal")

      assert has_element?(
               view,
               "#auix-product-discard-confirm-modal button[name='auix-keep-editing']"
             )

      assert has_element?(
               view,
               "#auix-product-discard-confirm-modal button.auix-button--danger[name='auix-discard-changes']"
             )

      view |> element("button[name='auix-keep-editing']") |> render_click()
      refute has_element?(view, "#auix-product-discard-confirm-modal")

      assert has_element?(
               view,
               "#auix-product-edit-modal input[name='product[name]'][value='Changed name']"
             )

      view = open_changed_edit(conn, edit_path)
      request_close(view)
      view |> element("button[name='auix-discard-changes']") |> render_click()
      refute has_element?(view, "#auix-product-edit-modal")
      assert Repo.get!(MirrorCtx.Product, product.id).name == "Item test-1"

      view = open_changed_edit(conn, edit_path)
      request_close(view)
      request_close(view)
      refute has_element?(view, "#auix-product-discard-confirm-modal")
      assert has_element?(view, "#auix-product-edit-modal")

      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products", "/new"))

      view
      |> form("#auix-product-form", product: %{name: "Brand new"})
      |> render_change()

      request_close(view, :new)
      assert has_element?(view, "#auix-product-new-modal")
      assert has_element?(view, "#auix-product-discard-confirm-modal")

      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products", "/new"))
      request_close(view, :new)
      {path, _flash} = assert_redirect(view)
      assert String.starts_with?(path, mirror_path(backend, "form", "products", "?"))

      view =
        open_changed_edit(
          conn,
          mirror_path(backend, "form-options", "products", "/#{product.id}/edit")
        )

      request_close(view)
      refute has_element?(view, "#auix-product-discard-confirm-modal")
      refute has_element?(view, "#auix-product-edit-modal")
    end)
  end

  test "select and enum fields render one option per value", %{conn: conn} do
    each_backend(fn backend ->
      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products", "/new"))

      assert has_element?(view, "select[name='product[status]']")

      for {value, index} <-
            Enum.with_index(~w(in_stock discontinued online_only in_store_only), 1) do
        assert has_element?(
                 view,
                 "select[name='product[status]'] option:nth-of-type(#{index})[value='#{value}']"
               )
      end

      assert count(view, "select[name='product[grade]'] option") == 3
    end)
  end

  test "a field the library cannot edit renders read-only", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} =
        create_sample_products(2, :test, fn
          1 -> %{labels: [:fragile, :hazardous]}
          _index -> %{}
        end)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "renderers", "products", "/#{product.id}/edit"))

      # Never an `<input type="unimplemented">`, which a browser silently renders as a text box.
      refute has_element?(view, "input[name='product[labels]']")
      refute has_element?(view, "input[type='unimplemented']")
      assert has_element?(view, "li", "fragile")
      assert has_element?(view, "li", "hazardous")

      {:ok, view, _html} = live(conn, mirror_path(backend, "renderers", "products", "/new"))
      assert has_element?(view, ".auix-selected-list-empty-msg")

      {:ok, view, _html} = live(conn, mirror_path(backend, "renderers", "products"))
      assert has_element?(view, "[name='auix-show-product']", "fragile, hazardous")
    end)
  end

  test "a multi-select checks, toggles, saves and shows its values", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_two-1" => two} = create_sample_products(1, :two, %{labels: [:fragile, :hazardous]})
      %{"id_one-1" => one} = create_sample_products(1, :one, %{labels: [:fragile]})
      %{"id_none-1" => none} = create_sample_products(1, :none, %{labels: []})

      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products", "/new"))
      assert has_element?(view, ".auix-multi-select-container")
      assert has_element?(view, "input[type='hidden'][name='product[labels][]']")
      refute has_element?(view, "select[multiple][name='product[labels][]']")

      for value <- ~w(fragile perishable hazardous) do
        assert has_element?(
                 view,
                 "input[type='checkbox'][name='product[labels][]'][value='#{value}']"
               )
      end

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "multi_ref",
          "name" => "Multi labels",
          "quantity_initial" => "5",
          "labels" => ["", "fragile", "perishable"]
        }
      })
      |> render_submit()

      assert %MirrorCtx.Product{labels: [:fragile, :perishable]} =
               Repo.get_by(MirrorCtx.Product, reference: "multi_ref")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{two.id}/edit"))

      assert checked_values(view) == ["fragile", "hazardous"]

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{one.id}/edit"))

      assert toggle_state(view) == :mixed
      toggle_all(view, "true")
      assert checked_values(view) == ["fragile", "perishable", "hazardous"]
      assert toggle_state(view) == :all
      toggle_all(view, "false")
      assert checked_values(view) == []
      assert toggle_state(view) == :none

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{two.id}/show"))

      assert selected_items(view) == ["Fragile", "Hazardous"]
      refute has_element?(view, "input[type='checkbox'][name='product[labels][]']")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{none.id}/show"))

      assert has_element?(
               view,
               "#auix-multi-select-labels-show-options .auix-selected-list-empty-msg",
               "No options to show"
             )
    end)
  end

  test "multi-select label, header and footer actions are replaced and added", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test, %{labels: [:fragile]})

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form-options", "products", "/#{product.id}/edit"))

      refute has_element?(view, "input#auix-multi-select-toggle_all-labels")

      assert has_element?(
               view,
               ".auix-checkbox-group-label-actions button[name='auix-custom-label-labels']"
             )

      assert has_element?(
               view,
               ".auix-checkbox-group-actions button[name='auix-custom-header-labels']"
             )

      assert has_element?(
               view,
               "[name='auix-multi-select-footer-actions-labels'] button[name='auix-custom-footer-labels']"
             )
    end)
  end

  test "booleans keep their checked state in the edit form", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_inactive-1" => inactive} = create_sample_products(1, :inactive, %{inactive: true})
      %{"id_deleted-1" => deleted} = create_sample_products(1, :deleted, %{deleted: true})

      %{"id_unchecked-1" => unchecked} =
        create_sample_products(1, :unchecked, %{inactive: false, deleted: false})

      %{"id_both-1" => both} =
        create_sample_products(1, :both, %{inactive: true, deleted: true})

      {:ok, view, _html} = live(conn, edit_path(backend, inactive))
      assert has_element?(view, "#{@inactive}[checked]")

      {:ok, view, _html} = live(conn, edit_path(backend, deleted))
      assert has_element?(view, "#{@deleted}[disabled][checked]")

      {:ok, view, _html} = live(conn, edit_path(backend, unchecked))
      assert has_element?(view, @inactive)
      assert has_element?(view, @deleted)
      refute has_element?(view, "#{@inactive}[checked]")
      refute has_element?(view, "#{@deleted}[checked]")

      {:ok, view, _html} = live(conn, mirror_path(backend, "form", "products"))

      view
      |> element(
        ".auix-items-table-action-cell a[name='auix-edit-product'][phx-value-route_path$='#{both.id}/edit']"
      )
      |> render_click()

      assert_checked(view)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form", "products", "/#{both.id}/show"))

      view
      |> element("a[name='auix-edit-product'][phx-value-route_path$='#{both.id}/show-edit']")
      |> render_click()

      assert_checked(view)
    end)
  end

  test "an upload field renders its file input, lists a selected file and cancels it", %{
    conn: conn
  } do
    field_with_upload = %Field{key: :image, upload: %Upload{allow: [], consume: & &1}}
    field_without = %Field{key: :name, data: %{}}

    auix = %{
      configurations: %{
        product: %{resource_config: %{fields: %{image: field_with_upload, name: field_without}}}
      },
      resource_name: :product
    }

    result = BasicHelpers.upload_fields(auix)
    assert length(result) == 1
    assert hd(result).key == :image

    assert BasicHelpers.upload_fields(%{
             configurations: %{product: %{resource_config: %{fields: %{name: field_without}}}},
             resource_name: :product
           }) == []

    each_backend(fn backend ->
      new_path = mirror_path(backend, "uploads", "products", "/new")

      {:ok, view, _html} = live(conn, new_path)
      assert has_element?(view, "input[type='file'][name='image']")
      assert has_element?(view, "[data-phx-upload-ref]")
      refute has_element?(view, ".auix-upload-entry")
      assert has_element?(view, "input[name$='[name]']")
      assert has_element?(view, "input[name$='[reference]']")

      # A validate cycle re-runs the form update path; an unguarded second
      # allow_upload/3 for the same name would raise ArgumentError here.
      view
      |> form("#auix-product-form", product: %{name: "Re-render"})
      |> render_change()

      assert has_element?(view, "input[type='file'][name='image']")

      {:ok, view, _html} = live(conn, new_path)
      upload_file(view, :image, "cancel.png", "cancel-me")
      assert has_element?(view, ".auix-upload-entry")

      view
      |> element("button[phx-click='auix_cancel_upload']")
      |> render_click()

      refute has_element?(view, ".auix-upload-entry")
    end)
  end

  test "a save persists what consume returns, keeps the stored value without a file, and aborts on an error",
       %{conn: conn} do
    each_backend(fn backend ->
      new_path = mirror_path(backend, "uploads", "products", "/new")
      content = "fake-png-binary-content"

      {:ok, view, _html} = live(conn, new_path)
      upload_file(view, :image, "test.png", content)
      submit_upload(view, "upload-test")
      assert Repo.get_by!(MirrorCtx.Product, reference: "upload-test").image == content

      {:ok, view, _html} = live(conn, new_path)
      submit_upload(view, "no-upload-test")
      assert is_nil(Repo.get_by!(MirrorCtx.Product, reference: "no-upload-test").image)

      {:ok, view, _html} = live(conn, new_path)
      upload_file(view, :description, "test.png", content)
      submit_upload(view, "socket-aware-upload")

      # The arity-2 consumer prefixes the binary with the live_action assign value.
      assert Repo.get_by!(MirrorCtx.Product, reference: "socket-aware-upload").description ==
               "new:#{content}"

      {:ok, view, _html} = live(conn, new_path)
      upload_file(view, :status, "bad.png", content)
      submit_upload(view, "error-upload")
      assert has_element?(view, "#flash-error", "bad file")
      assert Repo.get_by(MirrorCtx.Product, reference: "error-upload") == nil
    end)
  end

  test "a stored file shows as a card with its description, a download button and a replace button",
       %{conn: conn} do
    image = "[data-upload-field='image']"
    thumbnail = "[data-upload-field='thumbnail']"

    each_backend(fn backend ->
      with_image = insert_product("with-image", %{image: "fake-image-binary"})
      with_thumbnail = insert_product("with-thumbnail", %{thumbnail: "the-file-bytes"})
      no_file = insert_product("no-file", %{})

      # Without :file_info the card is named after the field label and shows no type or size.
      {:ok, view, _html} = live(conn, upload_path(backend, with_image, "show"))
      assert has_element?(view, "#{image} .auix-upload-file .auix-upload-file-name", "Image")
      refute has_element?(view, "#{image} .auix-upload-file-meta")
      refute has_element?(view, @download_button)
      refute has_element?(view, "input[type='file']")
      refute has_element?(view, ".auix-upload-file-replace")

      {:ok, view, _html} = live(conn, upload_path(backend, with_image, "edit"))
      refute has_element?(view, @download_button)
      assert has_element?(view, "#{image} .auix-upload-file label.auix-upload-file-replace[for]")
      refute has_element?(view, "#{image} .auix-upload-picker")
      assert has_element?(view, "#{image} input[type='file'].auix-upload-input")

      {:ok, view, _html} = live(conn, upload_path(backend, no_file, "show"))
      refute has_element?(view, @download_button)
      refute has_element?(view, "#{thumbnail} .auix-upload-file")
      assert has_element?(view, "#{thumbnail} span.auix-upload-empty", "No file")
      refute_push_event(view, "auix_download", _)

      {:ok, view, _html} = live(conn, upload_path(backend, no_file, "edit"))
      refute has_element?(view, @download_button)
      refute has_element?(view, "#{thumbnail} .auix-upload-file")
      assert has_element?(view, "#{thumbnail} label.auix-upload-picker[for]", "Choose file")
      assert has_element?(view, "#{thumbnail} .auix-upload-hint", "PNG, JPG")
      assert has_element?(view, "#{thumbnail} input[type='file']")

      {:ok, view, _html} = live(conn, upload_path(backend, with_thumbnail, "edit"))
      assert has_element?(view, "#{thumbnail} .auix-upload-file #{@download_button}")
      assert has_element?(view, "#{thumbnail} .auix-upload-file-replace")
      assert has_element?(view, "#{thumbnail} input[type='file']")

      {:ok, view, _html} = live(conn, upload_path(backend, with_thumbnail, "show"))
      assert has_element?(view, "#{thumbnail} .auix-upload-file-name", "image.png")
      assert has_element?(view, "#{thumbnail} .auix-upload-file-meta", "PNG · 14 bytes")
      assert has_element?(view, "#{thumbnail} .auix-upload-file #{@download_button}")
      view |> element(@download_button) |> render_click()
      assert_push_event(view, "auix_download", %{name: "image.png", data: data})
      assert Base.decode64!(data) == "the-file-bytes"
    end)
  end

  test "custom renderers replace the field in index, show and form", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, view, _html} = live(conn, mirror_path(backend, "renderers", "products"))
      assert has_element?(view, "span.auix-index-marker", "IDX:Item test-1")
      assert has_element?(view, "td", "item_test-1")
      refute has_element?(view, "span.auix-generic-renderer")

      assert has_element?(
               view,
               "span.auix-index-cols-marker",
               "COL:This is the item test-1 as described."
             )

      assert has_element?(view, "th[name='auix-column-label']", "ZZZ_CustomRef")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "renderers", "products", "/#{product.id}/show"))

      assert has_element?(view, "span.auix-show-marker", "SHOW:Item test-1")
      assert has_element?(view, "span.auix-generic-renderer", "GENERIC:item_test-1")

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "renderers", "products", "/#{product.id}/edit"))

      assert has_element?(view, "span.auix-edit-marker", "EDIT:Item test-1")
      assert has_element?(view, "span.auix-generic-renderer", "GENERIC:item_test-1")
      assert has_element?(view, "input[name='product[quantity_initial]']")
      assert has_element?(view, "input[name='product[quantity_initial]'][readonly]")
    end)
  end

  test "predefined renderers render in index, show and form", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} =
        create_sample_products(1, :test, %{
          inactive: true,
          status: "shipped",
          quantity_at_hand: Decimal.new(50),
          cost: Decimal.new(3)
        })

      %{"id_show-1" => show_product} =
        create_sample_products(1, :show, %{
          inactive: false,
          status: "in_stock",
          quantity_at_hand: Decimal.new(50),
          cost: Decimal.new(3)
        })

      {:ok, view, _html} = live(conn, mirror_path(backend, "predefined-renderers", "products"))
      assert has_element?(view, "input[type=checkbox][disabled][checked].auix-toggle-switch")
      assert has_element?(view, "span.auix-badge", "shipped")
      assert has_element?(view, "span.auix-color[style*='background-color']")
      assert has_element?(view, "div.auix-progress .auix-progress-bar")
      assert has_element?(view, "div.auix-progress .auix-progress-label", "50%")
      # :url renders as plain text in :index — no clickable link competing with row navigation.
      refute has_element?(view, "a.auix-url")
      assert has_element?(view, "span.auix-rating .auix-rating-star--on")

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "predefined-renderers", "products", "/#{show_product.id}/show")
        )

      assert has_element?(
               view,
               "#auix-product-show-modal input[type=checkbox][disabled].auix-toggle-switch"
             )

      refute has_element?(
               view,
               "#auix-product-show-modal input[type=checkbox][disabled][checked].auix-toggle-switch"
             )

      assert has_element?(view, "#auix-product-show-modal span.auix-badge", "in_stock")
      assert has_element?(view, "#auix-product-show-modal span.auix-color", "item_show-1")

      assert has_element?(
               view,
               "#auix-product-show-modal .auix-show-field .auix-label",
               "Progress bar"
             )

      assert has_element?(
               view,
               "#auix-product-show-modal div.auix-progress .auix-progress-label",
               "50%"
             )

      assert has_element?(view, "#auix-product-show-modal .auix-show-field .auix-label", "URL")
      assert has_element?(view, "#auix-product-show-modal a.auix-url")
      assert has_element?(view, "#auix-product-show-modal span.auix-rating .auix-rating-star--on")
      assert has_element?(view, "#auix-product-show-modal .auix-show-field .auix-label", "Rating")

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "predefined-renderers", "products", "/#{product.id}/edit")
        )

      assert has_element?(view, "input[type=checkbox][checked].auix-toggle-switch")
      assert has_element?(view, "input[type=color]")
      # Read-only renderers (:badge, :progress_bar, :url) delegate the form layout to the
      # default input — a badge/bar/link would never be an input.
      assert has_element?(view, "[name='product[status]']")
      assert has_element?(view, "[name='product[quantity_at_hand]']")
      assert has_element?(view, "[name='product[description]']")
      assert has_element?(view, "input[type=radio].auix-rating-radio[value='3']")
      assert has_element?(view, "input[type=radio].auix-rating-radio[value='3'][checked]")
    end)
  end

  test "a renderer atom resolves to its slot, a host registrar overrides it, and an unknown atom falls back" do
    each_backend(fn _backend ->
      field = %Field{renderer: :toggle_switch}
      assert Renderers.resolve(field, :show) == (&Predefined.ToggleSwitch.render/1)
      assert Renderers.resolve(field, :form) == (&Predefined.ToggleSwitch.render/1)

      field = %Field{renderer: :toggle_switch, index_renderer: :badge}
      assert Renderers.resolve(field, :index) == (&Predefined.Badge.render/1)

      assert Renderers.resolve(%Field{renderer: :toggle_switch}, :index) ==
               (&DefaultRenderer.render/1)

      assert Renderers.resolve(%Field{renderer: :not_a_renderer}, :show) ==
               (&DefaultRenderer.render/1)

      assert Renderers.resolve(%Field{}, :show) == (&DefaultRenderer.render/1)

      put_temporary_env(:renderers, HostRegistrar, fn ->
        assert Renderers.resolve(%Field{renderer: :toggle_switch}, :show) ==
                 (&HostToggle.render/1)

        assert Renderers.resolve(%Field{renderer: :badge}, :show) ==
                 (&Predefined.Badge.render/1)
      end)

      for name <- [
            :default_checkbox,
            :default_date,
            :default_datetime_local,
            :default_number,
            :default_select,
            :default_text,
            :default_textarea,
            :default_time
          ] do
        assert Map.fetch!(BuiltIn.renderers(), name) == (&Renderers.default/1)
      end
    end)
  end

  test "html_type tables resolve in their precedence", %{conn: conn} do
    each_backend(fn backend ->
      assert_resolver_tables()

      %{"id_test-1" => product} =
        create_sample_products(1, :test, %{inactive: true, quantity_at_hand: Decimal.new(3)})

      put_temporary_env(:html_type_renderers, %{checkbox: :toggle_switch}, fn ->
        {:ok, view, _html} = live(conn, mirror_path(backend, "renderers", "products"))
        assert has_element?(view, "input.auix-toggle-switch")
        assert has_element?(view, "input[type=checkbox][name='selected_check__#{product.id}']")

        {:ok, view, _html} =
          live(conn, mirror_path(backend, "renderers", "products", "/#{product.id}/show"))

        assert has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")
        assert has_element?(view, "input[type=checkbox][name='deleted']")

        {:ok, view, _html} =
          live(conn, mirror_path(backend, "renderers", "products", "/#{product.id}/edit"))

        assert has_element?(
                 view,
                 "input[type=checkbox][name='product[inactive]'].auix-toggle-switch"
               )
      end)

      {:ok, view, _html} = live(conn, mirror_path(backend, "renderer-module-table", "products"))
      assert has_element?(view, "input.auix-toggle-switch")
      assert has_element?(view, "input[type=checkbox][name='selected_check__#{product.id}']")

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "renderer-module-table", "products", "/#{product.id}/show")
        )

      assert has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")

      {:ok, view, _html} =
        live(
          conn,
          mirror_path(backend, "renderer-module-table", "products", "/#{product.id}/edit")
        )

      assert has_element?(
               view,
               "input[type=checkbox][name='product[inactive]'].auix-toggle-switch"
             )

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "renderer-precedence", "products", "/#{product.id}/show"))

      assert has_element?(view, "input[type=checkbox][disabled].auix-toggle-switch")
      assert has_element?(view, "input[type=checkbox][name='deleted']")
      assert has_element?(view, "span.auix-rating")
      refute has_element?(view, "div.auix-progress")
      refute has_element?(view, "span.auix-badge")

      {:ok, view, _html} = live(conn, mirror_path(backend, "renderer-precedence", "products"))
      refute has_element?(view, ".auix-toggle-switch")
      assert has_element?(view, "span.auix-rating")

      assert BasicHelpers.html_type_renderers(
               %{configurations: %{}, resource_name: :missing},
               :show
             ) == []
    end)
  end

  test "form header and footer actions are added and inserted", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, view, html} =
        live(conn, mirror_path(backend, "form-options", "products", "/#{product.id}/edit"))

      assert has_element?(view, "[name='auix-form-header-actions']")

      assert texts(html, "div[name='auix-form-header-actions'] [name='auix-save-product']") == [
               "Custom Save Product"
             ]

      assert texts(html, "div[name='auix-form-footer-actions'] [name='auix-save-product']") == [
               "Custom Footer Save Product",
               "Save Product"
             ]
    end)
  end

  test "form and show actions show their icons and keep their labels", %{conn: conn} do
    each_backend(fn backend ->
      %{"id_test-1" => product} = create_sample_products(1, :test)

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form-options", "products", "/#{product.id}/edit"))

      assert has_element?(
               view,
               "button[name='auix-save-product'][title='Save Product'][aria-label='Save Product'] span.auix-action-icon span.hero-bolt"
             )

      assert has_element?(
               view,
               "button[name='auix-save-product'] span.auix-action-label",
               "Save Product"
             )

      {:ok, view, _html} =
        live(conn, mirror_path(backend, "form-options", "products", "/#{product.id}/show"))

      assert has_element?(view, "[name='auix-show-header-actions']")

      assert has_element?(
               view,
               "a[name='auix-edit-product'][title='Edit Product'] span.auix-action-icon span.hero-pencil"
             )

      assert has_element?(
               view,
               "div[name='auix-show-navigate-back'] a[title='Back to Products'] span.auix-action-icon-text",
               "←"
             )

      assert has_element?(
               view,
               "div[name='auix-show-navigate-back'] a span.auix-action-label",
               "Back to Products"
             )
    end)
  end

  ## PRIVATE ##

  @spec assert_blank_error(View.t(), Aurora.UixWeb.Test.Scenario.backend()) :: true
  defp assert_blank_error(view, %{name: :ash}),
    do: assert(has_element?(view, ".auix-error-message", "is required"))

  defp assert_blank_error(view, %{name: :ctx}),
    do: assert(has_element?(view, ".auix-error-message", "can't be blank"))

  @spec submit_edit(View.t(), binary()) :: binary()
  defp submit_edit(view, location_id) do
    view
    |> form("#auix-product-form",
      product: %{
        name: "Edited name",
        description: "Edited text",
        quantity_initial: "7",
        units_per_box: "3",
        margin: "0.5",
        list_price: "1.5",
        released_on: "2026-03-10",
        opens_at: "17:45",
        audited_at: "2026-03-10T09:15",
        discontinued_at: "2026-04-01T08:00",
        status: "discontinued",
        grade: "clearance",
        inactive: "true",
        labels: ["", "perishable"],
        product_location_id: location_id
      }
    )
    |> render_submit()
  end

  @spec assert_edited(binary(), binary()) :: true
  defp assert_edited(id, location_id) do
    product = Repo.get!(MirrorCtx.Product, id)
    assert product.name == "Edited name"
    assert product.description == "Edited text"
    assert Decimal.equal?(product.quantity_initial, Decimal.new("7"))
    assert product.units_per_box == 3
    assert product.margin == 0.5
    assert Decimal.equal?(product.list_price, Decimal.new("1.5"))
    assert product.released_on == ~D[2026-03-10]
    assert product.opens_at == ~T[17:45:00]
    assert product.audited_at == ~N[2026-03-10 09:15:00]
    assert product.discontinued_at == ~U[2026-04-01 08:00:00Z]
    assert product.status == "discontinued"
    assert product.grade == :clearance
    assert product.inactive == true
    assert product.labels == [:perishable]
    assert product.product_location_id == location_id
  end

  @spec open_changed_edit(Plug.Conn.t(), binary()) :: View.t()
  defp open_changed_edit(conn, path) do
    {:ok, view, _html} = live(conn, path)

    view
    |> form("#auix-product-form", product: %{name: "Changed name"})
    |> render_change()

    view
  end

  # The form component root is the only element carrying `data-phx-component`; the form id
  # itself is not a component root, so `with_target/2` cannot resolve it.
  @spec request_close(View.t(), atom()) :: term()
  defp request_close(view, live_action \\ :edit) do
    view
    |> with_target("#auix-product-#{live_action}-modal [data-phx-component]")
    |> render_click("auix_request_close", %{})
  end

  @spec render_input(map()) :: binary()
  defp render_input(assigns) do
    defaults = %{
      name: "my-field",
      value: "",
      host_components: nil,
      errors: [],
      label: nil,
      fieldset_class: "",
      label_class: "",
      input_class: "",
      omit_label?: false
    }

    render_component(&CoreComponents.input/1, Map.merge(defaults, assigns))
  end

  @spec copy_warning?((-> term())) :: boolean()
  defp copy_warning?(fun),
    do: capture_log(fun) =~ "copyable input was rendered without a valid"

  @spec with_warning_level((-> term())) :: term()
  defp with_warning_level(fun) do
    Logger.configure(level: :warning)
    result = fun.()
    Logger.configure(level: :error)
    result
  end

  @spec count(View.t(), binary()) :: non_neg_integer()
  defp count(view, selector) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> Enum.count()
  end

  @spec texts(binary(), binary()) :: list(binary())
  defp texts(html, selector) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end

  @spec toggle_all(View.t(), binary()) :: binary()
  defp toggle_all(view, state) do
    view
    |> form("#auix-product-form", %{"auix_toggle_all__labels" => state})
    |> render_change(%{"_target" => ["auix_toggle_all__labels"]})
  end

  @spec toggle_state(View.t()) :: :all | :none | :mixed
  defp toggle_state(view) do
    toggle =
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("input#auix-multi-select-toggle_all-labels")

    cond do
      LazyHTML.attribute(toggle, "checked") != [] -> :all
      toggle |> LazyHTML.attribute("class") |> to_string() =~ "auix-checkbox--mixed" -> :mixed
      true -> :none
    end
  end

  @spec checked_values(View.t()) :: list(binary())
  defp checked_values(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("input[type='checkbox'][name='product[labels][]'][checked]")
    |> Enum.map(&(&1 |> LazyHTML.attribute("value") |> List.first()))
  end

  @spec selected_items(View.t()) :: list(binary())
  defp selected_items(view) do
    view
    |> render()
    |> texts("#auix-multi-select-labels-show-options .auix-selected-list-item")
  end

  @spec edit_path(Aurora.UixWeb.Test.Scenario.backend(), struct()) :: binary()
  defp edit_path(backend, product),
    do: mirror_path(backend, "form", "products", "/#{product.id}/edit")

  @spec assert_checked(View.t()) :: true
  defp assert_checked(view) do
    assert has_element?(view, "#{@inactive}[checked]")
    assert has_element?(view, "#{@deleted}[disabled][checked]")
  end

  @spec upload_file(View.t(), atom(), binary(), binary()) :: term()
  defp upload_file(view, field, name, content) do
    view
    |> file_input("#auix-product-form", field, [
      %{
        last_modified: 1_594_171_879_000,
        name: name,
        content: content,
        size: byte_size(content),
        type: "image/png"
      }
    ])
    |> render_upload(name)
  end

  @spec submit_upload(View.t(), binary()) :: binary()
  defp submit_upload(view, reference) do
    view
    |> form("#auix-product-form",
      product: %{reference: reference, name: "Upload Test", quantity_initial: 0}
    )
    |> render_submit()
  end

  @spec insert_product(binary(), map()) :: MirrorCtx.Product.t()
  defp insert_product(reference, attrs) do
    MirrorCtx.Product
    |> struct(Map.merge(%{reference: reference, name: reference, quantity_initial: 0}, attrs))
    |> Repo.insert!()
  end

  @spec upload_path(Aurora.UixWeb.Test.Scenario.backend(), struct(), binary()) :: binary()
  defp upload_path(backend, product, action),
    do: mirror_path(backend, "uploads", "products", "/#{product.id}/#{action}")

  @spec put_temporary_env(atom(), term(), (-> term())) :: term()
  defp put_temporary_env(key, value, fun) do
    Application.put_env(:aurora_uix, key, value)
    on_exit(fn -> Application.delete_env(:aurora_uix, key) end)

    try do
      fun.()
    after
      Application.delete_env(:aurora_uix, key)
    end
  end

  @spec assert_resolver_tables() :: term()
  defp assert_resolver_tables do
    field = %Field{html_type: :checkbox}

    for layout_type <- [:index, :show, :form] do
      assert Renderers.resolve(field, layout_type, [%{checkbox: :toggle_switch}]) ==
               (&Predefined.ToggleSwitch.render/1)
    end

    slotted = %Field{html_type: :checkbox, renderer: :badge}
    tables = [%{checkbox: :toggle_switch}]
    assert Renderers.resolve(slotted, :show, tables) == (&Predefined.Badge.render/1)
    assert Renderers.resolve(slotted, :index, tables) == (&Predefined.ToggleSwitch.render/1)

    assert Renderers.resolve(field, :show, [%{checkbox: :badge}, %{checkbox: :toggle_switch}]) ==
             (&Predefined.Badge.render/1)

    assert Renderers.resolve(field, :show, [
             %{checkbox: :not_a_renderer},
             %{checkbox: :toggle_switch}
           ]) == (&Predefined.ToggleSwitch.render/1)

    put_temporary_env(:html_type_renderers, %{checkbox: :toggle_switch}, fn ->
      assert Renderers.resolve(field, :show, []) == (&Predefined.ToggleSwitch.render/1)

      assert Renderers.resolve(field, :show, [%{checkbox: :badge}]) ==
               (&Predefined.Badge.render/1)
    end)

    put_temporary_env(:html_type_renderers, :oops, fn ->
      assert_raise ArgumentError,
                   ~r/config :aurora_uix, :html_type_renderers expected a map/,
                   fn -> Renderers.resolve(field, :show, []) end
    end)

    assert_raise ArgumentError, ~r/auix_create_ui renderers: expected a map/, fn ->
      Renderers.validate_table!("auix_create_ui renderers:", :oops)
    end

    assert Renderers.validate_table!("x", %{a: :b}) == %{a: :b}

    for {skipped, skipped_tables} <- [
          {%Field{html_type: :checkbox, hidden: true}, [%{checkbox: :toggle_switch}]},
          {%Field{html_type: :text, upload: %Upload{}}, [%{text: :badge}]},
          {%Field{html_type: :select, type: :many_to_many_association}, [%{select: :badge}]}
        ] do
      assert Renderers.resolve(skipped, :show, skipped_tables) == (&DefaultRenderer.render/1)
    end
  end
end
