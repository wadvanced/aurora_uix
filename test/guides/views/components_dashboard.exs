defmodule Aurora.UixWeb.Test.GuidesCapture.DashboardViews do
  @moduledoc false
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  auix_create_ui do
    index_columns(:product, [:name, :quantity_at_hand],
      order_by: :reference,
      page_title: "Products",
      pagination_items_per_page: 5
    )

    index_columns(:product_location, [:name, :type], page_title: "Locations", order_by: :name)
  end
end

defmodule Aurora.UixWeb.Test.GuidesCapture.DashboardLive do
  @moduledoc false
  use Aurora.UixWeb.Test, :live_view

  alias Aurora.UixWeb.Test.GuidesCapture.DashboardViews

  on_mount(Aurora.Uix.Live.ComponentHooks)

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:products, Module.safe_concat(DashboardViews, "Product.IndexComponent"))
      |> assign(:locations, Module.safe_concat(DashboardViews, "ProductLocation.IndexComponent"))

    ~H"""
    <main style="padding: 1.5rem;">
      <h1 style="font-size: 1.75rem; font-weight: 700; margin-bottom: 1.5rem;">
        My own dashboard page
      </h1>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; align-items: start;">
        <section style="border: 2px dashed #94a3b8; border-radius: 0.75rem; padding: 0.75rem;">
          <.live_component module={@products} id="dashboard-products" />
        </section>
        <section style="border: 2px dashed #94a3b8; border-radius: 0.75rem; padding: 0.75rem;">
          <.live_component module={@locations} id="dashboard-locations" />
        </section>
      </div>
    </main>
    """
  end

  @impl true
  def handle_info({Aurora.Uix, _component_id, _intent}, socket), do: {:noreply, socket}
end
