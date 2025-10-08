defmodule Aurora.UixWeb.Test.SeparatedSingleResourceUITest do
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Aurora.UixWeb.UICase, :phoenix_case

  defmodule TestResources do
    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product
    auix_resource_metadata(:product, context: Inventory, schema: Product)
  end

  @auix_resource_metadata TestResources.auix_resource(:product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "separated-single-resource-" do
    edit_layout :product, [] do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/separated-single-resource-products")
    assert html =~ "Listing Products"
    assert html =~ "New Product"

    assert view
           |> element("a[name='auix-new-product']")
           |> render_click() =~ "New Product"
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    delete_all_sample_data()
    {:ok, view, html} = live(conn, "/separated-single-resource-products/new")

    assert html =~ "New Product"

    assert view
           |> form("#auix-product-form",
             product: %{reference: "test-first", name: "This is the first test"}
           )
           |> render_change() =~ "can&#39;t be blank"

    view
    |> form("#auix-product-form",
      product: %{quantity_initial: 11}
    )
    |> render_submit()

    {:ok, _view, new_html} = live(conn, "/separated-single-resource-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end
end
