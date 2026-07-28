defmodule Aurora.UixWeb.Test.AssociationMany2ManyUIActionsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  use Aurora.Uix.CoreComponentsImporter

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.Supplier

  @spec custom_header_action(map()) :: Rendered.t()
  def custom_header_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-header-#{@field.key}"}>Custom header</.button>
    """
  end

  @spec custom_footer_action(map()) :: Rendered.t()
  def custom_footer_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-footer-#{@field.key}"}>Custom footer</.button>
    """
  end

  # Routes for both resources are registered in test/support/app_web/routes.ex as
  # "association/many_to_many/actions/products" and ".../suppliers".
  auix_resource_metadata :product, context: Inventory, schema: Product do
    field(:suppliers, option_label: :name)
  end

  auix_resource_metadata(:supplier, context: Inventory, schema: Supplier)

  auix_create_ui do
    edit_layout :product do
      stacked([
        :reference,
        :name,
        suppliers: [
          remove_header_action: :default_uncheck_all,
          add_header_action: {:custom_header, &__MODULE__.custom_header_action/1},
          add_footer_action: {:custom_footer, &__MODULE__.custom_footer_action/1}
        ]
      ])
    end
  end

  describe "header actions" do
    test "removes a default action and appends a custom one", %{conn: conn} do
      delete_all_inventory_data()
      {[product], _suppliers} = create_sample_products_with_suppliers(1, 2)

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/actions/products/#{product.id}/edit")

      refute has_element?(view, "button[name='auix-many-to-many-uncheck_all-suppliers']")
      assert has_element?(view, "button[name='auix-many-to-many-check_all-suppliers']")
      assert has_element?(view, "button[name='auix-custom-header-suppliers']")
    end
  end

  describe "footer actions" do
    # The library ships no default footer action; the group exists purely so a host can add one.
    test "renders a host action in the otherwise empty footer group", %{conn: conn} do
      delete_all_inventory_data()
      {[product], _suppliers} = create_sample_products_with_suppliers(1, 2)

      {:ok, view, _html} =
        live(conn, "/association/many_to_many/actions/products/#{product.id}/edit")

      assert has_element?(
               view,
               "[name='auix-many-to-many-footer-actions-suppliers'] button[name='auix-custom-footer-suppliers']"
             )
    end
  end
end
