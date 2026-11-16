defmodule Aurora.UixWeb.Test.ComponentsPairedViews do
  use Aurora.Uix

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  auix_create_ui generate: [:form_component, :show_component] do
    edit_layout :product, module_name: :reference_form do
      inline([:reference, :name])
    end
  end
end

defmodule Aurora.UixWeb.Test.ComponentsPairedHostLive do
  use Aurora.UixWeb.Test, :live_view
  use Aurora.Uix

  alias Aurora.UixWeb.Test.ComponentsPairedViews

  @auix_resource_metadata %{
    product_location: ComponentsPairedViews.auix_resource(:product_location)
  }

  auix_create_ui generate: [] do
    edit_layout(:product_location, use: ComponentsPairedViews.auix_module(:reference_form))
  end

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:entity_id, Map.fetch!(session, "entity_id"))
     |> assign(:saved, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="auix-paired-host">
      <.live_component
        module={ComponentsPairedViews.auix_module(:reference_form)}
        id="location-form"
        resource={:product_location}
        entity_id={@entity_id}
      />
      <p id="auix-paired-saved" data-component={@saved}></p>
    </div>
    """
  end

  @impl true
  def handle_info({Aurora.Uix, component_id, {:saved, _entity}}, socket),
    do: {:noreply, assign(socket, :saved, component_id)}
end

defmodule Aurora.UixWeb.Test.ComponentsFormShowTest do
  use(Aurora.UixWeb.Test.UICase, :phoenix_case)
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Repo
  alias Aurora.Uix.Templates.Basic.Helpers, as: H
  alias Aurora.UixWeb.Test.ComponentHostLive, as: Host
  alias Aurora.UixWeb.Test.ComponentsFormShowTest.Product.FormComponent
  alias Aurora.UixWeb.Test.ComponentsFormShowTest.Product.ShowComponent
  alias Aurora.UixWeb.Test.ComponentsPairedHostLive, as: Paired
  alias Aurora.UixWeb.Test.ComponentsPairedViews, as: Views
  alias Views.Product.ReferenceForm, as: Form
  alias Views.ProductLocation.FormComponent, as: LocationForm

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui()

  test "an embedded form saves and reports", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = mount_components(conn, [new_form()])

    assert has_element?(view, "#auix-product-form input[name='product[reference]']")

    view
    |> form("#auix-product-form",
      product: %{reference: "emb-1", name: "Embedded", quantity_initial: 1}
    )
    |> render_submit()

    assert has_element?(view, "#auix-host-intents li[data-component='f1'][data-intent='saved']")
    assert has_element?(view, "#flash-info", "Product updated successfully")
    assert has_element?(view, "#auix-host")
  end

  test "an embedded form loads the record of its entity_id", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(2)
    [first, second] = Repo.all(Product)

    {:ok, view, _html} =
      mount_components(conn, [
        %{module: FormComponent, id: "f1", props: %{entity_id: first.id}}
      ])

    assert has_element?(view, "input[name='product[reference]'][value='#{first.reference}']")

    send(
      view.pid,
      {:set_components, [%{module: FormComponent, id: "f1", props: %{entity_id: second.id}}]}
    )

    assert has_element?(view, "input[name='product[reference]'][value='#{second.reference}']")
  end

  test "an embedded show reports close and edit", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(1)
    [product] = Repo.all(Product)
    {:ok, view, _html} = mount_components(conn, [show(product)])

    view |> element("div[name='auix-show-navigate-back'] a") |> render_click()
    assert has_element?(view, "#auix-host-intents li[data-component='s1'][data-intent='closed']")

    view |> element("a[name='auix-edit-product']") |> render_click()

    assert has_element?(
             view,
             "#auix-host-intents li[data-component='s1'][data-intent='open'][data-value='edit:#{product.id}']"
           )
  end

  test "closing an embedded form reports closed", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = mount_components(conn, [new_form()])

    view
    |> with_target("#auix-host > [data-phx-component]")
    |> render_click("auix_request_close", %{})

    assert has_element?(view, "#auix-host-intents li[data-component='f1'][data-intent='closed']")
  end

  test "embedded components have no record navigator", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_products(2)
    [first, _second] = Repo.all(Product)

    {:ok, form_view, _html} =
      mount_components(conn, [
        %{module: FormComponent, id: "f1", props: %{entity_id: first.id}}
      ])

    refute has_element?(form_view, ".auix-record-navigator-bar")

    {:ok, show_view, _html} = mount_components(conn, [show(first)])
    refute has_element?(show_view, ".auix-record-navigator-bar")
  end

  test "a paired form serves a resource of the LiveView that renders it", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_product_locations(1)
    [location] = Repo.all(ProductLocation)

    {:ok, view, _html} = live_isolated(conn, Paired, session: %{"entity_id" => location.id})

    assert has_element?(
             view,
             "#auix-product_location-form input[name='product_location[reference]'][value='#{location.reference}']"
           )

    assert has_element?(view, "input[name='product_location[name]']")
    refute has_element?(view, "input[name='product_location[type]']")

    view
    |> form("#auix-product_location-form", product_location: %{name: "Renamed"})
    |> render_submit()

    assert Repo.get!(ProductLocation, location.id).name == "Renamed"
    assert has_element?(view, "#auix-paired-saved[data-component='location-form']")
  end

  test "resource is checked against the LiveView that renders the component" do
    host_socket = first(Host)
    paired_socket = first(Paired)
    bound_socket = later(Paired, :product_location)

    assert_raise ArgumentError, ~r/declares no auix_create_ui/, fn ->
      H.resource_binding(host_socket, %{id: "c", resource: :product_location}, Form, :form)
    end

    assert_raise ArgumentError, ~r/unknown resource :nope/, fn ->
      H.resource_binding(paired_socket, %{id: "c", resource: :nope}, Form, :form)
    end

    assert_raise ArgumentError, ~r/does not pair/, fn ->
      H.resource_binding(
        paired_socket,
        %{id: "c", resource: :product_location},
        LocationForm,
        :form
      )
    end

    assert_raise ArgumentError, ~r/already serves/, fn ->
      H.resource_binding(bound_socket, %{id: "c", resource: :product}, Form, :form)
    end
  end

  test "resource_binding/4 binds once" do
    paired_socket = first(Paired)
    bound_socket = later(Paired, :product_location)

    assert %{_resource: :product_location, resource_name: :product_location, layout_type: :form} =
             H.resource_binding(
               paired_socket,
               %{id: "c", resource: :product_location},
               Form,
               :form
             )

    assert H.resource_binding(paired_socket, %{id: "c"}, Form, :form) == %{_resource: nil}

    assert H.resource_binding(bound_socket, %{id: "c", resource: :product_location}, Form, :form) ==
             %{}

    assert H.resource_binding(bound_socket, %{id: "c"}, Form, :form) == %{}
  end

  @spec mount_components(Plug.Conn.t(), list(map())) :: tuple()
  defp mount_components(conn, components),
    do: live_isolated(conn, Host, session: %{"components" => components})

  @spec new_form() :: map()
  defp new_form,
    do: %{module: FormComponent, id: "f1", props: %{action: :new}}

  @spec show(struct()) :: map()
  defp show(product),
    do: %{module: ShowComponent, id: "s1", props: %{entity_id: product.id}}

  @spec first(module()) :: Phoenix.LiveView.Socket.t()
  defp first(view), do: %Phoenix.LiveView.Socket{view: view, assigns: %{__changed__: %{}}}

  @spec later(module(), atom()) :: Phoenix.LiveView.Socket.t()
  defp later(view, resource),
    do: %Phoenix.LiveView.Socket{
      view: view,
      assigns: %{__changed__: %{}, auix: %{_resource: resource}}
    }
end
