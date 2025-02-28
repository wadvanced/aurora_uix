defmodule AuroraUixTestWeb.CreateUILayoutTest do
  use AuroraUixTest.UICase, :phoenix_case

  # @endpoint AuroraUixTestWeb.Endpoint

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_resource_config(:product, context: Inventory, schema: Product)

    auix_create_ui link: "ui-layout-products" do
      layout :product, [] do
        inline([:name, :description])
        inline([:list_price, :rrp])
      end
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    test_module = AuroraUixTestWeb.CreateUILayoutTest.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, html} = live(conn, "/ui-layout-products")
    assert html =~ "Listing Products"
    assert html =~ "New Products"

    assert view
           |> element("#auix-new-products")
           |> render_click() =~ "New Product"
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/ui-layout-products/new")

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

    {:ok, _view, new_html} = live(conn, "/ui-layout-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end
end
