defmodule Aurora.Uix.Layout.CreateUI do
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
  1. Module uses `use Aurora.Uix.Layout.CreateUI`
  2. Configurations are collected via module attributes
  3. `__before_compile__/1` macro triggers UI generation
  4. Modules are dynamically created based on configurations

  ## Examples
  ```elixir
    defmodule MyApp.ProductViews do
      use Aurora.Uix.Layout.CreateUI
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

  import Aurora.Uix.Layout.Helper

  alias Aurora.Uix.Layout.Blueprint
  alias Aurora.Uix.Layout.CreateUI
  alias Aurora.Uix.Parser
  alias Aurora.Uix.Template

  defmacro __using__(_opts) do
    quote do
      import Aurora.Uix.Layout.CreateUI
      use Aurora.Uix.Layout.Blueprint

      @before_compile Aurora.Uix.Layout.CreateUI
    end
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module

    {layout_paths, opts} =
      module
      |> Module.get_attribute(:_auix_layout_paths, %{inner_elements: [], opts: []})
      |> then(&{&1.inner_elements, &1.opts})

    Module.delete_attribute(module, :_auix_layout_paths)

    ## Merge layout paths
    merged_layout_paths =
      layout_paths
      |> Enum.group_by(&{&1.name, &1.tag})
      |> Enum.map(&merge_layout_paths/1)

    modules =
      module
      |> Module.get_attribute(:auix_resource_metadata, [])
      |> Enum.reduce(%{}, fn resource, acc ->
        Enum.reduce(resource, acc, &Map.put(&2, elem(&1, 0), elem(&1, 1)))
      end)
      |> build_ui(module, merged_layout_paths, opts)

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
    {block, opts} = extract_block_options(opts, do_block)

    create_ui = register_dsl_entry(:ui, :ui, [], opts, block)

    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_layout_paths, unquote(create_ui))
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
  @spec build_ui(map, any, list, keyword) :: list
  def build_ui(resource_configs, caller, layout_paths, opts) do
    resource_configs
    |> filter_resources(opts[:for])
    |> build_layouts(caller, layout_paths, opts)
  end

  ## PRIVATE

  @spec merge_layout_paths(tuple) :: list
  defp merge_layout_paths({_, paths}) do
    Enum.reduce(paths, nil, &merge_layout_opts_inner_elements/2)
  end

  @spec merge_layout_opts_inner_elements(map, map | nil) :: map
  defp merge_layout_opts_inner_elements(path, nil), do: path

  defp merge_layout_opts_inner_elements(path, acc) do
    opts = Keyword.merge(acc.opts, path.opts)

    inner_elements =
      acc.inner_elements
      |> Enum.reverse()
      |> then(
        &Enum.reduce(path.inner_elements, &1, fn path_element, acc_elements ->
          [path_element | acc_elements]
        end)
      )

    acc
    |> Map.put(:opts, opts)
    |> Map.put(:inner_elements, inner_elements)
  end

  @spec filter_resources(map, nil | atom | list) :: map
  defp filter_resources(resource_configs, nil), do: resource_configs

  defp filter_resources(resource_configs, for) when is_atom(for) do
    Enum.filter(resource_configs, fn {key, _value} -> key == for end)
  end

  defp filter_resources(resource_configs, for) when is_list(for) do
    Enum.filter(resource_configs, fn {key, _value} -> key in for end)
  end

  # Returns a list of maps using the format of #build_configurations
  @spec build_layouts(map, module, list, keyword) :: [Macro.t()]
  defp build_layouts(resource_configs, caller, layout_paths, opts) do
    configurations =
      resource_configs
      |> Enum.reduce(
        [],
        &[build_configurations(&1, layout_paths, opts) | &2]
      )
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    resource_preloads = extract_resource_preloads(configurations)

    configurations
    |> Enum.reduce([], &[build_resource_preload_option(&1, resource_preloads) | &2])
    |> Map.new()
    |> then(fn configurations ->
      Enum.reduce(configurations, [], &[build_resource_layouts(&1, configurations, caller) | &2])
    end)
  end

  # Returns a map with the following format:
  #  %{
  #    resource_config_name: resource_config_name, Name of the resource, being configured.
  #    resource_config: resource_config, # Instance of Aurora.Uix.Resource struct.
  #    layouts: layouts, # List of layouts map TODO: should be provided by the template
  #    parsed_opts: parsed_opts, # Parsed options for the layout.
  #    defaulted_paths: defaulted_paths, # Paths making up the UI.
  #    template: template, # Used template
  #  }
  @spec build_configurations({atom, map}, list, keyword) :: map | nil
  defp build_configurations(
         {resource_config_name, resource_config},
         layout_paths,
         opts
       ) do
    # PENDING: The template should be passed or taken from a @ module variable
    template = Template.uix_template()

    resource_module = Map.get(resource_config, :schema)

    if is_nil(resource_module) do
      nil
    else
      parsed_opts = Parser.parse(resource_config, opts)

      layouts = [:index, :form, :show]

      # Get all layout paths

      paths =
        layouts
        |> Enum.map(&locate_layout_paths(&1, layout_paths, resource_config_name))
        |> Map.new()
        |> fill_missing_paths(:form, :show)

      defaulted_paths =
        layouts
        |> Enum.map(fn tag ->
          paths
          |> Map.get(tag)
          |> Blueprint.build_default_layout_paths(resource_config, opts, tag)
          |> Blueprint.parse_sections(tag)
          |> disable_show_fields(tag)
          |> then(&{tag, &1})
        end)
        |> Map.new()

      {resource_config_name,
       %{
         resource_config_name: resource_config_name,
         resource_config: resource_config,
         layouts: layouts,
         parsed_opts: parsed_opts,
         defaulted_paths: defaulted_paths,
         template: template
       }}
    end
  end

  @spec build_resource_layouts(tuple, map, module) :: list
  defp build_resource_layouts(
         {_resource_config_name,
          %{
            resource_config: resource_config,
            layouts: layouts,
            parsed_opts: parsed_opts,
            defaulted_paths: defaulted_paths,
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
      layouts,
      [],
      &[
        generate_module(
          modules,
          Map.get(defaulted_paths, &1, %{}),
          configurations,
          parsed_opts,
          template
        )
        | &2
      ]
    )
  end

  defp build_resource_layouts(%{}, _configurations, _caller), do: []

  @spec generate_module(map, map, map, map, module) :: Macro.t()
  defp generate_module(modules, path, configurations, parsed_opts, template) do
    parsed_opts
    |> Map.put(:_configurations, configurations)
    |> Map.put(:_path, path)
    |> Map.put(:_resource_name, path.name)
    |> Map.put(:_mode, path.tag)
    |> then(&template.generate_module(modules, &1))
  end

  @spec locate_layout_paths(atom, list, atom) :: tuple
  defp locate_layout_paths(tag, layout_paths, resource_config_name) do
    layout_paths
    |> Enum.filter(&(&1.tag == tag && &1.name == resource_config_name))
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

  @spec disable_show_fields(map, atom) :: map
  defp disable_show_fields(%{inner_elements: inner_elements} = path, :show) do
    inner_elements
    |> add_global_overrides(disabled: true)
    |> then(&Map.put(path, :inner_elements, &1))
  end

  defp disable_show_fields(path, _), do: path

  @spec add_global_overrides(list, keyword, list) :: list
  defp add_global_overrides(elements, global_overrides, result \\ [])

  defp add_global_overrides([], _global_overrides, default), do: default

  defp add_global_overrides(
         [%{tag: :field, inner_elements: inner_elements} = element | elements],
         global_overrides,
         result
       ) do
    new_opts =
      element
      |> Map.get(:opts, [])
      |> then(&Keyword.merge(global_overrides, &1, fn _k, _global, opts -> opts end))

    new_inner_elements = add_global_overrides(inner_elements, global_overrides)
    new_element = Map.merge(element, %{opts: new_opts, inner_elements: new_inner_elements})

    add_global_overrides(elements, global_overrides, [new_element | result])
  end

  defp add_global_overrides(
         [%{inner_elements: inner_elements} = element | elements],
         global_overrides,
         result
       ) do
    inner_elements
    |> add_global_overrides(global_overrides)
    |> then(&Map.put(element, :inner_elements, &1))
    |> then(&add_global_overrides(elements, global_overrides, [&1 | result]))
  end

  @spec extract_resource_preloads(map) :: map
  defp extract_resource_preloads(configurations) do
    configurations
    |> Enum.map(fn {resource_name,
                    %{resource_config: %{fields: fields}, defaulted_paths: defaulted_paths}} ->
      defaulted_paths
      |> Enum.filter(&(elem(&1, 0) in [:index, :form, :show]))
      |> Enum.map(&elem(&1, 1))
      |> extract_resource_fields(fields)
      |> Enum.map(&{&1.name, &1.resource})
      |> Enum.uniq()
      |> then(&{resource_name, &1})
    end)
    |> expand_associations()
  end

  @spec extract_resource_fields(list, map, list) :: list
  defp extract_resource_fields(resources, fields, result \\ [])

  defp extract_resource_fields([], _fields, result) do
    result
  end

  defp extract_resource_fields(
         [%{inner_elements: inner_elements} = resource | resources],
         fields,
         result
       ) do
    resource
    |> maybe_add_association_info(fields)
    |> then(&extract_resource_fields(inner_elements, fields, [&1]))
    |> Enum.filter(
      &(&1.tag == :field and &1.field_type in [:one_to_many_association, :many_to_one_association])
    )
    |> Enum.reduce(result, &[&1 | &2])
    |> then(&extract_resource_fields(resources, fields, &1))
  end

  @spec maybe_add_association_info(map, map) :: map
  defp maybe_add_association_info(%{tag: :field, name: name} = field, fields) do
    fields
    |> Map.get(name, %{field_type: nil, resource: nil})
    |> then(
      &Map.merge(field, %{field_type: &1.field_type, resource: &1.resource, inner_elements: []})
    )
  end

  defp maybe_add_association_info(field, _fields), do: Map.put(field, :inner_elements, [])

  @spec expand_associations(list) :: map
  defp expand_associations(associations) do
    parsed_associations = parse_association(associations)

    associations
    |> Enum.map(fn {resource_name, children} ->
      children
      |> Enum.map(fn {field, related_resource} ->
        parsed_associations
        |> Map.get(related_resource, [])
        |> then(&{field, &1})
      end)
      |> then(&{resource_name, &1})
    end)
    |> Map.new()
  end

  @spec parse_association(list) :: map
  defp parse_association(associations) do
    associations
    |> Enum.map(fn {resource, children} ->
      children
      |> Enum.map(&elem(&1, 0))
      |> then(&{resource, &1})
    end)
    |> Map.new()
  end

  @spec build_resource_preload_option(tuple, map) :: tuple
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

  defp find_web_module(caller) do
    caller
    |> Module.split()
    |> Enum.reverse()
    |> check_web_module()
  end

  defp check_web_module([]), do: nil

  defp check_web_module([_ | module_paths]) do
    module_paths
    |> Enum.reverse()
    |> Module.concat()
    |> Code.ensure_compiled()
    |> extract_web_module(module_paths)
  end

  defp extract_web_module({:module, module}, _module_paths), do: module

  defp extract_web_module(_, module_paths), do: check_web_module(module_paths)
end
