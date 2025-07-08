defmodule Aurora.Uix.Test.Web.GroupUILayoutTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "group-ui-layout-" do
    edit_layout :product, [] do
      inline([:reference, :name, :description])

      group "Quantities" do
        inline([:quantity_at_hand, :quantity_initial])
      end

      group "Sale Prices" do
        stacked([:list_price, :rrp])
      end
    end
  end

  test "Test groups", %{conn: conn} do
    {:ok, view, html} = live(conn, "/group-ui-layout-products/new")
    assert html =~ "auix-group-quantities-"
    assert html =~ "auix-group-sale_prices-"

    # check order of groups
    assert view
           |> element(~s(div[id^="auix-group-quantities-"] + div[id^="auix-group-sale_prices-"]))
           |> has_element?()

    # assert fields within group
    assert_group_field(view, "group-quantities", 1, "quantity_at_hand")
    assert_group_field(view, "group-quantities", 2, "quantity_initial")

    assert_group_field(view, "group-sale_prices", 1, "list_price")
    assert_group_field(view, "group-sale_prices", 2, "rrp")
  end

  @spec assert_group_field(Phoenix.LiveViewTest.View.t(), binary, integer, binary) :: any
  defp assert_group_field(view, group_name, position, field_name) do
    element_html =
      view
      |> element(~s|div[id^='auix-#{group_name}-'] > div > div:nth-child(#{position}) input|)
      |> render()

    assert(
      element_html =~ "auix-field-product-#{field_name}-",
      "Field: `#{field_name}` not in group `#{group_name}` at #{position}\n#{element_html}"
    )
  end
end
