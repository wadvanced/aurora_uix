defmodule Aurora.UixWeb.Test.MultiSelectUITest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Repo

  # Route registered in test/support/app_web/routes.ex as "multi-select-ui-products".
  # No field override on purpose: `labels` is an `{:array, Ecto.Enum}`, and what is under test is
  # that the parser alone turns it into a multiple select.
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    index_columns(:product, [:reference, :name, :labels], order_by: :reference)

    edit_layout :product, [] do
      stacked([:reference, :name, :quantity_initial, :labels])
    end
  end

  describe "form rendering" do
    test "renders the field as a multiple select with every declared value", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/multi-select-ui-products/new")

      assert has_element?(view, "select[multiple][name='product[labels][]']")

      for value <- ~w(fragile perishable hazardous) do
        assert has_element?(view, "select[name='product[labels][]'] option[value='#{value}']")
      end
    end

    test "pre-selects exactly the stored values on edit", %{conn: conn} do
      delete_all_inventory_data()

      [product] =
        1
        |> create_sample_products(:multi_select, %{labels: [:fragile, :hazardous]})
        |> Map.values()

      {:ok, view, _html} = live(conn, "/multi-select-ui-products/#{product.id}/edit")

      assert has_element?(view, "option[value='fragile'][selected]")
      assert has_element?(view, "option[value='hazardous'][selected]")
      refute has_element?(view, "option[value='perishable'][selected]")
    end
  end

  describe "writing through the parent form" do
    test "saves every selected value", %{conn: conn} do
      delete_all_inventory_data()

      {:ok, view, _html} = live(conn, "/multi-select-ui-products/new")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "multi_ref",
          "name" => "Multi labels",
          "quantity_initial" => "5",
          "labels" => ["fragile", "perishable"]
        }
      })
      |> render_submit()

      assert %Product{labels: [:fragile, :perishable]} =
               Repo.get_by(Product, reference: "multi_ref")
    end
  end

  describe "index" do
    test "shows the option labels joined, and offers no filter for the field", %{conn: conn} do
      delete_all_inventory_data()
      create_sample_products(1, :multi_select, %{labels: [:fragile, :hazardous]})

      {:ok, view, _html} = live(conn, "/multi-select-ui-products")

      assert has_element?(view, "[name='auix-show-product']", "Fragile, Hazardous")

      view
      |> element("[name='auix-filter_toggle_open']")
      |> render_click()

      # A multi-value select is not filterable: the strip renders a single-value input, and the
      # comparison against an array column would be a query error.
      refute has_element?(view, "[name='filter_from__labels']")
    end
  end
end
