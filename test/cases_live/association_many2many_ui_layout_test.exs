defmodule Aurora.UixWeb.Test.AssociationMany2ManyUILayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.Supplier
  alias Aurora.Uix.Repo

  # Routes for both resources are registered in test/support/app_web/routes.ex as
  # "association/many_to_many/layout/products" and ".../suppliers".
  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:suppliers, option_label: :name)
  end

  auix_resource_metadata(:supplier, context: Inventory, schema: Supplier)

  auix_create_ui do
    edit_layout :product do
      stacked([:reference, :name, :quantity_initial, :suppliers])
    end

    show_layout :product do
      stacked([:reference, :name, :suppliers])
    end
  end

  describe "form rendering" do
    test "renders every candidate supplier as an option, none selected, on new", %{conn: conn} do
      delete_all_inventory_data()
      create_sample_products_with_suppliers(0, 3)

      {:ok, view, _html} = live(conn, "/association/many_to_many/layout/products/new")

      assert has_element?(view, "input[type='checkbox'][name='product[suppliers][]']")
      assert has_element?(view, "input[type='hidden'][name='product[suppliers][]']")

      assert options_count(view) == 3
      assert checked_ids(view) == []
    end

    test "pre-selects exactly the current members on edit", %{conn: conn} do
      delete_all_inventory_data()
      {[product], suppliers} = create_sample_products_with_suppliers(1, 3)
      [first | _rest] = suppliers

      {:ok, _} =
        product
        |> Repo.preload(:suppliers)
        |> Inventory.update_product(%{"suppliers" => [first.id]})

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/layout/products/#{product.id}/edit")

      assert options_count(view) == 3
      assert checked_ids(view) == [first.id]
    end
  end

  # These submit through the same `product[suppliers][]` key a `<select multiple>` used, and are
  # deliberately untouched by the switch to checkboxes: their survival is the proof that the wire
  # format did not change, and therefore that no host has to adapt.
  describe "writing membership through the parent form" do
    test "adds the selected suppliers as join rows", %{conn: conn} do
      delete_all_inventory_data()
      {_products, suppliers} = create_sample_products_with_suppliers(0, 3)
      chosen = suppliers |> Enum.take(2) |> Enum.map(& &1.id)

      {:ok, view, _html} = live(conn, "/association/many_to_many/layout/products/new")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "m2m_ref",
          "name" => "Many suppliers",
          "quantity_initial" => "5",
          "suppliers" => chosen
        }
      })
      |> render_submit()

      product =
        Product
        |> Repo.all()
        |> Enum.find(&(&1.name == "Many suppliers"))
        |> Repo.preload(:suppliers)

      assert Enum.count(product.suppliers) == 2
      assert join_row_count() == 2
    end

    test "removing a supplier deletes only the join row, never the supplier", %{conn: conn} do
      delete_all_inventory_data()
      {[product], suppliers} = create_sample_products_with_suppliers(1, 3)
      keep = suppliers |> Enum.take(1) |> Enum.map(& &1.id)

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/layout/products/#{product.id}/edit")

      view
      |> form("#auix-product-form", %{"product" => %{"suppliers" => keep}})
      |> render_submit()

      assert join_row_count() == 1
      # The de-selected suppliers must survive -- delete semantics invert for many_to_many.
      assert Repo.aggregate(Supplier, :count) == 3
    end

    test "de-selecting everything clears membership", %{conn: conn} do
      delete_all_inventory_data()
      {[product], _suppliers} = create_sample_products_with_suppliers(1, 3)

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/layout/products/#{product.id}/edit")

      # Only the hidden sentinel is submitted, which is what a fully de-selected list looks like.
      view
      |> form("#auix-product-form", %{"product" => %{"suppliers" => [""]}})
      |> render_submit()

      assert join_row_count() == 0
      assert Repo.aggregate(Supplier, :count) == 3
    end
  end

  describe "toggle all" do
    test "an unchecked toggle selects every candidate", %{conn: conn} do
      delete_all_inventory_data()
      {_products, suppliers} = create_sample_products_with_suppliers(0, 3)

      {:ok, view, _html} = live(conn, "/association/many_to_many/layout/products/new")

      assert toggle_state(view) == :none

      toggle_all(view, "true")

      assert view |> checked_ids() |> Enum.sort() ==
               suppliers |> Enum.map(& &1.id) |> Enum.sort()

      assert toggle_state(view) == :all
    end

    test "a checked toggle clears the membership", %{conn: conn} do
      delete_all_inventory_data()
      {[product], _suppliers} = create_sample_products_with_suppliers(1, 3)

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/layout/products/#{product.id}/edit")

      assert toggle_state(view) == :all

      toggle_all(view, "false")

      assert checked_ids(view) == []
      assert toggle_state(view) == :none
    end

    test "a partial membership renders the toggle mixed, and toggling it selects all", %{
      conn: conn
    } do
      delete_all_inventory_data()
      {[product], suppliers} = create_sample_products_with_suppliers(1, 3)
      [first | _rest] = suppliers

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/layout/products/#{product.id}/edit")

      view
      |> form("#auix-product-form", %{"product" => %{"suppliers" => [first.id]}})
      |> render_change(%{"_target" => ["product", "suppliers"]})

      assert toggle_state(view) == :mixed

      toggle_all(view, "true")

      assert view |> checked_ids() |> Enum.count() == 3
      assert toggle_state(view) == :all
    end

    # The toggle has to reach `auix.form.params`, not just the DOM -- otherwise the submit would
    # persist the pre-toggle membership.
    test "a toggled-all membership survives submit", %{conn: conn} do
      delete_all_inventory_data()
      create_sample_products_with_suppliers(0, 3)

      {:ok, view, _html} = live(conn, "/association/many_to_many/layout/products/new")

      toggle_all(view, "true")

      view
      |> form("#auix-product-form", %{
        "product" => %{
          "reference" => "m2m_all",
          "name" => "All suppliers",
          "quantity_initial" => "5"
        }
      })
      |> render_submit()

      assert join_row_count() == 3
    end
  end

  describe "show rendering" do
    test "renders only the current membership, as a plain read-only list", %{conn: conn} do
      delete_all_inventory_data()
      {[product], suppliers} = create_sample_products_with_suppliers(1, 2)

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/layout/products/#{product.id}/show")

      refute has_element?(view, "#auix-many-to-many-suppliers-show input[type='checkbox']")

      for supplier <- suppliers do
        assert has_element?(
                 view,
                 "#auix-many-to-many-suppliers-show-options .auix-selected-list-item",
                 supplier.name
               )
      end
    end

    test "shows the empty-state message when there is no membership", %{conn: conn} do
      delete_all_inventory_data()
      {[product], _suppliers} = create_sample_products_with_suppliers(1, 0)

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/layout/products/#{product.id}/show")

      assert has_element?(
               view,
               "#auix-many-to-many-suppliers-show-options .auix-selected-list-empty-msg",
               "No items to show"
             )
    end
  end

  describe "index" do
    test "never renders the association as a column", %{conn: conn} do
      delete_all_inventory_data()
      create_sample_products_with_suppliers(2, 2)

      {:ok, view, _html} = live(conn, "/association/many_to_many/layout/products")

      refute view
             |> element("table.auix-items-table thead")
             |> render() =~ "Supplier"
    end
  end

  @spec join_row_count() :: non_neg_integer()
  defp join_row_count do
    "SELECT count(*) FROM product_suppliers"
    |> then(&Repo.query!(&1))
    |> Map.get(:rows)
    |> hd()
    |> hd()
  end

  @spec options_count(Phoenix.LiveViewTest.View.t()) :: non_neg_integer()
  defp options_count(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(".auix-checkbox-group input[type='checkbox']")
    |> Enum.count()
  end

  # The toggle rides the form's own phx-change; `_target` is what tells the handler it was the one
  # that moved, and `render_change/2` does not infer it.
  @spec toggle_all(Phoenix.LiveViewTest.View.t(), binary()) :: binary()
  defp toggle_all(view, state) do
    view
    |> form("#auix-product-form", %{"auix_toggle_all__suppliers" => state})
    |> render_change(%{"_target" => ["auix_toggle_all__suppliers"]})
  end

  @spec toggle_state(Phoenix.LiveViewTest.View.t()) :: :all | :none | :mixed
  defp toggle_state(view) do
    toggle =
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("input#auix-many-to-many-toggle_all-suppliers")

    cond do
      LazyHTML.attribute(toggle, "checked") != [] -> :all
      toggle |> LazyHTML.attribute("class") |> to_string() =~ "auix-checkbox--mixed" -> :mixed
      true -> :none
    end
  end

  # Asserting on the submitted values rather than the labels: the value is what the round trip
  # actually preserves.
  @spec checked_ids(Phoenix.LiveViewTest.View.t()) :: list(binary())
  defp checked_ids(view) do
    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query(".auix-checkbox-group input[type='checkbox'][checked]")
    |> Enum.map(&(&1 |> LazyHTML.attribute("value") |> List.first()))
  end
end
