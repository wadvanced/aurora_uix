defmodule Aurora.UixWeb.Test.IncludedLayouts do
  use Aurora.Uix

  auix_create_layout do
    edit_layout :product do
      inline([:reference, :name])
    end

    show_layout :product do
      inline([:reference, :description])
    end
  end
end

defmodule Aurora.UixWeb.Test.IncludedLayoutsTest do
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Aurora.UixWeb.Test.UICase, :phoenix_case

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui include: Aurora.UixWeb.Test.IncludedLayouts do
    show_layout :product do
      inline([:name])
    end
  end

  test "a layout declared in another module renders", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/included-layouts-products/new")

    assert has_element?(view, "input[name='product[reference]']")
    assert has_element?(view, "input[name='product[name]']")
    refute has_element?(view, "input[name='product[description]']")
  end

  test "a local layout replaces the included one", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test)
      |> get_in([Access.key!("id_test-1"), Access.key!(:id)])

    {:ok, view, _html} = live(conn, "/included-layouts-products/#{product_id}/show")

    assert has_element?(view, "input[name='name']")
    refute has_element?(view, "input[name='reference']")
    refute has_element?(view, "input[name='description']")
  end
end
