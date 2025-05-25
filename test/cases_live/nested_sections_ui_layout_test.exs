defmodule AuroraUixTestWeb.NestedSectionsUILayoutTest do
  use Aurora.Uix.Test.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product

    auix_resource_metadata(:product, context: Inventory, schema: Product)

    # When you define a link in a test, add a line to test/support/app_web/router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link_prefix: "nested-sections-ui-layout-" do
      edit_layout :product, [] do
        # sections_index_1
        sections do
          # sections_index_1 tab_index_1
          section "References" do
            inline([:reference, :name])

            # sections_index_2
            sections do
              # sections_index_2 tab_index_1
              section "Descriptions" do
                inline([:description, :status])
              end

              # sections_index_2 tab_index_2
              section "Specifications" do
                stacked do
                  inline([:width, :height, :length])
                  inline([:weight])
                end
              end
            end
          end

          # sections_index_1 tab_index_2
          section "Information" do
            # sections_index_3
            sections do
              # sections_index_3 tab_index_1
              section "Quantities" do
                inline([:quantity_at_hand, :quantity_initial])
              end

              # sections_index_3 tab_index_2
              section "Sale Prices", default: true do
                stacked([:list_price, :rrp])
              end
            end
          end
        end
      end
    end
  end

  test "Test groups", %{conn: conn} do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)

    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, _html} = live(conn, "/nested-sections-ui-layout-products/new")

    assert_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    refute_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    assert_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    assert_field_is_visible_in_section(view, [:reference, :name], :sections_index_1, :tab_index_1)

    assert_field_is_visible_in_section(
      view,
      [:description, :status],
      :sections_index_2,
      :tab_index_1
    )

    refute_field_is_visible_in_section(
      view,
      [:width, :height, :length],
      :sections_index_2,
      :tab_index_2
    )

    refute_field_is_visible_in_section(
      view,
      [:quantity_at_hand, :quantity_initial],
      :sections_index_3,
      :tab_index_1
    )

    refute_field_is_visible_in_section(view, [:list_price, :rrp], :sections_index_3, :tab_index_2)

    click_section_button(view, "information", 2)
    refute_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    assert_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    refute_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    assert_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    refute_field_is_visible_in_section(view, [:reference, :name], :sections_index_1, :tab_index_1)

    refute_field_is_visible_in_section(
      view,
      [:description, :status],
      :sections_index_2,
      :tab_index_1
    )

    refute_field_is_visible_in_section(
      view,
      [:width, :height, :length],
      :sections_index_2,
      :tab_index_2
    )

    refute_field_is_visible_in_section(
      view,
      [:quantity_at_hand, :quantity_initial],
      :sections_index_3,
      :tab_index_1
    )

    assert_field_is_visible_in_section(view, [:list_price, :rrp], :sections_index_3, :tab_index_2)

    click_section_button(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    assert_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    refute_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    assert_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    refute_field_is_visible_in_section(view, [:reference, :name], :sections_index_1, :tab_index_1)

    refute_field_is_visible_in_section(
      view,
      [:description, :status],
      :sections_index_2,
      :tab_index_1
    )

    refute_field_is_visible_in_section(
      view,
      [:width, :height, :length],
      :sections_index_2,
      :tab_index_2
    )

    assert_field_is_visible_in_section(
      view,
      [:quantity_at_hand, :quantity_initial],
      :sections_index_3,
      :tab_index_1
    )

    refute_field_is_visible_in_section(view, [:list_price, :rrp], :sections_index_3, :tab_index_2)

    click_section_button(view, "references", :sections_index_1, :tab_index_1)
    assert_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    refute_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    assert_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    refute_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    click_section_button(view, "specifications", :sections_index_2, :tab_index_2)
    assert_section_button_is_active(view, "references", :sections_index_1, :tab_index_1)
    refute_section_button_is_active(view, "information", :sections_index_1, :tab_index_2)
    refute_section_button_is_active(view, "descriptions", :sections_index_2, :tab_index_1)
    assert_section_button_is_active(view, "specifications", :sections_index_2, :tab_index_2)
    refute_section_button_is_active(view, "quantities", :sections_index_3, :tab_index_1)
    refute_section_button_is_active(view, "sale_prices", :sections_index_3, :tab_index_2)

    assert_field_is_visible_in_section(view, [:reference, :name], :sections_index_1, :tab_index_1)

    refute_field_is_visible_in_section(
      view,
      [:description, :status],
      :sections_index_2,
      :tab_index_1
    )

    assert_field_is_visible_in_section(
      view,
      [:width, :height, :length],
      :sections_index_2,
      :tab_index_2
    )

    refute_field_is_visible_in_section(
      view,
      [:quantity_at_hand, :quantity_initial],
      :sections_index_3,
      :tab_index_1
    )

    refute_field_is_visible_in_section(view, [:list_price, :rrp], :sections_index_3, :tab_index_2)
  end
end
