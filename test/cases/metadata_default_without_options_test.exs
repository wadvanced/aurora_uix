defmodule AuroraUixTest.MetadataWithoutOptionsTest do
  use AuroraUixTest.MetadataCase

  defmodule DefaultWithoutOptions do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    auix_schema_metadata(:product)
  end

  test "Test default without options - no schema, no context" do
    schemas_metadata = schemas_metadata(DefaultWithoutOptions)

    assert is_nil(Map.get(schemas_metadata, :product_transaction))
    product = Map.get(schemas_metadata, :product)

    assert is_nil(Map.get(product, :schema))
    assert is_nil(Map.get(product, :context))
    assert product |> Map.get(:fields, %{}) |> Enum.empty?()
  end
end
