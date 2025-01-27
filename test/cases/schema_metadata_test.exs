defmodule AuroraUixTest.SchemaMetaDataTest do
  use AuroraUixTestWeb.ConnCase

  alias AuroraUixTestWeb.ProductLive.Index

  test "Module attributes" do
    auix_schemas =
      :attributes
      |> Index.__info__()
      |> Keyword.get(:auix_schemas)
      |> List.first()

    assert is_map(auix_schemas)
    assert valid_product?(auix_schemas)
    assert valid_product_transaction?(auix_schemas)
  end

  defp valid_product?(%{product: schema}) do
    assert schema.context == AuroraUixTest.Inventory
    assert schema.schema == AuroraUixTest.Inventory.Product


    validate_field(schema.fields.cost, %{
      field: :cost,
      html_type: :number,
      renderer: nil,
      name: "cost",
      label: "Cost",
      placeholder: "0",
      length: 12,
      precision: 10,
      scale: 2,
      hidden: false,
      readonly: false,
      required: false
    })
  end

  defp valid_product_transaction?(%{product_transaction: schema}) do
    assert schema.context == AuroraUixTest.Inventory
    assert schema.schema == AuroraUixTest.Inventory.ProductTransaction
  end

  defp validate_field(field, checks) do
    Enum.each(checks, fn {key, value} ->
      assert(Map.get(field, key) == value, "Field `#{field.field}`")
    end)
  end
end
