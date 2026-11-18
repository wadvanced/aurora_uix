defmodule Aurora.Uix.Test.Cases.CreateUIValidationTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Layout.CreateUI
  alias Aurora.Uix.Layout.Node
  alias Spark.Error.DslError

  @spec compile(binary()) :: [{module(), binary()}]
  defp compile(body) do
    Code.compile_string("""
    defmodule Aurora.UixWeb.Test.CreateUIValidationSample#{System.unique_integer([:positive])} do
      use Aurora.Uix

      auix_resource_metadata :product,
        context: Aurora.Uix.Guides.Inventory,
        schema: Aurora.Uix.Guides.Inventory.Product

    #{body}
    end
    """)
  end

  test "including a module without layouts fails compilation" do
    assert_raise DslError, ~r/Aurora.Uix.Guides.Inventory has no layouts/, fn ->
      compile("""
        auix_create_ui include: Aurora.Uix.Guides.Inventory do
        end
      """)
    end
  end

  test "an unknown layout option fails compilation" do
    assert_raise DslError, ~r/unknown index layout options \[:page_tittle\]/, fn ->
      compile("""
        auix_create_ui do
          index_columns :product, [:reference], page_tittle: "Products"
        end
      """)
    end
  end

  test "an index action_icons key that is not a button or link action fails compilation" do
    assert_raise DslError,
                 ~r/index layout: unknown options \[:default_sort\], valid options are: \[:default_row_show,/,
                 fn ->
                   compile(
                     "  auix_create_ui do\n    index_columns :product, [:reference], action_icons: [default_sort: \"hero-bolt\"]\n  end\n"
                   )
                 end
  end

  test "a layout option of the wrong type fails compilation" do
    assert_raise DslError,
                 ~r/index layout: expected :pagination_items_per_page option to match/,
                 fn ->
                   compile("""
                     auix_create_ui do
                       index_columns :product, [:reference], pagination_items_per_page: "forty"
                     end
                   """)
                 end
  end

  test "a form action_icons key of another layout fails compilation" do
    assert_raise DslError,
                 ~r/form layout: unknown options \[:default_back\], valid options are: \[:default_save\]/,
                 fn ->
                   compile("""
                     auix_create_ui do
                       edit_layout :product, action_icons: [default_back: "←"] do
                         inline [:reference]
                       end
                     end
                   """)
                 end
  end

  test "an index layout preload of the wrong type fails compilation" do
    assert_raise DslError, ~r/invalid value for :preload option: expected list/, fn ->
      compile("""
        auix_create_ui do
          index_columns :product, [:reference], preload: :product_location
        end
      """)
    end
  end

  test "an unknown field option fails compilation" do
    assert_raise DslError, ~r/field :name: unknown options \[:lable\]/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            inline [:reference, name: [lable: "Name"]]
          end
        end
      """)
    end
  end

  test "a layout for an undeclared resource fails compilation" do
    assert_raise DslError, ~r/unknown resource :category/, fn ->
      compile("""
        auix_create_ui do
          index_columns :category, [:name]
        end
      """)
    end
  end

  test "a field the resource does not have fails compilation" do
    assert_raise DslError, ~r/unknown fields \[:nmae\] for resource :product/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            group "Identification", [:reference, :nmae]
          end
        end
      """)
    end
  end

  test "two layouts of the same type for a resource fail compilation" do
    assert_raise DslError, ~r/:product has more than one form layout/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            inline [:reference]
          end

          edit_layout :product do
            inline [:name]
          end
        end
      """)
    end
  end

  test "a section outside sections fails compilation" do
    assert_raise DslError, ~r/section can only be placed inside sections/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            section "Prices", [:msrp]
          end
        end
      """)
    end
  end

  test "field places one field, with options or as an association path, in a block" do
    modules =
      compile("""
        auix_create_ui do
          edit_layout :product do
            inline do
              field :reference, readonly: true
              field {:product_location_id, :name}
            end
          end
        end
      """)

    {module, _binary} =
      Enum.find(modules, fn {module, _binary} -> function_exported?(module, :auix_layouts, 0) end)

    assert [%Node.Form{children: [%Node.Inline{children: [reference, location]}]}] =
             module.auix_layouts()

    assert %Node.Field{key: :reference, overrides: %{readonly: true}} = reference
    assert %Node.Field{key: :product_location_id, path: [:name]} = location
  end

  test "every generated module has a registry entry" do
    mod = compiled_ui("  auix_create_ui()\n")
    form = Module.concat(mod, Product.FormComponent)
    index = Module.concat(mod, Product.Index)

    assert mod.auix_modules() == %{
             product_form_component: form,
             product_index: index,
             product_index_component: Module.concat(mod, Product.IndexComponent),
             product_show_component: Module.concat(mod, Product.ShowComponent)
           }

    assert mod.auix_module(:product_form_component) == form
    assert mod.auix_module(:nope) == nil
    assert form.auix_kind() == :form_component
    assert :reference in form.auix_fields()
    assert %Node.Form{resource: nil} = form.auix_layout()
    assert index.auix_kind() == :index_live
    assert index.auix_fields() == []
    assert index.auix_layout() == nil
  end

  test "module_name names the component of its layout" do
    mod =
      compiled_ui("""
        auix_create_ui do
          edit_layout :product, module_name: :reference_form do
            inline [:reference, :name]
          end
        end
      """)

    form = mod.auix_module(:reference_form)
    assert form == Module.concat(mod, Product.ReferenceForm)
    assert form.auix_fields() == [:reference, :name]
    refute mod |> Module.concat(Product.FormComponent) |> Code.ensure_loaded?()
  end

  test "an index_live line names the live view" do
    mod =
      compiled_ui("""
        auix_create_ui do
          index_live :product, module_name: :catalog
        end
      """)

    assert mod.auix_module(:catalog) == Module.concat(mod, Product.Catalog)
    assert mod.auix_module(:catalog).auix_kind() == :index_live
    refute mod |> Module.concat(Product.Index) |> Code.ensure_loaded?()
  end

  test "generate chooses the kinds of module" do
    mod = compiled_ui("  auix_create_ui generate: [:form_component, :show_component]\n")

    refute mod |> Module.concat(Product.Index) |> Code.ensure_loaded?()

    assert Enum.all?(mod.auix_modules(), fn {_name, module} ->
             module.auix_kind() != :index_live
           end)
  end

  test "two resources on one schema need their own module names" do
    body = """
      auix_resource_metadata :product_compact,
        context: Aurora.Uix.Guides.Inventory,
        schema: Aurora.Uix.Guides.Inventory.Product

      auix_create_ui()
    """

    assert_raise DslError, ~r/module name :product_form_component is taken more than once/, fn ->
      compile(body)
    end
  end

  test "two names for one module fail compilation" do
    body = """
      auix_resource_metadata :product_compact,
        context: Aurora.Uix.Guides.Inventory,
        schema: Aurora.Uix.Guides.Inventory.Product

      auix_create_ui do
        edit_layout :product_compact, module_name: :form_component do
          inline [:name]
        end

        show_layout :product_compact, module_name: :compact_show do
          inline [:name]
        end

        index_columns :product_compact, [:name], module_name: :index_compact
        index_live :product_compact, module_name: :compact
      end
    """

    assert_raise DslError, ~r/would be generated twice/, fn -> compile(body) end
  end

  test "use: rejects what it cannot take" do
    assert_raise DslError, ~r/unknown module :nope in use:/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product, use: :nope
        end
      """)
    end

    assert_raise DslError, ~r/use: :product_show_component names :show_component/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product, use: :product_show_component
        end
      """)
    end

    assert_raise DslError, ~r/names :index_live/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product, use: :product_index
        end
      """)
    end

    assert_raise DslError,
                 ~r/unknown fields \[:description\] for resource :product_location in use:/,
                 fn ->
                   compile("""
                     auix_resource_metadata :product_location,
                       context: Aurora.Uix.Guides.Inventory,
                       schema: Aurora.Uix.Guides.Inventory.ProductLocation

                     auix_create_ui do
                       edit_layout :product, module_name: :described do
                         inline [:reference, :description]
                       end

                       edit_layout :product_location, use: :described
                     end
                   """)
                 end

    assert_raise DslError, ~r/unknown module Enum in use:/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product, use: Enum
        end
      """)
    end
  end

  test "use: takes no do block" do
    assert_raise DslError, ~r/use: takes no do block/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product, use: :product_form_component do
            inline [:name]
          end
        end
      """)
    end
  end

  test "use: takes no other option" do
    assert_raise DslError, ~r/use: takes no other option/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product, use: :product_form_component, module_name: :other
        end
      """)
    end
  end

  test "a live view needs its form and show components" do
    assert_raise DslError,
                 ~r/the live view of :product needs a form component and a show component/,
                 fn -> compile("  auix_create_ui generate: [:index_live]\n") end
  end

  test "an embedded resource generates no modules" do
    mod =
      compiled_ui("""
        auix_resource_metadata :user,
          context: Aurora.Uix.Guides.Accounts,
          schema: Aurora.Uix.Guides.Accounts.User

        auix_create_ui()
      """)

    assert mod.auix_modules() |> Map.keys() |> Enum.sort() == [
             :product_form_component,
             :product_index,
             :product_index_component,
             :product_show_component,
             :user_form_component,
             :user_index,
             :user_index_component,
             :user_show_component
           ]

    refute mod |> Module.concat(Profile.Index) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Profile.FormComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Profile.ShowComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Email.Index) |> Code.ensure_loaded?()
    assert Map.has_key?(mod.auix_configurations(), :user__profile)
    assert Map.has_key?(mod.auix_configurations(), :user__emails)
  end

  test "index_columns generates an index component" do
    mod = compiled_ui("  auix_create_ui()\n")

    assert mod.auix_module(:product_index_component) == Module.concat(mod, Product.IndexComponent)
    assert mod.auix_module(:product_index_component).auix_kind() == :index_component

    named =
      compiled_ui("""
        auix_create_ui do
          index_columns :product, [:reference], module_name: :index_compact
        end
      """)

    assert named.auix_module(:index_compact) == Module.concat(named, Product.IndexCompact)

    assert named.auix_configurations().product.artifacts.index_component ==
             Module.concat(named, Product.IndexCompact)

    assert named.auix_module(:index_compact).auix_fields() == [:reference]
    refute named |> Module.concat(Product.IndexComponent) |> Code.ensure_loaded?()

    only = compiled_ui("  auix_create_ui generate: [:index_component]\n")

    assert only |> Module.concat(Product.IndexComponent) |> Code.ensure_loaded?()
    refute only |> Module.concat(Product.Index) |> Code.ensure_loaded?()
    refute only |> Module.concat(Product.FormComponent) |> Code.ensure_loaded?()
    refute only |> Module.concat(Product.ShowComponent) |> Code.ensure_loaded?()
  end

  test "use: gives a resource the index layout of another" do
    mod =
      compiled_ui("""
        auix_resource_metadata :product_location,
          context: Aurora.Uix.Guides.Inventory,
          schema: Aurora.Uix.Guides.Inventory.ProductLocation

        auix_create_ui do
          index_columns :product, [:reference, :name], module_name: :index_compact
          index_columns :product_location, use: :index_compact
        end
      """)

    assert Enum.map(
             mod.auix_configurations().product_location.layout_trees.index.children,
             & &1.key
           ) ==
             [:reference, :name]

    refute mod |> Module.concat(ProductLocation.IndexComponent) |> Code.ensure_loaded?()
    assert mod |> Module.concat(ProductLocation.Index) |> Code.ensure_loaded?()
  end

  test "use: on index_columns rejects what it cannot take" do
    assert_raise DslError, ~r/unknown module :nope in use:/, fn ->
      compile("""
        auix_create_ui do
          index_columns :product, use: :nope
        end
      """)
    end

    assert_raise DslError, ~r/use: takes no field list and no other option/, fn ->
      compile("""
        auix_create_ui do
          index_columns :product, [:name], use: :product_index_component
        end
      """)
    end
  end

  test "an imported module must be a registry entry" do
    assert_raise DslError,
                 ~r/@auix_modules entry :reference_form is not a generated module/,
                 fn ->
                   compile("""
                     @auix_modules %{reference_form: nil}

                     auix_create_ui()
                   """)
                 end
  end

  test "names are built from the caller, the schema hint and the atom" do
    assert CreateUI.module_name(MyApp.Views, "Product", :index_compact) ==
             MyApp.Views.Product.IndexCompact

    assert CreateUI.default_name("ProductLocation", :form_component) ==
             :product_location_form_component

    assert CreateUI.default_name("Product", :index_live) == :product_index
    assert CreateUI.schema_hint(Aurora.Uix.Guides.Inventory.Product) == "Product"
  end

  test "options built by hand take the default artifacts" do
    tree = %Aurora.Uix.Layout.Node.Form{
      resource: :product,
      children: [%Aurora.Uix.Layout.Node.Field{key: :reference}]
    }

    show = %Aurora.Uix.Layout.Node.Show{resource: :product}
    index = %Aurora.Uix.Layout.Node.Index{resource: :product}

    options = %{
      layout_type: :form,
      layout_tree: tree,
      modules: %{caller: MyApp.Views},
      module_name: "Product"
    }

    defaults = CreateUI.put_defaults(options)

    assert %{
             index_live: MyApp.Views.Product.Index,
             form_component: MyApp.Views.Product.FormComponent,
             show_component: MyApp.Views.Product.ShowComponent
           } = defaults.artifacts

    assert defaults.used == []
    assert defaults.generate == CreateUI.kinds()
    assert defaults.exposed_layouts == %{form_component: %{tree | resource: nil}}

    assert CreateUI.put_defaults(%{options | layout_type: :show, layout_tree: show}).exposed_layouts ==
             %{show_component: %{show | resource: nil}}

    assert defaults.artifacts.index_component == MyApp.Views.Product.IndexComponent

    assert CreateUI.put_defaults(%{options | layout_type: :index, layout_tree: index}).exposed_layouts ==
             %{index_component: %{index | resource: nil}}

    assert CreateUI.put_defaults(defaults) == defaults

    kept = options |> Map.put(:artifacts, %{form_component: Enum}) |> CreateUI.put_defaults()
    assert kept.artifacts == %{form_component: Enum}
  end

  @spec compiled_ui(binary()) :: module()
  defp compiled_ui(body) do
    {mod, _binary} =
      body
      |> compile()
      |> Enum.find(fn {m, _} -> function_exported?(m, :auix_modules, 0) end)

    mod
  end
end
