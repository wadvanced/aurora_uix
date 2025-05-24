defmodule AuroraUixTest.MetadataWithoutOptionsTest do
  use AuroraUixTest.UICase

  defmodule DefaultWithoutOptions do
    # Makes the modules attributes persistent.
    use AuroraUixTestWeb, :aurora_uix_for_test

    auix_resource_metadata(:product)
  end

  test "Test default without options - no schema, no context" do
    resource_configs = resource_configs(DefaultWithoutOptions)
    assert is_nil(Map.get(resource_configs, :product_transaction))
    product = Map.get(resource_configs, :product)

    assert is_nil(Map.get(product, :schema))
    assert is_nil(Map.get(product, :context))
    assert product |> Map.get(:fields, %{}) |> Enum.empty?()
  end
end
