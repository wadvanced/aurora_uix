defmodule AuroraUixTestWeb.CreateWithOptionsNoLayoutsTest do
  use AuroraUixTest.UICase

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_resource_config(:product, context: Inventory, schema: Product)

    auix_create_ui()
  end

  test "Test UI default with schema, context, NO layouts details" do
    index_module = AuroraUixTestWeb.CreateWithOptionsNoLayoutsTest.TestModule.Product.Index
    assert true == Code.ensure_loaded?(index_module)

    index_functions = index_module.__info__(:functions)
    assert {:__live__, 0} in index_functions
    assert {:render, 1} in index_functions
    assert {:handle_params, 3} in index_functions
    assert {:handle_event, 3} in index_functions
    assert {:handle_info, 2} in index_functions

    form_module = AuroraUixTestWeb.CreateWithOptionsNoLayoutsTest.TestModule.Product.FormComponent
    form_functions = form_module.__info__(:functions)
    assert {:__live__, 0} in form_functions
    assert {:__components__, 0} in form_functions
    assert {:render, 1} in form_functions
    assert {:update, 2} in form_functions
    assert {:handle_event, 3} in form_functions
  end
end
