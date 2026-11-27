defmodule Aurora.Uix.CoreComponentsImporter do
  @moduledoc """
  Imports `Phoenix.Component` and the core components of the template, as returned by its
  `default_core_components_module/0` callback.

  ## Key Features

  - One `use` line brings the components such as `<.button>` and `<.input>`

  ## Key Constraints

  - It takes no options. To replace components at runtime, configure
    `config :aurora_uix, :core_components, MyApp.MyCoreComponents`
    (see `Aurora.Uix.ComponentsResolver`)

  ## Examples
  ```elixir
  defmodule MyAppWeb.MyComponent do
    use Aurora.Uix.CoreComponentsImporter
  end
  ```
  """
  alias Aurora.Uix.Template

  @doc false
  # Imports component and helper functions from the configured template.
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    template = Template.uix_template()

    core_components_module = template.default_core_components_module()

    quote do
      import Phoenix.Component
      import unquote(core_components_module)
    end
  end
end
