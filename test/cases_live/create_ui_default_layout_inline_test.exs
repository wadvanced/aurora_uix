defmodule Aurora.UixWeb.Test.CreateUIDefaultLayoutInlineTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(default_fields_layout: :inline)

  test "Check field, inline order", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/create-ui-default-layout-inline-products/new")

    config = __MODULE__ |> resource_configs() |> get_in([Access.key!(:product)])

    config.fields_order
    |> reject_select_fields(config.fields)
    |> assert_inline_order(html)
  end

  # A select renders as `<select>`, so it never appears among the queried inputs and would shift the
  # whole comparison by one.
  @spec reject_select_fields(list, map) :: list
  defp reject_select_fields(fields_order, fields),
    do: Enum.reject(fields_order, &(get_in(fields, [&1, Access.key!(:html_type)]) == :select))

  @spec assert_inline_order(list, binary) :: :ok
  defp assert_inline_order(fields, html) do
    inputs =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query(
        "form#auix-product-form div.auix-form-container>div.auix-inline-container input:not([type='hidden'])"
      )
      |> Enum.map(fn input ->
        input
        |> LazyHTML.attribute("name")
        |> List.first()
        |> String.replace("product[", "")
        |> String.replace("]", "")
      end)

    fields_as_string = Enum.map(fields, &to_string/1)
    assert_values_order(fields_as_string, inputs)
  end
end
