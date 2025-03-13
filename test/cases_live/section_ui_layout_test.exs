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

    assert view
           |> element("#auix-field-quantity_at_hand-form")
           |> has_element?()

    assert view
           |> element("#auix-field-quantity_initial-form")
           |> has_element?()

    refute view
           |> element("#auix-field-list_price-form")
           |> has_element?()

    refute view
           |> element("#auix-field-rrp-form")
           |> has_element?()

    assert view
           |> element(~s|button[class~="tab-button"]:nth-of-type(2)|)
           |> render_click() =~ "List price"

    assert_section_button(view, "quantities", 1)
    assert_section_button(view, "sale_prices", 2)

    refute view
           |> element("#auix-field-quantity_at_hand-form")
           |> has_element?()

    refute view
           |> element("#auix-field-quantity_initial-form")
           |> has_element?()

    assert view
           |> element("#auix-field-list_price-form")
           |> has_element?()

    assert view
           |> element("#auix-field-rrp-form")
           |> has_element?()
  end

  defp assert_section_button(view, section_id, position) do
    element_html =
      view
      |> element(~s|button[class~="tab-button"]:nth-of-type(#{position})|)
      |> render()

    assert(
      element_html =~ ~s|phx-value-tab-id="auix-section-#{section_id}|,
      "Tab button: `#{section_id}` not found at #{position}\n#{element_html}"
    )
  end
end
