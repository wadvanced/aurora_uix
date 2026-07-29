defmodule Aurora.UixWeb.Test.UnimplementedFieldUITest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  # Route registered in test/support/app_web/routes.ex as "unimplemented-field-products".
  # `labels` is a real array column; the override forces the html_type the parsers assign to any
  # array they cannot offer an editor for, without needing a schema the library refuses to edit.
  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:labels, html_type: :unimplemented)
  end

  auix_create_ui do
    index_columns(:product, [:reference, :labels], order_by: :reference)

    edit_layout :product, [] do
      stacked([:reference, :name, :quantity_initial, :labels])
    end
  end

  describe "a field the library cannot edit" do
    test "renders the value read-only instead of an input", %{conn: conn} do
      delete_all_inventory_data()

      [product] =
        1
        |> create_sample_products(:unimplemented, %{labels: [:fragile, :hazardous]})
        |> Map.values()

      {:ok, view, _html} = live(conn, "/unimplemented-field-products/#{product.id}/edit")

      # Never an `<input type="unimplemented">`, which a browser silently renders as a text box.
      refute has_element?(view, "input[name='product[labels]']")
      refute has_element?(view, "input[type='unimplemented']")

      assert has_element?(view, "li", "fragile")
      assert has_element?(view, "li", "hazardous")
    end

    test "shows the empty message when there is no value", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/unimplemented-field-products/new")

      assert has_element?(view, ".auix-selected-list-empty-msg")
    end

    test "joins the values in the index cell rather than raising", %{conn: conn} do
      delete_all_inventory_data()
      create_sample_products(1, :unimplemented, %{labels: [:fragile, :hazardous]})

      {:ok, view, _html} = live(conn, "/unimplemented-field-products")

      assert has_element?(view, "[name='auix-show-product']", "fragile, hazardous")
    end
  end
end
