defmodule AuroraUixTest.MetadataAssociationTest do
  use AuroraUixTest.MetadataCase

  #  defmodule ParseAssociations do
  #    use AuroraUixTestWeb, :aurora_uix_for_test
  #
  #    alias AuroraUixTest.Inventory
  #    alias AuroraUixTest.Inventory.Product
  #
  #    auix_schema_metadata(:product,
  #      context: Inventory,
  #      schema: Product,
  #      include_associations: true
  #    )
  #  end
  #

  #  test "Parsing with associations" do
  #    schemas_metadata = schemas_metadata(ParseAssociations)
  #
  #    validate_schema(schemas_metadata, :product,
  #      cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
  #    )
  #
  #    validate_schema(schemas_metadata, :product_transaction,
  #      product_id: %{html_type: :text, name: "product_id", length: 255}
  #    )
  #  end
  #
end
