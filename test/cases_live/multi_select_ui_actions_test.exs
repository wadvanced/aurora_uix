defmodule Aurora.UixWeb.Test.MultiSelectUIActionsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  use Aurora.Uix.CoreComponentsImporter

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  @spec custom_label_action(map()) :: Rendered.t()
  def custom_label_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-label-#{@field.key}"}>Custom label</.button>
    """
  end

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

  # Route registered in test/support/app_web/routes.ex as "multi-select-actions-products".
  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product do
      stacked([
        :reference,
        :name,
        labels: [
          remove_label_action: :default_toggle_all,
          add_label_action: {:custom_label, &__MODULE__.custom_label_action/1},
          add_header_action: {:custom_header, &__MODULE__.custom_header_action/1},
          add_footer_action: {:custom_footer, &__MODULE__.custom_footer_action/1}
        ]
      ])
    end
  end

  setup do
    delete_all_inventory_data()

    [product] =
      1
      |> create_sample_products(:multi_select_actions, %{labels: [:fragile]})
      |> Map.values()

    %{product: product}
  end

  describe "label actions" do
    test "removes the default toggle and appends a custom control beside the label", %{
      conn: conn,
      product: product
    } do
      {:ok, view, _html} = live(conn, "/multi-select-actions-products/#{product.id}/edit")

      refute has_element?(view, "input#auix-multi-select-toggle_all-labels")

      assert has_element?(
               view,
               ".auix-checkbox-group-label-actions button[name='auix-custom-label-labels']"
             )
    end
  end

  describe "header actions" do
    # The library ships no default header action; the group exists purely so a host can add one.
    test "renders a host action in the otherwise empty header group", %{
      conn: conn,
      product: product
    } do
      {:ok, view, _html} = live(conn, "/multi-select-actions-products/#{product.id}/edit")

      assert has_element?(
               view,
               ".auix-checkbox-group-actions button[name='auix-custom-header-labels']"
             )
    end
  end

  describe "footer actions" do
    # The library ships no default footer action; the group exists purely so a host can add one.
    test "renders a host action in the otherwise empty footer group", %{
      conn: conn,
      product: product
    } do
      {:ok, view, _html} = live(conn, "/multi-select-actions-products/#{product.id}/edit")

      assert has_element?(
               view,
               "[name='auix-multi-select-footer-actions-labels'] button[name='auix-custom-footer-labels']"
             )
    end
  end
end
