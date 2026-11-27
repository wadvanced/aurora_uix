defmodule Aurora.Uix.CoreComponentsImporter do
  @moduledoc """
  Dynamically selects the core components module from either the provided options or the
  template configuration, and imports it along with Phoenix.Component.

  ## Options
  - `:core_components_module` (module()) - Optional. Override the default core components
    module. If not provided, uses the module returned by the template's
    `default_core_components_module/0` callback.

  The library's own modules compile before the host application's modules. When the configured
  template is not available yet, the default template's (`Aurora.Uix.Templates.Basic`) core
  components are imported, so a template defined in the host application can be configured.

  ## Examples
  ```elixir
    defmodule MyAppWeb.MyComponent do
      use Aurora.Uix.CoreComponentsImporter
    end
  ```
  """
  alias Aurora.Uix.Template
  alias Aurora.Uix.Templates.Basic

  @configured_template Application.compile_env(:aurora_uix, :template, Basic)

  @doc false
  # Imports component and helper functions from the configured template.
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    core_components_module = template().default_core_components_module()

    quote do
      import Phoenix.Component
      import unquote(core_components_module)
    end
  end

  ## PRIVATE

  @spec template() :: module()
  defp template do
    case Code.ensure_compiled(@configured_template) do
      {:module, _template} -> Template.uix_template()
      {:error, _reason} -> Basic
    end
  end
end
