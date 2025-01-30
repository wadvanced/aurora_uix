defmodule AuroraUixTest.SchemaMetaDataTest do
  use AuroraUixTest.MetadataCase

  defmodule DefaultGeneration do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_schema_metadata(:product, context: Inventory, schema: Product)
  end

  defmodule ParseAssociations do
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_schema_metadata(:product,
      context: Inventory,
      schema: Product,
      include_associations: true
    )
  end

  defmodule ModifyFieldValues do
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_schema_metadata(:product, context: Inventory, schema: Product) do
      field(:inactive, length: 10)
      field(:inserted_at, hidden: true)
    end
  end

  test "Default parsing with association" do
    schemas_metadata = schemas_metadata(DefaultGeneration)

    assert Map.get(schemas_metadata, :product_transaction) == nil

    validate_schema(schemas_metadata, :product,
      cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
    )
  end

  test "Parsing with associations" do
    schemas_metadata = schemas_metadata(ParseAssociations)

    validate_schema(schemas_metadata, :product,
      cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
    )

    validate_schema(schemas_metadata, :product_transaction,
      product_id: %{html_type: :text, name: "product_id", length: 255}
    )
  end

  test "Parsing with field modifications" do
    schemas_metadata = schemas_metadata(ModifyFieldValues)

    validate_schema(schemas_metadata, :product,
      inactive: %{html_type: :boolean, name: "inactive", label: "Inactive", length: 10},
      inserted_at: %{hidden: true}
    )
  end
end
