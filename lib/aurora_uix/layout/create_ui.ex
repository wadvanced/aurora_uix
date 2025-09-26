defmodule Aurora.Uix.Layout.CreateUI do
  @moduledoc """
  Provides a framework for dynamically generating UI layouts for Phoenix applications.

  This module offers a compile-time mechanism to create UI components for resources,
  including index, form, and show views, based on a flexible configuration.

  ## Key Features

  - **Compile-Time UI Generation**: Generates UI modules for resources at compile time, minimizing runtime overhead.
  - **Flexible Layout Configuration**: Allows for detailed customization of layouts using a DSL.
  - **Automatic View Generation**: Automatically creates modules for index, form, and show views.
  - **Schema Integration**: Integrates with Ecto schemas to infer field types and associations.

  ## Usage

  To use this module, you `use Aurora.Uix.Layout.CreateUI` in your view module and then define the UI using `auix_create_ui/2`.

  ## Example

  ```elixir
  defmodule MyApp.ProductViews do
    use Aurora.Uix

    auix_create_ui for: :product do
      index_columns [:name, :price]
      edit_layout do
        inline [:name, :price]
      end
    end
  end
  ```
  """

  alias Aurora.Uix.BehaviourHelper
  alias Aurora.Uix.Layout.Blueprint
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
  alias Aurora.Uix.Parser
  alias Aurora.Uix.Template

  @doc """
  Generates UI modules before the module is compiled.

  This macro is triggered before compilation, gathering all `auix_layout_trees`
  and `auix_layout_opts` attributes to build the final UI modules.
  It merges layout trees, processes resource metadata, and injects the
  generated modules into the calling module.

  ## Parameters
  - `env` (`Macro.Env.t()`) - The macro environment.

  ## Returns
  `Macro.t()` - A quoted expression containing the generated UI modules.
  """
  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module

    layout_trees =
      Module.get_attribute(module, :auix_layout_trees, [])

    opts =
      Module.get_attribute(module, :auix_layout_opts, [])

    ## Merge layout paths
    merged_layout_trees =
      layout_trees
      |> Enum.group_by(&{&1.name, &1.tag})
      |> Enum.map(&merge_layout_trees/1)

    modules =
      module
      |> Module.get_attribute(:auix_resource_metadata, [])
      |> Enum.reduce(%{}, fn resource, acc ->
        Enum.reduce(resource, acc, &Map.put(&2, elem(&1, 0), elem(&1, 1)))
      end)
      |> build_ui(module, merged_layout_trees, opts)

    quote do
      unquote(modules)
    end
  end

  @doc """
  Configures and initiates UI generation for a specific module.

  ## Parameters
  - `opts` (`Keyword.t()`) - Configuration options for UI generation.
  - `do_block` (`Macro.t()` | `nil`) - An optional configuration block for advanced layouts.

  ## Options
  - `:for` (`atom()`) - The target resource name to generate the UI for.

  ## Returns
  `Macro.t()` - A quoted expression that sets up the UI configuration.

  ## Example
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
    layouts = LayoutHelpers.create_layout(block, __CALLER__)

    quote do
      import Blueprint

      @before_compile Aurora.Uix.Layout.CreateUI

      unquote(quoted_opts)
      unquote(layouts)
    end
  end

  @doc """
  Builds UI layouts based on resource configurations.

  ## Parameters
  - `resource_configs` (`map()`) - A map of resource configurations.
  - `caller` (`module()`) - The calling module.
  - `layout_trees` (`list()`) - A list of layout tree definitions.
  - `opts` (`Keyword.t()`) - Configuration options.

  ## Options
  - `:for` (`atom()` | `list()`) - Generates UI for one or more specific resources.

  ## Returns
  `list()` - A list of quoted expressions representing the generated UI layout modules.
  """
  @spec build_ui(map(), module(), list(), keyword()) :: list()
  def build_ui(resource_configs, caller, layout_trees, opts) do
    resource_configs
    |> filter_resources(opts[:for])
    |> build_layouts(caller, layout_trees, opts)
  end

  ## PRIVATE

  # Merges layout paths by their name and tag, combining inner elements and options.
  @spec merge_layout_trees(tuple()) :: list()
  defp merge_layout_trees({_, paths}) do
    Enum.reduce(paths, nil, &merge_layout_opts_inner_elements/2)
  end

  # Merges the inner elements and options of two layout paths.
  @spec merge_layout_opts_inner_elements(map(), map() | nil) :: map()
  defp merge_layout_opts_inner_elements(layout_tree, nil), do: layout_tree

  defp merge_layout_opts_inner_elements(layout_tree, acc) do
    opts = Keyword.merge(acc.opts, layout_tree.opts)

    inner_elements =
      acc.inner_elements
      |> Enum.reverse()
      |> then(
        &Enum.reduce(layout_tree.inner_elements, &1, fn path_element, acc_elements ->
          [path_element | acc_elements]
        end)
      )

    acc
    |> Map.put(:opts, opts)
    |> Map.put(:inner_elements, inner_elements)
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
  @spec build_layouts(map(), module(), list(), keyword()) :: [Macro.t()]
  defp build_layouts(resource_configs, caller, layout_trees, opts) do
    configurations =
      resource_configs
      |> Enum.reduce(
        [],
        &[build_configurations(caller, &1, layout_trees, opts) | &2]
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

  # Builds the configuration for a single resource.
  @spec build_configurations(module(), {atom(), map()}, list(), keyword()) :: map() | nil
  defp build_configurations(
         caller,
         {resource_config_name, resource_config},
         layout_trees,
         opts
       ) do
    template =
      caller
      |> Module.get_attribute(:auix_template)
      |> BehaviourHelper.validate(Template)

    resource_module = Map.get(resource_config, :schema)

    if is_nil(resource_module) do
      nil
    else
      parsed_opts = Parser.parse(resource_config, opts)
      layouts = [:index, :form, :show]

      # Get all layout paths

      paths =
        layouts
        |> Enum.map(&locate_layout_trees(&1, layout_trees, resource_config_name))
        |> Map.new()
        |> fill_missing_paths(:form, :show)

      layout_trees =
        layouts
        |> Enum.map(fn tag ->
          paths
          |> Map.get(tag)
          |> Blueprint.build_default_layout_paths(resource_config, opts, tag)
          |> Blueprint.parse_sections(tag)
          |> then(&{tag, &1})
        end)
        |> Map.new()

      {resource_config_name,
       %{
         resource_config_name: resource_config_name,
         resource_config: resource_config,
         layouts: layouts,
         parsed_opts: parsed_opts,
         layout_trees: layout_trees,
         template: template
       }}
    end
  end

  # Builds the resource-specific layouts.
  @spec build_resource_layouts(tuple(), map(), module()) :: list()
  defp build_resource_layouts(
         {_resource_config_name,
          %{
            resource_config: resource_config,
            layouts: layouts,
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
      layouts,
      [],
      &[
        generate_module(
          modules,
          Map.get(layout_trees, &1, %{}),
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
  @spec generate_module(map(), map(), map(), map(), module()) :: Macro.t()
  defp generate_module(modules, layout_tree, configurations, parsed_opts, template) do
    parsed_opts
    |> Map.put(:configurations, configurations)
    |> Map.put(:modules, modules)
    |> Map.put(:layout_tree, layout_tree)
    |> Map.put(:resource_name, layout_tree.name)
    |> Map.put(:layout_type, layout_tree.tag)
    |> then(&template.generate_module(&1))
  end

  # Locates layout trees for a specific tag and resource name.
  @spec locate_layout_trees(atom(), list(), atom()) :: tuple()
  defp locate_layout_trees(tag, layout_trees, resource_config_name) do
    layout_trees
    |> Enum.filter(&(&1.tag == tag && &1.name == resource_config_name))
    |> then(&{tag, &1})
  end

  # Fills missing layout paths by copying from another layout type.
  @spec fill_missing_paths(map(), atom(), atom()) :: map()
  defp fill_missing_paths(layout_trees, from, to) do
    layout_trees
    |> Map.get(from, [])
    |> fill_missing_paths_recursive(layout_trees[to], from, to)
    |> then(&Map.put(layout_trees, to, &1))
  end

  # Recursively fills missing layout paths.
  @spec fill_missing_paths_recursive(list(), list(), atom(), atom()) :: list()
  defp fill_missing_paths_recursive(from_paths, to_paths, from, to)
       when is_nil(to_paths) or to_paths == [],
       do: Enum.map(from_paths, &update_layout_path_tag(&1, from, to))

  defp fill_missing_paths_recursive(_from_paths, to_paths, _from, _to), do: to_paths

  # Updates the tag of a layout path.
  @spec update_layout_path_tag(map(), atom(), atom()) :: map()
  defp update_layout_path_tag(%{tag: from} = layout_tree, from, to),
    do: Map.put(layout_tree, :tag, to)

  defp update_layout_path_tag(layout_tree, _from, _to), do: layout_tree

  # Extracts resource preloads from configurations.
  @spec extract_resource_preloads(map()) :: map()
  defp extract_resource_preloads(configurations) do
    configurations
    |> Enum.map(fn {resource_name,
                    %{resource_config: %{fields: fields}, layout_trees: layout_trees}} ->
      layout_trees
      |> Enum.filter(&(elem(&1, 0) in [:index, :form, :show]))
      |> Enum.map(&elem(&1, 1))
      |> extract_resource_fields(fields)
      |> Enum.map(&{&1.name, &1.resource})
      |> Enum.uniq()
      |> then(&{resource_name, &1})
    end)
    |> expand_associations()
  end

  # Extracts resource fields from a list of resources.
  @spec extract_resource_fields(list(), map(), list()) :: list()
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
      &(&1.tag == :field and &1.type in [:one_to_many_association, :many_to_one_association])
    )
    |> Enum.reduce(result, &[&1 | &2])
    |> then(&extract_resource_fields(resources, fields, &1))
  end

  # Adds association information to a field if it's an association.
  @spec maybe_add_association_info(map(), map()) :: map()

  defp maybe_add_association_info(%{tag: :field, name: names} = field, fields)
       when is_tuple(names) do
    names
    |> Tuple.to_list()
    |> List.first()
    |> then(&Map.put(field, :name, &1))
    |> maybe_add_association_info(fields)
  end

  defp maybe_add_association_info(%{tag: :field, name: name} = field, fields) do
    fields
    |> Map.get(name, %{type: nil, resource: nil})
    |> then(&Map.merge(field, %{type: &1.type, resource: &1.resource, inner_elements: []}))
  end

  defp maybe_add_association_info(field, _fields), do: Map.put(field, :inner_elements, [])

  # Expands nested associations for preloading.
  @spec expand_associations(list()) :: map()
  defp expand_associations(associations) do
    parsed_associations = parse_association(associations)

    associations
    |> Enum.map(fn {resource_name, children} ->
      children
      |> Enum.map(fn
        {field, ^resource_name} ->
          {field, []}

        {field, related_resource} ->
          parsed_associations
          |> Map.get(related_resource, [])
          |> then(&{field, &1})
      end)
      |> then(&{resource_name, &1})
    end)
    |> Map.new()
  end

  # Parses associations into a map.
  @spec parse_association(list()) :: map()
  defp parse_association(associations) do
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
