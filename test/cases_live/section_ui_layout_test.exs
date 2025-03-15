defmodule AuroraUixTestWeb.SectionUILayoutTest do
  use AuroraUixTest.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_resource_config(:product, context: Inventory, schema: Product)

    # When you define a link in a test, you must add a line to router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link: "section-ui-layout-products" do
      edit_layout :product, [] do
        inline([:reference, :name, :description])

        sections do
          section "Quantities" do
            inline([:quantity_at_hand, :quantity_initial])
          end

          section "Sale Prices" do
            stacked([:list_price, :rrp])
          end
        end
      end
    end
  end

  test "Test groups", %{conn: conn} do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, _html} = live(conn, "/section-ui-layout-products/new")

    assert_section_button(view, "quantities", 1)
    assert_section_button(view, "sale_prices", 2)

    assert_field(view, :quantity_at_hand)
    assert_field(view, :quantity_initial)

    refute_field(view, :list_price)
    refute_field(view, :rrp)

    click_section_button(view, "sale_prices", 2)

    assert_section_button(view, "quantities", 1)
    assert_section_button(view, "sale_prices", 2)

    refute_field(view, :quantity_at_hand)
    refute_field(view, :quantity_initial)

    assert_field(view, :list_price)
    assert_field(view, :rrp)
  end
end
