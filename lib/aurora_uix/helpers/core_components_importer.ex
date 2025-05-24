defmodule Aurora.Uix.Web.CoreComponentsImporter do
  @moduledoc """
  Core UI component provider for Aurora Uix. Imports appropriate component
  and helper functions based on configured templates.
  """
  alias Aurora.Uix.Template

  @doc """
  Imports component and helper functions from configured templates.

  ## Parameters
    - opts (keyword()) - Configuration options with optional core_components setting

  Returns:
    - Macro.t()
  """
  @spec __using__(keyword) :: Macro.t()
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
