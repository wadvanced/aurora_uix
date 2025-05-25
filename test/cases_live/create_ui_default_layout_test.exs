defmodule AuroraUixTestWeb.CreateUIDefaultLayoutTest do
  use Aurora.Uix.Test.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product

    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(link_prefix: "create-ui-default-layout-")
  end

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, html} = live(conn, "/create-ui-default-layout-products")
    assert html =~ "Listing Products"
    assert html =~ "New Product"

    assert view
           |> element("#auix-new-product")
           |> render_click() =~ "New Product"
  end

  test "Test CREATE new, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/create-ui-default-layout-products/new")

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

    {:ok, _view, new_html} = live(conn, "/create-ui-default-layout-products")

    assert new_html =~ "Listing Products"
    assert new_html =~ "test-first"
  end

  test "Check field, stacked order", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/create-ui-default-layout-products/new")

    TestModule
    |> resource_configs()
    |> get_in([Access.key!(:product), Access.key!(:fields_order)])
    |> assert_stacked_order(html)
  end

  @spec assert_stacked_order(list, binary) :: :ok
  defp assert_stacked_order(fields, html) do
    inputs =
      html
      |> Floki.parse_document!()
      |> Floki.find(
        "form#auix-product-form div.auix-form-container>div:not(.sm\\:flex-row).flex-col input:not([type=='hidden'])"
      )
      |> Enum.map(fn input ->
        input
        |> Floki.attribute("name")
        |> List.first()
        |> String.replace("product[", "")
        |> String.replace("]", "")
      end)

    fields_as_string = Enum.map(fields, &to_string/1)
    assert_values_order(fields_as_string, inputs)
  end
end
