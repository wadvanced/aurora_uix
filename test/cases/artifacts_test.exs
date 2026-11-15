defmodule Aurora.Uix.Test.ArtifactsTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Layout.Artifacts

  test "names are built from the caller, the schema hint and the atom" do
    assert Artifacts.module_name(MyApp.Views, "Product", :index_compact) ==
             MyApp.Views.Product.IndexCompact

    assert Artifacts.default_name("ProductLocation", :form_component) ==
             :product_location_form_component

    assert Artifacts.default_name("Product", :index_live) == :product_index
    assert Artifacts.schema_hint(Aurora.Uix.Guides.Inventory.Product) == "Product"
  end

  test "options built by hand take the default artifacts" do
    tree = %Aurora.Uix.Layout.Node.Form{
      resource: :product,
      children: [%Aurora.Uix.Layout.Node.Field{key: :reference}]
    }

    show = %Aurora.Uix.Layout.Node.Show{resource: :product}

    options = %{
      layout_type: :form,
      layout_tree: tree,
      modules: %{caller: MyApp.Views},
      module_name: "Product"
    }

    defaults = Artifacts.put_defaults(options)

    assert %{
             index_live: MyApp.Views.Product.Index,
             form_component: MyApp.Views.Product.FormComponent,
             show_component: MyApp.Views.Product.ShowComponent
           } = defaults.artifacts

    assert defaults.used == []
    assert defaults.generate == Artifacts.kinds()
    assert defaults.exposed_layouts == %{form_component: %{tree | resource: nil}}

    assert Artifacts.put_defaults(%{options | layout_type: :show, layout_tree: show}).exposed_layouts ==
             %{show_component: %{show | resource: nil}}

    assert Artifacts.put_defaults(defaults) == defaults

    kept = options |> Map.put(:artifacts, %{form_component: Enum}) |> Artifacts.put_defaults()
    assert kept.artifacts == %{form_component: Enum}
  end
end
