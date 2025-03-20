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

    module
    |> Module.get_attribute(:_auix_resource_configs, %{})
    |> List.first()
    |> then(&CreateUI.build_ui(module, &1, layout_paths, opts))
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
  @spec build_ui(any, map | nil, list, keyword) :: list
  def build_ui(caller, auix_resource_configs_ui, layout_paths, opts) do
    if resource_config_name = opts[:for] do
      build_index_form_layouts(
        caller,
        auix_resource_configs_ui,
        resource_config_name,
        layout_paths,
        opts
      )
    else
      build_base_layouts(caller, auix_resource_configs_ui, layout_paths, opts)
    end
  end

  ## PRIVATE

  @spec build_base_layouts(module, map | nil, list, keyword) :: list
  defp build_base_layouts(caller, auix_resource_configs_ui, layout_paths, opts) do
    Enum.reduce(
      auix_resource_configs_ui,
      [],
      &build_index_form_layouts(
        caller,
        auix_resource_configs_ui,
        elem(&1, 0),
        layout_paths,
        opts,
        &2
      )
    )
  end

  @spec build_index_form_layouts(module, map | nil, atom, list, keyword, list) :: any
  defp build_index_form_layouts(
         caller,
         auix_resource_config,
         resource_config_name,
         layout_paths,
         opts,
         acc \\ []
       ) do
    template = Template.uix_template()

    resource_config = Map.get(auix_resource_config, resource_config_name)

    resource_module = Map.get(resource_config, :schema)

    if is_nil(resource_module) do
      acc
    else
      parsed_opts =
        resource_module
        |> Parser.parse(opts)
        |> Map.put(:fields, resource_config.fields)

      layouts = %{index: :index_columns, form: :form_fields, show: :show_fields}

      # Get all layout paths
      paths =
        layouts
        |> Enum.map(&locate_layout_paths(&1, layout_paths, resource_config_name))
        |> Map.new()
        |> fill_missing_paths(:form, :show)

      parsed_opts =
        layouts
        |> Enum.map(&parse_template_paths(&1, paths, resource_config_name, parsed_opts, template))
        |> Map.new()
        |> then(&Map.merge(parsed_opts, &1))

      {web, _} = caller |> Module.split() |> List.first() |> Code.eval_string()

      modules = %{
        caller: caller,
        module: resource_module,
        web: web,
        context: resource_config.context
      }

      Enum.each(modules, fn {_, module} -> Code.ensure_compiled(module) end)

      Enum.reduce(
        [:form, :index, :show],
        acc,
        &[template.generate_module(modules, &1, parsed_opts) | &2]
      )
    end
  end

  @spec parse_template_paths(tuple, map, atom, map, module) :: tuple
  defp parse_template_paths({tag, key}, paths, resource_config_name, parsed_opts, template) do
    paths
    |> Map.get(tag)
    |> LayoutConfigUI.build_default_layout_paths(resource_config_name, parsed_opts, tag)
    |> LayoutConfigUI.parse_sections(tag)
    |> Enum.map_join(&parse_template_path(&1, parsed_opts, tag, template))
    |> then(&{key, &1})
  end

  @spec parse_template_path(map, map, atom, module) :: binary
  defp parse_template_path(path, parsed_opts, :show = tag, template) do
    path
    |> expand_fields(parsed_opts, %{disabled: true})
    |> template.parse_layout(tag)
  end

  defp parse_template_path(path, parsed_opts, tag, template) do
    path
    |> expand_fields(parsed_opts, %{})
    |> template.parse_layout(tag)
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
end
