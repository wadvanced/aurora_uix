defmodule AuroraUixWeb.Uix.CreateUI do
  @moduledoc """
    Provides functionality for defining and generating UI layouts and views.

  This module is responsible for creating base layouts, forms, and index views
  based on the provided schema configurations. It integrates with `AuroraUix.Parser`,
  and `AuroraUixWeb.Uix.Layout` to dynamically generate UI components.

  ## Usage
  - Use `__auix_create_ui__/3` to generate base layouts for a list of schema configurations.
  - Use the `layout/4` macro to define custom layouts within your modules.
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix.CreateUI
  alias AuroraUixWeb.Uix.SchemaConfigUI

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.CreateUI
      import AuroraUixWeb.Uix.Layout, only: [layout: 2, layout: 3]

      @before_compile AuroraUixWeb.Uix.CreateUI
    end
  end

  defmacro __before_compile__(env) do
    module = env.module
    opts = Module.get_attribute(module, :_auix_layouts_opts)

    module
    |> Module.get_attribute(:_auix_schema_configs, [])
    |> List.flatten()
    |> then(&CreateUI.__auix_create_ui__(module, &1, opts))
  end

  defmacro auix_create_ui(opts \\ []) do
    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_layouts_opts, unquote(opts))
    end
  end

  defmacro auix_create_ui(opts, do: block) do
    quote do
      use CreateUI
      Module.put_attribute(__MODULE__, :_auix_layouts_opts, unquote(opts))
      unquote(block)
    end
  end

  @doc """
  Generates base layouts for the given schema configurations.

  ## Parameters
  - `auix_schema_config`: A list of schema configurations or `nil`.
  - `opts`: A keyword list of options. The `:for` key specifies the target schema.

  ## Returns
  A list of generated layouts.
  """
  @spec __auix_create_ui__(any, list | nil, keyword) :: list
  def __auix_create_ui__(caller, auix_schema_configs, opts) do
    if schema_config_name = opts[:for] do
      generate_index_form_layouts(caller, auix_schema_configs, schema_config_name, opts)
    else
      generate_base_layouts(caller, auix_schema_configs, opts)
    end
  end

  ## PRIVATE

  @spec generate_base_layouts(module, list | nil, atom | nil) :: list
  defp generate_base_layouts(caller, auix_schema_configs, opts) do
    Enum.reduce(
      auix_schema_configs,
      [],
      &generate_index_form_layouts(caller, auix_schema_configs, elem(&1, 0), opts, &2)
    )
  end

  @spec generate_index_form_layouts(module, list | nil, atom, keyword, list) :: any
  defp generate_index_form_layouts(
         caller,
         auix_schema_config,
         schema_config_name,
         opts,
         acc \\ []
       ) do
    template = Template.uix_template()
    schema_config = SchemaConfigUI.__find_schema_config__(auix_schema_config, schema_config_name)
    schema_module = Map.get(schema_config, :schema)

    if is_nil(schema_module) do
      acc
    else
      parsed_opts =
        schema_module
        |> Parser.parse(opts)
        |> Map.put(:fields, schema_config.fields)

      {web, _} = caller |> Module.split() |> List.first() |> Code.eval_string()

      modules = %{
        caller: caller,
        module: schema_module,
        web: web,
        context: schema_config.context
      }

      Enum.each(modules, fn {_, module} -> Code.ensure_compiled(module) end)

      Enum.reduce(
        [:form, :index, :show],
        acc,
        &[template.generate_module(modules, &1, parsed_opts) | &2]
      )
    end
  end
end
