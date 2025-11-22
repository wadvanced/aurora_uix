defmodule Aurora.UixWeb.CreateWithOptionsNoLayoutsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui()

  test "Test UI default with schema, context, NO layouts details" do
    index_module = __MODULE__.Product.Index
    assert true == Code.ensure_loaded?(index_module)

    index_functions = index_module.__info__(:functions)
    assert {:__live__, 0} in index_functions
    assert {:handle_params, 3} in index_functions
    assert {:handle_event, 3} in index_functions
    assert {:handle_info, 2} in index_functions

    form_module = __MODULE__.Product.FormComponent
    form_functions = form_module.__info__(:functions)
    assert {:__live__, 0} in form_functions
    assert {:__components__, 0} in form_functions
    assert {:update, 2} in form_functions
    assert {:handle_event, 3} in form_functions
  end

  test "Test the `auix_resource` function with a single resource" do
    product = __MODULE__.auix_resource(:product).product

    assert product.schema == Aurora.Uix.Guides.Inventory.Product
    assert product.context == Aurora.Uix.Guides.Inventory
    assert product.fields != nil
    assert product.fields != []
  end
end
