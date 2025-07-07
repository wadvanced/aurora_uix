defmodule Aurora.Uix.Test.Web.CreateUIActionsShowTest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test
    use Aurora.Uix.Web.CoreComponentsImporter

    import Phoenix.Component, only: [sigil_H: 2]
    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product

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

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link_prefix: "create-ui-actions-show-" do
      index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])

      edit_layout :product do
        inline([:reference, :name, :description])
        inline([:quantity_at_hand, :quantity_initial])
        inline([:list_price, :rrp])
      end

      show_layout :product,
        replace_header_action: {:default_edit, &TestModule.custom_header_action/1},
        add_footer_action: {:custom_back_action, &TestModule.custom_back_footer_action/1} do
        inline([:reference, :name, :description])
        inline([:quantity_at_hand, :quantity_initial])
        inline([:list_price, :rrp])
      end
    end
  end

  test "Test show custom actions", %{conn: conn} do
    product_id =
      5
      |> create_sample_products(:test)
      |> get_in(["id_test-1", Access.key!(:id)])

    {:ok, view, html} = live(conn, "/create-ui-actions-show-products/#{product_id}")

    assert view
           |> element("div[name='auix-show-header-actions'] a[name='auix-edit-product']")
           |> render() =~ "Edit Custom Product"

    assert html
           |> Floki.find("div[name='auix-show-footer-actions'] [name='auix-show-navigate-back']")
           |> Enum.map(&(&1 |> Floki.text() |> String.trim())) == [
             "Back to Products",
             "Back Custom to Products"
           ]
  end
end
