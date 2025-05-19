defmodule AuroraUixTestWeb.SectionUILayoutTest do
  use AuroraUixTest.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link_prefix: "section-ui-layout-" do
      edit_layout :product, [] do
        inline([:reference, :name, :description])

        # section_index_1
        sections do
          # section_index_1, tab_index_1
          section "Quantities" do
            inline([:quantity_at_hand, :quantity_initial])
          end

          # section_index_1, tab_index_2
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

    assert_section_button_is_active(view, "quantities", :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :tab_index_2)

    assert_field_is_visible_in_section(view, [:quantity_at_hand, :quantity_initial], :tab_index_1)

    refute_field_is_visible_in_section(view, [:list_price, :rrp], :tab_index_2)

    click_section_button(view, "sale_prices", :tab_index_2)

    assert_section_button_is_active(view, "quantities", :tab_index_1)
    assert_section_button_is_active(view, "sale_prices", :tab_index_2)

    refute_field_is_visible_in_section(view, [:quantity_at_hand, :quantity_initial], :tab_index_1)

    assert_field_is_visible_in_section(view, [:list_price, :rrp], :tab_index_2)
  end
end
