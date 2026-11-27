defmodule Aurora.UixWeb.Test.Generation.Registry do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)
  auix_create_ui()
end

defmodule Aurora.UixWeb.Test.Generation.FieldInBlock do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    edit_layout :product do
      inline do
        field(:reference, readonly: true)
        field({:product_location_id, :name})
      end
    end
  end
end

defmodule Aurora.UixWeb.Test.Generation.ModuleName do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    edit_layout :product, module_name: :reference_form do
      inline([:reference, :name])
    end
  end
end

defmodule Aurora.UixWeb.Test.Generation.IndexLiveName do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    index_live(:product, module_name: :catalog)
  end
end

defmodule Aurora.UixWeb.Test.Generation.GenerateComponents do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)
  auix_create_ui(generate: [:form_component, :show_component])
end

defmodule Aurora.UixWeb.Test.Generation.NamedIndex do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    index_columns(:product, [:reference], module_name: :index_compact)
  end
end

defmodule Aurora.UixWeb.Test.Generation.OnlyIndexComponent do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)
  auix_create_ui(generate: [:index_component])
end

defmodule Aurora.UixWeb.Test.Generation.UseIndexLayout do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)
  mirror_resource(:product_location)

  auix_create_ui do
    index_columns(:product, [:reference, :name], module_name: :index_compact)
    index_columns(:product_location, use: :index_compact)
  end
end

defmodule Aurora.UixWeb.Test.Generation.CardColumns do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    index_columns :product do
      card title: :name, subtitle: :reference do
        stacked([:msrp, :name])
      end
    end
  end
end

defmodule Aurora.UixWeb.Test.Generation.IndexOptions do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    index_columns(:product, [:reference], page_title: "Products")
  end
end

defmodule Aurora.UixWeb.Test.Generation.IndexPair do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    index_columns(:product, name: [label: "Product"])
  end
end

defmodule Aurora.UixWeb.Test.Generation.IndexWithoutCard do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  auix_create_ui do
    index_columns(:product, [:reference])
  end
end

defmodule Aurora.UixWeb.Test.Generation.NestedPreload do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx
  mirror_resource(:product)

  mirror_resource :product_location do
    field(:products, resource: :product)
  end

  auix_create_ui do
    index_columns(:product, [:reference, :product_location])

    edit_layout :product do
      stacked([:reference, :product_location])
    end

    show_layout :product do
      stacked([:reference, :product_location, :product_transactions])
    end

    index_columns(:product_location, [:name])

    edit_layout :product_location do
      stacked([:name])
    end

    show_layout :product_location do
      stacked([:name, :products])
    end
  end
end

defmodule Aurora.UixWeb.Test.Generation.RenderTree do
  defmacro __using__(opts) do
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource(:product)

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
            inline([:msrp])
            field(:name, label: "Product name")
          end
        end
      end
    end
  end
end

defmodule Aurora.UixWeb.Test.Generation.Ash.RenderTree do
  use Aurora.UixWeb.Test.Generation.RenderTree, backend: :ash
end

defmodule Aurora.UixWeb.Test.Generation.Ctx.RenderTree do
  use Aurora.UixWeb.Test.Generation.RenderTree, backend: :ctx
end

defmodule Aurora.UixWeb.Test.Generation.CtxEmbedded do
  use Aurora.UixWeb.Test.Mirror, backend: :ctx

  mirror_resource(:product)

  auix_resource_metadata :product__packaging do
    schema(Aurora.Uix.Test.MirrorCtx.Product.Packaging)
    field(:fragile, readonly: true)
  end

  auix_create_ui()
end

defmodule Aurora.UixWeb.Test.Generation.AshEmbedded do
  use Aurora.UixWeb.Test.Mirror, backend: :ash

  mirror_resource(:product)

  auix_resource_metadata :product__packaging do
    ash_resource(Aurora.Uix.Test.MirrorAsh.Packaging)
    field(:notes, readonly: true)
  end

  auix_resource_metadata(:contact_metadata, ash_resource: Aurora.Uix.Test.MirrorAsh.Contact)
  auix_resource_metadata(:policy_item, ash_resource: AshActorTest.PolicyItem)
  auix_resource_metadata(:policy_item__tags, ash_resource: AshActorTest.Tag)

  auix_create_ui do
    edit_layout :product__packaging do
      stacked([:notes])
    end
  end
end

