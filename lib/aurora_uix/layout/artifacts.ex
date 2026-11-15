defmodule Aurora.Uix.Layout.Artifacts do
  @moduledoc """
  Names the modules auix_create_ui generates and keeps their registry.

  Every generated module is an artifact: the declaring module keeps a registry that maps an atom
  to the generated module, returned by `auix_modules/0` and `auix_module/1`. A module also lists
  the modules it imports with `@auix_modules`, under the atoms it gives them. Every generated
  module describes itself with `auix_kind/0`, `auix_fields/0` and `auix_layout/0`.

  ## Key Features
  - One naming function for every generated module.
  - A registry from name to module, with the imported modules beside the generated ones.
  - The three functions every generated module describes itself with.
  - `use:` substitution: a layout takes a component instead of generating one.
  - Collision detection: two artifacts with one name, or two names for one module, do not
    compile.

  ## Key Constraints
  - The registry holds modules, never a resource.
  - The schema hint only names, it never restricts reuse.
  - Pure, it defines no module itself.
  """

  alias Aurora.Uix.Layout.CreateUI.IndexLive
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Layout.RenderTree
  alias Aurora.Uix.Resource
  alias Spark.Error.DslError

  @type kind() :: :index_live | :form_component | :show_component
  @type entry() :: %{
          module: module(),
          kind: kind(),
          fields: [atom()],
          layout: Node.layout() | nil
        }

  @component_kinds [form: :form_component, show: :show_component]

  @doc """
  Returns the kinds of module `auix_create_ui` generates.

  ## Parameters
  None.

  ## Returns
  `[kind()]` - `[:index_live, :form_component, :show_component]`.
  """
  @spec kinds() :: [kind()]
  def kinds, do: [:index_live, :form_component, :show_component]

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
  - `name` (atom()) - The last segment, camelized.

  ## Returns
  `module()` - e.g. `MyApp.Views.Product.IndexCompact`.
  """
  @spec module_name(module(), binary(), atom()) :: module()
  def module_name(caller, schema_hint, name),
    do: Module.concat([caller, schema_hint, name |> Atom.to_string() |> Macro.camelize()])

  @doc """
  Returns the default registry name of a generated module.

  The atom is built at compile time from a schema module name.

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
  @spec functions_code(%{atom() => module()}) :: Macro.t()
  def functions_code(modules) do
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

  Options `plan/1` built already carry the four keys and are returned as they are. Options built
  by hand take the module names the generators built before named artifacts.

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
  Plans the artifacts of a module: names its modules, resolves its `use:` lines and builds its
  registry.

  ## Parameters
  - `input` (map()) - `caller` (module()), `resources` (resources by name, already filtered by
    `for:`), `layouts` (the declared layouts by resource and layout type), `index_lives`
    ([IndexLive.t()]), `imported` (the `@auix_modules` modules by name), `generate` ([kind()])
    and `opts` (the `auix_create_ui` options).

  ## Returns
  `map()` - `layouts` (the effective layouts by resource), `resolved` (the artifacts, the used
  and generated kinds and the exposed layouts by target resource) and `modules` (the registry).
  Raises `Spark.Error.DslError` on a collision or an invalid `use:`.
  """
  @spec plan(map()) :: %{layouts: map(), resolved: map(), modules: %{atom() => module()}}
  def plan(input) do
    validate_imported(input)

    targets =
      input.resources
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.filter(fn {_name, resource} -> target?(resource) end)

    index_lives = validate_index_lives(input, targets)
    collected = collect_names(input, targets, index_lives)
    validate_collisions(input, collected)

    state =
      Enum.reduce(
        @component_kinds,
        %{layouts: %{}, entries: %{}, used: %{}},
        fn {layout_type, kind}, state ->
          plan_layout_type(input, collected, layout_type, kind, state)
        end
      )

    entries = plan_index_lives(input, collected, state)
    generated = Map.new(entries, fn {name, entry} -> {name, entry.module} end)

    %{
      layouts: Map.new(input.resources, &{elem(&1, 0), effective_layouts(input, state, &1)}),
      resolved: Map.new(targets, &resolved(collected, state, entries, &1)),
      modules: Map.merge(input.imported, generated)
    }
  end

  ## PRIVATE

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
      form_component: module_name(caller, hint, :form_component),
      show_component: module_name(caller, hint, :show_component)
    }
  end

  @spec default_exposed_layouts(map()) :: %{kind() => Node.layout()}
  defp default_exposed_layouts(%{layout_type: :form} = options),
    do: %{form_component: %{options.layout_tree | resource: nil}}

  defp default_exposed_layouts(%{layout_type: :show} = options),
    do: %{show_component: %{options.layout_tree | resource: nil}}

  defp default_exposed_layouts(_options), do: %{}

  @spec target?(Resource.t()) :: boolean()
  defp target?(resource), do: resource.schema != nil and not resource.embedded?

  # `Code.ensure_compiled/1` waits for a module that is still compiling.
  @spec generated_module?(term()) :: boolean()
  defp generated_module?(module) when is_atom(module) and not is_nil(module),
    do:
      match?({:module, _}, Code.ensure_compiled(module)) and
        function_exported?(module, :auix_kind, 0)

  defp generated_module?(_module), do: false

  @spec module_entry(module()) :: entry()
  defp module_entry(module),
    do: %{
      module: module,
      kind: module.auix_kind(),
      fields: module.auix_fields(),
      layout: module.auix_layout()
    }

  @spec raise_error(map(), binary()) :: no_return()
  defp raise_error(input, message),
    do: raise(DslError, module: input.caller, path: [:auix_create_ui], message: message)

  @spec validate_imported(map()) :: :ok
  defp validate_imported(input) do
    Enum.each(input.imported, fn {name, module} ->
      if not generated_module?(module),
        do:
          raise_error(
            input,
            "@auix_modules entry #{inspect(name)} is not a generated module; take it from auix_module/1"
          )
    end)
  end

  @spec validate_index_lives(map(), list()) :: %{atom() => IndexLive.t()}
  defp validate_index_lives(input, targets) do
    target_names = Enum.map(targets, &elem(&1, 0))

    Enum.reduce(input.index_lives, %{}, fn line, lines ->
      cond do
        line.resource not in target_names ->
          raise_error(input, "unknown resource #{inspect(line.resource)}")

        Map.has_key?(lines, line.resource) ->
          raise_error(input, "#{inspect(line.resource)} has more than one index_live line")

        :index_live not in input.generate ->
          raise_error(
            input,
            "index_live #{inspect(line.resource)} needs :index_live in generate:"
          )

        true ->
          Map.put(lines, line.resource, line)
      end
    end)
  end

  # The names of the modules this module generates: `{name, kind, resource_name, module}`.
  @spec collect_names(map(), list(), map()) :: [{atom(), kind(), atom(), module()}]
  defp collect_names(input, targets, index_lives) do
    Enum.flat_map(targets, fn {resource_name, resource} ->
      hint = schema_hint(resource.schema)
      declared = Map.get(input.layouts, resource_name, %{})

      components =
        @component_kinds
        |> Enum.filter(fn {layout_type, kind} ->
          kind in input.generate and not using?(Map.get(declared, layout_type))
        end)
        |> Enum.map(fn {layout_type, kind} ->
          module_name = declared |> Map.get(layout_type) |> layout_module_name()
          segment = module_name || kind
          name = module_name || default_name(hint, kind)
          {name, kind, resource_name, module_name(input.caller, hint, segment)}
        end)

      index_live =
        if :index_live in input.generate do
          line_name = index_lives |> Map.get(resource_name) |> then(&(&1 && &1.module_name))
          segment = line_name || :index
          name = line_name || default_name(hint, :index_live)
          [{name, :index_live, resource_name, module_name(input.caller, hint, segment)}]
        else
          []
        end

      components ++ index_live
    end)
  end

  @spec using?(Node.layout() | nil) :: boolean()
  defp using?(nil), do: false
  defp using?(%{use: nil}), do: false
  defp using?(_layout), do: true

  @spec layout_module_name(Node.layout() | nil) :: atom() | nil
  defp layout_module_name(nil), do: nil
  defp layout_module_name(layout), do: layout.module_name

  @collision_hint "set module_name: on the layout of one of them, reuse a module with use:, or rename a live view with an index_live line"

  @spec validate_collisions(map(), list()) :: :ok
  defp validate_collisions(input, collected) do
    by_name = Enum.group_by(collected, &elem(&1, 0))

    by_name
    |> Map.keys()
    |> Enum.sort()
    |> Enum.each(&validate_name(input, &1, Map.fetch!(by_name, &1)))

    _seen =
      collected
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.reduce(%{}, &validate_module(input, &1, &2))

    :ok
  end

  @spec validate_name(map(), atom(), list()) :: :ok
  defp validate_name(input, name, collected_for_name) do
    owners = Enum.map(collected_for_name, &inspect(elem(&1, 2)))
    imported? = Map.has_key?(input.imported, name)

    if length(owners) > 1 or imported? do
      owners_text =
        if imported?,
          do: Enum.join(owners, ", ") <> ", @auix_modules",
          else: Enum.join(owners, ", ")

      raise_error(
        input,
        "module name #{inspect(name)} is taken more than once (#{owners_text}); #{@collision_hint}"
      )
    end

    :ok
  end

  @spec validate_module(map(), tuple(), map()) :: map()
  defp validate_module(input, {name, _kind, _resource_name, module}, seen) do
    case Map.fetch(seen, module) do
      {:ok, other_name} ->
        raise_error(
          input,
          "#{inspect(module)} would be generated twice, as #{inspect(other_name)} and #{inspect(name)}; #{@collision_hint}"
        )

      :error ->
        Map.put(seen, module, name)
    end
  end

  # Within one layout type, layouts without `use:` build their entries before any `use:` reads them.
  @spec plan_layout_type(map(), list(), atom(), kind(), map()) :: map()
  defp plan_layout_type(input, collected, layout_type, kind, state) do
    {using, own} =
      input.resources
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.split_with(fn {resource_name, _resource} ->
        input |> declared_layout(resource_name, layout_type) |> using?()
      end)

    state = Enum.reduce(own, state, &plan_own_layout(input, collected, layout_type, kind, &1, &2))
    Enum.reduce(using, state, &plan_used_layout(input, collected, layout_type, kind, &1, &2))
  end

  @spec plan_own_layout(map(), list(), atom(), kind(), {atom(), Resource.t()}, map()) :: map()
  defp plan_own_layout(input, collected, layout_type, kind, {resource_name, resource}, state) do
    layout =
      case declared_layout(input, resource_name, layout_type) do
        nil -> missing_layout(state, resource_name, layout_type)
        declared -> declared
      end

    state = put_layout(state, resource_name, layout_type, layout)

    case collected_name(collected, resource_name, kind) do
      nil ->
        state

      {name, module} ->
        written = layout || RenderTree.default(layout_type, resource, input.opts)
        fields = written |> Node.fields() |> Enum.map(& &1.key) |> Enum.uniq()
        entry = %{module: module, kind: kind, fields: fields, layout: %{written | resource: nil}}
        %{state | entries: Map.put(state.entries, name, entry)}
    end
  end

  @spec plan_used_layout(map(), list(), atom(), kind(), {atom(), Resource.t()}, map()) :: map()
  defp plan_used_layout(input, collected, layout_type, kind, {resource_name, resource}, state) do
    name = declared_layout(input, resource_name, layout_type).use

    if not target?(resource),
      do:
        raise_error(
          input,
          "use: is not available for #{inspect(resource_name)}, an embedded resource"
        )

    entry = find_entry(input, collected, state, name, layout_type, kind, resource_name)
    missing = Enum.reject(entry.fields, &Map.has_key?(resource.fields, &1))

    if missing != [],
      do:
        raise_error(
          input,
          "unknown fields #{inspect(missing)} for resource #{inspect(resource_name)} in use: #{inspect(name)}"
        )

    state
    |> put_layout(resource_name, layout_type, %{entry.layout | resource: resource_name})
    |> put_used(resource_name, kind, entry.module)
  end

  @spec find_entry(map(), list(), map(), atom(), atom(), kind(), atom()) :: entry()
  defp find_entry(input, collected, state, name, layout_type, kind, resource_name) do
    found = lookup_entry(input, state, name)
    collected_kind = Enum.find_value(collected, fn {n, k, _r, _m} -> if n == name, do: k end)

    case {found, collected_kind} do
      {%{kind: ^kind} = entry, _collected_kind} ->
        entry

      {nil, nil} ->
        raise_error(
          input,
          "unknown module #{inspect(name)} in use:; declare it with module_name:, import it with @auix_modules, or give the module auix_module/1 returns"
        )

      {found, collected_kind} ->
        found_kind = if found, do: found.kind, else: collected_kind

        raise_error(
          input,
          "use: #{inspect(name)} names #{inspect(found_kind)}; the #{layout_type} layout of #{inspect(resource_name)} takes #{inspect(kind)}"
        )
    end
  end

  @spec lookup_entry(map(), map(), atom()) :: entry() | nil
  defp lookup_entry(input, state, name) do
    cond do
      Map.has_key?(input.imported, name) -> input.imported |> Map.fetch!(name) |> module_entry()
      Map.has_key?(state.entries, name) -> Map.fetch!(state.entries, name)
      generated_module?(name) -> module_entry(name)
      true -> nil
    end
  end

  @spec plan_index_lives(map(), list(), map()) :: %{atom() => entry()}
  defp plan_index_lives(input, collected, state) do
    collected
    |> Enum.filter(&(elem(&1, 1) == :index_live))
    |> Enum.reduce(state.entries, fn {name, _kind, resource_name, module}, entries ->
      components = component_artifacts(collected, state, resource_name)

      if is_nil(components.form_component) or is_nil(components.show_component),
        do:
          raise_error(
            input,
            "the live view of #{inspect(resource_name)} needs a form component and a show component; add :form_component and :show_component to generate:, or name them with use:"
          )

      Map.put(entries, name, %{module: module, kind: :index_live, fields: [], layout: nil})
    end)
  end

  @spec component_artifacts(list(), map(), atom()) :: map()
  defp component_artifacts(collected, state, resource_name) do
    used = Map.get(state.used, resource_name, %{})

    Map.new(@component_kinds, fn {_layout_type, kind} ->
      generated =
        case collected_name(collected, resource_name, kind) do
          {_name, module} -> module
          nil -> nil
        end

      {kind, Map.get(used, kind, generated)}
    end)
  end

  @spec resolved(list(), map(), map(), {atom(), Resource.t()}) :: {atom(), map()}
  defp resolved(collected, state, entries, {resource_name, _resource}) do
    index_live =
      case collected_name(collected, resource_name, :index_live) do
        {_name, module} -> module
        nil -> nil
      end

    used = state.used |> Map.get(resource_name, %{}) |> Map.keys()

    own =
      Enum.filter(collected, fn {_name, _kind, collected_resource, _module} ->
        collected_resource == resource_name
      end)

    exposed_layouts =
      own
      |> Enum.reject(fn {_name, kind, _resource_name, _module} -> kind == :index_live end)
      |> Map.new(fn {name, kind, _resource_name, _module} ->
        {kind, entries |> Map.fetch!(name) |> Map.fetch!(:layout)}
      end)

    {resource_name,
     %{
       artifacts:
         collected
         |> component_artifacts(state, resource_name)
         |> Map.put(:index_live, index_live),
       used: Enum.filter([:form_component, :show_component], &(&1 in used)),
       generate: Enum.filter(kinds(), fn kind -> Enum.any?(own, &(elem(&1, 1) == kind)) end),
       exposed_layouts: exposed_layouts
     }}
  end

  @spec effective_layouts(map(), map(), {atom(), Resource.t()}) :: map()
  defp effective_layouts(input, state, {resource_name, _resource}) do
    layouts = Map.get(state.layouts, resource_name, %{})

    %{
      index: declared_layout(input, resource_name, :index),
      form: Map.get(layouts, :form),
      show: Map.get(layouts, :show)
    }
  end

  @spec collected_name(list(), atom(), kind()) :: {atom(), module()} | nil
  defp collected_name(collected, resource_name, kind) do
    Enum.find_value(collected, fn
      {name, ^kind, ^resource_name, module} -> {name, module}
      _other -> nil
    end)
  end

  @spec declared_layout(map(), atom(), atom()) :: Node.layout() | nil
  defp declared_layout(input, resource_name, layout_type),
    do: input.layouts |> Map.get(resource_name, %{}) |> Map.get(layout_type)

  # Without a show layout, the show view reuses the form layout and its `show_handler_module`.
  @spec missing_layout(map(), atom(), atom()) :: Node.layout() | nil
  defp missing_layout(state, resource_name, :show) do
    case get_in(state, [:layouts, resource_name, :form]) do
      nil ->
        nil

      form ->
        form
        |> Map.from_struct()
        |> Map.merge(%{
          handler_module: Keyword.get(form.options, :show_handler_module),
          module_name: nil,
          use: nil
        })
        |> then(&struct(Node.Show, &1))
    end
  end

  defp missing_layout(_state, _resource_name, _layout_type), do: nil

  @spec put_layout(map(), atom(), atom(), Node.layout() | nil) :: map()
  defp put_layout(state, resource_name, layout_type, layout) do
    state.layouts
    |> Map.get(resource_name, %{})
    |> Map.put(layout_type, layout)
    |> then(&%{state | layouts: Map.put(state.layouts, resource_name, &1)})
  end

  @spec put_used(map(), atom(), kind(), module()) :: map()
  defp put_used(state, resource_name, kind, module) do
    state.used
    |> Map.get(resource_name, %{})
    |> Map.put(kind, module)
    |> then(&%{state | used: Map.put(state.used, resource_name, &1)})
  end
end
