defmodule AuroraUixTest.MetadataDefaultWithOptionsTest do
  use AuroraUixTest.UICase

  defmodule DefaultWithOptions do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product
    alias AuroraUixTest.Inventory.ProductTransaction

    auix_resource_config(:product, context: Inventory, schema: Product)
    auix_resource_config(:product_transaction, context: Inventory, schema: ProductTransaction)
  end

  test "Test default with options schema and context" do
    resource_configs =
      resource_configs(DefaultWithOptions)

    validate_schema(resource_configs, :product,
      cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
    )

    validate_schema(resource_configs, :product_transaction,
      product_id: %{html_type: :text, name: "product_id", length: 255}
    )
  end
end
