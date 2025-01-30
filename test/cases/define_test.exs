defmodule AuroraUixTest.DefineTest do
  use AuroraUixTest.DefineCase

  defmodule DefaultGeneration do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_schema_metadata(:product, context: Inventory, schema: Product)

    auix_define do
      layout(:form, :component)
    end
  end

  test "Component layout" do
  end
end
