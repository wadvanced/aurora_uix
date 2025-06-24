defmodule Aurora.Uix.Web.CoreComponentsImporter do
  @moduledoc """
  Core UI component provider for Aurora UIX.

  ## Purpose
  Imports the appropriate core component and helper functions based on the configured template.
  This module enables dynamic selection of UI component modules, allowing for flexible and
  customizable UI composition in Aurora UIX-based applications.

  ## Key Constraints
  - Only imports components from the configured template or the default core components module.
  - Intended for use in modules that require dynamic UI component imports.
  """
  alias Aurora.Uix.Template

  @doc """
  Imports component and helper functions from the configured template.

  ## Parameters
  - `opts` (keyword()) - Configuration options. Options:
    * `:core_components_module` (module()) - Optional. The module to import as core components.
      If not provided, the default core components module from the template is used.

  ## Returns
  - `Macro.t()` - A quoted expression that imports the selected core components and Phoenix.Component.

  ## Examples
  ```elixir
  defmodule MyAppWeb.MyComponent do
    use Aurora.Uix.Web.CoreComponentsImporter, core_components_module: MyAppWeb.CustomComponents
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
