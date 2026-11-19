defmodule Aurora.UixWeb.Test.ComponentsIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl

  alias Aurora.Uix.Templates.Basic.Helpers

  @spec auix_handle_event(binary(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def auix_handle_event("ping", _params, socket),
    do: {:noreply, Helpers.report_intent(socket, {:page, 99})}

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end

defmodule Aurora.UixWeb.Test.ComponentsIndexHandled do
  use Aurora.Uix

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui generate: [:index_component] do
    index_columns(:product, [:reference],
      component_handler_module: Aurora.UixWeb.Test.ComponentsIndexHandler
    )
  end
end

defmodule Aurora.UixWeb.Test.ComponentsIndexViews do
  use Aurora.Uix

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  auix_create_ui generate: [:index_component] do
    index_columns(:product, [:reference, :name], module_name: :index_compact)
  end
end

defmodule Aurora.UixWeb.Test.ComponentsIndexPairedHostLive do
  use Aurora.UixWeb.Test, :live_view
  use Aurora.Uix

  alias Aurora.UixWeb.Test.ComponentsIndexViews

  @auix_resource_metadata %{
    product_location: ComponentsIndexViews.auix_resource(:product_location)
  }

  auix_create_ui generate: [] do
    index_columns(:product_location,
      use: ComponentsIndexViews.auix_module(:index_compact)
    )
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div id="auix-paired-host">
      <.live_component
        module={ComponentsIndexViews.auix_module(:index_compact)}
        id="locations"
        resource={:product_location}
      />
    </div>
    """
  end
end

defmodule Aurora.UixWeb.Test.ComponentsIndexTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Event
  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Repo
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.UixWeb.Test.ComponentHostLive, as: Host
  alias Aurora.UixWeb.Test.ComponentsIndexHandled
  alias Aurora.UixWeb.Test.ComponentsIndexPairedHostLive, as: PairedHost
  alias Aurora.UixWeb.Test.ComponentsIndexTest, as: T

  alias T.Product.IndexComponent, as: C

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    index_columns(:product, [:reference, :name], pagination_items_per_page: 5)
  end

  test "an embedded index lists its scope", %{conn: conn} do
    products = sample_products(10)

    {:ok, view, _html} =
      mount_components(conn, [
        %{module: C, id: "low", props: %{where: [{:reference, :lt, "item_test-04"}]}}
      ])

    assert has_element?(view, row("low", p(products, 1)))
    assert has_element?(view, row("low", p(products, 3)))
    refute has_element?(view, row("low", p(products, 4)))
  end

  test "two instances keep their own page", %{conn: conn} do
    products = sample_products(10)

    {:ok, view, _html} =
      mount_components(conn, [
        %{module: C, id: "a", props: %{where: [{:reference, :lt, "item_test-04"}]}},
        %{module: C, id: "b", props: %{}}
      ])

    view
    |> element("#b div[name$='-xl2'] a[name='auix-pages_bar_page-2']")
    |> render_click()

    assert has_element?(view, row("b", p(products, 6)))
    refute has_element?(view, row("b", p(products, 1)))
    assert has_element?(view, row("a", p(products, 1)))

    assert has_element?(
             view,
             "#auix-host-intents li[data-component='b'][data-intent='page'][data-value='2']"
           )

    refute has_element?(view, "#auix-host-intents li[data-component='a']")
  end

  test "an embedded index reports open and delete", %{conn: conn} do
    products = sample_products(10)
    first = p(products, 1)
    second = p(products, 2)

    {:ok, view, _html} = mount_components(conn, [%{module: C, id: "a", props: %{}}])

    view
    |> element(row("a", first) <> " td.auix-items-table-action-cell a[name='auix-show-product']")
    |> render_click()

    assert has_element?(
             view,
             "#auix-host-intents li[data-intent='open'][data-value='show:#{first.id}']"
           )

    view |> element("#a a[name='auix-new-product']") |> render_click()
    assert has_element?(view, "#auix-host-intents li[data-intent='open'][data-value='new:']")

    view
    |> element(
      row("a", second) <> " td.auix-items-table-action-cell a[name='auix-delete-product']"
    )
    |> render_click()

    refute has_element?(view, row("a", second))

    assert has_element?(
             view,
             "#auix-host-intents li[data-intent='deleted'][data-value='#{second.id}']"
           )

    assert Repo.get(Product, second.id) == nil
  end

  test "an instance takes its page and its options", %{conn: conn} do
    products = sample_products(10)

    {:ok, view, _html} =
      mount_components(conn, [
        %{module: C, id: "a", props: %{page: 2}},
        %{module: C, id: "b", props: %{options: [sort_disabled?: true]}}
      ])

    assert has_element?(view, row("a", p(products, 6)))
    refute has_element?(view, row("a", p(products, 1)))
    assert has_element?(view, "#a button[name='auix-sort-reference']")
    refute has_element?(view, "#b button[name='auix-sort-reference']")
  end

  test "the card sort menu sorts its own instance", %{conn: conn} do
    sample_products(3)

    {:ok, view, _html} =
      mount_components(conn, [
        %{module: C, id: "a", props: %{}},
        %{module: C, id: "b", props: %{}}
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

  test "an event refreshes an instance", %{conn: conn} do
    sample_products(3)
    {:ok, view, _html} = mount_components(conn, [%{module: C, id: "a", props: %{}}])
    {:ok, added} = Repo.insert(%Product{reference: "item_test-9", name: "Added"})

    refute has_element?(view, row("a", added))

    Phoenix.LiveView.send_update(view.pid, C,
      id: "a",
      auix_event: %Event{schema: Product, action: :created, ids: [added.id]}
    )

    assert has_element?(view, row("a", added))
  end

  test "an embedded index with no record says so", %{conn: conn} do
    sample_products(10)

    {:ok, view, _html} =
      mount_components(conn, [%{module: C, id: "a", props: %{where: [{:reference, "none"}]}}])

    assert has_element?(view, "#a .auix-items-table-empty")
    refute has_element?(view, "#a tr[id^='a-products-']")
  end

  test "component_handler_module sets the handler of the component", %{conn: conn} do
    sample_products(10)

    {:ok, view, _html} =
      mount_components(conn, [
        %{
          module: ComponentsIndexHandled.Product.IndexComponent,
          id: "h",
          props: %{}
        }
      ])

    view |> with_target("#h") |> render_click("ping", %{})

    assert has_element?(
             view,
             "#auix-host-intents li[data-component='h'][data-intent='page'][data-value='99']"
           )
  end

  test "a paired index serves a resource of the LiveView that renders it", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_product_locations(2)
    [first | _] = locations = Repo.all(ProductLocation)

    {:ok, view, _html} = live_isolated(conn, PairedHost)

    location_row = fn location ->
      "#locations tr[id='locations-product_locations-#{location.id}']"
    end

    assert Enum.all?(locations, &has_element?(view, location_row.(&1)))
    assert has_element?(view, location_row.(first), first.reference)
    refute has_element?(view, location_row.(first), first.type)
  end

  test "an index component is checked against the pairing" do
    socket = %Phoenix.LiveView.Socket{
      view: PairedHost,
      assigns: %{__changed__: %{}}
    }

    assert_raise ArgumentError, ~r/does not pair/, fn ->
      Helpers.resource_binding(
        socket,
        %{id: "x", resource: :product_location},
        C,
        :index
      )
    end
  end

  @spec sample_products(pos_integer()) :: [struct()]
  defp sample_products(count) do
    delete_all_inventory_data()
    create_sample_products(count, :test)
    Product |> Repo.all() |> Enum.sort_by(& &1.reference)
  end

  @spec p([struct()], pos_integer()) :: struct()
  defp p(products, n), do: Enum.at(products, n - 1)

  @spec row(binary(), struct()) :: binary()
  defp row(id, product), do: "##{id} tr[id='#{id}-products-#{product.id}']"

  @spec mount_components(Plug.Conn.t(), list(map())) :: tuple()
  defp mount_components(conn, components),
    do: live_isolated(conn, Host, session: %{"components" => components})
end
