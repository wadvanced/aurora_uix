defmodule AuroraUixTestWeb.CrudTest do
  use AuroraUixTest.UICase
  import Phoenix.LiveViewTest

  defmodule TestModule do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_schema_config(:product, context: Inventory, schema: Product)

    auix_create_ui()
  end

  test "Test CRUD List", %{conn: conn} do
    index_module = AuroraUixTestWeb.CrudTest.TestModule.Product.Index

    index_functions = index_module.__info__(:functions)
    assert {:__live__, 0} in index_functions
  end
end
