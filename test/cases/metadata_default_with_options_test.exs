defmodule AuroraUixTest.MetadataDefaultWithOptionsTest do
  use AuroraUixTest.MetadataCase

  defmodule DefaultWithOptions do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_schema_metadata(:product, context: Inventory, schema: Product)
  end

  test "Test default with options schema and context" do
    schemas_metadata =
      schemas_metadata(DefaultWithOptions)

    assert Map.get(schemas_metadata, :product_transaction) == nil

    validate_schema(schemas_metadata, :product,
      cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
    )
  end
end
