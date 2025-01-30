defmodule AuroraUixWeb.Uix.DefineUI do
  @moduledoc """
  Enables the definition of views and components.
  """

  alias AuroraUix.Parser
  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Uix.SchemaMetadataUI

  @spec __auix_define__(module, keyword) :: :ok
  def __auix_define__(module, opts) do
    generate_default_layouts(module, opts[:for])
  end

  @spec layout(atom, atom, Keyword.t(), Keyword.t() | nil) :: Macro.t()
  defmacro layout(_name, _type, _opts) do
  end

  defmacro layout(name, type, opts, do: block) do
    quote do
      import AuroraUixWeb.Layouts

      AuroraUixWeb.Layouts.__auix_layout__(
        __MODULE__,
        unquote(name),
        unquote(type),
        unquote(opts)
      )

      unquote(block)
    end
  end

  ## PRIVATE

  @spec generate_default_layouts(module, atom | nil) :: :ok
  defp generate_default_layouts(module, nil) do
    Module.put_attribute(module, :_auix_layouts, %{})
  end

  defp generate_default_layouts(module, metadata_name) do
    template = Template.uix_template()
    schema = SchemaMetadataUI.__get_metadata__(module, metadata_name)
    module = Map.get(schema, :schema)

    if !is_nil(module) do
      parsed_opts = Parser.parse(module)

      layouts = %{
        form: generate(template, :form, parsed_opts),
        index: generate(template, :index, parsed_opts)
      }

      Module.put_attribute(module, :_auix_layouts, layouts)
    end
  end

  @spec generate(module, atom, map) :: map
  defp generate(template, type, parsed_options) do
    %{
      view: template.generate_view(type, parsed_options)
    }
  end
end
