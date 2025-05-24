defmodule AuroraUixTestWeb.CreateUIDefaultLayoutInlineTest do
  use AuroraUixTest.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui(
      link_prefix: "create-ui-default-layout-inline-",
      default_fields_layout: :inline
    )
  end

  test "Check field, inline order", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/create-ui-default-layout-inline-products/new")

    TestModule
    |> resource_configs()
    |> get_in([Access.key!(:product), Access.key!(:fields_order)])
    |> assert_inline_order(html)
  end

  @spec assert_inline_order(list, binary) :: :ok
  defp assert_inline_order(fields, html) do
    inputs =
      html
      |> Floki.parse_document!()
      |> Floki.find(
        "form#auix-product-form div.auix-form-container>div.sm\\:flex-row.flex-col input:not([type=='hidden'])"
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
