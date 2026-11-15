defmodule Aurora.UixWeb.Test.NamedModulesForms do
  use Aurora.Uix

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation

  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  auix_create_ui generate: [:form_component, :show_component] do
    edit_layout :product, module_name: :reference_form do
      inline([:reference, :name])
    end
  end
end

defmodule Aurora.UixWeb.Test.NamedModulesHost do
  use Aurora.Uix

  alias Aurora.UixWeb.Test.NamedModulesForms

  @auix_resource_metadata %{
    product_location: NamedModulesForms.auix_resource(:product_location)
  }

  auix_create_ui generate: [] do
    edit_layout(:product_location, use: NamedModulesForms.auix_module(:reference_form))
  end
end

defmodule Aurora.UixWeb.Test.NamedModulesTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Repo
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.UixWeb.Test.NamedModulesForms
  alias Aurora.UixWeb.Test.NamedModulesHost, as: PairingHost

  @auix_modules %{reference_form: NamedModulesForms.auix_module(:reference_form)}

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)

  auix_create_ui do
    edit_layout(:product_location, use: :reference_form)
    index_live(:product_location, module_name: :locations)
  end

  test "a used form component serves the resource of its host", %{conn: conn} do
    delete_all_inventory_data()
    create_sample_product_locations(1)
    [location] = Repo.all(ProductLocation)

    {:ok, view, _html} = live(conn, "/named-modules-locations/#{location.id}/edit")

    assert has_element?(
             view,
             "#auix-product_location-form input[name='product_location[reference]']"
           )

    assert has_element?(view, "#auix-product_location-form input[name='product_location[name]']")
    refute has_element?(view, "input[name='product_location[type]']")

    view
    |> form("#auix-product_location-form", product_location: %{name: "Renamed"})
    |> render_submit()

    assert Repo.get!(ProductLocation, location.id).name == "Renamed"
    refute Code.ensure_loaded?(__MODULE__.ProductLocation.FormComponent)
    refute Code.ensure_loaded?(__MODULE__.ProductLocation.Index)
    assert Code.ensure_loaded?(__MODULE__.ProductLocation.Locations)
  end

  test "an imported module is in the registry of its importer" do
    assert __MODULE__.auix_module(:reference_form) == NamedModulesForms.Product.ReferenceForm

    assert Map.has_key?(__MODULE__.auix_modules(), :reference_form)
  end

  test "a module declares a pairing without generating modules" do
    assert PairingHost.auix_modules() == %{}
    configuration = PairingHost.auix_configurations().product_location
    assert configuration.artifacts.form_component == NamedModulesForms.Product.ReferenceForm
    assert configuration.used == [:form_component]
    refute Code.ensure_loaded?(Aurora.UixWeb.Test.NamedModulesHost.ProductLocation.FormComponent)
    refute Code.ensure_loaded?(Aurora.UixWeb.Test.NamedModulesHost.ProductLocation.ShowComponent)
    refute Code.ensure_loaded?(Aurora.UixWeb.Test.NamedModulesHost.ProductLocation.Index)
  end

  test "component_binding/3 builds the options of a pairing" do
    binding =
      Helpers.component_binding(PairingHost.auix_configurations(), :product_location, :form)

    assert %{
             resource_name: :product_location,
             layout_type: :form,
             modules: %{caller: PairingHost},
             artifacts: %{form_component: module},
             layout_tree: %Node.Form{resource: :product_location} = tree
           } = binding

    assert module == NamedModulesForms.Product.ReferenceForm
    assert tree |> Node.fields() |> Enum.map(& &1.key) == [:reference, :name]

    assert_raise KeyError, fn ->
      Helpers.component_binding(PairingHost.auix_configurations(), :nope, :form)
    end
  end
end
