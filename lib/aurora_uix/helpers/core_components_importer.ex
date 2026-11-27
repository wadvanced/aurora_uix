defmodule Aurora.Uix.CoreComponentsImporter do
  @moduledoc """
  Dynamically selects the core components module from either the provided options or the
  template configuration, and imports it along with Phoenix.Component.

  ## Options
  - `:core_components_module` (module()) - Optional. Override the default core components
    module. If not provided, uses the module returned by the template's
    `default_core_components_module/0` callback.
  - `:template` (module()) - Optional. The template whose core components are imported.
    Defaults to the configured template (`Aurora.Uix.Template.uix_template/0`). The library's
    own template modules name it, because they compile before the host application's modules
    exist, so a template defined in the host application cannot be resolved for them.

  ## Examples
  ```elixir
    defmodule MyAppWeb.MyComponent do
      use Aurora.Uix.CoreComponentsImporter
    end
  ```
  """
  alias Aurora.Uix.BehaviourHelper
  alias Aurora.Uix.Template

  @doc false
  # Imports component and helper functions from the configured template.
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    core_components_module =
      case Keyword.fetch(opts, :core_components_module) do
        {:ok, core_components_module} ->
          Macro.expand(core_components_module, __CALLER__)

        :error ->
          opts
          |> Keyword.get_lazy(:template, &Template.uix_template/0)
          |> Macro.expand(__CALLER__)
          |> BehaviourHelper.validate(Template)
          |> then(& &1.default_core_components_module())
      end

    quote do
      import Phoenix.Component
      import unquote(core_components_module)
    end
  end
end
