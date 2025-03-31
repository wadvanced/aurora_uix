defmodule AuroraUixWeb.Uix.CreateUI do
  @moduledoc """
  Provides a comprehensive framework for dynamically generating UI layouts and views in Phoenix/Elixir applications.

  ## Key Features
  - Compile-time UI generation for resources
  - Flexible layout configuration
  - Automatic module generation for index, form, and show views
  - Integration with schema parsing and template generation

  ## Core Responsibilities
  - Define macros for UI configuration
  - Process schema configurations
  - Generate UI-related modules dynamically
  - Support custom layout definitions

  ## Compilation Workflow
  1. Module uses `use AuroraUixWeb.Uix.CreateUI`
  2. Configurations are collected via module attributes
  3. `__before_compile__/1` macro triggers UI generation
  4. Modules are dynamically created based on configurations

  ## Examples
  ```elixir
    defmodule MyApp.ProductViews do
      use AuroraUixWeb.Uix.CreateUI
      auix_create_ui for: :product do
        index_columns :product, [:name, :price]
        edit_layout :product do
          inline [:name, :price]
        end
      end
    end
  ```

  ## Performance Considerations
  - UI generation occurs at compile-time
  - Minimal runtime overhead
  - Supports complex, nested layouts
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix
  alias AuroraUixWeb.Uix.CreateUI
  alias AuroraUixWeb.Uix.CreateUI.LayoutConfigUI

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.CreateUI
      use AuroraUixWeb.Uix.CreateUI.LayoutConfigUI
      use AuroraUixWeb.Uix.CreateUI.IndexUI

      @before_compile AuroraUixWeb.Uix.CreateUI
    end
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module
    opts = Module.get_attribute(module, :_auix_form_layouts_opts)

    layout_paths =
      module
      |> Module.get_attribute(:_auix_layout_paths, [])
      |> Enum.reverse()

    Module.delete_attribute(module, :_auix_layout_paths)

    modules =
      module
      |> Module.get_attribute(:auix_resource_config, %{})
      |> map_resources()
      |> then(&CreateUI.build_ui(module, &1, layout_paths, opts))

    quote do
      unquote(modules)
    end
  end

  @doc """
  Configures and initiates UI generation for a specific module.

  ## Parameters
  - `opts` (keyword): Configuration options for UI generation
  - `:for` - Specify the target resource
  - `do_block` (optional): Custom configuration block for advanced layouts

  ## Options
  - `for: :resource_name` - Generates UI specifically for the named resource
  - Custom layout blocks using macros like `index_columns/2`, `edit_layout/2`

  ## Examples
  ```elixir
    auix_create_ui for: :user do
      index_columns [:name, :email]
      edit_layout do
        inline [:name, :email, :role]
      end
    end
  ```

  ## Compile-Time Behavior
    - Registers module attributes
    - Prepares for UI generation via @before_compile hook

  """
  @spec auix_create_ui(keyword, any) :: Macro.t()
  defmacro auix_create_ui(opts \\ [], do_block \\ nil) do
    {block, opts} = Uix.extract_block_options(opts, do_block)

    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_form_layouts_opts, unquote(opts))
      unquote(block)
    end
  end

  @doc """
  Builds UI layouts based on resource configurations.

  This function is the main entry point for dynamic UI generation. It is typically
  invoked during the compile phase via the `@before_compile` callback. Depending on the
  options provided, it either builds index and form layouts for a specific schema (using
  the `:for` option) or creates base layouts for all provided schema configurations.

  ## Parameters

    - `caller` (module): The module initiating UI generation.
    - `auix_resource_configs_ui` (map | nil): A map containing schema configuration(s).
    - `layout_paths` (list): A list of layout path definitions accumulated from the module.
    - `opts` (keyword): A list of options. If the `:for` key is present, only the layouts
      for the specified schema are generated; otherwise, base layouts for all schemas are created.

  ## Options
    - :for - Generate UI for a specific resource
    - Other resource-specific customization options

  ## Returns

  A list of generated UI layout modules.

  ## Behavior
  - If :for is provided, generates layouts for the specific resource
  - Otherwise, generates base layouts for all configured resources

  """
  @spec build_ui(any, map, list, keyword) :: list
  def build_ui(caller, resource_configs, layout_paths, opts) do
    {web, _} = caller |> Module.split() |> List.first() |> Code.eval_string()
    template = Template.uix_template()

    resource_configs
    |> filter_resources(opts[:for])
    |> build_resources_layouts(caller, layout_paths, opts)
    |> build_common_components(web, template)
  end

  ## PRIVATE

  @spec filter_resources(map, nil | atom | list) :: map
  defp filter_resources(resource_configs, nil), do: resource_configs

  defp filter_resources(resource_configs, for) when is_atom(for) do
    Enum.filter(resource_configs, fn {key, _value} -> key == for end)
  end

  defp filter_resources(resource_configs, for) when is_list(for) do
    Enum.filter(resource_configs, fn {key, _value} -> key in for end)
  end

  # Returns a list of maps using the format of #build_resource_paths
  @spec build_resources_layouts(map, module, list, keyword) :: [Macro.t()]
  defp build_resources_layouts(resource_configs, caller, layout_paths, opts) do
    configurations =
      Enum.reduce(
        resource_configs,
        [],
        &[build_resource_paths(resource_configs, elem(&1, 0), layout_paths, opts) | &2]
      )

    resource_paths = extract_resources(configurations)

    resource_preloads = extract_resource_preloads(resource_paths, opts)

    configurations
    |> Enum.reduce([], &[expand_association_fields(&1, resource_paths) | &2])
    |> Enum.reduce([], &[build_resource_preload_option(&1, resource_preloads) | &2])
    |> Enum.reduce([], &[build_resource_layouts(&1, caller) | &2])
    |> List.flatten()
  end

  # Returns a map with the following format:
  #  %{
  #    resource_config_name: resource_config_name, Name of the resource, being configured.
  #    resource_config: resource_config, # Instance of AuroraUix.ResourceConfigUI struct.
  #    layouts: layouts, # List of layouts map TODO: should be provided by the template
  #    parsed_opts: parsed_opts, # Parsed options for the layout.
  #    defaulted_paths: defaulted_paths, # Paths making up the UI.
  #    template: template, # Used template
  #  }
  @spec build_resource_paths(map, atom, list, keyword) :: map
  defp build_resource_paths(
         auix_resource_config,
         resource_config_name,
         layout_paths,
         opts
       ) do
    # PENDING: should be passed or taken from a @ module variable
    template = Template.uix_template()
    resource_config = Map.get(auix_resource_config, resource_config_name)

    resource_module = Map.get(resource_config, :schema)

    if is_nil(resource_module) do
      %{}
    else
      parsed_opts =
        resource_config
        |> Parser.parse(opts)
        |> Map.put(:fields, resource_config.fields)

      layouts = %{index: :index_columns, form: :form_fields, show: :show_fields}

      # Get all layout paths
      paths =
        layouts
        |> Enum.map(&locate_layout_paths(&1, layout_paths, resource_config_name))
        |> Map.new()
        |> fill_missing_paths(:form, :show)

      defaulted_paths =
        layouts
        |> Enum.map(fn {tag, _key} ->
          paths
          |> Map.get(tag)
          |> LayoutConfigUI.build_default_layout_paths(resource_config_name, parsed_opts, tag)
          |> LayoutConfigUI.unpack_paths_fields(tag)
          |> LayoutConfigUI.parse_sections(tag)
          |> Enum.map(&expand_fields(&1, parsed_opts, %{disabled: tag == :show}))
          |> then(&{tag, &1})
        end)
        |> Map.new()

      %{
        resource_config_name: resource_config_name,
        resource_config: resource_config,
        layouts: layouts,
        parsed_opts: parsed_opts,
        defaulted_paths: defaulted_paths,
        template: template
      }
    end
  end

  @spec build_resource_layouts(map, module) :: list
  defp build_resource_layouts(
         %{
           resource_config: resource_config,
           layouts: layouts,
           parsed_opts: parsed_opts,
           defaulted_paths: defaulted_paths,
           template: template
         },
         caller
       ) do
    {web, _} = caller |> Module.split() |> List.first() |> Code.eval_string()
    resource_module = Map.get(resource_config, :schema)

    parsed_opts =
      layouts
      |> Enum.map(&parse_template_paths(&1, defaulted_paths, parsed_opts, template))
      |> Map.new()
      |> then(&Map.merge(parsed_opts, &1))

    modules = %{
      caller: caller,
      module: resource_module,
      web: web,
      context: resource_config.context
    }

    Enum.each(modules, fn {_, module} -> Code.ensure_compiled(module) end)

    Enum.reduce(
      [:form, :index, :show],
      [],
      &[template.generate_module(modules, &1, parsed_opts) | &2]
    )
  end

  defp build_resource_layouts(%{}, _caller), do: []

  @spec build_common_components(list, module, module) :: list
  defp build_common_components(uis, web, template) do
    Enum.reduce(
      template.common_modules(),
      uis,
      &maybe_build_common_component(web, template, &1, &2)
    )
  end

  @spec maybe_build_common_component(module, module, tuple, list) :: Macro.t()
  defp maybe_build_common_component(web, template, {type, module}, uis) do
    if Code.loaded?(module) do
      uis
    else
      [template.generate_module(%{web: web}, type) | uis]
    end
  end

  @spec parse_template_paths(tuple, map, map, module) :: tuple
  defp parse_template_paths({tag, key}, paths, parsed_opts, template) do
    paths
    |> Map.get(tag, %{})
    |> Enum.map_join(&template.parse_layout(&1, parsed_opts, tag))
    |> then(&{key, &1})
  end

  @spec locate_layout_paths(tuple, list, atom) :: tuple
  defp locate_layout_paths({tag, _key}, layout_paths, resource_config_name) do
    layout_paths
    |> locate_layout_paths_by_resource(resource_config_name, tag)
    |> then(&{tag, &1})
  end

  @spec fill_missing_paths(map, atom, atom) :: map
  defp fill_missing_paths(layout_paths, from, to) do
    layout_paths
    |> Map.get(from, [])
    |> fill_missing_paths_recursive(layout_paths[to], from, to)
    |> then(&Map.put(layout_paths, to, &1))
  end

  @spec fill_missing_paths_recursive(list, list, atom, atom) :: list
  defp fill_missing_paths_recursive(from_paths, to_paths, from, to)
       when is_nil(to_paths) or to_paths == [],
       do: Enum.map(from_paths, &update_layout_path_tag(&1, from, to))

  defp fill_missing_paths_recursive(_from_paths, to_paths, _from, _to), do: to_paths

  @spec update_layout_path_tag(map, atom, atom) :: map
  defp update_layout_path_tag(%{tag: from} = path, from, to), do: Map.put(path, :tag, to)
  defp update_layout_path_tag(path, _from, _to), do: path

  @spec locate_layout_paths_by_resource(list, atom, atom) :: list
  defp locate_layout_paths_by_resource(layout_paths, resource_config_name, tag) do
    layout_paths
    |> locate_layout_paths_recursive(resource_config_name, tag, [])
    |> Enum.reverse()
  end

  @spec locate_layout_paths_recursive(list, atom, atom, list) :: list
  defp locate_layout_paths_recursive(
         [%{tag: tag, name: resource_config_name, state: :start} = path | rest],
         resource_config_name,
         tag,
         paths
       ) do
    append_layout_path(rest, tag, [path | paths])
  end

  defp locate_layout_paths_recursive([_ | rest], resource_config_name, tag, _paths),
    do: locate_layout_paths_recursive(rest, resource_config_name, tag, [])

  defp locate_layout_paths_recursive([], _resource_config_name, _tag, _paths), do: []

  @spec append_layout_path(list, atom, list) :: list
  defp append_layout_path([%{tag: tag, state: :end} = path | _rest], tag, paths),
    do: [path | paths]

  defp append_layout_path([], _tag, paths), do: paths

  defp append_layout_path([path | rest], tag, paths),
    do: append_layout_path(rest, tag, [path | paths])

  @spec expand_fields(map, map, map) :: map
  defp expand_fields(
         %{config: {:fields, fields}} = path,
         %{fields: configured_fields},
         global_overrides
       ) do
    fields
    |> Enum.map(&expand_field(&1, configured_fields, global_overrides))
    |> then(&Map.put(path, :config, {:fields, &1}))
  end

  defp expand_fields(
         %{tag: :field, config: field} = path,
         %{fields: configured_fields},
         global_overrides
       ) do
    field
    |> expand_field(configured_fields, global_overrides)
    |> then(&Map.put(path, :config, &1))
  end

  defp expand_fields(path, _parsed_opts, _global_overrides), do: path

  @spec expand_field(tuple, list, map) :: map
  defp expand_field(overrode_field, configured_fields, global_overrides)
       when is_tuple(overrode_field) do
    overrides = elem(overrode_field, 1)

    overrode_field
    |> elem(0)
    |> then(&locate_field(configured_fields, &1))
    |> struct(global_overrides)
    |> struct(overrides)
  end

  defp expand_field(field, configured_fields, global_overrides),
    do: configured_fields |> locate_field(field) |> struct(global_overrides)

  @spec locate_field(list, atom) :: map
  defp locate_field(configured_fields, field) do
    Enum.find(configured_fields, &(&1.field == field))
  end

  # Its main purpose is to create a map where the resource is the key
  # for a map containing all classified paths:
  # :index, :form, :show
  @spec extract_resources(list) :: map
  defp extract_resources(configurations) do
    configurations
    |> Enum.map(&extract_resource/1)
    |> List.flatten()
    |> Map.new()
  end

  @spec extract_resource(map) :: list
  defp extract_resource(configuration) do
    configuration
    |> Map.get(:defaulted_paths, [])
    |> Enum.reduce(%{}, fn {tag, paths}, resources ->
      first_path = List.first(paths)

      resources
      |> Map.get(first_path.name, %{})
      |> Map.put(tag, paths)
      |> then(&Map.put(resources, first_path.name, &1))
      |> then(
        &put_in(&1, [first_path.name, :parsed_opts], Map.get(configuration, :parsed_opts, %{}))
      )
    end)
    |> Enum.map(& &1)
  end

  @spec expand_association_fields(map, map) :: map
  defp expand_association_fields(
         %{defaulted_paths: defaulted_paths} = configuration,
         resource_paths
       ) do
    defaulted_paths
    |> Enum.map(fn {key, paths} ->
      {key, Enum.map(paths, &expand_association_field(&1, resource_paths))}
    end)
    |> Map.new()
    |> then(&Map.put(configuration, :defaulted_paths, &1))
  end

  defp expand_association_fields(configuration, _resources), do: configuration

  @spec expand_association_field(map, map) :: map
  defp expand_association_field(
         %{
           tag: :field,
           state: :start,
           config: %{field_type: :one_to_many_association, resource: resource}
         } = path,
         resource_paths
       ) do
    resource_paths
    |> get_in([resource, :index])
    |> Kernel.||([])
    |> List.first()
    |> maybe_add_association_data_to_resource(path, resource_paths)
  end

  defp expand_association_field(path, _resources), do: path

  @spec maybe_add_association_data_to_resource(map, map, map) :: map
  defp maybe_add_association_data_to_resource(
         %{name: resource, config: {:fields, fields}},
         path,
         resource_paths
       ) do
    put_in(path, [Access.key!(:config), Access.key!(:resource)], %{
      resource: resource,
      fields: fields,
      parsed_opts: get_in(resource_paths, [resource, :parsed_opts]) || %{}
    })
  end

  defp maybe_add_association_data_to_resource(_resource, path, _resource_paths), do: path

  @spec extract_resource_preloads(map, keyword) :: map
  defp extract_resource_preloads(resource_paths, opts) do
    resource_paths
    |> Enum.map(fn {resource_name, layouts} ->
      layouts
      |> Enum.map(&extract_resource_preload/1)
      |> List.flatten()
      |> Enum.uniq()
      |> then(&{resource_name, &1})
    end)
    |> Map.new()
    |> expand_preload(opts[:preload_depth] || 1)
  end

  @spec extract_resource_preload(tuple) :: list
  defp extract_resource_preload({:parsed_opts, _}), do: []

  defp extract_resource_preload({:index, paths}) do
    paths
    |> List.first()
    |> Map.get(:config)
    |> elem(1)
    |> extract_resource_preload_from_paths()
  end

  defp extract_resource_preload({_tag, paths}) do
    paths
    |> Enum.filter(&(&1.tag == :field && &1.state == :start))
    |> Enum.map(fn path ->
      path |> Map.get(:config) |> extract_resource_preload_from_paths()
    end)
  end

  @spec extract_resource_preload_from_paths(list) :: list
  defp extract_resource_preload_from_paths(paths) when is_list(paths) do
    paths
    |> Enum.filter(&(&1.field_type in [:one_to_many_association, :many_to_one_association]))
    |> Enum.map(&{&1.field, &1.resource})
  end

  defp extract_resource_preload_from_paths(path), do: extract_resource_preload_from_paths([path])

  @spec expand_preload(map, integer) :: map
  defp expand_preload(preload, depth) do
    translations =
      preload
      |> Enum.map(fn {_parent_resource, field_resource} -> field_resource end)
      |> List.flatten()
      |> Enum.reject(fn {_parent_resource, resource} -> is_nil(resource) end)
      |> Map.new()

    preload
    |> Enum.map(fn {parent_resource, fields} ->
      fields
      |> Enum.map(&elem(&1, 0))
      |> then(&{parent_resource, &1})
    end)
    |> Map.new()
    |> expand_preload(translations, depth)
  end

  @spec expand_preload(map, map, integer) :: map
  defp expand_preload(preload, translations, depth) do
    preload
    |> Enum.map(fn {parent, children} ->
      {parent, expand_preload_children(preload, children, translations, 0, depth)}
    end)
    |> Map.new()
  end

  @spec expand_preload_children(map, list, map, integer, integer) :: tuple
  defp expand_preload_children(preload, children, translations, current_depth, depth)
       when current_depth < depth do
    Enum.map(children, fn field ->
      translations
      |> Map.get(field, field)
      |> then(&Map.get(preload, &1, []))
      |> then(
        &{field, expand_preload_children(preload, &1, translations, current_depth + 1, depth)}
      )
    end)
  end

  defp expand_preload_children(_preloads, children, _translations, _current_depth, _depth),
    do: children

  @spec build_resource_preload_option(map, map) :: map
  defp build_resource_preload_option(
         %{parsed_opts: parsed_opts} = configuration,
         resource_preloads
       ) do
    resource_preloads
    |> Map.get(configuration.resource_config_name, [])
    |> then(&Map.put(parsed_opts, :preload, &1))
    |> then(&Map.put(configuration, :parsed_opts, &1))
  end

  defp build_resource_preload_option(configuration, _resource_preloads), do: configuration

  @spec map_resources(list) :: map
  defp map_resources(resource_configs) do
    flatten_resource_configs = List.flatten(resource_configs)

    if Enum.count(flatten_resource_configs) == 1,
      do: List.first(flatten_resource_configs),
      else: map_resources(flatten_resource_configs, %{})
  end

  @spec map_resources(list, map) :: map
  defp map_resources([resource_config | rest], acc) do
    map_resources(rest, Map.merge(acc, resource_config))
  end

  defp map_resources([], acc), do: acc
end
