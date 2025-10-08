defmodule Aurora.Uix.Test.Cases.MetadataDefaultWithOptionsTest do
  use Aurora.UixWeb, :aurora_uix_for_test
  use Aurora.UixWeb.UICase
  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductTransaction

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

  test "Test default with options schema and context" do
    resource_configs =
      resource_configs(__MODULE__)

    validate_schema(resource_configs, :product,
      cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
    )

    validate_schema(resource_configs, :product_transaction,
      product_id: %{html_type: :select, name: "product_id", length: 255}
    )
  end

  test "Test the `auix_resource` function with multiple resources" do
    product = __MODULE__.auix_resource(:product).product

    assert product.schema == Aurora.Uix.Test.Inventory.Product
    assert product.context == Aurora.Uix.Test.Inventory
    assert product.fields != nil
    assert product.fields != []

    product_transaction =
      __MODULE__.auix_resource(:product_transaction).product_transaction

    assert product_transaction.schema == Aurora.Uix.Test.Inventory.ProductTransaction
    assert product_transaction.context == Aurora.Uix.Test.Inventory
    assert product_transaction.fields != nil
    assert product_transaction.fields != []
  end
end
