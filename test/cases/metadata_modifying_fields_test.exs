defmodule Aurora.Uix.Test.Cases.MetadataModifyingFieldsTest do
  use Aurora.Uix.Test.Web.UICase

  defmodule FieldValuesModified do
    use Aurora.Uix.Test.Web, :aurora_uix_for_test

    alias Aurora.Uix.Test.Inventory
    alias Aurora.Uix.Test.Inventory.Product

    auix_resource_metadata(:product, context: Inventory, schema: Product) do
      field(:inactive, length: 10)
      field(:inserted_at, hidden: true)
      fields([:weight, :length, :width, :height], precision: 16, scale: 3)
      # :height field properties are changed again, the last one should be the one prevailing
      field(:height, scale: 1)
      field(:data_virtual, field_html_type: :checkbox)
      field(:status, data: [:in_stock, :discontinued, :online_only, :in_store_only])
    end
  end

  test "Test field modifications" do
    resource_configs = resource_configs(FieldValuesModified)

    validate_schema(resource_configs, :product,
      inactive: %{field_html_type: :checkbox, name: "inactive", label: "Inactive", length: 10},
      inserted_at: %{hidden: true},
      weight: %{precision: 16, scale: 3},
      length: %{precision: 16, scale: 3},
      width: %{precision: 16, scale: 3},
      # Order is important, scale is changed, once again on the :height field
      height: %{precision: 16, scale: 1},
      data_virtual: %{field_html_type: :checkbox},
      status: %{data: [:in_stock, :discontinued, :online_only, :in_store_only]}
    )
  end

  test "Check fields order" do
    FieldValuesModified
    |> resource_configs()
    |> get_in([Access.key!(:product), Access.key!(:fields_order)])
    |> assert_values_order([
      :inactive,
      :weight,
      :length,
      :width,
      :height,
      :data_virtual,
      :status,
      :id,
      :reference,
      :name
    ])
  end
end
