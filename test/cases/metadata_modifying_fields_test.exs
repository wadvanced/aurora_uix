defmodule AuroraUixTest.MetadataModifyingFieldsTest do
  use AuroraUixTest.MetadataCase

  defmodule FieldValuesModified do
    use AuroraUixTestWeb, :aurora_uix_for_test

    alias AuroraUixTest.Inventory
    alias AuroraUixTest.Inventory.Product

    auix_schema_metadata(:product, context: Inventory, schema: Product) do
      field(:inactive, length: 10)
      field(:inserted_at, hidden: true)
      fields([:weight, :length, :width, :height], precision: 16, scale: 3)
      # :height field properties are changed again, the last one should be the one prevailing
      field(:height, scale: 1)
      field(:data_virtual, html_type: :boolean)
    end
  end

  test "Test field modifications" do
    schemas_metadata = schemas_metadata(FieldValuesModified)

    validate_schema(schemas_metadata, :product,
      inactive: %{html_type: :boolean, name: "inactive", label: "Inactive", length: 10},
      inserted_at: %{hidden: true},
      weight: %{precision: 16, scale: 3},
      length: %{precision: 16, scale: 3},
      width: %{precision: 16, scale: 3},
      # Order is important, scale is changed, once again on the :height field
      height: %{precision: 16, scale: 1},
      data_virtual: %{html_type: :boolean}
    )
  end
end
