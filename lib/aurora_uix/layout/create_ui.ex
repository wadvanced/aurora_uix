defmodule Aurora.Uix.Layout.CreateUI do
  @moduledoc """
  Provides a framework for dynamically generating UI layouts for Phoenix applications.

  Offers a compile-time mechanism to create UI components for resources, including index,
  form, and show views, based on flexible configuration using a DSL.
  """

  alias Aurora.Uix.BehaviourHelper
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Blueprint
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Layout.RenderTree
  alias Aurora.Uix.Parser
  alias Aurora.Uix.Renderers
  alias Aurora.Uix.Resource
  alias Aurora.Uix.Template

  @doc false
  # Generates UI modules before the module is compiled.
  #
  # This macro is triggered before compilation, gathering all `auix_layouts`
  # and `auix_layout_opts` attributes to build the final UI modules.
  # It merges layout trees, processes resource metadata, and injects the
  # generated modules into the calling module.
  #
  # ## Parameters
  # - `env` (Macro.Env.t()) - The macro environment.
  #
  # ## Returns
  # Macro.t() - A quoted expression containing the generated UI modules.
  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module

    declared_layouts =
      module
      |> Module.get_attribute(:auix_layouts, [])
      |> Enum.group_by(&{&1.__struct__, &1.resource})
      |> Enum.map(fn {_key, layouts} ->
        layouts |> Enum.reverse() |> Enum.reduce(&merge_layouts(&2, &1))
      end)

    opts =
      Module.get_attribute(module, :auix_layout_opts, [])

    configurations =
      module
      |> Module.get_attribute(:auix_resource_metadata, [])
      |> Enum.reduce(%{}, fn resource, acc ->
        Enum.reduce(resource, acc, &Map.put(&2, elem(&1, 0), Resource.resolve(elem(&1, 1))))
      end)
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

      @doc false
      @spec auix_layouts() :: list()
      def auix_layouts do
        unquote(Macro.escape(declared_layouts))
      end

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

  @doc """
  Configures and initiates UI generation for a specific module.

  ## Parameters
  - `opts` (keyword()) - Configuration options for UI generation.
  - `do_block` (Macro.t() | nil) - An optional configuration block for advanced layouts.

  ## Options
  - `:for` (atom()) - The target resource name to generate the UI for.
  - `:renderers` (map()) - `html_type => renderer` table for every layout this call generates.
    Beats `auix_resource_metadata` and `use Aurora.Uix`; a layout macro's `renderers:` and a
    field slot beat it. See `Aurora.Uix.Renderers`.

  ## Returns
  Macro.t() - A quoted expression that sets up the UI configuration.

  ## Examples
  ```elixir
  auix_create_ui for: :product do
    index_columns [:name, :price]
    edit_layout do
      inline [:name, :price]
    end
  end
  ```
  """
  @spec auix_create_ui(keyword(), Macro.t() | nil) :: Macro.t()
  defmacro auix_create_ui(opts \\ [], do_block \\ nil) do
    {block, opts} = LayoutHelpers.extract_block_options(opts, do_block)

    quoted_opts = LayoutHelpers.create_layout_opts(opts)
    layout_trees = LayoutHelpers.create_layout(block)

    quote do
      import Blueprint

      @before_compile Aurora.Uix.Layout.CreateUI

      unquote(quoted_opts)
      unquote(layout_trees)
    end
  end

  ## PRIVATE

  # Merges two layouts declared for the same resource and layout type; `layout` wins.
  @spec merge_layouts(Node.layout(), Node.layout()) :: Node.layout()
  defp merge_layouts(%Node.Index{} = acc, layout) do
    acc
    |> merge_container_opts(layout)
    |> Map.merge(%{
      children: acc.children ++ layout.children,
      order_by: layout.order_by || acc.order_by,
      where: layout.where || acc.where
    })
  end

  defp merge_layouts(acc, layout) do
    acc
    |> merge_container_opts(layout)
    |> Map.put(:children, acc.children ++ layout.children)
  end

  @spec merge_container_opts(Node.layout(), Node.layout()) :: Node.layout()
  defp merge_container_opts(acc, layout) do
    %{
      acc
      | renderers: layout.renderers || acc.renderers,
        handler_module: layout.handler_module || acc.handler_module,
        actions: Keyword.merge(acc.actions, layout.actions),
        options: Keyword.merge(acc.options, layout.options)
    }
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