defmodule Aurora.UixWeb.Test.Generation.OptionsSet do
  use Aurora.Uix.Layout.Options, layout_type: :sample

  option(:greeting, :string)
  option(:farewell, :string)

  @spec get_default(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_default(_assigns, :greeting), do: {:ok, "hello"}
  defp get_default(_assigns, option), do: {:not_found, option}
end

defmodule Aurora.Uix.Test.Cases.GenerationTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Layout.CreateUI
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Layout.Options
  alias Aurora.Uix.Layout.Options.Form
  alias Aurora.Uix.Layout.Options.Option
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.UixWeb.Test.Generation
  alias Aurora.UixWeb.Test.Mirror
  alias Aurora.UixWeb.Test.MirrorAsh
  alias Aurora.UixWeb.Test.MirrorCtx
  alias Spark.Error.DslError

  @named_views [
    {Aurora.UixWeb.Test.MirrorCtx.Named, Aurora.UixWeb.Test.MirrorCtx.NamedForms,
     Aurora.UixWeb.Test.MirrorCtx.NamedHost},
    {Aurora.UixWeb.Test.MirrorAsh.Named, Aurora.UixWeb.Test.MirrorAsh.NamedForms,
     Aurora.UixWeb.Test.MirrorAsh.NamedHost}
  ]

  # The 0.1.x options form raises before Spark sees the module, so its error is not a DslError.
  @exceptions %{"the 0.1.x form fails compilation" => ArgumentError}

  @variant_views ~w(Default DefaultInline Groups Sections NestedSections Options NamedForms
                    NamedHost Named Included Manual SeparatedResources Separated Index IndexQuery
                    IndexWhere IndexCards IndexActions Form FormOptions Uploads Renderers
                    PredefinedRenderers RendererModuleTable RendererPrecedence Show ShowNavigator
                    ManyToOne ManyToOneQueries OneToMany OneToManyComponent OneToManyActions
                    OneToOne ManyToMany ManyToManyActions Embeds EmbedsExpanded Navigation
                    HooksIndex HooksForm HooksShow Components ComponentsPaired ComponentsHandled
                    Events Gettext PairedFormHost PairedIndexHost)a

  @single_views [
    MirrorCtx.ManualResource,
    Mirror.IncludedLayouts,
    MirrorAsh.Aggregates,
    MirrorCtx.ContextFunctions,
    Aurora.UixWeb.Test.AshActorViews
  ]

  @kinds [:form_component, :index_component, :index_live, :show_component]

  test "the module registry lists every generated module with its kind, fields and layout" do
    assert_registry()
  end

  test "module names come from module_name, index_live and the defaults" do
    assert_module_name()
    assert_index_live_name()
    assert_names()
  end

  test "generate:, the index component and the default artifacts decide which modules exist" do
    assert_generate_kinds()
    assert_index_component()
    assert_default_artifacts()
  end

  test "use: takes a layout and a component from another module" do
    assert_use_index_layout()

    for {named, forms, host} <- @named_views do
      assert_named_modules(named, forms, host)
    end
  end

  test "field, card and index declarations build their layout trees" do
    assert_field_in_block()
    assert_card_columns()
    assert_index_columns_without_block()
    assert_index_without_card()
  end

  test "the render tree carries node ids, field nodes, tab state and cards" do
    for mod <- [Generation.Ash.RenderTree, Generation.Ctx.RenderTree] do
      assert_render_tree(mod)
    end
  end

  test "a field with resource: keeps its nested preload" do
    assert_nested_preload()
  end

  test "an embedded resource generates no modules" do
    assert_ctx_embedded_resources()
    assert_ash_embedded_resources()
  end

  test "layout option sets list and read their options" do
    assert_option_sets()
  end

  test "the mounted views export a known kind and the fields of each generated module" do
    assert_views()
  end

  test "duplicate layouts and module names fail compilation" do
    assert_compile_errors([
      {"two layouts of the same type for a resource fail compilation",
       """
        auix_create_ui do
          edit_layout :product do
            inline [:reference]
          end

          edit_layout :product do
            inline [:name]
          end
        end
       """, ~r/:product has more than one form layout/},
      {"two resources on one schema need their own module names",
       """
        auix_resource_metadata :product_compact,
          context: Aurora.Uix.Test.MirrorCtx,
          schema: Aurora.Uix.Test.MirrorCtx.Product

        auix_create_ui()
       """, ~r/module name :product_form_component is taken more than once/},
      {"two names for one module fail compilation",
       """
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
       """, ~r/would be generated twice/}
    ])
  end

  test "use:, includes and imports reject what they cannot take" do
    assert_compile_errors([
      {"including a module without layouts fails compilation",
       """
        auix_create_ui include: Aurora.Uix.Test.MirrorCtx do
        end
       """, ~r/Aurora.Uix.Test.MirrorCtx has no layouts/},
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
       """, ~r/@auix_modules entry :reference_form is not a generated module/}
    ])
  end

  test "layout and field options that fail compilation" do
    assert_compile_errors([
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
      {"an unknown show_on fails compilation",
       """
        auix_create_ui do
          index_columns :product, [:name] do
            card show_on: :desktop
          end
        end
       """, ~r/show_on/}
    ])
  end

  test "layouts with an unknown resource, an unknown field or a misplaced container fail compilation" do
    assert_compile_errors([
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
       """, ~r/card takes no sections/}
    ])
  end

  test "option set declarations that fail compilation" do
    assert_compile_errors([
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
    ])
  end

  # A host application's modules compile after its dependencies, so the packaged library
  # compiles in another VM, with a configured template that does not exist yet.
  @tag :tmp_dir
  test "the packaged library compiles with a template defined in the host application",
       %{tmp_dir: tmp_dir} do
    exclude_patterns = Mix.Project.config()[:package][:exclude_patterns]

    files =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.reject(fn file -> Enum.any?(exclude_patterns, &Regex.match?(&1, file)) end)

    code_paths = :code.get_path() -- [String.to_charlist(Mix.Project.compile_path())]

    script = """
    Application.put_env(:aurora_uix, :template, Aurora.UixWeb.Test.HostTemplate)
    files = #{inspect(files, limit: :infinity)}

    case Kernel.ParallelCompiler.compile_to_path(files, #{inspect(tmp_dir)}, return_diagnostics: true) do
      {:ok, _modules, _diagnostics} -> :ok
      {:error, _errors, _diagnostics} -> System.halt(1)
    end
    """

    args = Enum.flat_map(code_paths, &["-pa", to_string(&1)]) ++ ["-e", script]
    {output, status} = System.cmd("elixir", args, stderr_to_stdout: true)

    assert status == 0, output
  end

  ## PRIVATE ##

  @spec assert_compile_errors([{binary(), binary(), Regex.t()}]) :: term()
  defp assert_compile_errors(cases) do
    for {label, body, regex} <- cases do
      exception = Map.get(@exceptions, label, DslError)

      raised =
        try do
          compile(body)
          nil
        rescue
          error -> error
        end

      assert is_exception(raised, exception),
             "#{label}: expected #{inspect(exception)}, got #{inspect(raised)}"

      assert Exception.message(raised) =~ regex,
             "#{label}: #{inspect(Exception.message(raised))} does not match #{inspect(regex)}"
    end
  end

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

  @spec assert_views() :: term()
  defp assert_views do
    for name <- @variant_views, backend <- [:ash, :ctx] do
      assert_registry_kinds(Mirror.sibling(backend, name), "#{name} on #{backend}")
    end

    for views <- @single_views, do: assert_registry_kinds(views, inspect(views))

    assert_manual_views()
    assert_included_views()
    assert_resource_only_views()
  end

  @spec assert_registry_kinds(module(), binary()) :: term()
  defp assert_registry_kinds(views, label) do
    for {name, {kind, fields}} <- signature(views).modules do
      assert kind in @kinds, "#{label}: #{name} has the kind #{inspect(kind)}"
      assert fields != [] or kind == :index_live, "#{label}: #{name} has no fields"
    end
  end

  @spec assert_manual_views() :: term()
  defp assert_manual_views do
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
      manual = backend |> Mirror.sibling(:Manual) |> signature()

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

    hand_built = signature(MirrorCtx.ManualResource)
    assert hand_built.resources == []
    assert hand_built.modules.product_form_component == product_form
    assert hand_built.modules.product_show_component == put_elem(product_form, 0, :show_component)
  end

  @spec assert_included_views() :: term()
  defp assert_included_views do
    layouts = [{Node.Form, :product}, {Node.Show, :product}]

    assert signature(Mirror.IncludedLayouts) ==
             %{resources: [], layouts: layouts, modules: %{}}

    for backend <- [:ash, :ctx] do
      included = backend |> Mirror.sibling(:Included) |> signature()
      assert included.layouts == layouts
      assert included.modules.product_form_component == {:form_component, [:name, :reference]}
      assert included.modules.product_show_component == {:show_component, [:name]}
    end
  end

  @spec assert_resource_only_views() :: term()
  defp assert_resource_only_views do
    for backend <- [:ash, :ctx] do
      assert backend |> Mirror.sibling(:SeparatedResources) |> signature() == %{
               resources: [
                 :product,
                 :product__contacts,
                 :product__packaging,
                 :product_transaction
               ],
               layouts: [],
               modules: %{}
             }

      assert backend |> Mirror.sibling(:NamedHost) |> signature() == %{
               resources: [],
               layouts: [{Node.Form, :product_location}],
               modules: %{}
             }
    end
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
    mod = Generation.CtxEmbedded

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
    mod = Generation.AshEmbedded

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

    options_set = Generation.OptionsSet

    assigns = %{auix: %{layout_type: :sample, layout_tree: %{options: [farewell: "bye"]}}}

    assert options_set.get(assigns, :greeting) == {:ok, "hello"}
    assert options_set.get(assigns, :farewell) == {:ok, "bye"}
    assert options_set.get(assigns, :unlisted) == {:not_found, :unlisted}

    label_option = fn label ->
      Form.get(
        %{auix: %{layout_type: :form, layout_tree: %{options: [save_action_label: label]}}},
        :save_action_label
      )
    end

    assert label_option.(fn -> "Store" end) == {:ok, "Store"}

    assert label_option.(fn %{auix: auix} -> "Store #{auix.layout_type}" end) ==
             {:ok, "Store form"}
  end

  @spec assert_field_in_block() :: term()
  defp assert_field_in_block do
    assert [%Node.Form{children: [%Node.Inline{children: [reference, location]}]}] =
             Generation.FieldInBlock.auix_layouts()

    assert %Node.Field{key: :reference, overrides: %{readonly: true}} = reference
    assert %Node.Field{key: :product_location_id, path: [:name]} = location
  end

  @spec assert_registry() :: term()
  defp assert_registry do
    mod = Generation.Registry
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
    mod = Generation.ModuleName

    form = mod.auix_module(:reference_form)
    assert form == Module.concat(mod, Product.ReferenceForm)
    assert form.auix_fields() == [:reference, :name]
    refute mod |> Module.concat(Product.FormComponent) |> Code.ensure_loaded?()
  end

  @spec assert_index_live_name() :: term()
  defp assert_index_live_name do
    mod = Generation.IndexLiveName

    assert mod.auix_module(:catalog) == Module.concat(mod, Product.Catalog)
    assert mod.auix_module(:catalog).auix_kind() == :index_live
    refute mod |> Module.concat(Product.Index) |> Code.ensure_loaded?()
  end

  @spec assert_generate_kinds() :: term()
  defp assert_generate_kinds do
    mod = Generation.GenerateComponents

    refute mod |> Module.concat(Product.Index) |> Code.ensure_loaded?()

    assert Enum.all?(mod.auix_modules(), fn {_name, module} ->
             module.auix_kind() != :index_live
           end)
  end

  @spec assert_index_component() :: term()
  defp assert_index_component do
    mod = Generation.Registry

    assert mod.auix_module(:product_index_component) == Module.concat(mod, Product.IndexComponent)
    assert mod.auix_module(:product_index_component).auix_kind() == :index_component

    named = Generation.NamedIndex

    assert named.auix_module(:index_compact) == Module.concat(named, Product.IndexCompact)

    assert named.auix_configurations().product.artifacts.index_component ==
             Module.concat(named, Product.IndexCompact)

    assert named.auix_module(:index_compact).auix_fields() == [:reference]
    refute named |> Module.concat(Product.IndexComponent) |> Code.ensure_loaded?()

    only = Generation.OnlyIndexComponent

    assert only |> Module.concat(Product.IndexComponent) |> Code.ensure_loaded?()
    refute only |> Module.concat(Product.Index) |> Code.ensure_loaded?()
    refute only |> Module.concat(Product.FormComponent) |> Code.ensure_loaded?()
    refute only |> Module.concat(Product.ShowComponent) |> Code.ensure_loaded?()
  end

  @spec assert_use_index_layout() :: term()
  defp assert_use_index_layout do
    mod = Generation.UseIndexLayout

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
    mod = Generation.CardColumns

    assert Enum.map(mod.auix_configurations().product.layout_trees.index.children, & &1.key) ==
             [:name, :reference, :msrp]
  end

  @spec assert_index_columns_without_block() :: term()
  defp assert_index_columns_without_block do
    with_options = Generation.IndexOptions

    assert [%Node.Index{options: [page_title: "Products"]}] = with_options.auix_layouts()

    pair_only = Generation.IndexPair

    assert [%Node.Index{children: [%Node.Field{key: :name, overrides: %{label: "Product"}}]}] =
             pair_only.auix_layouts()
  end

  @spec assert_index_without_card() :: term()
  defp assert_index_without_card do
    mod = Generation.IndexWithoutCard

    assert mod.auix_configurations().product.layout_trees.index.card == nil
  end

  @spec assert_nested_preload() :: term()
  defp assert_nested_preload do
    mod = Generation.NestedPreload

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
