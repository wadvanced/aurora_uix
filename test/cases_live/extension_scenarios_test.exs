defmodule Aurora.UixWeb.Test.ExtensionScenariosTest do
  use Aurora.UixWeb.Test.UICase, :scenario_case
  use Aurora.Uix.GettextResolver

  import Ecto.Query, only: [from: 2]

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Live.ComponentHooks
  alias Aurora.Uix.Repo
  alias Aurora.Uix.Templates.Basic.Generators.FormGenerator
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.Uix.Test.MirrorCtx
  alias Aurora.UixWeb.Test.ComponentHostLive, as: Host
  alias Aurora.UixWeb.Test.Mirror

  @badge "#auix-delete-all-button-product>button span.auix-button-badge"
  @intents "#auix-host-intents"
  @theme_hook "[phx-hook='AuixThemeName'][data-auix-theme-name='white_charcoal']"

  @gettext_files [
    "lib/aurora_uix/templates/basic/components/embeds_many_component.ex",
    "lib/aurora_uix/templates/basic/components/core_components.ex",
    "lib/aurora_uix/templates/basic/components/components.ex",
    "lib/aurora_uix/templates/basic/components/confirm_button.ex",
    "lib/aurora_uix/templates/basic/actions/index.ex",
    "lib/aurora_uix/templates/basic/actions/embeds_many.ex",
    "lib/aurora_uix/templates/basic/handlers/index_impl.ex"
  ]

  @spec test_translation() :: binary()
  def test_translation, do: dt("Save")

  @spec gettext_domain() :: binary() | nil
  def gettext_domain, do: @gettext_domain

  @spec passthrough(term()) :: term()
  def passthrough(value), do: dt(value)

  describe "handler hooks" do
    test "handler hooks run in the index", %{conn: conn} do
      each_backend(fn backend ->
        create_sample_products_with_transactions(2, 2, :test)
        create_sample_products(2, :low)
        path = mirror_path(backend, "hooks-index", "products")

        {:ok, view, _html} = live(conn, path)
        assert has_element?(view, "tr[id^='products-']", "item_low-1")
        refute has_element?(view, "tr[id^='products-']", "item_test-1")
        refute has_element?(view, "tr[id^='products-']", "item_test-2")

        {:ok, filtered, _html} = live(conn, path <> "?filter=abc")
        render_click(filtered, "hooks_report", %{})
        assert has_element?(filtered, "#flash-info", "mount=mounted filter=abc")

        {:ok, async_view, _html} = live(conn, path)
        render_click(async_view, "hooks_async", %{})
        render_async(async_view)
        assert has_element?(async_view, "#flash-info", "async done")

        product = Repo.get_by!(MirrorCtx.Product, reference: "item_low-1")
        {:ok, saving, _html} = live(conn, "#{path}/#{product.id}/edit")

        saving
        |> form("#auix-product-form", product: %{name: "Renamed", quantity_initial: 11})
        |> render_submit()

        render_click(saving, "hooks_report", %{})
        assert has_element?(saving, "#flash-info", "saved=Renamed")
      end)
    end

    test "handler hooks run in the form", %{conn: conn} do
      each_backend(fn backend ->
        products = create_sample_products_with_transactions(2, 2, :test)
        {_key, product} = hd(products)
        path = mirror_path(backend, "hooks-form", "products")

        {:ok, view, _html} = live(conn, "#{path}/#{product.id}/edit")

        refute has_element?(view, "[name='product[rrp]']")
        refute has_element?(view, "[name='product[list_price]']")
        assert has_element?(view, "[name='product[description]']")

        view |> element("button[name='hooks-hide-description']") |> render_click()

        refute has_element?(view, "[name='product[description]']")
        refute has_element?(view, "[name='product[rrp]']")
        refute has_element?(view, "[name='product[list_price]']")
        assert has_element?(view, "[name='product[name]']")

        {:ok, closing, _html} = live(conn, "#{path}/#{product.id}/edit")

        closing
        |> with_target("#auix-product-edit-modal [data-phx-component]")
        |> render_click("auix_request_close", %{})

        assert closing |> assert_patch() |> URI.parse() |> Map.fetch!(:path) == path

        assert_hooked_saves(conn, path, product)
      end)
    end

    test "handler hooks run in the show view", %{conn: conn} do
      each_backend(fn backend ->
        [{_key, product} | _] = create_sample_products_with_transactions(2, 2, :test)
        path = mirror_path(backend, "hooks-show", "products")
        transactions = "#auix-one_to_many-product__product_transactions-show"

        {:ok, view, _html} = live(conn, "#{path}/#{product.id}/show")

        assert has_element?(view, transactions)
        assert has_element?(view, "#auix-product-show-modal input[value='#{product.reference}']")
        refute has_element?(view, "#auix-product-show-modal input[value='#{product.name}']")

        view
        |> with_target(
          "#auix-product-show-modal [data-phx-component]:has(> .auix-show-container)"
        )
        |> render_click("hooks_back", %{})

        assert view |> assert_patch() |> URI.parse() |> Map.fetch!(:path) == path

        assert_show_from_index(conn, path, product)
      end)
    end
  end

  describe "embedded components" do
    test "an embedded index component lists its scope, pages, sorts and refreshes per instance",
         %{conn: conn} do
      each_backend(fn backend ->
        create_sample_products(12, :test)
        create_sample_product_locations(2, :test)
        products = sorted_products()
        index = component(backend, Components, Product, IndexComponent)

        {:ok, view, _html} =
          mount_components(conn, [
            %{module: index, id: "low", props: %{where: [{:reference, :lt, "item_test-04"}]}}
          ])

        assert has_element?(view, "#low[name='auix-index-component']")
        assert has_element?(view, "#low #{@theme_hook}")
        assert has_element?(view, row("low", p(products, 1)))
        assert has_element?(view, row("low", p(products, 3)))
        refute has_element?(view, row("low", p(products, 4)))

        assert_instances_page_separately(conn, index, products)
        assert_page_and_options(conn, index, products)
        assert_card_sort(conn, index)
        assert_event_refresh(conn, backend, index)
        assert_empty_message(conn, index)
      end)
    end

    test "an embedded index reports open and delete", %{conn: conn} do
      each_backend(fn backend ->
        create_sample_products(12, :test)
        create_sample_product_locations(2, :test)
        [first, second | _] = sorted_products()
        index = component(backend, Components, Product, IndexComponent)

        {:ok, view, _html} =
          mount_components(conn, [%{module: index, id: "a", props: %{order_by: :reference}}])

        view
        |> element(
          row("a", first) <> " td.auix-items-table-action-cell a[name='auix-show-product']"
        )
        |> render_click()

        assert has_element?(
                 view,
                 "#{@intents} li[data-intent='open'][data-value='show:#{first.id}']"
               )

        view |> element("#a a[name='auix-new-product']") |> render_click()
        assert has_element?(view, "#{@intents} li[data-intent='open'][data-value='new:']")

        view
        |> element(
          row("a", second) <> " td.auix-items-table-action-cell a[name='auix-delete-product']"
        )
        |> render_click()

        refute has_element?(view, row("a", second))

        assert has_element?(
                 view,
                 "#{@intents} li[data-intent='deleted'][data-value='#{second.id}']"
               )

        assert Repo.get(MirrorCtx.Product, second.id) == nil
      end)
    end

    test "component_handler_module sets the handler of the component", %{conn: conn} do
      each_backend(fn backend ->
        create_sample_products(12, :test)
        create_sample_product_locations(2, :test)
        index = component(backend, ComponentsHandled, Product, IndexComponent)

        {:ok, view, _html} = mount_components(conn, [%{module: index, id: "h", props: %{}}])

        view |> with_target("#h") |> render_click("ping", %{})

        assert has_element?(
                 view,
                 "#{@intents} li[data-component='h'][data-intent='page'][data-value='99']"
               )
      end)
    end

    test "a paired index serves a resource of its host, and its pairing is checked", %{
      conn: conn
    } do
      each_backend(fn backend ->
        create_sample_products(12, :test)
        create_sample_product_locations(2, :test)
        [first | _] = locations = Repo.all(MirrorCtx.ProductLocation)

        {:ok, view, _html} = live_isolated(conn, paired_index_host(backend))

        location_row = fn location ->
          "#locations tr[id='locations-product_locations-#{location.id}']"
        end

        assert Enum.all?(locations, &has_element?(view, location_row.(&1)))
        assert has_element?(view, location_row.(first), first.reference)
        refute has_element?(view, location_row.(first), first.type)

        socket = %Phoenix.LiveView.Socket{
          view: paired_index_host(backend),
          assigns: %{__changed__: %{}}
        }

        index = component(backend, Components, Product, IndexComponent)

        assert_raise ArgumentError, ~r/does not pair/, fn ->
          Helpers.resource_binding(socket, %{id: "x", resource: :product_location}, index, :index)
        end
      end)
    end

    test "an embedded form loads its record, saves and reports", %{conn: conn} do
      each_backend(fn backend ->
        create_sample_products(1, :test, %{quantity_initial: 1})
        create_sample_products(1, :extra, %{quantity_initial: 1})
        create_sample_product_locations(1, :test)
        form_module = component(backend, Components, Product, FormComponent)

        {:ok, view, _html} = mount_components(conn, [new_form(form_module)])

        assert has_element?(view, "#auix-product-form input[name='product[reference]']")
        assert has_element?(view, "#auix-host #{@theme_hook}")

        view
        |> form("#auix-product-form",
          product: %{reference: "emb-1", name: "Embedded", quantity_initial: 1}
        )
        |> render_submit()

        assert has_element?(view, "#{@intents} li[data-component='f1'][data-intent='saved']")
        assert has_element?(view, "#flash-info", "Product updated successfully")
        assert has_element?(view, "#auix-host")

        [first, second | _] = sorted_products()

        {:ok, loaded, _html} =
          mount_components(conn, [
            %{module: form_module, id: "f1", props: %{entity_id: first.id}}
          ])

        assert has_element?(
                 loaded,
                 "input[name='product[reference]'][value='#{first.reference}']"
               )

        send(
          loaded.pid,
          {:set_components, [%{module: form_module, id: "f1", props: %{entity_id: second.id}}]}
        )

        assert has_element?(
                 loaded,
                 "input[name='product[reference]'][value='#{second.reference}']"
               )

        {:ok, closing, _html} = mount_components(conn, [new_form(form_module)])

        closing
        |> with_target("#auix-host > [data-phx-component]")
        |> render_click("auix_request_close", %{})

        assert has_element?(closing, "#{@intents} li[data-component='f1'][data-intent='closed']")
      end)
    end

    test "an embedded show reports close and edit and has no record navigator", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        Helpers.assign_component_inputs(
          %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, id: "s1", auix: %{}}},
          %{id: "s1"},
          :show
        )
      end

      each_backend(fn backend ->
        create_sample_products(1, :test, %{quantity_initial: 1})
        create_sample_products(1, :extra, %{quantity_initial: 1})
        create_sample_product_locations(1, :test)
        [product | _] = sorted_products()
        show_module = component(backend, Components, Product, ShowComponent)
        form_module = component(backend, Components, Product, FormComponent)

        {:ok, view, _html} = mount_components(conn, [show(show_module, product)])

        assert has_element?(view, "#auix-host #{@theme_hook}")

        view |> element("div[name='auix-show-navigate-back'] a") |> render_click()
        assert has_element?(view, "#{@intents} li[data-component='s1'][data-intent='closed']")

        view |> element("a[name='auix-edit-product']") |> render_click()

        assert has_element?(
                 view,
                 "#{@intents} li[data-component='s1'][data-intent='open'][data-value='edit:#{product.id}']"
               )

        refute has_element?(view, ".auix-record-navigator-bar")

        {:ok, form_view, _html} =
          mount_components(conn, [
            %{module: form_module, id: "f1", props: %{entity_id: product.id}}
          ])

        refute has_element?(form_view, ".auix-record-navigator-bar")
      end)
    end

    test "a paired form serves a resource of its host, and its resource is checked", %{
      conn: conn
    } do
      each_backend(fn backend ->
        create_sample_products(1, :test, %{quantity_initial: 1})
        create_sample_product_locations(1, :test)
        [location] = Repo.all(MirrorCtx.ProductLocation)
        host = paired_form_host(backend)

        {:ok, view, _html} = live_isolated(conn, host, session: %{"entity_id" => location.id})

        assert has_element?(
                 view,
                 "#auix-product_location-form input[name='product_location[reference]'][value='#{location.reference}']"
               )

        assert has_element?(view, "input[name='product_location[name]']")
        refute has_element?(view, "input[name='product_location[type]']")

        view
        |> form("#auix-product_location-form", product_location: %{name: "Renamed"})
        |> render_submit()

        assert Repo.get!(MirrorCtx.ProductLocation, location.id).name == "Renamed"
        assert has_element?(view, "#auix-paired-saved[data-component='location-form']")

        assert_resource_checked(backend, host)
        assert_resource_binds_once(backend, host)
      end)
    end

    test "report_intent/2 reaches a pid, a component and the calling process" do
      pid_socket = %Phoenix.LiveView.Socket{
        assigns: %{__changed__: %{}, id: "c1", auix: %{notify: self()}}
      }

      Helpers.report_intent(pid_socket, {:closed})
      assert_receive {Aurora.Uix, "c1", {:closed}}

      component_socket = %Phoenix.LiveView.Socket{
        assigns: %{__changed__: %{}, id: "c1", auix: %{notify: {SomeComponent, "parent"}}}
      }

      Helpers.report_intent(component_socket, {:closed})

      assert_receive {:phoenix, :send_update,
                      {{SomeComponent, "parent"},
                       %{id: "parent", auix_intent: {Aurora.Uix, "c1", {:closed}}}}}

      plain_socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, id: "c1", auix: %{}}}

      Helpers.report_intent(plain_socket, {:closed})
      assert_receive {Aurora.Uix, "c1", {:closed}}
    end

    test "component hooks forward events to every instance", %{conn: conn} do
      assert ComponentHooks.register(%Phoenix.LiveComponent.CID{cid: 1}, MirrorCtx.Product) == :ok
      assert Process.get({ComponentHooks, :instances}) == nil

      each_backend(fn backend ->
        create_sample_products(12, :test)
        index = component(backend, Components, Product, IndexComponent)

        {:ok, view, _html} =
          live_isolated(conn, Host,
            session: %{
              "hooks" => true,
              "components" => [
                %{module: index, id: "a", props: %{where: [{:reference, :lt, "item_test-04"}]}},
                %{module: index, id: "b", props: %{where: [{:reference, :lt, "item_test-02"}]}}
              ]
            }
          )

        added = publish_created(backend)
        _ = :sys.get_state(view.pid)

        assert has_element?(view, "#a tr[id='a-products-#{added.id}']")
        assert has_element?(view, "#b tr[id='b-products-#{added.id}']")

        {:ok, plain, _html} =
          live_isolated(conn, Host,
            session: %{
              "components" => [
                %{module: index, id: "a", props: %{where: [{:reference, :lt, "item_test-04"}]}}
              ]
            }
          )

        other = publish_created(backend, "item_test-03x")
        _ = :sys.get_state(plain.pid)

        refute has_element?(plain, "#a tr[id='a-products-#{other.id}']")

        {:ok, hooked, _html} =
          live_isolated(conn, Host,
            session: %{"hooks" => true, "components" => [%{module: index, id: "a", props: %{}}]}
          )

        send(hooked.pid, {:other, "x"})

        assert has_element?(hooked, "#auix-host-other li[data-message='x']")
      end)
    end
  end

  describe "events between views" do
    test "a save, a create and a delete in one view update another index", %{conn: conn} do
      each_backend(fn backend ->
        schema = schema(backend, :Product)
        path = mirror_path(backend, "events", "products")

        assert_own_topic(conn, backend, schema)
        assert_save_reread(conn, path)
        assert_created_published(conn, path, schema)
        assert_row_delete(conn, path)
        assert_originator_silent(conn, path)
        assert_child_delete(conn, backend, path)
        assert_outside_event(conn, backend, path)
        assert_unset_pubsub(conn, path, schema)
      end)
    end

    test "delete selected publishes what it deleted and clears the selection of other views",
         %{conn: conn} do
      each_backend(fn backend ->
        schema = schema(backend, :Product)
        path = mirror_path(backend, "events", "products")
        subscribe(schema)

        %{"id_test-1" => first, "id_test-2" => second, "id_test-3" => third} =
          create_sample_products(3, :test)

        {:ok, view_a, _} = live(conn, path)
        {:ok, view_b, _} = live(conn, path)

        Enum.each([first, second, third], &select_row(view_a, &1.id))
        Repo.delete!(third)

        render_click(view_a, "selected-delete_all", %{})
        render_async(view_a)

        assert_receive %Event{schema: ^schema, action: :deleted, ids: ids}
        assert Enum.sort(ids) == Enum.sort([first.id, second.id])
        refute has_element?(view_b, "#products-#{first.id}")

        assert_nothing_deleted(conn, path, schema)
        assert_selection_leaves(conn, path)
      end)
    end

    test "index commands target one view", %{conn: conn} do
      each_backend(fn backend ->
        path = mirror_path(backend, "events", "products")
        %{"id_test-1" => first} = create_sample_products(2, :test)

        {:ok, view_a, _} = live(conn, path)
        {:ok, view_b, _} = live(conn, path)
        select_row(view_a, first.id)
        select_row(view_b, first.id)

        Events.reset_selection(view_a.pid)

        refute has_element?(view_a, "#auix-delete-all-button-product")
        assert has_element?(view_b, @badge, "1")

        extra = 1 |> create_sample_products(:extra) |> Map.fetch!("id_extra-1")
        Events.refresh(view_b.pid)

        assert has_element?(view_b, "#products-#{extra.id}")

        extra2 = 1 |> create_sample_products(:more) |> Map.fetch!("id_more-1")
        render_click(view_a, "events-test-refresh", %{})

        assert has_element?(view_a, "#products-#{extra2.id}")
      end)
    end

    test "an open show follows the events of its record", %{conn: conn} do
      each_backend(fn backend ->
        schema = schema(backend, :Product)
        path = mirror_path(backend, "events", "products")
        %{"id_test-1" => product} = create_sample_products(1, :test)

        {:ok, view, _} = live(conn, "#{path}/#{product.id}/show")

        product |> Ecto.Changeset.change(name: "Renamed item") |> Repo.update!()
        backend |> read(:Product, product.id) |> Events.updated()

        assert has_element?(view, "#auix-product-show-modal input[value='Renamed item']")

        {:ok, kept, _} = live(conn, "#{path}/#{product.id}/show")
        entity = read(backend, :Product, product.id)
        Repo.delete!(product)

        Events.updated(entity)

        assert has_element?(kept, "#auix-product-show-modal input[value='Renamed item']")

        Events.deleted(schema, [product.id])

        assert_patch(view, path)
        refute has_element?(view, "#auix-product-show-modal")
        assert has_element?(view, "#flash-info", "Item deleted successfully")
      end)
    end

    test "an open form keeps its input and reports the events of its record", %{conn: conn} do
      each_backend(fn backend ->
        schema = schema(backend, :Product)
        path = mirror_path(backend, "events", "products")
        %{"id_test-1" => first, "id_test-2" => second} = create_sample_products(2, :test)

        {:ok, view, _} = live(conn, "#{path}/#{first.id}/edit")
        type_name(view, "Typed name")

        backend |> read(:Product, first.id) |> Events.updated()

        assert has_element?(
                 view,
                 "#auix-product-edit-modal input[name='product[name]'][value='Typed name']"
               )

        assert has_element?(view, "#flash-info", "Product updated successfully")

        request_close(view)

        assert has_element?(view, "#auix-product-discard-confirm-modal")

        {:ok, deleted, _} = live(conn, "#{path}/#{second.id}/edit")

        Events.deleted(schema, [second.id])

        assert has_element?(deleted, "#auix-product-edit-modal")
        assert has_element?(deleted, "#flash-info", "Item deleted successfully")

        assert_reopened_starts_clean(conn, path, first, second)
        assert_other_record_ignored(conn, backend, path, first, second)
      end)
    end
  end

  describe "gettext" do
    test "labels and buttons render through dt and the gettext domain", %{conn: conn} do
      assert test_translation() == "Save"
      assert gettext_domain() == "default"

      callback = & &1
      assert passthrough(callback) == callback

      each_backend(fn backend ->
        product_id = 1 |> create_sample_products(:test) |> get_in(["id_test-1", Access.key!(:id)])

        {:ok, view, _html} =
          live(conn, mirror_path(backend, "gettext", "products", "/#{product_id}/edit"))

        assert has_element?(view, "[name='auix-save-product']", "Save Product")
        assert has_element?(view, "label", "Reference")
        assert has_element?(view, "label", "Name")

        {:ok, show, _html} =
          live(conn, mirror_path(backend, "gettext", "products", "/#{product_id}/show"))

        assert has_element?(show, "[name='auix-edit-product']", "Edit Product")
        assert has_element?(show, "label", "Reference")
        assert has_element?(show, "label", "Name")
      end)
    end

    test "the template sources route their strings through dt" do
      Enum.each(
        @gettext_files -- ["lib/aurora_uix/templates/basic/components/core_components.ex"],
        fn path ->
          content = File.read!(path)

          refute content =~ "gettext(\""
          assert content =~ "dt("
        end
      )

      core_components = File.read!("lib/aurora_uix/templates/basic/components/core_components.ex")
      refute core_components =~ "gettext(\"close\")"
      refute core_components =~ "gettext(\"Success!\")"
      assert core_components =~ "dt(\"close\")"
      assert core_components =~ "Gettext.dngettext(gettext_backend(), \"errors\""
      assert core_components =~ "Gettext.dgettext(gettext_backend(), \"errors\""

      generated =
        sample_parsed_opts()
        |> FormGenerator.generate_module()
        |> Macro.to_string()

      assert generated =~ "use Aurora.Uix.GettextResolver"
      refute generated =~ "_aurora_uix_extract"

      assert_domain_extraction()
    end
  end

  ## Navigation of the hooks

  @spec assert_hooked_saves(Plug.Conn.t(), binary(), struct()) :: term()
  defp assert_hooked_saves(conn, path, product) do
    reference = "test-#{System.system_time(:nanosecond)}"

    {:ok, new_view, _html} = live(conn, path <> "/new")
    assert has_element?(new_view, "div#auix-product-new-modal header", "New Product")

    new_view
    |> form("#auix-product-form",
      product: %{reference: reference, name: "This is the first test", quantity_initial: 11}
    )
    |> render_submit()

    assert Repo.get_by(MirrorCtx.Product, reference: reference)

    {:ok, index, _html} = live(conn, path)
    assert has_element?(index, "tr[id^='products-']", reference)

    index
    |> element(
      "tr[id^='products'] a[name='auix-edit-product'][phx-value-route_path$='#{product.id}/edit']"
    )
    |> render_click()

    assert has_element?(index, "[name='auix-save-product']")

    index
    |> form("#auix-product-form", product: %{name: "renamed-by-hook", quantity_initial: 11})
    |> render_submit()

    assert Repo.get!(MirrorCtx.Product, product.id).name == product.name
  end

  @spec assert_show_from_index(Plug.Conn.t(), binary(), struct()) :: term()
  defp assert_show_from_index(conn, path, product) do
    {:ok, view, _html} = live(conn, path)

    view
    |> element("tr[id^='products-#{product.id}'] td:nth-child(2) a[name='auix-show-product']")
    |> render_click()

    assert has_element?(view, "#auix-one_to_many-product__product_transactions-show table")

    view |> element("#auix-product-show-modal a[name='auix-edit-product']") |> render_click()
    assert has_element?(view, "#auix-product-show_edit-modal")
  end

  ## Components

  @spec assert_instances_page_separately(Plug.Conn.t(), module(), [struct()]) :: term()
  defp assert_instances_page_separately(conn, index, products) do
    {:ok, view, _html} =
      mount_components(conn, [
        %{module: index, id: "a", props: %{where: [{:reference, :lt, "item_test-04"}]}},
        %{module: index, id: "b", props: %{order_by: :reference}}
      ])

    first_page = row_ids(view, "b")
    assert Enum.count(first_page) == 5

    view
    |> element("#b div[name$='-xl2'] a[name='auix-pages_bar_page-2']")
    |> render_click()

    paged = row_ids(view, "b")

    refute paged == first_page
    assert has_element?(view, row("a", p(products, 1)))

    assert paged -- first_page == paged
    assert has_element?(view, row("b", p(products, 6)))
    refute has_element?(view, row("b", p(products, 1)))

    assert has_element?(
             view,
             "#{@intents} li[data-component='b'][data-intent='page'][data-value='2']"
           )

    refute has_element?(view, "#{@intents} li[data-component='a']")
  end

  @spec row_ids(term(), binary()) :: [binary()]
  defp row_ids(view, id) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("##{id} tbody tr[id^='#{id}-products-']")
    |> Enum.flat_map(&LazyHTML.attribute(&1, "id"))
  end

  @spec assert_page_and_options(Plug.Conn.t(), module(), [struct()]) :: term()
  defp assert_page_and_options(conn, index, products) do
    {:ok, view, _html} =
      mount_components(conn, [
        %{module: index, id: "a", props: %{page: 2, order_by: :reference}},
        %{module: index, id: "b", props: %{options: [sort_disabled?: true]}}
      ])

    assert has_element?(view, row("a", p(products, 6)))
    refute has_element?(view, row("a", p(products, 1)))
    assert has_element?(view, "#a button[name='auix-sort-reference']")
    refute has_element?(view, "#b button[name='auix-sort-reference']")
  end

  @spec assert_card_sort(Plug.Conn.t(), module()) :: term()
  defp assert_card_sort(conn, index) do
    {:ok, view, _html} =
      mount_components(conn, [
        %{module: index, id: "a", props: %{}},
        %{module: index, id: "b", props: %{}}
      ])

    view |> element("#a button[name='auix-sort_menu_field-reference']") |> render_click()

    assert has_element?(
             view,
             "#a button[name='auix-sort_menu_field-reference'][aria-checked='true']"
           )

    assert has_element?(
             view,
             "#b button[name='auix-sort_menu_field-reference'][aria-checked='false']"
           )
  end

  @spec assert_event_refresh(Plug.Conn.t(), map(), module()) :: term()
  defp assert_event_refresh(conn, backend, index) do
    {:ok, view, _html} =
      mount_components(conn, [
        %{module: index, id: "a", props: %{where: [{:reference, "item_added"}]}}
      ])

    {:ok, added} = Repo.insert(%MirrorCtx.Product{reference: "item_added", name: "Added"})

    refute has_element?(view, row("a", added))

    Phoenix.LiveView.send_update(view.pid, index,
      id: "a",
      auix_event: %Event{schema: schema(backend, :Product), action: :created, ids: [added.id]}
    )

    assert has_element?(view, row("a", added))
  end

  @spec assert_empty_message(Plug.Conn.t(), module()) :: term()
  defp assert_empty_message(conn, index) do
    {:ok, view, _html} =
      mount_components(conn, [%{module: index, id: "a", props: %{where: [{:reference, "none"}]}}])

    assert has_element?(view, "#a .auix-items-table-empty")
    refute has_element?(view, "#a tr[id^='a-products-']")
  end

  @spec assert_resource_checked(map(), module()) :: term()
  defp assert_resource_checked(backend, paired) do
    views = Mirror.sibling(backend.name, ComponentsPaired)
    form_module = views.auix_module(:reference_form)
    location_form = component(backend, ComponentsPaired, ProductLocation, FormComponent)
    host_socket = first_socket(Host)
    paired_socket = first_socket(paired)
    bound_socket = later_socket(paired, :product_location)

    assert_raise ArgumentError, ~r/declares no auix_create_ui/, fn ->
      Helpers.resource_binding(
        host_socket,
        %{id: "c", resource: :product_location},
        form_module,
        :form
      )
    end

    assert_raise ArgumentError, ~r/unknown resource :nope/, fn ->
      Helpers.resource_binding(paired_socket, %{id: "c", resource: :nope}, form_module, :form)
    end

    assert_raise ArgumentError, ~r/does not pair/, fn ->
      Helpers.resource_binding(
        paired_socket,
        %{id: "c", resource: :product_location},
        location_form,
        :form
      )
    end

    assert_raise ArgumentError, ~r/already serves/, fn ->
      Helpers.resource_binding(bound_socket, %{id: "c", resource: :product}, form_module, :form)
    end
  end

  @spec assert_resource_binds_once(map(), module()) :: term()
  defp assert_resource_binds_once(backend, paired) do
    form_module = Mirror.sibling(backend.name, ComponentsPaired).auix_module(:reference_form)
    paired_socket = first_socket(paired)
    bound_socket = later_socket(paired, :product_location)

    assert %{_resource: :product_location, resource_name: :product_location, layout_type: :form} =
             Helpers.resource_binding(
               paired_socket,
               %{id: "c", resource: :product_location},
               form_module,
               :form
             )

    assert Helpers.resource_binding(paired_socket, %{id: "c"}, form_module, :form) ==
             %{_resource: nil}

    assert Helpers.resource_binding(
             bound_socket,
             %{id: "c", resource: :product_location},
             form_module,
             :form
           ) == %{}

    assert Helpers.resource_binding(bound_socket, %{id: "c"}, form_module, :form) == %{}
  end

  @spec publish_created(map(), binary()) :: struct()
  defp publish_created(backend, reference \\ "item_test-0") do
    {:ok, added} = Repo.insert(%MirrorCtx.Product{reference: reference, name: "Added"})
    backend |> read(:Product, added.id) |> Events.created()
    added
  end

  ## Events

  @spec assert_own_topic(Plug.Conn.t(), map(), module()) :: term()
  defp assert_own_topic(conn, backend, schema) do
    {:ok, products, _} = live(conn, mirror_path(backend, "events", "products"))
    {:ok, locations, _} = live(conn, mirror_path(backend, "events", "product_locations"))

    pids = Aurora.Uix.PubSub |> Registry.lookup(Events.topic(schema)) |> Enum.map(&elem(&1, 0))

    assert products.pid in pids
    refute locations.pid in pids
  end

  @spec assert_save_reread(Plug.Conn.t(), binary()) :: term()
  defp assert_save_reread(conn, path) do
    %{"id_test-1" => product} = create_sample_products(1, :test)
    id = product.id

    {:ok, view_b, _} = live(conn, path)
    {:ok, view_a, _} = live(conn, "#{path}/#{id}/edit")

    view_a
    |> form("#auix-product-form", product: %{name: "Renamed item", quantity_initial: "5"})
    |> render_submit()

    assert has_element?(view_b, "#products-#{id}", "Renamed item")
  end

  @spec assert_created_published(Plug.Conn.t(), binary(), module()) :: term()
  defp assert_created_published(conn, path, schema) do
    subscribe(schema)
    {:ok, view_a, _} = live(conn, path <> "/new")

    view_a
    |> form("#auix-product-form",
      product: %{reference: "item_new-1", name: "New item", quantity_initial: "5"}
    )
    |> render_submit()

    assert_receive %Event{schema: ^schema, action: :created, ids: [id], entities: [entity]}
    assert id
    assert entity.__struct__ == schema
    assert entity.name == "New item"

    :ok = Events.unsubscribe(schema)
  end

  @spec assert_row_delete(Plug.Conn.t(), binary()) :: term()
  defp assert_row_delete(conn, path) do
    %{"id_row-1" => first} = create_sample_products(2, :row)
    id = first.id

    {:ok, view_a, _} = live(conn, path)
    {:ok, view_b, _} = live(conn, path)

    render_click(view_a, "delete", %{"id" => id})

    refute has_element?(view_b, "#products-#{id}")
  end

  @spec assert_originator_silent(Plug.Conn.t(), binary()) :: term()
  defp assert_originator_silent(conn, path) do
    Process.register(self(), :auix_events_probe)
    %{"id_orig-1" => first} = create_sample_products(2, :orig)
    id = first.id

    {:ok, view_a, _} = live(conn, path)
    {:ok, view_b, _} = live(conn, path)

    render_click(view_a, "delete", %{"id" => id})

    pid_b = view_b.pid
    assert_receive {:auix_event_seen, ^pid_b, %Event{action: :deleted}}
    pid_a = view_a.pid
    refute_receive {:auix_event_seen, ^pid_a, _}, 100

    Process.unregister(:auix_events_probe)
  end

  @spec assert_child_delete(Plug.Conn.t(), map(), binary()) :: term()
  defp assert_child_delete(conn, backend, path) do
    create_sample_products_with_transactions(1, 2, :child)
    product = Repo.get_by!(MirrorCtx.Product, reference: "item_child-1")

    query =
      from(t in MirrorCtx.ProductTransaction,
        where: t.product_id == ^product.id,
        order_by: t.id,
        limit: 1
      )

    transaction = Repo.one!(query)

    child_schema = schema(backend, :ProductTransaction)
    subscribe(child_schema)
    {:ok, view, _} = live(conn, "#{path}/#{product.id}/edit")

    view
    |> element(
      "table a[name^='auix-delete-product__product_transaction-'][phx-click*='#{transaction.id}']"
    )
    |> render_click()

    assert_receive %Event{schema: ^child_schema, action: :deleted, ids: [id]}
    assert id == transaction.id

    :ok = Events.unsubscribe(child_schema)
  end

  @spec assert_outside_event(Plug.Conn.t(), map(), binary()) :: term()
  defp assert_outside_event(conn, backend, path) do
    {:ok, view, _} = live(conn, path)
    extra = 1 |> create_sample_products(:extra) |> Map.fetch!("id_extra-1")

    refute has_element?(view, "#products-#{extra.id}")

    entity = read(backend, :Product, extra.id)
    fn -> Events.created(entity) end |> Task.async() |> Task.await()

    assert has_element?(view, "#products-#{extra.id}", "Item extra-1")
  end

  @spec assert_unset_pubsub(Plug.Conn.t(), binary(), module()) :: term()
  defp assert_unset_pubsub(conn, path, schema) do
    previous = Application.get_env(:aurora_uix, :pubsub_server)
    on_exit(fn -> restore_pubsub_server(previous) end)
    Application.delete_env(:aurora_uix, :pubsub_server)

    %{"id_unset-1" => product} = create_sample_products(1, :unset)
    id = product.id
    {:ok, view, _} = live(conn, path)
    Phoenix.PubSub.subscribe(Aurora.Uix.PubSub, Events.topic(schema))
    on_exit(fn -> Phoenix.PubSub.unsubscribe(Aurora.Uix.PubSub, Events.topic(schema)) end)

    pids = Aurora.Uix.PubSub |> Registry.lookup(Events.topic(schema)) |> Enum.map(&elem(&1, 0))

    refute view.pid in pids

    flush_events(schema)
    render_click(view, "delete", %{"id" => id})

    refute_receive %Event{schema: ^schema}, 100
    refute has_element?(view, "#products-#{id}")

    restore_pubsub_server(previous)
  end

  @spec assert_nothing_deleted(Plug.Conn.t(), binary(), module()) :: term()
  defp assert_nothing_deleted(conn, path, schema) do
    %{"id_only-1" => product} = create_sample_products(1, :only)
    {:ok, view, _} = live(conn, path)

    select_row(view, product.id)
    Repo.delete!(product)

    render_click(view, "selected-delete_all", %{})
    render_async(view)

    refute_receive %Event{schema: ^schema}, 100
  end

  @spec assert_selection_leaves(Plug.Conn.t(), binary()) :: term()
  defp assert_selection_leaves(conn, path) do
    %{"id_sel-1" => first, "id_sel-2" => second} = create_sample_products(2, :sel)

    {:ok, view_b, _} = live(conn, path)
    select_row(view_b, first.id)
    select_row(view_b, second.id)
    {:ok, view_a, _} = live(conn, path)

    assert has_element?(view_b, @badge, "2")

    render_click(view_a, "delete", %{"id" => first.id})

    assert has_element?(view_b, @badge, "1")
  end

  @spec assert_reopened_starts_clean(Plug.Conn.t(), binary(), struct(), struct()) :: term()
  defp assert_reopened_starts_clean(conn, path, first, second) do
    {:ok, view, _} = live(conn, "#{path}/#{first.id}/edit")
    type_name(view, "Typed name")

    render_patch(view, "#{path}/#{second.id}/edit")

    assert has_element?(
             view,
             "#auix-product-edit-modal input[name='product[name]'][value='#{second.name}']"
           )

    refute has_element?(view, "input[name='product[name]'][value='Typed name']")

    request_close(view)

    refute has_element?(view, "#auix-product-discard-confirm-modal")
  end

  @spec assert_other_record_ignored(Plug.Conn.t(), map(), binary(), struct(), struct()) ::
          term()
  defp assert_other_record_ignored(conn, backend, path, first, second) do
    {:ok, view, _} = live(conn, "#{path}/#{first.id}/edit")
    type_name(view, "Typed name")

    backend |> read(:Product, second.id) |> Events.updated()

    refute has_element?(view, "#flash-info")
    assert has_element?(view, "input[name='product[name]'][value='Typed name']")
  end

  ## Gettext

  @spec sample_parsed_opts() :: map()
  defp sample_parsed_opts do
    %{
      layout_type: :form,
      layout_tree: %Aurora.Uix.Layout.Node.Form{
        resource: :product,
        children: [
          %Aurora.Uix.Layout.Node.Field{key: :reference},
          %Aurora.Uix.Layout.Node.Field{key: :name}
        ]
      },
      fields: [
        %{label: "Reference", omitted: false},
        %{label: "Name", omitted: false},
        %{label: "Name", omitted: false},
        %{label: nil, omitted: false}
      ],
      preload: [],
      configurations: %{},
      resource_name: :product,
      modules: %{caller: Aurora.UixWeb.Test, web: Aurora.UixWeb.Test},
      module_name: "GeneratedProduct"
    }
  end

  @spec assert_domain_extraction() :: term()
  defp assert_domain_extraction do
    source_path = File.cwd!() <> "/lib/aurora_uix/templates/basic/generators/form_generator.ex"
    source = File.read!(source_path)

    old_domain = Application.get_env(:aurora_uix, :gettext_domain)
    temp_module = Aurora.Uix.Test.FormGeneratorWithDomain

    try do
      Application.put_env(:aurora_uix, :gettext_domain, "forms")
      :code.purge(temp_module)
      :code.delete(temp_module)

      [{compiled_module, _bytecode}] =
        source
        |> String.replace(
          "defmodule Aurora.Uix.Templates.Basic.Generators.FormGenerator do",
          "defmodule Aurora.Uix.Test.FormGeneratorWithDomain do"
        )
        |> Code.compile_string(source_path)

      generated =
        sample_parsed_opts()
        |> compiled_module.generate_module()
        |> Macro.to_string()

      assert generated =~ "use Aurora.Uix.GettextResolver"
      assert generated =~ "defp _aurora_uix_extract do"
      assert generated =~ "dgettext(\"forms\", \"Reference\")"
      assert length(Regex.scan(~r/dgettext\("forms", "Name"\)/, generated)) == 1
      refute generated =~ "dgettext(\"forms\", nil)"
    after
      restore_gettext_domain(old_domain)

      :code.purge(temp_module)
      :code.delete(temp_module)
    end
  end

  @spec restore_gettext_domain(binary() | nil) :: :ok
  defp restore_gettext_domain(nil), do: Application.delete_env(:aurora_uix, :gettext_domain)

  defp restore_gettext_domain(domain),
    do: Application.put_env(:aurora_uix, :gettext_domain, domain)

  ## Helpers

  @spec flush_events(module()) :: :ok
  defp flush_events(schema) do
    receive do
      %Event{schema: ^schema} -> flush_events(schema)
    after
      0 -> :ok
    end
  end

  @spec subscribe(module()) :: :ok
  defp subscribe(schema) do
    :ok = Events.subscribe(schema)
    on_exit(fn -> Events.unsubscribe(schema) end)
  end

  @spec restore_pubsub_server(module() | nil) :: :ok
  defp restore_pubsub_server(nil), do: Application.delete_env(:aurora_uix, :pubsub_server)
  defp restore_pubsub_server(server), do: Application.put_env(:aurora_uix, :pubsub_server, server)

  @spec schema(map(), atom()) :: module()
  defp schema(%{name: :ash}, name), do: Module.concat(Aurora.Uix.Test.MirrorAsh, name)
  defp schema(%{name: :ctx}, name), do: Module.concat(Aurora.Uix.Test.MirrorCtx, name)

  @spec read(map(), atom(), binary()) :: struct()
  defp read(%{name: :ash} = backend, name, id), do: backend |> schema(name) |> Ash.get!(id)
  defp read(%{name: :ctx} = backend, name, id), do: backend |> schema(name) |> Repo.get!(id)

  @spec component(map(), atom(), atom(), atom()) :: module()
  defp component(backend, variant, resource, kind),
    do: Module.concat([Mirror.sibling(backend.name, variant), resource, kind])

  @spec paired_form_host(map()) :: module()
  defp paired_form_host(%{name: :ash}), do: Aurora.UixWeb.Test.MirrorAsh.PairedFormHost
  defp paired_form_host(%{name: :ctx}), do: Aurora.UixWeb.Test.MirrorCtx.PairedFormHost

  @spec paired_index_host(map()) :: module()
  defp paired_index_host(%{name: :ash}), do: Aurora.UixWeb.Test.MirrorAsh.PairedIndexHost
  defp paired_index_host(%{name: :ctx}), do: Aurora.UixWeb.Test.MirrorCtx.PairedIndexHost

  @spec sorted_products() :: [struct()]
  defp sorted_products, do: MirrorCtx.Product |> Repo.all() |> Enum.sort_by(& &1.reference)

  @spec p([struct()], pos_integer()) :: struct()
  defp p(products, n), do: Enum.at(products, n - 1)

  @spec row(binary(), struct()) :: binary()
  defp row(id, product), do: "##{id} tr[id='#{id}-products-#{product.id}']"

  @spec mount_components(Plug.Conn.t(), list(map())) :: tuple()
  defp mount_components(conn, components),
    do: live_isolated(conn, Host, session: %{"components" => components})

  @spec new_form(module()) :: map()
  defp new_form(module), do: %{module: module, id: "f1", props: %{action: :new}}

  @spec show(module(), struct()) :: map()
  defp show(module, product), do: %{module: module, id: "s1", props: %{entity_id: product.id}}

  @spec first_socket(module()) :: Phoenix.LiveView.Socket.t()
  defp first_socket(view), do: %Phoenix.LiveView.Socket{view: view, assigns: %{__changed__: %{}}}

  @spec later_socket(module(), atom()) :: Phoenix.LiveView.Socket.t()
  defp later_socket(view, resource),
    do: %Phoenix.LiveView.Socket{
      view: view,
      assigns: %{__changed__: %{}, auix: %{_resource: resource}}
    }

  @spec select_row(term(), term()) :: binary()
  defp select_row(view, id),
    do: render_change(view, "index-layout-change", %{"_target" => ["selected_check__#{id}"]})

  @spec type_name(term(), binary()) :: binary()
  defp type_name(view, name),
    do: view |> form("#auix-product-form", product: %{name: name}) |> render_change()

  @spec request_close(term()) :: binary()
  defp request_close(view) do
    view
    |> with_target("#auix-product-edit-modal [data-phx-component]:has(> #auix-product-form)")
    |> render_click("auix_request_close", %{})
  end
end
