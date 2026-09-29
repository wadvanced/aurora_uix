defmodule Aurora.UixWeb.Test.CheckboxCheckedTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:deleted, disabled: true)
  end

  auix_create_ui do
    edit_layout :product do
      stacked([:reference, :name, :inactive, :deleted])
    end
  end

  @inactive "#auix-product-form input[type=checkbox][name='product[inactive]']"
  @deleted "#auix-product-form input[type=checkbox][name='product[deleted]']"

  @spec seed(map()) :: binary()
  defp seed(attrs) do
    delete_all_inventory_data()

    1
    |> create_sample_products(:test, attrs)
    |> get_in([Access.key!("id_test-1"), Access.key!(:id)])
  end

  @spec assert_checked(Phoenix.LiveViewTest.View.t()) :: true
  defp assert_checked(view) do
    assert has_element?(view, "#{@inactive}[checked]")
    assert has_element?(view, "#{@deleted}[disabled][checked]")
  end

  describe "edit route" do
    test "a true boolean renders checked", %{conn: conn} do
      id = seed(%{inactive: true})
      {:ok, view, _html} = live(conn, "/checkbox-checked-products/#{id}/edit")

      assert has_element?(view, "#{@inactive}[checked]")
    end

    test "a true disabled boolean renders disabled and checked", %{conn: conn} do
      id = seed(%{deleted: true})
      {:ok, view, _html} = live(conn, "/checkbox-checked-products/#{id}/edit")

      assert has_element?(view, "#{@deleted}[disabled][checked]")
    end

    test "a false boolean renders unchecked", %{conn: conn} do
      id = seed(%{inactive: false, deleted: false})
      {:ok, view, _html} = live(conn, "/checkbox-checked-products/#{id}/edit")

      assert has_element?(view, @inactive)
      assert has_element?(view, @deleted)
      refute has_element?(view, "#{@inactive}[checked]")
      refute has_element?(view, "#{@deleted}[checked]")
    end
  end

  describe "navigation" do
    test "index to edit keeps both booleans checked", %{conn: conn} do
      id = seed(%{inactive: true, deleted: true})
      {:ok, view, _html} = live(conn, "/checkbox-checked-products")

      view
      |> element(
        ".auix-items-table-action-cell a[name='auix-edit-product'][phx-value-route_path$='#{id}/edit']"
      )
      |> render_click()

      assert_checked(view)
    end

    test "show to edit keeps both booleans checked", %{conn: conn} do
      id = seed(%{inactive: true, deleted: true})
      {:ok, view, _html} = live(conn, "/checkbox-checked-products/#{id}/show")

      view
      |> element("a[name='auix-edit-product'][phx-value-route_path$='#{id}/show-edit']")
      |> render_click()

      assert_checked(view)
    end
  end
end
