defmodule Aurora.UixWeb.RenderTreeTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Layout.Node

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product, [] do
      group("Identification", [:reference, name: [label: "Product name"]])

      sections do
        section("Quantities", [:quantity_initial])
        section("Prices", [:msrp], default: true)
      end
    end
  end

  setup do
    %{form: __MODULE__.auix_configurations().product.layout_trees.form}
  end

  test "node ids come from the position in the layout", %{form: form} do
    assert %Node.Form{id: "auix-product-form", children: [group, sections]} = form
    assert group.id == "auix-group-identification-product-form-0"
    assert sections.id == "auix-sections-product-form-1"

    assert Enum.map(sections.children, & &1.id) == [
             "auix-section-quantities-product-form-1-0",
             "auix-section-prices-product-form-1-1"
           ]
  end

  test "field nodes carry the resource field with the layout options", %{form: form} do
    assert [%Node.Field{key: :reference}, %Node.Field{key: :name, field: name}] =
             form |> Node.fields() |> Enum.take(2)

    assert name.label == "Product name"
    assert name.type == :string
  end

  test "sections carry the tab state", %{form: form} do
    assert %Node.Sections{index: 1, tabs: [quantities, prices]} = Enum.at(form.children, 1)
    assert {quantities.active?, quantities.tab_index} == {false, 1}
    assert {prices.active?, prices.tab_index} == {true, 2}
  end
end
