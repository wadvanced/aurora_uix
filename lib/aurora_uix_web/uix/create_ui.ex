defmodule AuroraUixWeb.Uix.CreateUI do
  @moduledoc """
    Provides functionality for defining and generating UI layouts and views.

  This module is responsible for creating base layouts, forms, and index views
  based on the provided schema configurations. It integrates with `AuroraUix.Parser`,
  `AuroraUixWeb.Layouts`, and `AuroraUixWeb.Template` to dynamically generate
  UI components.

  ## Usage
  - Use `__auix_create_ui__/3` to generate base layouts for a list of schema configurations.
  - Use the `layout/4` macro to define custom layouts within your modules.
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Layouts
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix.CreateUI
  alias AuroraUixWeb.Uix.SchemaConfigUI

  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.CreateUI

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

  @doc """
    Defines a layout for a given name and type.

    This macro is used to define a layout block within a module. It delegates
    to `Layouts.__auix_layout__/4` to handle the actual layout generation.

    ## Parameters
    - `name`: The name of the layout (atom).
    - `type`: The type of the layout (atom).
    - `opts`: A keyword list of options for the layout.
    - `block`: A `do` block containing the layout definition.

    ## Example
        layout :my_layout, :form, [class: "form-layout"] do
          # Layout content
        end
  """
  @spec layout(atom, atom, Keyword.t(), Keyword.t() | nil) :: Macro.t()
  defmacro layout(_name, _type, _opts), do: :ok

  defmacro layout(name, type, opts, do: block) do
    quote do
      import Layouts

      Layouts.__auix_layout__(
        __MODULE__,
        unquote(name),
        unquote(type),
        unquote(opts)
      )

      unquote(block)
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
