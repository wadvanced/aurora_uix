defmodule Aurora.UixWeb.Test.MultiSelectUITest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Repo

  # Route registered in test/support/app_web/routes.ex as "multi-select-ui-products".
  # No field override on purpose: `labels` is an `{:array, Ecto.Enum}`, and what is under test is
  # that the parser alone turns it into a multi-value select.
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    index_columns(:product, [:reference, :name, :labels], order_by: :reference)

    edit_layout :product, [] do
      stacked([:reference, :name, :quantity_initial, :labels])
    end

    show_layout :product, [] do
      stacked([:reference, :name, :labels])
    end
  end

  describe "form rendering" do
    test "renders one checkbox per declared value, plus the empty-list sentinel", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/multi-select-ui-products/new")

      assert has_element?(view, "input[type='hidden'][name='product[labels][]']")
      refute has_element?(view, "select[multiple][name='product[labels][]']")

      for value <- ~w(fragile perishable hazardous) do
        assert has_element?(
                 view,
                 "input[type='checkbox'][name='product[labels][]'][value='#{value}']"
               )
      end
    end

    test "checks exactly the stored values on edit", %{conn: conn} do
      delete_all_inventory_data()

      [product] =
        1
        |> create_sample_products(:multi_select, %{labels: [:fragile, :hazardous]})
        |> Map.values()

      {:ok, view, _html} = live(conn, "/multi-select-ui-products/#{product.id}/edit")

      assert checked_values(view) == ["fragile", "hazardous"]
    end
  end

  describe "toggle all" do
    test "checks every option, then clears them", %{conn: conn} do
      delete_all_inventory_data()

      [product] =
        1
        |> create_sample_products(:multi_select, %{labels: [:fragile]})
        |> Map.values()

      {:ok, view, _html} = live(conn, "/multi-select-ui-products/#{product.id}/edit")

      assert toggle_state(view) == :mixed

      toggle_all(view, "true")

      assert checked_values(view) == ["fragile", "perishable", "hazardous"]
      assert toggle_state(view) == :all

      toggle_all(view, "false")

      assert checked_values(view) == []
      assert toggle_state(view) == :none
    end
  end

  describe "writing through the parent form" do
    test "saves every checked value, ignoring the sentinel", %{conn: conn} do
      delete_all_inventory_data()

      {:ok, view, _html} = live(conn, "/multi-select-ui-products/new")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "multi_ref",
          "name" => "Multi labels",
          "quantity_initial" => "5",
          "labels" => ["", "fragile", "perishable"]
        }
      })
      |> render_submit()

      assert %Product{labels: [:fragile, :perishable]} =
               Repo.get_by(Product, reference: "multi_ref")
    end
  end

  describe "show" do
    test "lists only the selected values", %{conn: conn} do
      delete_all_inventory_data()

      [product] =
        1
        |> create_sample_products(:multi_select, %{labels: [:fragile, :hazardous]})
        |> Map.values()

      {:ok, view, _html} = live(conn, "/multi-select-ui-products/#{product.id}/show")

      assert selected_items(view) == ["Fragile", "Hazardous"]
      refute has_element?(view, "input[type='checkbox'][name='product[labels][]']")
    end

    test "shows the empty-state message when nothing is selected", %{conn: conn} do
      delete_all_inventory_data()

      [product] =
        1
        |> create_sample_products(:multi_select, %{labels: []})
        |> Map.values()

      {:ok, view, _html} = live(conn, "/multi-select-ui-products/#{product.id}/show")

      assert has_element?(
               view,
               "#auix-multi-select-labels-show-options .auix-selected-list-empty-msg",
               "No options to show"
             )
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

  @spec toggle_all(Phoenix.LiveViewTest.View.t(), binary()) :: binary()
  defp toggle_all(view, state) do
    view
    |> form("#auix-product-form", %{"auix_toggle_all__labels" => state})
    |> render_change(%{"_target" => ["auix_toggle_all__labels"]})
  end

  @spec toggle_state(Phoenix.LiveViewTest.View.t()) :: :all | :none | :mixed
  defp toggle_state(view) do
    toggle =
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("input#auix-multi-select-toggle_all-labels")

    cond do
      LazyHTML.attribute(toggle, "checked") != [] -> :all
      toggle |> LazyHTML.attribute("class") |> to_string() =~ "auix-checkbox--mixed" -> :mixed
      true -> :none
    end
  end

  @spec checked_values(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp checked_values(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("input[type='checkbox'][name='product[labels][]'][checked]")
    |> Enum.map(&(&1 |> LazyHTML.attribute("value") |> List.first()))
  end

  @spec selected_items(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp selected_items(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("#auix-multi-select-labels-show-options .auix-selected-list-item")
    |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
  end
end
