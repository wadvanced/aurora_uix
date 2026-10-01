defmodule Aurora.UixWeb.Test.EventsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  @badge "#auix-delete-all-button-product>button span.auix-button-badge"

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  auix_create_ui do
    index_columns(:product, [:reference, :name],
      handler_module: Aurora.UixWeb.EventsProbeIndexHandler
    )

    edit_layout :product do
      stacked([:reference, :name, :quantity_initial, :product_transactions])
    end

    show_layout :product do
      stacked([:reference, :name])
    end
  end

  test "an index subscribes to its own schema's topic only", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, products, _} = live(conn, "/events-products")
    {:ok, locations, _} = live(conn, "/events-product-locations")

    pids = Aurora.Uix.PubSub |> Registry.lookup(Events.topic(Product)) |> Enum.map(&elem(&1, 0))

    assert products.pid in pids
    refute locations.pid in pids
  end

  test "a save in one view re-reads another index", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(1, :test)
    id = product.id

    {:ok, view_b, _} = live(conn, "/events-products")
    {:ok, view_a, _} = live(conn, "/events-products/#{id}/edit")

    view_a
    |> form("#auix-product-form", product: %{name: "Renamed item", quantity_initial: "5"})
    |> render_submit()

    assert has_element?(view_b, "#products-#{id}", "Renamed item")
  end

  test "a new-record save publishes :created", %{conn: conn} do
    delete_all_inventory_data()
    :ok = Events.subscribe(Product)
    {:ok, view_a, _} = live(conn, "/events-products/new")

    view_a
    |> form("#auix-product-form",
      product: %{reference: "item_new-1", name: "New item", quantity_initial: "5"}
    )
    |> render_submit()

    assert_receive %Event{action: :created, ids: [id], entities: [%Product{name: "New item"}]}
    assert id
  end

  test "a row delete removes the row from another index", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => first} = create_sample_products(2, :test)
    id = first.id

    {:ok, view_a, _} = live(conn, "/events-products")
    {:ok, view_b, _} = live(conn, "/events-products")

    render_click(view_a, "delete", %{"id" => id})

    refute has_element?(view_b, "#products-#{id}")
  end

  test "the originating view does not receive its own event", %{conn: conn} do
    Process.register(self(), :auix_events_probe)
    delete_all_inventory_data()
    %{"id_test-1" => first} = create_sample_products(2, :test)
    id = first.id

    {:ok, view_a, _} = live(conn, "/events-products")
    {:ok, view_b, _} = live(conn, "/events-products")

    render_click(view_a, "delete", %{"id" => id})

    pid_b = view_b.pid
    assert_receive {:auix_event_seen, ^pid_b, %Event{action: :deleted}}
    pid_a = view_a.pid
    refute_receive {:auix_event_seen, ^pid_a, _}, 100
  end

  test "a one-to-many child delete publishes on the child's schema", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products_with_transactions(1, 2, :test)
    product = List.first(Inventory.list_products())

    transaction =
      product.id
      |> Inventory.get_product!(preload: [:product_transactions])
      |> Map.get(:product_transactions)
      |> List.first()

    :ok = Events.subscribe(ProductTransaction)
    {:ok, view, _} = live(conn, "/events-products/#{product.id}/edit")

    view
    |> element(
      "table a[name^='auix-delete-product__product_transaction-'][phx-click*='#{transaction.id}']"
    )
    |> render_click()

    assert_receive %Event{schema: ProductTransaction, action: :deleted, ids: [id]}
    assert id == transaction.id
  end

  test "Delete selected publishes only the records it deleted", %{conn: conn} do
    delete_all_inventory_data()

    %{"id_test-1" => first, "id_test-2" => second, "id_test-3" => third} =
      create_sample_products(3, :test)

    :ok = Events.subscribe(Product)
    {:ok, view_a, _} = live(conn, "/events-products")
    {:ok, view_b, _} = live(conn, "/events-products")

    Enum.each([first, second, third], &select_row(view_a, &1.id))
    Inventory.delete_product(third)

    render_click(view_a, "selected-delete_all", %{})
    render_async(view_a)

    assert_receive %Event{action: :deleted, ids: ids}
    assert Enum.sort(ids) == Enum.sort([first.id, second.id])
    refute has_element?(view_b, "#products-#{first.id}")
  end

  test "Delete selected publishes nothing when nothing was deleted", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(1, :test)
    :ok = Events.subscribe(Product)
    {:ok, view, _} = live(conn, "/events-products")

    select_row(view, product.id)
    Inventory.delete_product(product)

    render_click(view, "selected-delete_all", %{})
    render_async(view)

    refute_receive %Event{}, 100
  end

  test "a deleted id leaves another view's selection", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => first, "id_test-2" => second} = create_sample_products(2, :test)

    {:ok, view_b, _} = live(conn, "/events-products")
    select_row(view_b, first.id)
    select_row(view_b, second.id)
    {:ok, view_a, _} = live(conn, "/events-products")

    assert has_element?(view_b, @badge, "2")

    render_click(view_a, "delete", %{"id" => first.id})

    assert has_element?(view_b, @badge, "1")
  end

  test "an event from a non-LiveView process re-reads the index", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(1, :test)
    {:ok, view, _} = live(conn, "/events-products")
    extra = 1 |> create_sample_products(:extra) |> Map.fetch!("id_extra-1")

    refute has_element?(view, "#products-#{extra.id}")

    fn -> Events.created(extra) end |> Task.async() |> Task.await()

    assert has_element?(view, "#products-#{extra.id}", "Item extra-1")
  end

  test "index commands target one view", %{conn: conn} do
    delete_all_inventory_data()
    %{"id_test-1" => first} = create_sample_products(2, :test)

    {:ok, view_a, _} = live(conn, "/events-products")
    {:ok, view_b, _} = live(conn, "/events-products")
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
  end

  test "an unset pubsub_server keeps today's behaviour", %{conn: conn} do
    previous = Application.get_env(:aurora_uix, :pubsub_server)
    on_exit(fn -> Application.put_env(:aurora_uix, :pubsub_server, previous) end)
    Application.delete_env(:aurora_uix, :pubsub_server)

    delete_all_inventory_data()
    %{"id_test-1" => product} = create_sample_products(1, :test)
    id = product.id
    {:ok, view, _} = live(conn, "/events-products")
    Phoenix.PubSub.subscribe(Aurora.Uix.PubSub, Events.topic(Product))

    pids = Aurora.Uix.PubSub |> Registry.lookup(Events.topic(Product)) |> Enum.map(&elem(&1, 0))

    refute view.pid in pids

    render_click(view, "delete", %{"id" => id})

    refute_receive %Event{}, 100
    refute has_element?(view, "#products-#{id}")
  end

  describe "an open show" do
    test "re-reads its record on :updated", %{conn: conn} do
      delete_all_inventory_data()
      %{"id_test-1" => product} = create_sample_products(1, :test)
      {:ok, view, _} = live(conn, "/events-products/#{product.id}/show")

      {:ok, renamed} =
        Inventory.update_product(product, %{name: "Renamed item", quantity_initial: 5})

      Events.updated(renamed)

      assert has_element?(view, "#auix-product-show-modal input[value='Renamed item']")
    end

    test "closes on :deleted", %{conn: conn} do
      delete_all_inventory_data()
      %{"id_test-1" => product} = create_sample_products(1, :test)
      {:ok, view, _} = live(conn, "/events-products/#{product.id}/show")
      Inventory.delete_product(product)

      Events.deleted(Product, [product.id])

      assert_patch(view, "/events-products")
      refute has_element?(view, "#auix-product-show-modal")
      assert has_element?(view, "#flash-info", "Item deleted successfully")
    end

    test "keeps its record when the re-read finds nothing", %{conn: conn} do
      delete_all_inventory_data()
      %{"id_test-1" => product} = create_sample_products(1, :test)
      {:ok, view, _} = live(conn, "/events-products/#{product.id}/show")
      Inventory.delete_product(product)

      Events.updated(product)

      assert has_element?(view, "#auix-product-show-modal input[value='Item test-1']")
    end
  end

  describe "an open form" do
    test "keeps typed input and reports an update", %{conn: conn} do
      delete_all_inventory_data()
      %{"id_test-1" => product} = create_sample_products(1, :test)
      {:ok, view, _} = live(conn, "/events-products/#{product.id}/edit")
      type_name(view, "Typed name")

      Events.updated(product)

      assert has_element?(
               view,
               "#auix-product-edit-modal input[name='product[name]'][value='Typed name']"
             )

      assert has_element?(view, "#flash-info", "Product updated successfully")

      request_close(view)

      assert has_element?(view, "#auix-product-discard-confirm-modal")
    end

    test "stays open and reports a delete", %{conn: conn} do
      delete_all_inventory_data()
      %{"id_test-1" => product} = create_sample_products(1, :test)
      {:ok, view, _} = live(conn, "/events-products/#{product.id}/edit")

      Events.deleted(Product, [product.id])

      assert has_element?(view, "#auix-product-edit-modal")
      assert has_element?(view, "#flash-info", "Item deleted successfully")
    end

    test "reopened on another record starts clean", %{conn: conn} do
      delete_all_inventory_data()
      %{"id_test-1" => first, "id_test-2" => second} = create_sample_products(2, :test)
      {:ok, view, _} = live(conn, "/events-products/#{first.id}/edit")
      type_name(view, "Typed name")

      render_patch(view, "/events-products/#{second.id}/edit")

      assert has_element?(
               view,
               "#auix-product-edit-modal input[name='product[name]'][value='Item test-2']"
             )

      refute has_element?(view, "input[name='product[name]'][value='Typed name']")

      request_close(view)

      refute has_element?(view, "#auix-product-discard-confirm-modal")
    end

    test "ignores an event for another record", %{conn: conn} do
      delete_all_inventory_data()
      %{"id_test-1" => first, "id_test-2" => second} = create_sample_products(2, :test)
      {:ok, view, _} = live(conn, "/events-products/#{first.id}/edit")
      type_name(view, "Typed name")

      Events.updated(second)

      refute has_element?(view, "#flash-info")
      assert has_element?(view, "input[name='product[name]'][value='Typed name']")
    end
  end

  @spec select_row(term(), term()) :: binary()
  defp select_row(view, id),
    do: render_change(view, "index-layout-change", %{"_target" => ["selected_check__#{id}"]})

  @spec type_name(term(), binary()) :: binary()
  defp type_name(view, name),
    do: view |> form("#auix-product-form", product: %{name: name}) |> render_change()

  @spec request_close(term()) :: binary()
  defp request_close(view) do
    view
    |> with_target("#auix-product-edit-modal [data-phx-component]")
    |> render_click("auix_request_close", %{})
  end
end

defmodule Aurora.UixWeb.EventsProbeIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("events-test-refresh", _params, socket) do
    Events.refresh()
    {:noreply, socket}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)

  @impl IndexImpl
  def auix_handle_info(%Event{} = event, socket) do
    case Process.whereis(:auix_events_probe) do
      nil -> :ok
      probe -> send(probe, {:auix_event_seen, self(), event})
    end

    super(event, socket)
  end

  def auix_handle_info(message, socket), do: super(message, socket)
end
