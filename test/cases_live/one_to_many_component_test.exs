defmodule Aurora.UixWeb.Test.OneToManyComponentTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Repo

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_compact, context: Inventory, schema: Product)

  auix_resource_metadata :product_location do
    context(Inventory)
    schema(ProductLocation)
    field(:products, resource: :product_compact)
  end

  auix_create_ui do
    index_columns(:product_compact, [:reference, :name], module_name: :index_compact)
    edit_layout(:product_compact, use: :product_form_component)
    show_layout(:product_compact, use: :product_show_component)
    index_live(:product_compact, module_name: :compact_products)

    show_layout :product_location do
      stacked([:reference, :name, :products])
    end
  end

  @locations "/one-to-many-component-product_locations"

  test "the child list is an index component of the related resource", %{conn: conn} do
    delete_all_inventory_data()

    {:ok, location} =
      Repo.insert(%ProductLocation{reference: "loc", name: "Loc", type: "t"})

    {:ok, product} =
      Repo.insert(%Product{reference: "p-1", name: "First", product_location_id: location.id})

    {:ok, _product} =
      Repo.insert(%Product{reference: "p-2", name: "Second", product_location_id: location.id})

    {:ok, view, _html} = live(conn, "#{@locations}/#{location.id}/show")

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

    assert String.starts_with?(to, "/one-to-many-component-products/#{product.id}/show")
  end
end
