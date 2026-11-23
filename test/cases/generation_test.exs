defmodule Aurora.Uix.Test.Cases.GenerationTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Layout.CreateUI
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Layout.Options
  alias Aurora.Uix.Layout.Options.Form
  alias Aurora.Uix.Layout.Options.Option
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.UixWeb.Test.Mirror
  alias Aurora.UixWeb.Test.Mirror.Variants
  alias Aurora.UixWeb.Test.MirrorCtx
  alias Spark.Error.DslError

  @render_tree_sources [
    "context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product",
    "ash_resource: Aurora.Uix.Test.MirrorAsh.Product"
  ]

  @named_views [
    {Aurora.UixWeb.Test.MirrorCtx.Named, Aurora.UixWeb.Test.MirrorCtx.NamedForms,
     Aurora.UixWeb.Test.MirrorCtx.NamedHost},
    {Aurora.UixWeb.Test.MirrorAsh.Named, Aurora.UixWeb.Test.MirrorAsh.NamedForms,
     Aurora.UixWeb.Test.MirrorAsh.NamedHost}
  ]

  # The 0.1.x options form raises before Spark sees the module, so its error is not a DslError.
  @exceptions %{"the 0.1.x form fails compilation" => ArgumentError}

  @run_time_variants ~w(Default DefaultInline Groups Sections NestedSections Options NamedForms
                        NamedHost Named Included Manual SeparatedResources Separated)a

  @run_time_single_views [
    {Variants.ManualResource, :ctx, MirrorCtx.ManualResource},
    {Variants.IncludedLayouts, :ctx, Mirror.IncludedLayouts}
  ]

  test "generated modules, names, render trees and option sets" do
    assert_duplicate_layouts()
    assert_field_in_block()
    assert_registry()
    assert_module_name()
    assert_index_live_name()
    assert_generate_kinds()
    assert_shared_schema_names()
    assert_duplicate_module()
    assert_index_component()
    assert_use_index_layout()
    assert_names()
    assert_default_artifacts()
    assert_card_columns()
    assert_index_columns_without_block()
    assert_index_without_card()
    assert_nested_preload()

    for {named, forms, host} <- @named_views do
      assert_named_modules(named, forms, host)
    end

    for source <- @render_tree_sources do
      source |> render_tree_body() |> compile_raw() |> assert_render_tree()
    end

    assert_ctx_embedded_resources()
    assert_ash_embedded_resources()
    assert_option_sets()
    assert_run_time_views()
  end

  test "create_ui and layout option compile errors" do
    cases = [
      {"including a module without layouts fails compilation",
       """
        auix_create_ui include: Aurora.Uix.Test.MirrorCtx do
        end
       """, ~r/Aurora.Uix.Test.MirrorCtx has no layouts/},
      {"an unknown layout option fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:reference], page_tittle: "Products"
        end
       """, ~r/unknown index layout options \[:page_tittle\]/},
      {"an index action_icons key that is not a button or link action fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:reference], action_icons: [default_sort: "hero-bolt"]
        end
       """,
       ~r/index layout: unknown options \[:default_sort\], valid options are: \[:default_row_show,/},
      {"a layout option of the wrong type fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:reference], pagination_items_per_page: "forty"
        end
       """, ~r/index layout: expected :pagination_items_per_page option to match/},
      {"a form action_icons key of another layout fails compilation",
       """
        auix_create_ui do
          edit_layout :product, action_icons: [default_back: "←"] do
            inline [:reference]
          end
        end
       """,
       ~r/form layout: unknown options \[:default_back\], valid options are: \[:default_save\]/},
      {"an index layout preload of the wrong type fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:reference], preload: :product_location
        end
       """, ~r/invalid value for :preload option: expected list/},
      {"an unknown field option fails compilation",
       """
        auix_create_ui do
          edit_layout :product do
            inline [:reference, name: [lable: "Name"]]
          end
        end
       """, ~r/field :name: unknown options \[:lable\]/},
      {"a one-to-many field rejects an action_icons key of another field type",
       """
        auix_create_ui do
          edit_layout :product do
            inline [:reference, product_transactions: [action_icons: [default_add_entry: "hero-plus"]]]
          end
        end
       """,
       ~r/field :product_transactions: unknown options \[:default_add_entry\], valid options are: \[:default_new, :default_row_show, :default_row_edit, :default_row_delete\]/},
      {"a many-to-many field takes no action_icons key",
       """
        auix_create_ui do
          edit_layout :product do
            inline [:reference, suppliers: [action_icons: [default_toggle_all: "hero-check"]]]
          end
        end
       """,
       ~r/field :suppliers: unknown options \[:default_toggle_all\], valid options are: \[\]/},
      {"a layout for an undeclared resource fails compilation",
       """
        auix_create_ui do
          index_columns :category, [:name]
        end
       """, ~r/unknown resource :category/},
      {"a field the resource does not have fails compilation",
       """
        auix_create_ui do
          edit_layout :product do
            group "Identification", [:reference, :nmae]
          end
        end
       """, ~r/unknown fields \[:nmae\] for resource :product/},
      {"a section outside sections fails compilation",
       """
        auix_create_ui do
          edit_layout :product do
            section "Prices", [:msrp]
          end
        end
       """, ~r/section can only be placed inside sections/},
      {"use: rejects what it cannot take (1)",
       """
        auix_create_ui do
          edit_layout :product, use: :nope
        end
       """, ~r/unknown module :nope in use:/},
      {"use: rejects what it cannot take (2)",
       """
        auix_create_ui do
          edit_layout :product, use: :product_show_component
        end
       """, ~r/use: :product_show_component names :show_component/},
      {"use: rejects what it cannot take (3)",
       """
        auix_create_ui do
          edit_layout :product, use: :product_index
        end
       """, ~r/names :index_live/},
      {"use: rejects what it cannot take (4)",
       """
        auix_resource_metadata :product_location,
          context: Aurora.Uix.Test.MirrorCtx,
          schema: Aurora.Uix.Test.MirrorCtx.ProductLocation

        auix_create_ui do
          edit_layout :product, module_name: :described do
            inline [:reference, :description]
          end

          edit_layout :product_location, use: :described
        end
       """, ~r/unknown fields \[:description\] for resource :product_location in use:/},
      {"use: rejects what it cannot take (5)",
       """
        auix_create_ui do
          edit_layout :product, use: Enum
        end
       """, ~r/unknown module Enum in use:/},
      {"use: takes no do block",
       """
        auix_create_ui do
          edit_layout :product, use: :product_form_component do
            inline [:name]
          end
        end
       """, ~r/use: takes no do block/},
      {"use: takes no other option",
       """
        auix_create_ui do
          edit_layout :product, use: :product_form_component, module_name: :other
        end
       """, ~r/use: takes no other option/},
      {"a live view needs its form and show components",
       """
        auix_create_ui generate: [:index_live]
       """, ~r/the live view of :product needs a form component and a show component/},
      {"use: on index_columns rejects what it cannot take (1)",
       """
        auix_create_ui do
          index_columns :product, use: :nope
        end
       """, ~r/unknown module :nope in use:/},
      {"use: on index_columns rejects what it cannot take (2)",
       """
        auix_create_ui do
          index_columns :product, [:name], use: :product_index_component
        end
       """, ~r/use: takes no field list and no other option/},
      {"an imported module must be a registry entry",
       """
        @auix_modules %{reference_form: nil}

        auix_create_ui()
       """, ~r/@auix_modules entry :reference_form is not a generated module/},
      {"a card field outside the field list fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:reference, :name] do
            card title: :name do
              stacked [:msrp]
            end
          end
        end
       """, ~r/card fields \[:msrp\] are not index columns/},
      {"sections in a card fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:name] do
            card do
              sections do
                section "A", [:name]
              end
            end
          end
        end
       """, ~r/card takes no sections/},
      {"sections under a card sub-layout fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:name] do
            card do
              inline do
                sections do
                  section "A", [:name]
                end
              end
            end
          end
        end
       """, ~r/card takes no sections/},
      {"an unknown show_on fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:name] do
            card show_on: :desktop
          end
        end
       """, ~r/show_on/},
      {"an option declared twice fails compilation",
       """
        defmodule LayoutOptionsSet do
          use Aurora.Uix.Layout.Options, layout_type: :sample

          option :greeting, :string
          option :greeting, :string

          defp get_default(_assigns, option), do: {:not_found, option}
        end
       """, ~r/option :greeting is declared more than once/},
      {"an unknown option type fails compilation",
       """
        defmodule LayoutOptionsSet do
          use Aurora.Uix.Layout.Options, layout_type: :sample

          option :greeting, :text

          defp get_default(_assigns, option), do: {:not_found, option}
        end
       """, ~r/option :greeting: unknown type :text/},
      {"the 0.1.x form fails compilation",
       """
        defmodule LayoutOptionsOldSample do
          use Aurora.Uix.Layout.Options, :sample
        end
       """, ~r/no longer finds the options/}
    ]

    for {label, body, regex} <- cases do
      exception = Map.get(@exceptions, label, DslError)

      # Spark keeps the entity being built in the process dictionary, and a DSL error raised
      # mid-entity leaves it there: each case compiles in a process of its own.
      raised =
        fn ->
          try do
            compile(body)
            nil
          rescue
            error -> error
          end
        end
        |> Task.async()
        |> Task.await(:infinity)

      assert is_exception(raised, exception),
             "#{label}: expected #{inspect(exception)}, got #{inspect(raised)}"

      assert Exception.message(raised) =~ regex,
             "#{label}: #{inspect(Exception.message(raised))} does not match #{inspect(regex)}"
    end
  end

  ## PRIVATE ##

  @spec compile(binary()) :: [{module(), binary()}]
  defp compile(body) do
    Code.compile_string("""
    defmodule Aurora.UixWeb.Test.GenerationSample#{System.unique_integer([:positive])} do
      use Aurora.Uix

      auix_resource_metadata :product,
        context: Aurora.Uix.Test.MirrorCtx,
        schema: Aurora.Uix.Test.MirrorCtx.Product

    #{body}
    end
    """)
  end

  @spec compiled_ui(binary()) :: module()
  defp compiled_ui(body) do
    {mod, _binary} =
      body
      |> compile()
      |> Enum.find(fn {m, _} -> function_exported?(m, :auix_modules, 0) end)

    mod
  end

  @spec compile_raw(binary()) :: module()
  defp compile_raw(body) do
    {mod, _binary} =
      """
      defmodule Aurora.UixWeb.Test.GenerationSample#{System.unique_integer([:positive])} do
        use Aurora.Uix
      #{body}
      end
      """
      |> Code.compile_string()
      |> Enum.find(fn {m, _} -> function_exported?(m, :auix_modules, 0) end)

    mod
  end

  # Compiles every views definition while the suite runs and compares it with the views module
  # the scenarios mount, so the DSL a variant declares is exercised by a test.
  @spec assert_run_time_views() :: term()
  defp assert_run_time_views do
    variants =
      for name <- @run_time_variants, backend <- [:ash, :ctx] do
        {Module.concat(Variants, name), backend, Mirror.sibling(backend, name)}
      end

    signatures =
      (variants ++ @run_time_single_views)
      |> Task.async_stream(
        fn {definition, backend, twin} ->
          signature = definition |> compile_view(backend) |> signature()
          assert signature == signature(twin), "#{inspect(definition)} on #{backend}"
          {{definition, backend}, signature}
        end,
        timeout: :infinity
      )
      |> Map.new(fn {:ok, entry} -> entry end)

    assert_manual_views(signatures)
    assert_included_views(signatures)
    assert_resource_only_views(signatures)
  end

  @spec assert_manual_views(map()) :: term()
  defp assert_manual_views(signatures) do
    product_form =
      {:form_component,
       [
         :description,
         :list_price,
         :name,
         :product_location_id,
         :product_transactions,
         :quantity_at_hand,
         :quantity_initial,
         :reference,
         :rrp
       ]}

    for backend <- [:ash, :ctx] do
      manual = signatures[{Variants.Manual, backend}]

      assert manual.layouts == [
               {Node.Form, :product},
               {Node.Show, :product},
               {Node.Index, :product}
             ]

      assert manual.modules.product_form_component == product_form

      assert manual.modules.product_show_component ==
               {:show_component,
                [
                  :description,
                  :name,
                  :product_location_id,
                  :product_transactions,
                  :quantity_at_hand,
                  :quantity_initial,
                  :reference
                ]}

      assert manual.modules.product_index_component ==
               {:index_component, [:description, :name, :product_location_id, :reference]}
    end

    hand_built = signatures[{Variants.ManualResource, :ctx}]
    assert hand_built.resources == []
    assert hand_built.modules.product_form_component == product_form
    assert hand_built.modules.product_show_component == put_elem(product_form, 0, :show_component)
  end

  @spec assert_included_views(map()) :: term()
  defp assert_included_views(signatures) do
    layouts = [{Node.Form, :product}, {Node.Show, :product}]

    assert signatures[{Variants.IncludedLayouts, :ctx}] ==
             %{resources: [], layouts: layouts, modules: %{}}

    for backend <- [:ash, :ctx] do
      included = signatures[{Variants.Included, backend}]
      assert included.layouts == layouts
      assert included.modules.product_form_component == {:form_component, [:name, :reference]}
      assert included.modules.product_show_component == {:show_component, [:name]}
    end
  end

  @spec assert_resource_only_views(map()) :: term()
  defp assert_resource_only_views(signatures) do
    for backend <- [:ash, :ctx] do
      assert signatures[{Variants.SeparatedResources, backend}] == %{
               resources: [
                 :product,
                 :product__contacts,
                 :product__packaging,
                 :product_transaction
               ],
               layouts: [],
               modules: %{}
             }

      assert signatures[{Variants.NamedHost, backend}] == %{
               resources: [],
               layouts: [{Node.Form, :product_location}],
               modules: %{}
             }
    end
  end

  @spec compile_view(module(), :ash | :ctx) :: module()
  defp compile_view(definition, backend) do
    name = "Aurora.UixWeb.Test.GenerationSample#{System.unique_integer([:positive])}"

    Code.compile_string("""
    defmodule #{name} do
      use #{inspect(definition)}, backend: #{inspect(backend)}
    end
    """)

    Module.concat([name])
  end

  @spec signature(module()) :: map()
  defp signature(views) do
    %{
      resources: views |> exported(:auix_resources, %{}) |> Map.keys() |> Enum.sort(),
      layouts: views |> exported(:auix_layouts, []) |> Enum.map(&{&1.__struct__, &1.resource}),
      modules:
        views
        |> exported(:auix_modules, %{})
        |> Map.new(fn {name, module} ->
          {name, {module.auix_kind(), Enum.sort(module.auix_fields())}}
        end)
    }
  end

  @spec exported(module(), atom(), term()) :: term()
  defp exported(views, function, default) do
    Code.ensure_loaded!(views)

    if function_exported?(views, function, 0),
      do: apply(views, function, []),
      else: default
  end

  @spec render_tree_body(binary()) :: binary()
  defp render_tree_body(source) do
    """
    auix_resource_metadata :product, #{source}

    auix_create_ui do
      edit_layout :product, [] do
        group("Identification", [:reference, name: [label: "Product name"]])

        sections do
          section("Quantities", [:quantity_initial])
          section("Prices", [:msrp], default: true)
        end
      end

      index_columns :product, [:reference, :name, :msrp] do
        card title: :name, subtitle: :reference, show_on: :all do
          inline [:msrp]
          field :name, label: "Product name"
        end
      end
    end
    """
  end

  @spec assert_render_tree(module()) :: term()
  defp assert_render_tree(mod) do
    form = mod.auix_configurations().product.layout_trees.form

    assert %Node.Form{id: "auix-product-form", children: [group, sections]} = form
    assert group.id == "auix-group-identification-product-form-0"
    assert sections.id == "auix-sections-product-form-1"

    assert Enum.map(sections.children, & &1.id) == [
             "auix-section-quantities-product-form-1-0",
             "auix-section-prices-product-form-1-1"
           ]

    assert [%Node.Field{key: :reference}, %Node.Field{key: :name, field: name}] =
             form |> Node.fields() |> Enum.take(2)

    assert name.label == "Product name"
    assert name.type == :string

    assert %Node.Sections{index: 1, tabs: [quantities, prices]} = Enum.at(form.children, 1)
    assert {quantities.active?, quantities.tab_index} == {false, 1}
    assert {prices.active?, prices.tab_index} == {true, 2}

    index = mod.auix_configurations().product.layout_trees.index

    assert %Node.Card{
             show_on: :all,
             title: %Node.Field{key: :name, field: %{label: title_label}},
             subtitle: %Node.Field{key: :reference},
             children: [
               %Node.Inline{id: nil},
               %Node.Field{key: :name, field: %{label: "Product name"}}
             ]
           } = index.card

    refute title_label == "Product name"

    name_column = Enum.find(index.children, &(&1.key == :name))
    assert name_column.field.label != "Product name"
  end

  @spec assert_named_modules(module(), module(), module()) :: term()
  defp assert_named_modules(named, forms, host) do
    assert named.auix_module(:reference_form) == Module.concat(forms, Product.ReferenceForm)
    assert Map.has_key?(named.auix_modules(), :reference_form)

    assert host.auix_modules() == %{}
    configuration = host.auix_configurations().product_location
    assert configuration.artifacts.form_component == Module.concat(forms, Product.ReferenceForm)
    assert configuration.used == [:form_component]
    refute host |> Module.concat(ProductLocation.FormComponent) |> Code.ensure_loaded?()
    refute host |> Module.concat(ProductLocation.ShowComponent) |> Code.ensure_loaded?()
    refute host |> Module.concat(ProductLocation.Index) |> Code.ensure_loaded?()

    binding = Helpers.component_binding(host.auix_configurations(), :product_location, :form)

    assert %{
             resource_name: :product_location,
             layout_type: :form,
             modules: %{caller: ^host},
             artifacts: %{form_component: module},
             layout_tree: %Node.Form{resource: :product_location} = tree
           } = binding

    assert module == Module.concat(forms, Product.ReferenceForm)
    assert tree |> Node.fields() |> Enum.map(& &1.key) == [:reference, :name]

    assert_raise KeyError, fn ->
      Helpers.component_binding(host.auix_configurations(), :nope, :form)
    end
  end

  @spec assert_ctx_embedded_resources() :: term()
  defp assert_ctx_embedded_resources do
    mod =
      compile_raw("""
      auix_resource_metadata :product, context: Aurora.Uix.Test.MirrorCtx, schema: Aurora.Uix.Test.MirrorCtx.Product
      auix_resource_metadata :product__packaging do
        schema Aurora.Uix.Test.MirrorCtx.Product.Packaging
        field :fragile, readonly: true
      end
      auix_create_ui()
      """)

    assert mod.auix_modules() |> Map.keys() |> Enum.sort() == [
             :product_form_component,
             :product_index,
             :product_index_component,
             :product_show_component
           ]

    refute mod |> Module.concat(Packaging.Index) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Packaging.FormComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Packaging.ShowComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Contact.Index) |> Code.ensure_loaded?()
    assert Map.has_key?(mod.auix_configurations(), :product__packaging)
    assert Map.has_key?(mod.auix_configurations(), :product__contacts)
    assert mod.auix_resource(:product__packaging).embedded?
    assert mod.auix_resource(:product__contacts).embedded?
    assert mod.auix_resource(:product__packaging).fields.fragile.readonly
  end

  @spec assert_ash_embedded_resources() :: term()
  defp assert_ash_embedded_resources do
    mod =
      compile_raw("""
      auix_resource_metadata :product, ash_resource: Aurora.Uix.Test.MirrorAsh.Product
      auix_resource_metadata :product__packaging do
        ash_resource Aurora.Uix.Test.MirrorAsh.Packaging
        field :notes, readonly: true
      end
      auix_resource_metadata :contact_metadata, ash_resource: Aurora.Uix.Test.MirrorAsh.Contact
      auix_resource_metadata :policy_item, ash_resource: AshActorTest.PolicyItem
      auix_resource_metadata :policy_item__tags, ash_resource: AshActorTest.Tag
      auix_create_ui do
        edit_layout :product__packaging do
          stacked [:notes]
        end
      end
      """)

    assert mod.auix_modules() |> Map.keys() |> Enum.sort() == [
             :policy_item_form_component,
             :policy_item_index,
             :policy_item_index_component,
             :policy_item_show_component,
             :product_form_component,
             :product_index,
             :product_index_component,
             :product_show_component
           ]

    refute mod |> Module.concat(Packaging.Index) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Packaging.FormComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Packaging.ShowComponent) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Contact.Index) |> Code.ensure_loaded?()
    refute mod |> Module.concat(Tag.Index) |> Code.ensure_loaded?()

    for name <- [:product__packaging, :product__contacts, :policy_item__tags, :contact_metadata] do
      assert mod.auix_resource(name).embedded?
    end

    assert mod.auix_resource(:product__packaging).fields.notes.readonly

    assert [%Node.Stacked{children: [%Node.Field{key: :notes}]}] =
             mod.auix_configurations().product__packaging.layout_trees.form.children
  end

  @spec assert_option_sets() :: term()
  defp assert_option_sets do
    assert %Option{layout_type: :form, name: :edit_title} =
             Enum.find(Form.options(), &(&1.name == :edit_title))

    assert Enum.all?(Form.options(), &(&1.layout_type == :form))

    assert :record_navigator in Options.available_options(:form)
    assert :record_navigator in Options.available_options(:show)
    refute :edit_title in Options.available_options(:show)

    [{options_set, _binary}] =
      Code.compile_string("""
      defmodule Aurora.Uix.Test.LayoutOptionsSample#{System.unique_integer([:positive])} do
        use Aurora.Uix.Layout.Options, layout_type: :sample

        option :greeting, :string
        option :farewell, :string

        defp get_default(_assigns, :greeting), do: {:ok, "hello"}
        defp get_default(_assigns, option), do: {:not_found, option}
      end
      """)

    assigns = %{auix: %{layout_type: :sample, layout_tree: %{options: [farewell: "bye"]}}}

    assert options_set.get(assigns, :greeting) == {:ok, "hello"}
    assert options_set.get(assigns, :farewell) == {:ok, "bye"}
    assert options_set.get(assigns, :unlisted) == {:not_found, :unlisted}
  end

  @spec assert_duplicate_layouts() :: term()
  defp assert_duplicate_layouts do
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

  @spec assert_field_in_block() :: term()
  defp assert_field_in_block do
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

  @spec assert_registry() :: term()
  defp assert_registry do
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

  @spec assert_module_name() :: term()
  defp assert_module_name do
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

  @spec assert_index_live_name() :: term()
  defp assert_index_live_name do
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

  @spec assert_generate_kinds() :: term()
  defp assert_generate_kinds do
    mod = compiled_ui("  auix_create_ui generate: [:form_component, :show_component]\n")

    refute mod |> Module.concat(Product.Index) |> Code.ensure_loaded?()

    assert Enum.all?(mod.auix_modules(), fn {_name, module} ->
             module.auix_kind() != :index_live
           end)
  end

  @spec assert_shared_schema_names() :: term()
  defp assert_shared_schema_names do
    body = """
      auix_resource_metadata :product_compact,
        context: Aurora.Uix.Test.MirrorCtx,
        schema: Aurora.Uix.Test.MirrorCtx.Product

      auix_create_ui()
    """

    assert_raise DslError, ~r/module name :product_form_component is taken more than once/, fn ->
      compile(body)
    end
  end

  @spec assert_duplicate_module() :: term()
  defp assert_duplicate_module do
    body = """
      auix_resource_metadata :product_compact,
        context: Aurora.Uix.Test.MirrorCtx,
        schema: Aurora.Uix.Test.MirrorCtx.Product

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

  @spec assert_index_component() :: term()
  defp assert_index_component do
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

  @spec assert_use_index_layout() :: term()
  defp assert_use_index_layout do
    mod =
      compiled_ui("""
        auix_resource_metadata :product_location,
          context: Aurora.Uix.Test.MirrorCtx,
          schema: Aurora.Uix.Test.MirrorCtx.ProductLocation

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

  @spec assert_names() :: term()
  defp assert_names do
    assert CreateUI.module_name(MyApp.Views, "Product", :index_compact) ==
             MyApp.Views.Product.IndexCompact

    assert CreateUI.default_name("ProductLocation", :form_component) ==
             :product_location_form_component

    assert CreateUI.default_name("Product", :index_live) == :product_index
    assert CreateUI.schema_hint(Aurora.Uix.Test.MirrorCtx.Product) == "Product"
  end

  @spec assert_default_artifacts() :: term()
  defp assert_default_artifacts do
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

  @spec assert_card_columns() :: term()
  defp assert_card_columns do
    mod =
      compiled_ui("""
        auix_create_ui do
          index_columns :product do
            card title: :name, subtitle: :reference do
              stacked [:msrp, :name]
            end
          end
        end
      """)

    assert Enum.map(mod.auix_configurations().product.layout_trees.index.children, & &1.key) ==
             [:name, :reference, :msrp]
  end

  @spec assert_index_columns_without_block() :: term()
  defp assert_index_columns_without_block do
    with_options =
      compiled_ui("""
        auix_create_ui do
          index_columns :product, [:reference], page_title: "Products"
        end
      """)

    assert [%Node.Index{options: [page_title: "Products"]}] = with_options.auix_layouts()

    pair_only =
      compiled_ui("""
        auix_create_ui do
          index_columns :product, [name: [label: "Product"]]
        end
      """)

    assert [%Node.Index{children: [%Node.Field{key: :name, overrides: %{label: "Product"}}]}] =
             pair_only.auix_layouts()
  end

  @spec assert_index_without_card() :: term()
  defp assert_index_without_card do
    mod =
      compiled_ui("""
        auix_create_ui do
          index_columns :product, [:reference]
        end
      """)

    assert mod.auix_configurations().product.layout_trees.index.card == nil
  end

  @spec assert_nested_preload() :: term()
  defp assert_nested_preload do
    mod =
      compiled_ui("""
        auix_resource_metadata :product_location do
          context Aurora.Uix.Test.MirrorCtx
          schema Aurora.Uix.Test.MirrorCtx.ProductLocation
          field :products, resource: :product
        end

        auix_create_ui do
          index_columns :product, [:reference, :product_location]

          edit_layout :product do
            stacked [:reference, :product_location]
          end

          show_layout :product do
            stacked [:reference, :product_location, :product_transactions]
          end

          index_columns :product_location, [:name]

          edit_layout :product_location do
            stacked [:name]
          end

          show_layout :product_location do
            stacked [:name, :products]
          end
        end
      """)

    assert mod.auix_resource(:product_location).fields.products.resource == :product_location
    preloads = mod.auix_preloads()

    assert preloads.product_location |> Keyword.fetch!(:products) |> Enum.sort() == [
             :product_location,
             :product_transactions
           ]

    assert Keyword.fetch!(preloads.product, :product_location) == []
    assert Keyword.fetch!(preloads.product, :product_transactions) == []
  end
end
