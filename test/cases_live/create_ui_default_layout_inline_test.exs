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

  # A single-value select renders as `<select>` and a multi-value one as a group of checkboxes;
  # neither contributes exactly one positional `<input>`, so both would shift the comparison.
  # `scalar_field_name/1` drops them from the other side.
  @spec reject_select_fields(list, map) :: list
  defp reject_select_fields(fields_order, fields),
    do: Enum.reject(fields_order, &(get_in(fields, [&1, Access.key!(:html_type)]) == :select))

  # Keeps only the `product[key]` inputs: a multi-value select renders `product[key][]` boxes plus a
  # toggle named outside the resource scope, and neither has a place in a positional comparison.
  @spec scalar_field_name(LazyHTML.t()) :: list(binary())
  defp scalar_field_name(input) do
    with "product[" <> rest <- input |> LazyHTML.attribute("name") |> List.first(),
         [key, ""] <- String.split(rest, "]") do
      [key]
    else
      _other -> []
    end
  end

  @spec assert_inline_order(list, binary) :: :ok
  defp assert_inline_order(fields, html) do
    inputs =
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query(
        "form#auix-product-form div.auix-form-container>div.auix-inline-container input:not([type='hidden'])"
      )
      |> Enum.flat_map(&scalar_field_name/1)

    fields_as_string = Enum.map(fields, &to_string/1)
    assert_values_order(fields_as_string, inputs)
  end
end
