defmodule Aurora.Uix.Web.CoreComponents do
  @moduledoc """
  Core UI component provider for Aurora Uix. Imports appropriate component
  and helper functions based on configured templates.
  """
  alias Aurora.Uix.Web.Template

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
    core_components = opts[:core_components] || template.default_core_components()

    quote do
      import Phoenix.Component
      import unquote(core_components)
    end
  end
end
