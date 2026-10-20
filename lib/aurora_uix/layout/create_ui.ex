defmodule Aurora.Uix.Layout.CreateUI do
  @moduledoc """
  Spark DSL extension for the UI: `auix_create_ui`, `auix_create_layout` and the layouts they
  hold, available in any module that calls `use Aurora.Uix`.

  `auix_create_ui` generates the index, form and show LiveViews of the module's resources. A
  resource without a declared layout gets the default one.

  ## Example

  ```elixir
  defmodule MyAppWeb.Inventory.Views do
    use Aurora.Uix

    auix_resource_metadata :product, context: MyApp.Inventory, schema: MyApp.Product

    auix_create_ui renderers: %{checkbox: :toggle_switch} do
      index_columns :product, [:reference, name: [label: "Product"]], page_title: "Products"

      edit_layout :product, new_title: "New product" do
        group "Identification", [:reference, :name]

        sections do
          section "Prices", [:msrp, :rrp], default: true

          section "Details" do
            inline [:description]
            field :notes, readonly: true
          end
        end
      end

      show_layout :product do
        inline [:reference, :name, :description]
      end
    end
  end
  ```

  `auix_create_ui()` with no block generates the default layouts.

  ## Reusable layouts

  A module with `auix_create_layout` blocks and no `auix_create_ui` only exposes its layouts
  through `auix_layouts/0`. `auix_create_ui include: [MyAppWeb.ProductLayouts]` uses them; for
  one resource and layout type, the module's own layout replaces an included one.

  ## Layouts
  - `index_columns resource, fields, options` - the index columns and options. See
    `Aurora.Uix.Layout.Options.Index`; `order_by` and `where` set the listed entries.
  - `edit_layout resource, options do ... end` - the form layout. See
    `Aurora.Uix.Layout.Options.Form`.
  - `show_layout resource, options do ... end` - the show layout. See
    `Aurora.Uix.Layout.Options.Page`. Without it, the show view reuses the form layout.

  Every layout also takes the `add_/insert_/replace_/remove_*_action` options of its action
  groups (see `Aurora.Uix.Templates.Basic.Actions.Index`), `renderers:` (an `html_type =>
  renderer` table, see `Aurora.Uix.Renderers`) and its handler module (`handler_module:`,
  `edit_handler_module:` or `show_handler_module:`).

  ## Sub-layouts
  - `inline fields` / `inline do ... end` - side by side.
  - `stacked fields` / `stacked do ... end` - one below the other.
  - `group title, fields` / `group title do ... end` - framed under a title.
  - `sections do ... end` - tabs, holding only `section` entries.
  - `section label, fields, default: true` / `section label do ... end` - one tab.
  - `field key, options` - one field with options.

  A block's sub-layouts come first, then the listed fields. A field is an atom, a `{key, options}`
  pair or an association path such as `{:category_id, :name}`.

  ## `auix_create_ui` options

  #{Spark.Options.docs(Aurora.Uix.Layout.CreateUI.Dsl.ui_schema())}

  ## Field options

  The resource metadata field options, plus `order_by` and `where` for one-to-many fields and
  the action options of association fields.

  ## Key Features
  - Compile-time validation of fields and options, with the offending line.
  - Generates the LiveView modules, plus `auix_layouts/0`, `auix_configurations/0` and
    `auix_preloads/0`, in the declaring module.

  ## Key Constraints
  - Options and a `do` block go together only as `edit_layout :product, options do ... end`.
  - A field list holding only `key: options` pairs or association paths is read as options;
    write those fields with `field` in a block.
  - One `auix_create_ui` per module, and one layout per resource and layout type in it.
  """

  use Spark.Dsl.Extension,
    sections: [__MODULE__.Dsl.section()],
    transformers: [__MODULE__.GenerateUI]

  alias Aurora.Uix.BehaviourHelper
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.CreateUI.Call
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Layout.RenderTree
  alias Aurora.Uix.Parser
  alias Aurora.Uix.Renderers
  alias Aurora.Uix.Resource
  alias Aurora.Uix.Template
  alias Spark.Error.DslError

  @doc """
  Collects the layouts of the `auix_create_ui` and `auix_create_layout` calls of a module.

  The calls' layouts follow `included`. A later layout replaces an earlier one for the same
  resource and layout type, so the module's own layouts replace included ones.

  ## Parameters
  - `calls` ([Call.t()]) - The calls, in declaration order.
  - `included` ([Node.layout()]) - Layouts brought in with `include`, see `included_layouts/2`.
  - `module` (module()) - The declaring module, for error reporting.

  ## Returns
  `[Node.layout()]` - The layouts.
  """
  @spec collect_layouts([Call.t()], [Node.layout()], module()) :: [Node.layout()]
  def collect_layouts(calls, included, module) do
    Enum.reduce(calls, included, fn call, layouts ->
      Enum.each(call.children, &reject_duplicate(&1, call.children, module))
      replace_layouts(layouts, call.children)
    end)
  end

  @doc """
  Reads the layouts of the modules an `auix_create_ui` call includes.

  A later module's layout replaces an earlier one's for the same resource and layout type.

  ## Parameters
  - `modules` (module() | [module()] | nil) - The `include` option.
  - `module` (module()) - The declaring module, for error reporting.

  ## Returns
  `[Node.layout()]` - The included layouts, or raises `Spark.Error.DslError` when a module has
  no layouts.
  """
  @spec included_layouts(module() | [module()] | nil, module()) :: [Node.layout()]
  def included_layouts(modules, module) do
    modules
    |> List.wrap()
    |> Enum.reduce([], &replace_layouts(&2, module_layouts(&1, module)))
  end

  @doc """
  Returns the code defining `auix_layouts/0`, which returns a module's layouts as written.

  ## Parameters
  - `layouts` ([Node.layout()]) - The layouts.

  ## Returns
  `Macro.t()` - The function definition.
  """
  @spec layouts_code([Node.layout()]) :: Macro.t()
  def layouts_code(layouts) do
    quote do
      @doc false
      @spec auix_layouts() :: list()
      def auix_layouts do
        unquote(Macro.escape(layouts))
      end
    end
  end

  @doc """
  Returns the options of an `auix_create_ui` call.

  ## Parameters
  - `call` (Call.t()) - The `auix_create_ui` call.

  ## Returns
  `keyword()` - Its options, given positionally or as keywords.
  """
  @spec ui_opts(Call.t()) :: keyword()
  def ui_opts(%Call{} = call) do
    call
    |> Map.take([:renderers, :default_fields_layout, :include])
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> then(&Keyword.merge(call.layout_opts, &1))
  end

  @doc """
  Checks that every layout names a declared resource and fields that resource has.

  ## Parameters
  - `layouts` ([Node.layout()]) - The layouts.
  - `resources` (map()) - The resolved resources by name.
  - `module` (module()) - The declaring module, for error reporting.

  ## Returns
  `:ok`, or raises `Spark.Error.DslError`.
  """
  @spec validate_layouts([Node.layout()], map(), module()) :: :ok
  def validate_layouts(layouts, resources, module) do
    Enum.each(layouts, fn layout ->
      case Map.get(resources, layout.resource) do
        nil ->
          raise DslError,
            module: module,
            path: [:auix_create_ui, layout_type(layout), layout.resource],
            message: "unknown resource #{inspect(layout.resource)}"

        resource ->
          validate_fields(layout, resource, module)
      end
    end)
  end

  @doc """
  Returns the code generating the UI of a module.

  ## Parameters
  - `module` (module()) - The declaring module.
  - `declared_layouts` ([Node.layout()]) - The layouts.
  - `resources` (map()) - The resolved resources by name.
  - `opts` (keyword()) - The `auix_create_ui` options.

  ## Returns
  `Macro.t()` - The generated LiveView modules and `auix_layouts/0`, `auix_configurations/0` and
  `auix_preloads/0`.
  """
  @spec ui_code(module(), [Node.layout()], map(), keyword()) :: Macro.t()
  def ui_code(module, declared_layouts, resources, opts) do
    configurations =
      resources
      |> Map.new(fn {name, resource} -> {name, Resource.resolve(resource)} end)
      |> filter_resources(opts[:for])
      |> Enum.reduce(
        [],
        &[build_configurations(module, &1, declared_layouts, opts) | &2]
      )
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    resource_preloads = extract_resource_preloads(configurations)

    preload_configurations =
      configurations
      |> Enum.reduce([], &[build_resource_preload_option(&1, resource_preloads) | &2])
      |> Map.new()

    modules =
      build_layouts(preload_configurations, module)

    quote do
      unquote(modules)

      unquote(layouts_code(declared_layouts))

      @doc false
      @spec auix_configurations() :: map()
      def auix_configurations do
        unquote(Macro.escape(preload_configurations))
      end

      @doc false
      @spec auix_preloads() :: map()
      def auix_preloads do
        unquote(Macro.escape(resource_preloads))
      end
    end
  end

  ## PRIVATE

  @spec reject_duplicate(Node.layout(), [Node.layout()], module()) :: :ok
  defp reject_duplicate(layout, layouts, module) do
    if Enum.count(layouts, &same_layout?(&1, layout)) > 1 do
      raise DslError,
        module: module,
        path: [:auix_create_ui, layout_type(layout), layout.resource],
        message:
          "#{inspect(layout.resource)} has more than one #{layout_type(layout)} layout; declare it once"
    end

    :ok
  end

  @spec replace_layouts([Node.layout()], [Node.layout()]) :: [Node.layout()]
  defp replace_layouts(layouts, new_layouts) do
    layouts
    |> Enum.reject(fn layout -> Enum.any?(new_layouts, &same_layout?(&1, layout)) end)
    |> Enum.concat(new_layouts)
  end

  @spec module_layouts(module(), module()) :: [Node.layout()]
  defp module_layouts(included, module) do
    if match?({:module, _}, Code.ensure_compiled(included)) and
         function_exported?(included, :auix_layouts, 0) do
      included.auix_layouts()
    else
      raise DslError,
        module: module,
        path: [:auix_create_ui, :include],
        message:
          "#{inspect(included)} has no layouts; include modules that declare auix_create_layout or auix_create_ui"
    end
  end

  @spec same_layout?(Node.layout(), Node.layout()) :: boolean()
  defp same_layout?(layout, other),
    do: layout.__struct__ == other.__struct__ and layout.resource == other.resource

  @spec validate_fields(Node.layout(), Resource.t(), module()) :: :ok
  defp validate_fields(layout, resource, module) do
    unknown_fields =
      layout |> Node.fields() |> Enum.reject(&Map.has_key?(resource.fields, &1.key))

    case unknown_fields do
      [] ->
        :ok

      unknown ->
        raise DslError,
          module: module,
          path: [:auix_create_ui, layout_type(layout), layout.resource],
          message:
            "unknown fields #{inspect(Enum.map(unknown, & &1.key))} for resource #{inspect(resource.name)}"
    end
  end

  # Filters resource configurations based on the :for option.
  @spec filter_resources(map(), nil | atom() | list()) :: map()
  defp filter_resources(resource_configs, nil), do: resource_configs

  defp filter_resources(resource_configs, for) when is_atom(for) do
    Enum.filter(resource_configs, fn {key, _value} -> key == for end)
  end

  defp filter_resources(resource_configs, for) when is_list(for) do
    Enum.filter(resource_configs, fn {key, _value} -> key in for end)
  end

  # Builds the layouts for the given resource configurations.
  @spec build_layouts(map(), module()) :: [Macro.t()]
  defp build_layouts(preload_configurations, caller) do
    Enum.reduce(
      preload_configurations,
      [],
      &[build_resource_layouts(&1, preload_configurations, caller) | &2]
    )
  end

  # Builds the configuration for a single resource.
  @spec build_configurations(module(), {atom(), map()}, list(), keyword()) :: map() | nil
  defp build_configurations(
         caller,
         {resource_config_name, resource_config},
         declared_layouts,
         opts
       ) do
    resource_module = Map.get(resource_config, :schema)

    if is_nil(resource_module) do
      nil
    else
      parsed_opts = Parser.parse(resource_config, opts)

      template =
        caller
        |> Module.get_attribute(:auix_template)
        |> BehaviourHelper.validate(Template)

      layout_tags = Module.get_attribute(caller, :auix_layout_tags)

      layouts =
        declared_layouts
        |> Enum.filter(&(&1.resource == resource_config_name))
        |> Map.new(&{layout_type(&1), &1})
        |> put_missing_show()

      layout_trees =
        Map.new(layout_tags, fn tag ->
          {tag, RenderTree.build(Map.get(layouts, tag), tag, resource_config, opts)}
        end)

      html_type_renderers =
        Map.new(layout_trees, fn {tag, layout_tree} ->
          {tag,
           [
             Renderers.validate_table!("#{tag} layout renderers:", layout_tree.renderers || %{}),
             Renderers.validate_table!(
               "auix_create_ui renderers:",
               Keyword.get(opts, :renderers, %{})
             ),
             Renderers.validate_table!(
               "auix_resource_metadata renderers:",
               resource_config.renderers
             ),
             Renderers.validate_table!(
               "use Aurora.Uix, renderers:",
               Module.get_attribute(caller, :auix_html_type_renderers)
             )
           ]}
        end)

      {resource_config_name,
       %{
         resource_config_name: resource_config_name,
         resource_config: resource_config,
         layout_tags: layout_tags,
         parsed_opts: parsed_opts,
         layout_trees: layout_trees,
         template: template,
         html_type_renderers: html_type_renderers
       }}
    end
  end

  @spec layout_type(Node.layout()) :: atom()
  defp layout_type(%Node.Index{}), do: :index
  defp layout_type(%Node.Form{}), do: :form
  defp layout_type(%Node.Show{}), do: :show

  # Without a show layout, the show view reuses the form layout and its `show_handler_module`.
  @spec put_missing_show(map()) :: map()
  defp put_missing_show(%{show: _show} = layouts), do: layouts

  defp put_missing_show(%{form: form} = layouts) do
    form
    |> Map.from_struct()
    |> Map.put(:handler_module, Keyword.get(form.options, :show_handler_module))
    |> then(&struct(Node.Show, &1))
    |> then(&Map.put(layouts, :show, &1))
  end

  defp put_missing_show(layouts), do: layouts

  # Builds the resource-specific layouts.
  @spec build_resource_layouts(tuple(), map(), module()) :: list()
  defp build_resource_layouts(
         {_resource_config_name,
          %{
            resource_config: resource_config,
            layout_tags: layout_tags,
            parsed_opts: parsed_opts,
            layout_trees: layout_trees,
            template: template
          }},
         configurations,
         caller
       ) do
    web = find_web_module(caller)

    resource_module = Map.get(resource_config, :schema)

    modules = %{
      caller: caller,
      module: resource_module,
      web: web,
      context: resource_config.context
    }

    Enum.each(modules, fn {_, module} -> Code.ensure_compiled(module) end)

    Enum.reduce(
      layout_tags,
      [],
      &[
        generate_module(
          %{modules: modules, layout_type: &1, layout_tree: Map.fetch!(layout_trees, &1)},
          configurations,
          parsed_opts,
          template
        )
        | &2
      ]
    )
  end

  defp build_resource_layouts(%{}, _configurations, _caller), do: []

  # Generates a single UI module.
  @spec generate_module(map(), map(), map(), module()) :: Macro.t()
  defp generate_module(layout, configurations, parsed_opts, template) do
    parsed_opts
    |> Map.put(:configurations, configurations)
    |> Map.put(:modules, layout.modules)
    |> Map.put(:layout_tree, layout.layout_tree)
    |> Map.put(:resource_name, layout.layout_tree.resource)
    |> Map.put(:layout_type, layout.layout_type)
    |> then(&template.generate_module(&1))
  end

  # Extracts resource preloads from configurations.
  @spec extract_resource_preloads(map()) :: map()
  defp extract_resource_preloads(configurations) do
    fields_by_resource =
      Enum.map(configurations, fn {resource_name, %{layout_trees: layout_trees}} ->
        preload_fields =
          layout_trees
          |> Map.take([:index, :form, :show])
          |> Map.values()
          |> Node.fields()
          |> Enum.map(& &1.field)
          |> Enum.filter(&preload?/1)
          |> Enum.uniq_by(& &1.key)

        {resource_name, preload_fields}
      end)

    associations =
      fields_by_resource
      |> Enum.map(fn {resource_name, resource_fields} ->
        resource_fields
        |> Enum.reject(&generated?/1)
        |> Enum.map(&{&1.key, &1.resource})
        |> then(&{resource_name, &1})
      end)
      |> expand_associations()

    generated =
      Map.new(fields_by_resource, fn {resource_name, resource_fields} ->
        resource_fields
        |> Enum.filter(&generated?/1)
        |> Enum.map(& &1.key)
        |> then(&{resource_name, &1})
      end)

    Map.merge(associations, generated, fn _resource_name,
                                          association_preloads,
                                          generated_fields ->
      generated_fields ++ association_preloads
    end)
  end

  @spec preload?(Field.t()) :: boolean()
  defp preload?(%Field{type: type})
       when type in [
              :one_to_many_association,
              :many_to_one_association,
              :one_to_one_association,
              :many_to_many_association
            ],
       do: true

  defp preload?(field), do: generated?(field)

  @spec generated?(Field.t()) :: boolean()
  defp generated?(%Field{generated?: true}), do: true
  defp generated?(%Field{data: data}), do: match?(%{generated: true}, data)

  # Expands nested associations for preloading.
  @spec expand_associations(list()) :: map()
  defp expand_associations(associations) do
    expanded_associations = do_expand_associations(associations)

    associations
    |> Enum.map(fn {resource_name, children} ->
      children
      |> Enum.map(fn
        {field, ^resource_name} ->
          {field, []}

        {field, related_resource} ->
          expanded_associations
          |> Map.get(related_resource, [])
          |> then(&{field, &1})
      end)
      |> then(&{resource_name, &1})
    end)
    |> Map.new()
  end

  # Parses associations into a map.
  @spec do_expand_associations(list()) :: map()
  defp do_expand_associations(associations) do
    associations
    |> Enum.map(fn {resource, children} ->
      children
      |> Enum.map(&elem(&1, 0))
      |> then(&{resource, &1})
    end)
    |> Map.new()
  end

  # Builds the resource preload option.
  @spec build_resource_preload_option(tuple(), map()) :: tuple()
  defp build_resource_preload_option(
         {resource_config_name, %{parsed_opts: parsed_opts} = configuration},
         resource_preloads
       ) do
    resource_preloads
    |> Map.get(resource_config_name, [])
    |> then(&Map.put(parsed_opts, :preload, &1))
    |> then(&Map.put(configuration, :parsed_opts, &1))
    |> then(&{resource_config_name, &1})
  end

  # Finds the web module from the caller module.
  @spec find_web_module(module()) :: module() | nil
  defp find_web_module(caller) do
    caller
    |> Module.split()
    |> Enum.reverse()
    |> check_web_module()
  end

  # Checks if a module is a web module.
  @spec check_web_module(list()) :: module() | nil
  defp check_web_module([]), do: nil

  defp check_web_module([_ | module_paths]) do
    module_paths
    |> Enum.reverse()
    |> Module.concat()
    |> Code.ensure_compiled()
    |> extract_web_module(module_paths)
  end

  # Extracts the web module.
  @spec extract_web_module(tuple(), list()) :: module() | nil
  defp extract_web_module({:module, module}, _module_paths), do: module

  defp extract_web_module(_, module_paths), do: check_web_module(module_paths)
end
