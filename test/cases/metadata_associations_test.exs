defmodule AuroraUixTest.MetadataAssociationTest do
  use AuroraUixTest.UICase

  #  defmodule ParseAssociations do
  #    use AuroraUixTestWeb, :aurora_uix_for_test
  #
  #    alias AuroraUixTest.Inventory
  #    alias AuroraUixTest.Inventory.Product
  #
  #    auix_resource_config(:product,
  #      context: Inventory,
  #      schema: Product,
  #      include_associations: true
  #    )
  #  end
  #

  #  test "Parsing with associations" do
  #    resource_configs = resource_configs(ParseAssociations)
  #
  #    validate_schema(resource_configs, :product,
  #      cost: %{html_type: :number, name: "cost", label: "Cost", precision: 10, scale: 2}
  #    )
  #
  #    validate_schema(resource_configs, :product_transaction,
  #      product_id: %{html_type: :text, name: "product_id", length: 255}
  #    )
  #  end
  #
end
