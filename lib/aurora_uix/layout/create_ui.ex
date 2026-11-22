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
  - `index_columns resource, fields, options do card ... end` - the index columns and options,
    and the card of the card view. See `Aurora.Uix.Layout.Options.Index` and
    `Aurora.Uix.Layout.Node.Card`; `order_by` and `where` set the listed entries.
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

  ## Generated modules

  Every generated module is a named artifact. By default the LiveView of a resource is named
  `:<schema>_index`, and its components `:<schema>_index_component`, `:<schema>_form_component`
  and `:<schema>_show_component`, where `<schema>` is the underscored last segment of the schema
  module. `module_name:` on `index_columns`, `edit_layout` and `show_layout` names the generated
  component, and is the last segment of the module as given. An
  `index_live resource, module_name: name` line names the LiveView. `component_handler_module:`
  on `index_columns` sets the handler of the index component.

  `index_columns resource, use: name`, `edit_layout resource, use: name` (or `show_layout`) takes
  a component instead of generating one. `name` is a name of the registry, or a generated module itself: the value
  `auix_module/1` of another module returns. It checks that the name exists, that it names a
  component of the layout's kind, and that the resource has every field its layout places. A
  module imports modules of another one with
  `@auix_modules %{name => OtherViews.auix_module(:their_name)}`; `auix_modules/0` maps the
  names of the generated and the imported modules to the modules, and `auix_module/1` returns
  one of them by name.

  Every generated module exposes `auix_kind/0`, `auix_fields/0` (the keys of the fields its
  layout places) and `auix_layout/0` (the layout it was generated from).

  `generate:` chooses the kinds of module to generate (`:index_live`, `:index_component`,
  `:form_component`, `:show_component`). `generate: []` with `use:` lines suits a module that only declares
  pairings, a LiveView written by hand included.

  ## Key Features
  - Compile-time validation of fields and options, with the offending line.
  - Generates the LiveView modules, plus `auix_layouts/0`, `auix_configurations/0` and
    `auix_preloads/0`, in the declaring module.

  ## Key Constraints
  - Options and a `do` block go together only as `edit_layout :product, options do ... end`.
  - A field list holding only `key: options` pairs or association paths is read as options;
    write those fields with `field` in a block.
  - One `auix_create_ui` per module, and one layout per resource and layout type in it.
  - Two generated modules with one name, or two names for one module, do not compile.
  - A resource on an embedded-only schema generates no modules, whatever its name; neither does
    a resource the library creates for an embedded field.
  - Two modules that import from each other do not compile.
  """

  use Spark.Dsl.Extension,
    sections: [__MODULE__.Dsl.section()],
    transformers: [__MODULE__.GenerateUI]

  alias Aurora.Uix.Action
  alias Aurora.Uix.BehaviourHelper
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.CreateUI.Call
  alias Aurora.Uix.Layout.CreateUI.IndexLive
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Layout.RenderTree
  alias Aurora.Uix.Parser
  alias Aurora.Uix.Renderers
  alias Aurora.Uix.Resource
  alias Aurora.Uix.Template
  alias Spark.Error.DslError

  @type kind() :: :index_live | :index_component | :form_component | :show_component

  @component_kinds [index: :index_component, form: :form_component, show: :show_component]

  @collision_hint "set module_name: on the layout of one of them, reuse a module with use:, or rename a live view with an index_live line"

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
  Returns the kinds of module `auix_create_ui` generates.

  ## Parameters
  None.

  ## Returns
  `[kind()]` - `[:index_live, :index_component, :form_component, :show_component]`.
  """
  @spec kinds() :: [kind()]
  def kinds, do: [:index_live, :index_component, :form_component, :show_component]

  @doc """
  Returns the schema hint: the last segment of a schema module, the middle segment of every
  generated module name.

  ## Parameters
  - `schema` (module()) - The schema module of a resource.

  ## Returns
  `binary()` - The hint, e.g. `"Product"`.
  """
  @spec schema_hint(module()) :: binary()
  def schema_hint(schema), do: schema |> Module.split() |> List.last()

  @doc """
  Builds the name of a generated module.

  ## Parameters
  - `caller` (module()) - The declaring module.
  - `schema_hint` (binary()) - The schema hint, see `schema_hint/1`.
  - `name` (atom()) - The last segment, camelized as given: no suffix is added.

  ## Returns
  `module()` - e.g. `MyApp.Views.Product.IndexCompact`.
  """
  @spec module_name(module(), binary(), atom()) :: module()
  def module_name(caller, schema_hint, name),
    do: Module.concat([caller, schema_hint, name |> Atom.to_string() |> Macro.camelize()])

  @doc """
  Returns the default registry name of a generated module.

  A default name is a new atom that no source spells, such as `:product_form_component`, so
  `String.to_existing_atom/1` cannot build it. It is built at compile time from a schema module
  name, as `Aurora.Uix.Layout.Helpers.field_embedded_resource/2` builds the name of an embedded
  resource. The call runs only while the declaring module compiles, on the last segment of a
  schema module the host declared, and creates at most four atoms per resource.

  ## Parameters
  - `schema_hint` (binary()) - The schema hint, see `schema_hint/1`.
  - `kind` (kind()) - The kind of module.

  ## Returns
  `atom()` - `:<schema>_index` for a LiveView, `:<schema>_<kind>` for a component.
  """
  @spec default_name(binary(), kind()) :: atom()
  def default_name(schema_hint, :index_live),
    do: String.to_atom("#{Macro.underscore(schema_hint)}_index")

  def default_name(schema_hint, kind),
    do: String.to_atom("#{Macro.underscore(schema_hint)}_#{kind}")

  @doc """
  Returns the code defining `auix_modules/0` and `auix_module/1`.

  ## Parameters
  - `modules` (%{atom() => module()}) - The registry: generated and imported modules by name.

  ## Returns
  `Macro.t()` - The function definitions.
  """
  @spec modules_code(%{atom() => module()}) :: Macro.t()
  def modules_code(modules) do
    module_functions = Enum.map(modules, &module_function/1)

    quote do
      @doc """
      Gets the generated and imported modules by name.
      """
      @spec auix_modules() :: %{atom() => module()}
      def auix_modules do
        unquote(Macro.escape(modules))
      end

      unquote(module_functions)

      def auix_module(_), do: nil
    end
  end

  @doc """
  Returns the code every generated module evaluates in its body: `auix_kind/0`, `auix_fields/0`
  and `auix_layout/0`.

  ## Parameters
  - `kind` (kind()) - The kind of the module.
  - `layout` (Node.layout() | nil) - The layout the module is generated from, as written, with
    `resource: nil`; `nil` for the index LiveView.

  ## Returns
  `Macro.t()` - The function definitions.
  """
  @spec module_code(kind(), Node.layout() | nil) :: Macro.t()
  def module_code(kind, layout) do
    fields = layout |> List.wrap() |> Node.fields() |> Enum.map(& &1.key) |> Enum.uniq()

    quote do
      @doc false
      @spec auix_kind() :: atom()
      def auix_kind, do: unquote(kind)

      @doc false
      @spec auix_fields() :: [atom()]
      def auix_fields, do: unquote(fields)

      @doc false
      @spec auix_layout() :: struct() | nil
      def auix_layout, do: unquote(Macro.escape(layout))
    end
  end

  @doc """
  Fills the `artifacts`, `used`, `generate` and `exposed_layouts` keys of the options of a
  generator, each one only when the options lack it.

  `ui_code/5` fills the four keys for every module `auix_create_ui` generates, and those options
  are returned as they are. Options built by hand take the module names the generators built
  before named artifacts.

  ## Parameters
  - `options` (map()) - The options of a generator: `layout_type`, `layout_tree`,
    `modules.caller` and `module_name` (the schema hint).

  ## Returns
  `map()` - The options with the four keys.
  """
  @spec put_defaults(map()) :: map()
  def put_defaults(options) do
    options
    |> Map.put_new_lazy(:artifacts, fn -> default_artifacts(options) end)
    |> Map.put_new(:used, [])
    |> Map.put_new(:generate, kinds())
    |> Map.put_new_lazy(:exposed_layouts, fn -> default_exposed_layouts(options) end)
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
    |> Map.take([:renderers, :default_fields_layout, :include, :generate])
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
          :ok = validate_fields(layout, resource, module)
          validate_action_icons(layout, resource, module)
      end
    end)
  end

  @doc """
  Checks the names of the modules `auix_create_ui` generates and the modules a module imports.

  ## Parameters
  - `module` (module()) - The declaring module, for error reporting.
  - `layouts` ([Node.layout()]) - The declared layouts.
  - `resources` (map()) - The resources by name.
  - `opts` (keyword()) - The `auix_create_ui` options.
  - `naming` (map()) - `%{index_lives: [IndexLive.t()], imported: %{atom() => module()}}`: the
    `index_live` lines of the call and the modules the module imports with `@auix_modules`.

  ## Returns
  `:ok`, or raises `Spark.Error.DslError` on an invalid import, an invalid `index_live` line, a
  name collision or a live view without its components.
  """
  @spec validate_modules(module(), [Node.layout()], map(), keyword(), map()) :: :ok
  def validate_modules(module, layouts, resources, opts, naming) do
    :ok = validate_imported(naming.imported, module)
    :ok = validate_index_lives(module, resources, opts, naming)

    names = module_names(module, layouts, resources, opts, naming)
    :ok = validate_collisions(names, naming.imported, module)
    validate_live_views(names, layouts, module)
  end

  @doc """
  Returns the code generating the UI of a module.

  ## Parameters
  - `module` (module()) - The declaring module.
  - `declared_layouts` ([Node.layout()]) - The layouts.
  - `resources` (map()) - The resolved resources by name.
  - `opts` (keyword()) - The `auix_create_ui` options.
  - `naming` (map()) - The map `validate_modules/5` takes: `index_lives`, the `index_live` lines
    of the call, and `imported`, the modules the module imports with `@auix_modules`.

  ## Returns
  `Macro.t()` - The generated LiveView modules and `auix_layouts/0`, `auix_configurations/0`,
  `auix_preloads/0`, `auix_modules/0` and `auix_module/1`.
  """
  @spec ui_code(module(), [Node.layout()], map(), keyword(), map()) :: Macro.t()
  def ui_code(module, declared_layouts, resources, opts, naming) do
    resources =
      resources
      |> Map.new(fn {name, resource} -> {name, Resource.resolve(resource)} end)
      |> filter_resources(opts[:for])
      |> Map.new()

    names = module_names(module, declared_layouts, resources, opts, naming)

    layouts =
      used_layouts(declared_layouts, %{
        caller: module,
        resources: resources,
        names: names,
        imported: naming.imported,
        opts: opts
      })

    configurations =
      resources
      |> Enum.reduce(
        [],
        &[build_configurations(module, &1, layouts, names, opts) | &2]
      )
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    registry =
      Map.merge(
        naming.imported,
        Map.new(names, fn {name, _kind, _resource_name, generated} -> {name, generated} end)
      )

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

      unquote(modules_code(registry))

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

  # A field's `action_icons:` keys are the default actions of its own type, which the layout DSL
  # does not know when it reads the field.
  @spec validate_action_icons(Node.layout(), Resource.t(), module()) :: :ok
  defp validate_action_icons(layout, resource, module) do
    layout
    |> Node.fields()
    |> Enum.reject(&(&1.action_icons == []))
    |> Enum.each(&validate_field_action_icons(&1, resource, layout, module))
  end

  @spec validate_field_action_icons(Node.Field.t(), Resource.t(), Node.layout(), module()) :: :ok
  defp validate_field_action_icons(field_node, resource, layout, module) do
    group =
      resource.fields |> Map.fetch!(field_node.key) |> Map.fetch!(:type) |> field_action_group()

    schema = [action_icons: [type: {:keyword_list, Action.icons_schema(group)}]]

    case Spark.Options.validate([action_icons: field_node.action_icons], schema) do
      {:ok, _validated} ->
        :ok

      {:error, error} ->
        raise DslError,
          module: module,
          path: [:auix_create_ui, layout_type(layout), layout.resource],
          message: "field #{inspect(field_node.key)}: #{Exception.message(error)}"
    end
  end

  @spec field_action_group(atom()) :: atom()
  defp field_action_group(:one_to_many_association), do: :one_to_many
  defp field_action_group(:embeds_many), do: :embeds_many
  defp field_action_group(_type), do: :none

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

  @spec resource_layouts([Node.layout()], atom()) :: map()
  defp resource_layouts(declared_layouts, name) do
    declared_layouts
    |> Enum.filter(&(&1.resource == name))
    |> Map.new(&{layout_type(&1), &1})
  end

  # Builds the configuration for a single resource.
  @spec build_configurations(module(), {atom(), map()}, [Node.layout()], list(), keyword()) ::
          map() | nil
  defp build_configurations(
         caller,
         {resource_config_name, resource_config},
         declared_layouts,
         names,
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

      layouts = declared_layouts |> resource_layouts(resource_config_name) |> put_missing_show()

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
       Map.merge(
         %{
           resource_config_name: resource_config_name,
           resource_config: resource_config,
           layout_tags: layout_tags,
           parsed_opts: parsed_opts,
           layout_trees: layout_trees,
           template: template,
           html_type_renderers: html_type_renderers,
           modules: %{
             caller: caller,
             module: resource_module,
             web: find_web_module(caller),
             context: resource_config.context
           }
         },
         resource_modules({resource_config_name, resource_config}, layouts, names, opts)
       )}
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
    |> Map.merge(%{
      handler_module: Keyword.get(form.options, :show_handler_module),
      module_name: nil,
      use: nil
    })
    |> then(&struct(Node.Show, &1))
    |> then(&Map.put(layouts, :show, &1))
  end

  defp put_missing_show(layouts), do: layouts

  @spec module_function({atom(), module()}) :: Macro.t()
  defp module_function({name, module}) do
    quote do
      @doc """
      Gets a generated or imported module by name.
      """
      @spec auix_module(atom()) :: module() | nil
      def auix_module(unquote(name)), do: unquote(module)
    end
  end

  @spec default_artifacts(map()) :: %{kind() => module()}
  defp default_artifacts(options) do
    caller = options.modules.caller
    hint = options.module_name

    %{
      index_live: module_name(caller, hint, :index),
      index_component: module_name(caller, hint, :index_component),
      form_component: module_name(caller, hint, :form_component),
      show_component: module_name(caller, hint, :show_component)
    }
  end

  @spec default_exposed_layouts(map()) :: %{kind() => Node.layout()}
  defp default_exposed_layouts(%{layout_type: :form} = options),
    do: %{form_component: %{options.layout_tree | resource: nil}}

  defp default_exposed_layouts(%{layout_type: :show} = options),
    do: %{show_component: %{options.layout_tree | resource: nil}}

  defp default_exposed_layouts(%{layout_type: :index} = options),
    do: %{index_component: %{options.layout_tree | resource: nil}}

  defp default_exposed_layouts(_options), do: %{}

  @spec raise_naming_error(module(), binary()) :: no_return()
  defp raise_naming_error(module, message),
    do: raise(DslError, module: module, path: [:auix_create_ui], message: message)

  # The resources `auix_create_ui` generates modules for, by name.
  @spec targets(map(), keyword()) :: [{atom(), Resource.t()}]
  defp targets(resources, opts) do
    resources
    |> filter_resources(opts[:for])
    |> Enum.filter(fn {_name, resource} -> target?(resource) end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  @spec target?(Resource.t()) :: boolean()
  defp target?(resource), do: resource.schema != nil and not resource.embedded?

  # `Code.ensure_compiled/1` waits for a module that is still compiling.
  @spec generated_module?(term()) :: boolean()
  defp generated_module?(module) when is_atom(module) and not is_nil(module),
    do:
      match?({:module, _}, Code.ensure_compiled(module)) and
        function_exported?(module, :auix_kind, 0)

  defp generated_module?(_module), do: false

  @spec using?(Node.layout() | nil) :: boolean()
  defp using?(nil), do: false
  defp using?(%{use: nil}), do: false
  defp using?(_layout), do: true

  @spec layout_module_name(Node.layout() | nil) :: atom() | nil
  defp layout_module_name(nil), do: nil
  defp layout_module_name(layout), do: layout.module_name

  @spec validate_imported(map(), module()) :: :ok
  defp validate_imported(imported, module) do
    Enum.each(imported, fn {name, imported_module} ->
      if not generated_module?(imported_module),
        do:
          raise_naming_error(
            module,
            "@auix_modules entry #{inspect(name)} is not a generated module; take it from auix_module/1"
          )
    end)
  end

  @spec validate_index_lives(module(), map(), keyword(), map()) :: :ok
  defp validate_index_lives(module, resources, opts, naming) do
    target_names = resources |> targets(opts) |> Enum.map(&elem(&1, 0))
    generate = Keyword.get(opts, :generate, kinds())

    _seen =
      Enum.reduce(naming.index_lives, [], fn line, seen ->
        cond do
          line.resource not in target_names ->
            raise_naming_error(module, "unknown resource #{inspect(line.resource)}")

          line.resource in seen ->
            raise_naming_error(
              module,
              "#{inspect(line.resource)} has more than one index_live line"
            )

          :index_live not in generate ->
            raise_naming_error(
              module,
              "index_live #{inspect(line.resource)} needs :index_live in generate:"
            )

          true ->
            [line.resource | seen]
        end
      end)

    :ok
  end

  # The names of the modules this module generates: `{name, kind, resource_name, module}`.
  @spec module_names(module(), [Node.layout()], map(), keyword(), map()) ::
          [{atom(), kind(), atom(), module()}]
  defp module_names(module, layouts, resources, opts, naming) do
    generate = Keyword.get(opts, :generate, kinds())

    resources
    |> targets(opts)
    |> Enum.flat_map(fn {resource_name, resource} ->
      hint = schema_hint(resource.schema)
      declared = resource_layouts(layouts, resource_name)

      components =
        @component_kinds
        |> Enum.filter(fn {layout_type, kind} ->
          kind in generate and not using?(Map.get(declared, layout_type))
        end)
        |> Enum.map(fn {layout_type, kind} ->
          given = declared |> Map.get(layout_type) |> layout_module_name()

          {given || default_name(hint, kind), kind, resource_name,
           module_name(module, hint, given || kind)}
        end)

      components ++ index_live_names(module, {resource_name, hint}, naming.index_lives, generate)
    end)
  end

  @spec index_live_names(module(), {atom(), binary()}, [IndexLive.t()], [kind()]) ::
          [{atom(), kind(), atom(), module()}]
  defp index_live_names(module, {resource_name, hint}, index_lives, generate) do
    if :index_live in generate do
      given =
        index_lives
        |> Enum.find(&(&1.resource == resource_name))
        |> layout_module_name()

      [
        {given || default_name(hint, :index_live), :index_live, resource_name,
         module_name(module, hint, given || :index)}
      ]
    else
      []
    end
  end

  @spec validate_collisions(list(), map(), module()) :: :ok
  defp validate_collisions(names, imported, module) do
    by_name = Enum.group_by(names, &elem(&1, 0))

    by_name
    |> Map.keys()
    |> Enum.sort()
    |> Enum.each(&validate_name(&1, Map.fetch!(by_name, &1), imported, module))

    _seen =
      names
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.reduce(%{}, &validate_module(&1, &2, module))

    :ok
  end

  @spec validate_name(atom(), list(), map(), module()) :: :ok
  defp validate_name(name, rows, imported, module) do
    owners = Enum.map(rows, &inspect(elem(&1, 2)))
    imported? = Map.has_key?(imported, name)

    if length(owners) > 1 or imported? do
      owners_text =
        if imported?,
          do: Enum.join(owners, ", ") <> ", @auix_modules",
          else: Enum.join(owners, ", ")

      raise_naming_error(
        module,
        "module name #{inspect(name)} is taken more than once (#{owners_text}); #{@collision_hint}"
      )
    end

    :ok
  end

  @spec validate_module(tuple(), map(), module()) :: map()
  defp validate_module({name, _kind, _resource_name, generated}, seen, module) do
    case Map.fetch(seen, generated) do
      {:ok, other_name} ->
        raise_naming_error(
          module,
          "#{inspect(generated)} would be generated twice, as #{inspect(other_name)} and #{inspect(name)}; #{@collision_hint}"
        )

      :error ->
        Map.put(seen, generated, name)
    end
  end

  @spec validate_live_views(list(), [Node.layout()], module()) :: :ok
  defp validate_live_views(names, layouts, module) do
    names
    |> Enum.filter(fn {_name, kind, _resource_name, _module} -> kind == :index_live end)
    |> Enum.each(fn {_name, _kind, resource_name, _module} ->
      declared = resource_layouts(layouts, resource_name)

      complete? =
        @component_kinds
        |> Keyword.take([:form, :show])
        |> Enum.all?(fn {layout_type, kind} ->
          using?(Map.get(declared, layout_type)) or
            Enum.any?(names, &match?({_name, ^kind, ^resource_name, _module}, &1))
        end)

      if not complete?,
        do:
          raise_naming_error(
            module,
            "the live view of #{inspect(resource_name)} needs a form component and a show component; add :form_component and :show_component to generate:, or name them with use:"
          )
    end)
  end

  # Replaces every `use:` layout by the layout of the component it names, bound to the resource
  # of the line. Indexes go first, then forms: a missing show layout is a copy of the form.
  @spec used_layouts([Node.layout()], map()) :: [Node.layout()]
  defp used_layouts(layouts, context) do
    Enum.reduce(@component_kinds, layouts, fn component_kind, layouts ->
      Enum.map(layouts, &used_layout(&1, component_kind, layouts, context))
    end)
  end

  @spec used_layout(Node.layout(), {atom(), kind()}, [Node.layout()], map()) :: Node.layout()
  defp used_layout(%{use: nil} = layout, _component_kind, _layouts, _context), do: layout

  defp used_layout(%{use: name} = layout, {layout_type, _kind} = component_kind, layouts, context) do
    case {layout_type(layout), Map.fetch(context.resources, layout.resource)} do
      {^layout_type, {:ok, resource}} ->
        component =
          used_component(name, component_kind, {layout.resource, resource}, layouts, context)

        %{component.layout | resource: layout.resource, module_name: nil, use: component.module}

      _other ->
        layout
    end
  end

  defp used_layout(layout, _component_kind, _layouts, _context), do: layout

  @spec used_component(atom(), {atom(), kind()}, {atom(), Resource.t()}, [Node.layout()], map()) ::
          map()
  defp used_component(name, {layout_type, kind}, {resource_name, resource}, layouts, context) do
    if not target?(resource),
      do:
        raise_naming_error(
          context.caller,
          "use: is not available for #{inspect(resource_name)}, an embedded resource"
        )

    component =
      case find_component(name, layouts, context) do
        %{kind: ^kind} = component ->
          component

        nil ->
          raise_naming_error(
            context.caller,
            "unknown module #{inspect(name)} in use:; declare it with module_name:, import it with @auix_modules, or give the module auix_module/1 returns"
          )

        other ->
          raise_naming_error(
            context.caller,
            "use: #{inspect(name)} names #{inspect(other.kind)}; the #{layout_type} layout of #{inspect(resource_name)} takes #{inspect(kind)}"
          )
      end

    missing = Enum.reject(component.fields, &Map.has_key?(resource.fields, &1))

    if missing != [],
      do:
        raise_naming_error(
          context.caller,
          "unknown fields #{inspect(missing)} for resource #{inspect(resource_name)} in use: #{inspect(name)}"
        )

    component
  end

  # The component a `use:` names: imported, generated by this module, or a generated module.
  @spec find_component(atom(), [Node.layout()], map()) :: map() | nil
  defp find_component(name, layouts, context) do
    own = Enum.find(context.names, &(elem(&1, 0) == name))

    cond do
      Map.has_key?(context.imported, name) ->
        context.imported |> Map.fetch!(name) |> module_component()

      own != nil ->
        own_component(own, layouts, context)

      generated_module?(name) ->
        module_component(name)

      true ->
        nil
    end
  end

  @spec module_component(module()) :: map()
  defp module_component(module),
    do: %{
      module: module,
      kind: module.auix_kind(),
      fields: module.auix_fields(),
      layout: module.auix_layout()
    }

  @spec own_component(tuple(), [Node.layout()], map()) :: map()
  defp own_component({_name, :index_live, _resource_name, module}, _layouts, _context),
    do: %{module: module, kind: :index_live, fields: [], layout: nil}

  defp own_component({_name, kind, resource_name, module}, layouts, context) do
    {layout_type, ^kind} = List.keyfind(@component_kinds, kind, 1)

    layout =
      layouts
      |> resource_layouts(resource_name)
      |> put_missing_show()
      |> Map.get(layout_type)
      |> exposed_layout(layout_type, Map.fetch!(context.resources, resource_name), context.opts)

    fields = layout |> Node.fields() |> Enum.map(& &1.key) |> Enum.uniq()
    %{module: module, kind: kind, fields: fields, layout: layout}
  end

  # The layout a generated component returns from `auix_layout/0`.
  @spec exposed_layout(Node.layout() | nil, atom(), Resource.t(), keyword()) :: Node.layout()
  defp exposed_layout(nil, layout_type, resource, opts),
    do: %{RenderTree.default(layout_type, resource, opts) | resource: nil}

  defp exposed_layout(layout, _layout_type, _resource, _opts), do: %{layout | resource: nil}

  # The modules of one resource: generated here, or taken with `use:`.
  @spec resource_modules({atom(), Resource.t()}, map(), list(), keyword()) :: map()
  defp resource_modules({resource_name, resource}, layouts, names, opts) do
    generated =
      names
      |> Enum.filter(fn {_name, _kind, owner, _module} -> owner == resource_name end)
      |> Map.new(fn {_name, kind, _owner, module} -> {kind, module} end)

    used =
      @component_kinds
      |> Enum.filter(fn {layout_type, _kind} -> using?(Map.get(layouts, layout_type)) end)
      |> Map.new(fn {layout_type, kind} -> {kind, Map.fetch!(layouts, layout_type).use} end)

    exposed_layouts =
      @component_kinds
      |> Enum.filter(fn {_layout_type, kind} -> Map.has_key?(generated, kind) end)
      |> Map.new(fn {layout_type, kind} ->
        {kind, exposed_layout(Map.get(layouts, layout_type), layout_type, resource, opts)}
      end)

    %{
      artifacts:
        %{index_live: nil, index_component: nil, form_component: nil, show_component: nil}
        |> Map.merge(generated)
        |> Map.merge(used),
      used: Enum.filter([:form_component, :show_component], &Map.has_key?(used, &1)),
      generate: Enum.filter(kinds(), &Map.has_key?(generated, &1)),
      exposed_layouts: exposed_layouts
    }
  end

  # Builds the resource-specific layouts.
  @spec build_resource_layouts(tuple(), map(), module()) :: list()
  defp build_resource_layouts(
         {_resource_config_name,
          %{
            resource_config: resource_config,
            layout_tags: layout_tags,
            parsed_opts: parsed_opts,
            layout_trees: layout_trees,
            template: template,
            modules: modules,
            artifacts: artifacts,
            used: used,
            generate: generate,
            exposed_layouts: exposed_layouts
          }},
         configurations,
         _caller
       ) do
    Enum.each(modules, fn {_, module} -> Code.ensure_compiled(module) end)

    if resource_config.embedded? do
      []
    else
      layout_tags
      |> Enum.filter(&generate_tag?(&1, generate))
      |> Enum.reduce(
        [],
        &[
          generate_module(
            %{
              modules: modules,
              layout_type: &1,
              layout_tree: Map.fetch!(layout_trees, &1),
              artifacts: artifacts,
              used: used,
              generate: generate,
              exposed_layouts: exposed_layouts
            },
            configurations,
            parsed_opts,
            template
          )
          | &2
        ]
      )
    end
  end

  defp build_resource_layouts(%{}, _configurations, _caller), do: []

  @spec generate_tag?(atom(), [atom()]) :: boolean()
  defp generate_tag?(:index, generate),
    do: :index_live in generate or :index_component in generate

  defp generate_tag?(:form, generate), do: :form_component in generate
  defp generate_tag?(:show, generate), do: :show_component in generate
  defp generate_tag?(_tag, _generate), do: true

  # Generates a single UI module.
  @spec generate_module(map(), map(), map(), module()) :: Macro.t()
  defp generate_module(layout, configurations, parsed_opts, template) do
    parsed_opts
    |> Map.put(:configurations, configurations)
    |> Map.put(:modules, layout.modules)
    |> Map.put(:layout_tree, layout.layout_tree)
    |> Map.put(:resource_name, layout.layout_tree.resource)
    |> Map.put(:layout_type, layout.layout_type)
    |> Map.put(:artifacts, layout.artifacts)
    |> Map.put(:used, layout.used)
    |> Map.put(:generate, layout.generate)
    |> Map.put(:exposed_layouts, layout.exposed_layouts)
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
        links = declared_links(Map.fetch!(configurations, resource_name).resource_config)

        resource_fields
        |> Enum.reject(&generated?/1)
        |> Enum.map(&{&1.key, preload_resource(&1, resource_name, links)})
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

  # The `resource:` links a resource declares for its fields, by field key.
  @spec declared_links(Resource.t()) :: %{(atom() | tuple()) => atom()}
  defp declared_links(%Resource{field_overrides: field_overrides}) do
    field_overrides
    |> Enum.reject(&is_nil(&1.resource))
    |> Map.new(&{&1.key, &1.resource})
  end

  # The resource whose association keys are nested under an association. A field that keeps
  # the name of its own resource nests nothing, unless the resource declares `resource:` for it.
  @spec preload_resource(Field.t(), atom(), map()) :: atom() | nil
  defp preload_resource(%Field{resource: resource_name} = field, resource_name, links),
    do: Map.get(links, field.key, resource_name)

  defp preload_resource(%Field{resource: resource}, _resource_name, _links), do: resource

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
