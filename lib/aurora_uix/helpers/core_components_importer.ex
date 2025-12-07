defmodule Aurora.Uix.CoreComponentsImporter do
  @moduledoc """
  Provides dynamic selection and import of UI component modules based on template configuration.
  """
  alias Aurora.Uix.Template

  @doc """
  Imports component and helper functions from the configured template.

  Dynamically selects the core components module from either the provided options or the
  template configuration, and imports it along with Phoenix.Component.

  ## Parameters
  - `opts` (keyword()) - Configuration options. Options:
    * `:core_components_module` (module()) - Optional. Override the default core components
      module. If not provided, uses the module returned by the template's
      `default_core_components_module/0` callback.

  ## Returns
  Macro.t() - A quoted expression that imports Phoenix.Component and the selected core
  components module.

  ## Examples
  ```elixir
  defmodule MyAppWeb.MyComponent do
    use Aurora.Uix.CoreComponentsImporter
  end

  defmodule MyAppWeb.CustomComponent do
    use Aurora.Uix.CoreComponentsImporter, core_components_module: MyAppWeb.CustomComponents
  end
  ```
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    template = Template.uix_template()

    core_components_module =
      opts[:core_components_module] || template.default_core_components_module()

    quote do
      import Phoenix.Component
      import unquote(core_components_module)
    end
  end
end
