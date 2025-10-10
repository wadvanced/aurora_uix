defmodule Aurora.UixWeb.Test.CreateUIActionsFormTest do
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Aurora.UixWeb.UICase, :phoenix_case
  use Aurora.Uix.CoreComponentsImporter
  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  @spec custom_form_header_action(map()) :: Rendered.t()
  def custom_form_header_action(assigns) do
    ~H"""
      <.button phx-disable-with="Saving..." name={"auix-save-#{@auix.module}"}>Custom Save {@auix.name}</.button>
    """
  end

  @spec custom_form_footer_action(map()) :: Rendered.t()
  def custom_form_footer_action(assigns) do
    ~H"""
      <.button phx-disable-with="Saving..." name={"auix-save-#{@auix.module}"}>Custom Footer Save {@auix.name}</.button>
    """
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "create-ui-actions-form-" do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])

    edit_layout :product,
      add_header_action: {:custom_header, &__MODULE__.custom_form_header_action/1},
      insert_footer_action: {:custom_footer, &__MODULE__.custom_form_footer_action/1} do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end

    show_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test form header custom actions", %{conn: conn} do
    delete_all_sample_data()

    product_id =
      5
      |> create_sample_products(:test)
      |> get_in(["id_test-1", Access.key!(:id)])

    {:ok, _view, html} = live(conn, "/create-ui-actions-form-products/#{product_id}/edit")

    # Validate row actions order of elements
    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("div[name='auix-form-header-actions'] [name='auix-save-product']")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "Custom Save Product"
           ]
  end

  test "Test form footer custom actions", %{conn: conn} do
    delete_all_sample_data()

    product_id =
      5
      |> create_sample_products(:test)
      |> get_in(["id_test-1", Access.key!(:id)])

    {:ok, _view, html} = live(conn, "/create-ui-actions-form-products/#{product_id}/edit")

    # Validate row actions order of elements
    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("div[name='auix-form-footer-actions'] [name='auix-save-product']")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "Custom Footer Save Product",
             "Save Product"
           ]
  end
end
