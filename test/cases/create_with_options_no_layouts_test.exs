defmodule Aurora.Uix.Test.Web.CreateWithOptionsNoLayoutsTest do
  use Aurora.Uix.Test.Web.UICase

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product

    auix_resource_metadata(:product, context: Inventory, schema: Product)

    auix_create_ui()
  end

  test "Test UI default with schema, context, NO layouts details" do
    index_module = __MODULE__.TestModule.Product.Index
    assert true == Code.ensure_loaded?(index_module)

    index_functions = index_module.__info__(:functions)
    assert {:__live__, 0} in index_functions
    assert {:handle_params, 3} in index_functions
    assert {:handle_event, 3} in index_functions
    assert {:handle_info, 2} in index_functions

    form_module = __MODULE__.TestModule.Product.FormComponent
    form_functions = form_module.__info__(:functions)
    assert {:__live__, 0} in form_functions
    assert {:__components__, 0} in form_functions
    assert {:update, 2} in form_functions
    assert {:handle_event, 3} in form_functions
  end

  test "Test the `auix_resource` function with a single resource" do
    product = __MODULE__.TestModule.auix_resource(:product).product

    assert product.schema == Aurora.Uix.Test.Inventory.Product
    assert product.context == Aurora.Uix.Test.Inventory
    assert product.fields != nil
    assert product.fields != []
  end
end
