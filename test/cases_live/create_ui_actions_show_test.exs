defmodule Aurora.UixWeb.Test.CreateUIActionsShowTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Inventory
  alias Aurora.Uix.Inventory.Product

  @spec custom_header_action(map()) :: Rendered.t()
  def custom_header_action(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{@auix.entity.id}/show/edit"} name={"auix-edit-#{@auix.module}"}>
        <.button>Edit Custom {@auix.name}</.button>
      </.auix_link>
    """
  end

  @spec custom_back_footer_action(map()) :: Rendered.t()
  def custom_back_footer_action(assigns) do
    ~H"""
      <div name="auix-show-navigate-back">
        <.auix_back>Back Custom to {@auix.title}</.auix_back>
      </div>
    """
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "create-ui-actions-show-" do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])

    edit_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end

    show_layout :product,
      replace_header_action: {:default_edit, &__MODULE__.custom_header_action/1},
      add_footer_action: {:custom_back_action, &__MODULE__.custom_back_footer_action/1} do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test show custom actions", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      5
      |> create_sample_products(:test)
      |> get_in(["id_test-1", Access.key!(:id)])

    {:ok, view, html} = live(conn, "/create-ui-actions-show-products/#{product_id}")

    assert view
           |> element("div[name='auix-show-header-actions'] a[name='auix-edit-product']")
           |> render() =~ "Edit Custom Product"

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-show-footer-actions'] [name='auix-show-navigate-back']"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "Back to Products",
             "Back Custom to Products"
           ]
  end
end
