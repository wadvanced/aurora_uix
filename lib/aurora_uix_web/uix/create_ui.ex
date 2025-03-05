defmodule AuroraUixWeb.Uix.CreateUI do
  @moduledoc """
    Provides functionality for defining and generating UI layouts and views.

  This module is responsible for creating base layouts, forms, and index views
  based on the provided schema configurations. It integrates with `AuroraUix.Parser`,
  and `AuroraUixWeb.Uix.CreateUI.LayoutConfigUI` to dynamically generate UI components.

  ## Usage
  - Use `create_ui/3` to generate base layouts for a list of schema configurations.
  - Use the `layout/4` macro to define custom layouts within your modules.
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix
  alias AuroraUixWeb.Uix.CreateUI
  alias AuroraUixWeb.Uix.DataConfigUI

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.CreateUI
      use AuroraUixWeb.Uix.CreateUI.LayoutConfigUI

      @before_compile AuroraUixWeb.Uix.CreateUI
    end
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module
    opts = Module.get_attribute(module, :_auix_form_layouts_opts)

    layout_paths =
      Module.get_attribute(module, :_auix_layout_paths, [])

    module
    |> Module.get_attribute(:_auix_resource_configs, [])
    |> List.flatten()
    |> then(&CreateUI.create_ui(module, &1, layout_paths, opts))
  end

  defmacro auix_create_ui(opts \\ [], do_block \\ nil) do
    {block, opts} = Uix.extract_block_options(opts, do_block)

    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_form_layouts_opts, unquote(opts))
      unquote(block)
    end
  end

  @doc """
  Generates base layouts for the given schema configurations.

  ## Parameters
  - `caller` (module): Host module for the generated children modules.
  - `auix_resource_config` (list): A list of schema configurations or `nil`.
  - `opts` (keyword): A keyword list of options. The `:for` key specifies the target schema.

  ## Returns
  A list of generated layouts.
  """
  @spec create_ui(any, list | nil, list, keyword) :: list
  def create_ui(caller, auix_resource_configs_ui, layout_paths, opts) do
    if resource_config_name = opts[:for] do
      generate_index_form_layouts(
        caller,
        auix_resource_configs_ui,
        resource_config_name,
        layout_paths,
        opts
      )
    else
      generate_base_layouts(caller, auix_resource_configs_ui, layout_paths, opts)
    end
  end

  ## PRIVATE

  @spec generate_base_layouts(module, list | nil, list, keyword) :: list
  defp generate_base_layouts(caller, auix_resource_configs_ui, layout_paths, opts) do
    Enum.reduce(
      auix_resource_configs_ui,
      [],
      &generate_index_form_layouts(
        caller,
        auix_resource_configs_ui,
        elem(&1, 0),
        layout_paths,
        opts,
        &2
      )
    )
  end

  @spec generate_index_form_layouts(module, list | nil, atom, list, keyword, list) :: any
  defp generate_index_form_layouts(
         caller,
         auix_resource_config,
         resource_config_name,
         layout_paths,
         opts,
         acc \\ []
       ) do
    template = Template.uix_template()

    resource_config =
      DataConfigUI.__find_schema_config__(auix_resource_config, resource_config_name)

    resource_module = Map.get(resource_config, :schema)

    if is_nil(resource_module) do
      acc
    else
      parsed_opts =
        resource_module
        |> Parser.parse(opts)
        |> Map.put(:fields, resource_config.fields)

      parsed_paths =
        layout_paths
        |> Enum.reverse()
        |> find_layout_paths(resource_config_name)
        |> generate_default_layout_paths(resource_config_name, parsed_opts)
        |> Enum.map(&expand_fields(&1, parsed_opts))

      form_fields = Enum.map_join(parsed_paths, "", &template.parse_layout(&1, :form))

      show_fields = Enum.map_join(parsed_paths, "", &template.parse_layout(&1, :entity))

      parsed_opts = Map.merge(parsed_opts, %{form_fields: form_fields, show_fields: show_fields})

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

  @spec find_layout_paths(list, atom) :: list
  defp find_layout_paths(layout_paths, resource_config_name) do
    layout_paths
    |> do_find_layout_path(resource_config_name, [])
    |> Enum.reverse()
  end

  @spec do_find_layout_path(list, atom, list) :: list
  defp do_find_layout_path(
         [%{tag: :layout, state: _start, config: {:name, resource_config_name}} = path | rest],
         resource_config_name,
         paths
       ) do
    append_layout_path(rest, [path | paths])
  end

  defp do_find_layout_path([_ | rest], resource_config_name, _paths),
    do: do_find_layout_path(rest, resource_config_name, [])

  defp do_find_layout_path([], _resource_config_name, _paths), do: []

  @spec append_layout_path(list, list) :: list
  defp append_layout_path([%{tag: :layout, state: :end} = path | _rest], paths),
    do: [path | paths]

  defp append_layout_path([], paths), do: paths
  defp append_layout_path([path | rest], paths), do: append_layout_path(rest, [path | paths])

  @spec generate_default_layout_paths(list, atom, map) :: list
  defp generate_default_layout_paths([], resource_config_name, %{fields: fields}) do
    inline = Enum.map(fields, & &1.field)

    [
      %{tag: :layout, state: :start, config: {:name, resource_config_name}, opts: []},
      %{tag: :inline, state: :start, config: {:fields, inline}, opts: []},
      %{tag: :inline, state: :end},
      %{tag: :layout, state: :end}
    ]
  end

  defp generate_default_layout_paths(paths, _resource_config_name, _parsed_opts), do: paths

  @spec expand_fields(map, map) :: map
  defp expand_fields(%{config: {:fields, fields}} = path, %{fields: configured_fields}) do
    fields
    |> Enum.map(&expand_field(&1, configured_fields))
    |> then(&Map.put(path, :config, {:fields, &1}))
  end

  defp expand_fields(path, _parsed_opts), do: path

  @spec expand_field(tuple, list) :: map
  defp expand_field(overrode_field, configured_fields) when is_tuple(overrode_field) do
    overrides = elem(overrode_field, 1)

    overrode_field
    |> elem(0)
    |> then(&find_field(configured_fields, &1))
    |> struct(overrides)
  end

  defp expand_field(field, configured_fields), do: find_field(configured_fields, field)

  @spec find_field(list, atom) :: map
  defp find_field(configured_fields, field) do
    Enum.find(configured_fields, &(&1.field == field))
  end
end
