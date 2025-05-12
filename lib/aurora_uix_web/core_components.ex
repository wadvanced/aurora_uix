defmodule Aurora.Uix.Web.CoreComponents do
  @moduledoc """
  This module provides core components for the Aurora Uix web application.
  It includes helper functions and macros for building UI components
  and templates using Phoenix LiveView.
  """
  alias Aurora.Uix.Web.Template

  @spec __using__(keyword) :: Macro.t()
  @doc """
  When used, dispatch to the appropriate component or helper functions.
  """
  defmacro __using__(opts) do
    template = Template.uix_template()
    core_components = opts[:core_components] || template.default_core_components()

    quote do
      import unquote(core_components)
    end
  end
end
