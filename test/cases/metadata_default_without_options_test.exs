defmodule Aurora.Uix.Test.MetadataWithoutOptionsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  auix_resource_metadata(:product)

  test "Test default without options - no schema, no context" do
    resource_configs = resource_configs(__MODULE__)
    assert is_nil(Map.get(resource_configs, :product_transaction))
    product = Map.get(resource_configs, :product)

    assert is_nil(Map.get(product, :schema))
    assert is_nil(Map.get(product, :context))
    assert product |> Map.get(:fields, %{}) |> Enum.empty?()
  end
end
