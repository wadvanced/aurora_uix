defmodule AuroraUixTestWeb.SpecialFieldsUITest do
  use AuroraUixTest.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_resource_config :product, context: Inventory, schema: Product do
      field(:status,
        html_type: :select,
        data: [
          opts: [
            "In stock": "in_stock",
            Discontinued: "discontinued",
            "Only available online": "online_only",
            "Only available in the store": "in_store_only"
          ],
          multiple: false
        ]
      )
    end

    # When you define a link in a test, you must add a line to router.exs
    # See section `Including cases_live tests in the test server` in the README.md file.
    auix_create_ui link_prefix: "special-fields-ui-" do
      edit_layout :product, [] do
        stacked([:reference, :name, :description, :status])
      end
    end
  end

  test "Test select field", %{conn: conn} do
    test_module = __MODULE__.TestModule
    index_module = Module.concat(test_module, Product.Index)
    assert true == Code.ensure_loaded?(index_module)

    {:ok, view, _html} = live(conn, "/special-fields-ui-products/new")

    assert view
           |> element("#auix-field-status-form")
           |> has_element?()

    assert_option_exists(view, :status, 1, "in_stock")
    assert_option_exists(view, :status, 2, "discontinued")
    assert_option_exists(view, :status, 3, "online_only")
    assert_option_exists(view, :status, 4, "in_store_only")
  end

  defp assert_option_exists(view, field_name, index, value) do
    element =
      view
      |> element("#auix-field-#{field_name}-form option:nth-of-type(#{index})")
      |> render()

    assert element =~ value,
           "The field `#{field_name}` at option `#{index}` does not contain the value #{value}. #{element}"
  end
end
