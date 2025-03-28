defmodule AuroraUixTestWeb.SeparatedSingleResourceUITest do
  use AuroraUixTest.UICase, :phoenix_case

  defmodule TestResources do
    use AuroraUixTestWeb, :aurora_uix_for_test
    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product
    auix_resource_config(:product, context: Inventory, schema: Product)
  end

  defmodule TestModule do
    use AuroraUixTestWeb, :aurora_uix_for_test

    @auix_resource_config TestResources.auix_resource(:product)

    # When you define a link in a test, you must add a line to router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link_prefix: "separated-single-resource-" do
      edit_layout :product, [] do
        inline([:reference, :name, :description])
        inline([:quantity_at_hand, :quantity_initial])
        inline([:list_price, :rrp])
      end
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, html} = live(conn, "/separated-single-resource-products")
    assert html =~ "Listing Products"
    assert html =~ "New Products"

    assert view
           |> element("#auix-new-products")
           |> render_click() =~ "New Product"
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/separated-single-resource-products/new")

    assert html =~ "New Product"

    assert view
           |> form("#auix-product-form",
             product: %{reference: "test-first", name: "This is the first test"}
           )
           |> render_change() =~ "can&#39;t be blank"

    assert view
           |> form("#auix-product-form",
             product: %{quantity_initial: 11}
           )
           |> render_submit() =~ "Listing Products"

    {:ok, _view, new_html} = live(conn, "/separated-single-resource-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end
end
