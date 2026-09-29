defmodule Aurora.UixWeb.Test.AshCheckboxCheckedTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.UixWeb.Test.AshCheckbox.Item

  auix_resource_metadata :checkbox_item, ash_resource: Item do
    field(:is_deleted, disabled: true)
  end

  auix_create_ui do
    edit_layout :checkbox_item do
      stacked([:name, :active?, :is_deleted])
    end
  end

  @active "#auix-item-form input[type=checkbox][name='item[active?]']"
  @deleted "#auix-item-form input[type=checkbox][name='item[is_deleted]']"

  @spec seed(map()) :: Item.t()
  defp seed(attrs) do
    Item
    |> Ash.Changeset.for_create(:create, Map.merge(%{name: "checkbox-item"}, attrs))
    |> Ash.create!()
  end

  @spec assert_checked(Phoenix.LiveViewTest.View.t()) :: true
  defp assert_checked(view) do
    assert has_element?(view, "#{@active}[checked]")
    assert has_element?(view, "#{@deleted}[disabled][checked]")
  end

  describe "edit route" do
    test "a true boolean renders checked", %{conn: conn} do
      item = seed(%{active?: true})
      {:ok, view, _html} = live(conn, "/ash-checkbox-checked-items/#{item.id}/edit")

      assert has_element?(view, "#{@active}[checked]")
    end

    test "a true disabled boolean renders disabled and checked", %{conn: conn} do
      item = seed(%{is_deleted: true})
      {:ok, view, _html} = live(conn, "/ash-checkbox-checked-items/#{item.id}/edit")

      assert has_element?(view, "#{@deleted}[disabled][checked]")
    end

    test "a false boolean renders unchecked", %{conn: conn} do
      item = seed(%{active?: false, is_deleted: false})
      {:ok, view, _html} = live(conn, "/ash-checkbox-checked-items/#{item.id}/edit")

      assert has_element?(view, @active)
      assert has_element?(view, @deleted)
      refute has_element?(view, "#{@active}[checked]")
      refute has_element?(view, "#{@deleted}[checked]")
    end
  end

  describe "navigation" do
    test "index to edit keeps both booleans checked", %{conn: conn} do
      item = seed(%{active?: true, is_deleted: true})
      {:ok, view, _html} = live(conn, "/ash-checkbox-checked-items")

      view
      |> element(
        ".auix-items-table-action-cell a[name='auix-edit-item'][phx-value-route_path$='#{item.id}/edit']"
      )
      |> render_click()

      assert_checked(view)
    end

    test "show to edit keeps both booleans checked", %{conn: conn} do
      item = seed(%{active?: true, is_deleted: true})
      {:ok, view, _html} = live(conn, "/ash-checkbox-checked-items/#{item.id}/show")

      view
      |> element("a[name='auix-edit-item'][phx-value-route_path$='#{item.id}/show-edit']")
      |> render_click()

      assert_checked(view)
    end
  end
end
