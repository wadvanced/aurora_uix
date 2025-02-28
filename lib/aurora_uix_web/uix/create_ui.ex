defmodule AuroraUixWeb.Uix.CreateUI do
  @moduledoc """
    Provides functionality for defining and generating UI layouts and views.

  This module is responsible for creating base layouts, forms, and index views
  based on the provided schema configurations. It integrates with `AuroraUix.Parser`,
  and `AuroraUixWeb.Uix.LayoutConfigUI` to dynamically generate UI components.

  ## Usage
  - Use `__auix_create_ui__/3` to generate base layouts for a list of schema configurations.
  - Use the `layout/4` macro to define custom layouts within your modules.
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix.CreateUI
  alias AuroraUixWeb.Uix.DataConfigUI
  alias AuroraUixWeb.Uix.LayoutConfigUI

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.CreateUI
      use AuroraUixWeb.Uix.LayoutConfigUI

      @before_compile AuroraUixWeb.Uix.CreateUI
    end
  end

  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module
    opts = Module.get_attribute(module, :_auix_form_layouts_opts)

    form_layouts =
      module
      |> Module.get_attribute(:_auix_form_layouts, [])
      |> List.flatten()
      |> Map.new()

    module
    |> Module.get_attribute(:_auix_resource_configs, [])
    |> List.flatten()
    |> LayoutConfigUI.generate_form_layouts(form_layouts)
    |> then(&CreateUI.__auix_create_ui__(module, &1, opts))
  end

  defmacro auix_create_ui(opts \\ []) do
    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_form_layouts_opts, unquote(opts))
    end
  end

  defmacro auix_create_ui(opts, do: block) do
    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_form_layouts_opts, unquote(opts))
      unquote(block)
    end
  end

  @doc """
  Generates base layouts for the given schema configurations.

  ## Parameters
  - `auix_resource_config` (list): A list of schema configurations or `nil`.
  - `opts` (keyword): A keyword list of options. The `:for` key specifies the target schema.

  ## Returns
  A list of generated layouts.
  """
  @spec __auix_create_ui__(any, list | nil, keyword) :: list
  def __auix_create_ui__(caller, auix_resource_configs_ui, opts) do
    if resource_config_name = opts[:for] do
      generate_index_form_layouts(caller, auix_resource_configs_ui, resource_config_name, opts)
    else
      generate_base_layouts(caller, auix_resource_configs_ui, opts)
    end
  end

  ## PRIVATE

  @spec generate_base_layouts(module, list | nil, atom | nil) :: list
  defp generate_base_layouts(caller, auix_resource_configs_ui, opts) do
    Enum.reduce(
      auix_resource_configs_ui,
      [],
      &generate_index_form_layouts(caller, auix_resource_configs_ui, elem(&1, 0), opts, &2)
    )
  end

  @spec generate_index_form_layouts(module, list | nil, atom, keyword, list) :: any
  defp generate_index_form_layouts(
         caller,
         auix_resource_config,
         resource_config_name,
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

      {web, _} = caller |> Module.split() |> List.first() |> Code.eval_string()

      modules = %{
        caller: caller,
        module: resource_module,
        web: web,
        context: resource_config.context
      }

      Enum.each(modules, fn {_, module} -> Code.ensure_compiled(module) end)

      Enum.reduce(
        [:form, :index],
        # [:form, :index, :show],
        acc,
        &[template.generate_module(modules, &1, parsed_opts) | &2]
      )
    end
  end
end
