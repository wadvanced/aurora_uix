defmodule AuroraUixWeb.Uix.CreateUI do
  @moduledoc """
    Provides functionality for defining and generating UI layouts and views.

  This module is responsible for creating base layouts, forms, and index views
  based on the provided schema configurations. It integrates with `AuroraUix.Parser`,
  `AuroraUixWeb.Layouts`, and `AuroraUixWeb.Template` to dynamically generate
  UI components.

  ## Usage
  - Use `__auix_create_ui__/2` to generate base layouts for a list of schema configurations.
  - Use the `layout/4` macro to define custom layouts within your modules.
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Layouts
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix.SchemaConfigUI

  @doc """
  Generates base layouts for the given schema configurations.

  ## Parameters
  - `auix_schema_configs`: A list of schema configurations or `nil`.
  - `opts`: A keyword list of options. The `:for` key specifies the target schema.

  ## Returns
  A list of generated layouts.
  """
  @spec __auix_create_ui__(list | nil, keyword) :: list
  def __auix_create_ui__(auix_schema_configs, opts) do
    opt_for = opts[:for]

    generate_base_layouts(auix_schema_configs, opt_for)
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
  defmacro layout(_name, _type, _opts) do
  end

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

  @spec generate_base_layouts(list | nil, atom | nil) :: list
  defp generate_base_layouts(auix_schema_configs, nil) do
    Enum.reduce(
      auix_schema_configs,
      [],
      &generate_index_form_layouts(auix_schema_configs, elem(&1, 0), &2)
    )
  end

  @spec generate_index_form_layouts(list | nil, atom, list) :: any
  defp generate_index_form_layouts(auix_schema_configs, schema_config_name, acc) do
    template = Template.uix_template()
    schema = SchemaConfigUI.__find_schema_config__(auix_schema_configs, schema_config_name)
    module = Map.get(schema, :schema)

    if is_nil(module) do
      acc
    else
      parsed_opts = Parser.parse(module)

      layouts = %{
        form: generate(template, :form, parsed_opts),
        index: generate(template, :index, parsed_opts)
      }

      [{schema_config_name, layouts} | acc]
    end
  end

  @spec generate(module, atom, map) :: map
  defp generate(template, type, parsed_options) do
    %{
      view: template.generate_view(type, parsed_options)
    }
  end
end
