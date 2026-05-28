defmodule Aurora.UixWeb.Test.GettextDomainTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    index_columns(:product, [:id, :reference, :name])

    edit_layout :product do
      inline([:reference, :name])
    end

    show_layout :product do
      inline([:reference, :name])
    end
  end

  test "save button and field labels render through dt translation", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test)
      |> get_in(["id_test-1", Access.key!(:id)])

    {:ok, view, _html} = live(conn, "/gettext-domain-products/#{product_id}/edit")

    assert has_element?(view, "[name='auix-save-product']", "Save Product")
    assert has_element?(view, "label", "Reference")
    assert has_element?(view, "label", "Name")
  end

  test "edit button and field labels render through dt translation", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products(:test)
      |> get_in(["id_test-1", Access.key!(:id)])

    {:ok, view, _html} = live(conn, "/gettext-domain-products/#{product_id}/show")

    assert has_element?(view, "[name='auix-edit-product']", "Edit Product")
    assert has_element?(view, "label", "Reference")
    assert has_element?(view, "label", "Name")
  end
end
