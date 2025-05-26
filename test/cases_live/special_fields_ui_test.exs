defmodule Aurora.Uix.Test.Web.SpecialFieldsUITest do
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product

    auix_resource_metadata :product, context: Inventory, schema: Product do
      field(:status,
        field_html_type: :select,
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

    # When you define a link in a test, add a line to test/support/app_web/router.exs
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

  @spec assert_option_exists(Phoenix.LiveViewTest.View.t(), atom, integer, binary) :: any
  defp assert_option_exists(view, field_name, index, value) do
    element =
      view
      |> element("#auix-field-#{field_name}-form option:nth-of-type(#{index})")
      |> render()

    assert element =~ value,
           "The field `#{field_name}` at option `#{index}` does not contain the value #{value}. #{element}"
  end
end
