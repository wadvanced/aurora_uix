defmodule Aurora.Uix.RendererRegistrar do
  @moduledoc """
  Behaviour for a module that registers predefined field renderers.

  A registrar exposes a single map of `atom => render_function`, where each value is an
  arity-1 function `(assigns) -> Phoenix.LiveView.Rendered.t()` — typically a renderer
  module's `&render/1` capture (see `Aurora.Uix.Renderer`). The reserved `:default` key
  holds the fallback renderer. The built-in registrar is `Aurora.Uix.Renderers.BuiltIn`.

  Host applications extend or override the catalog by implementing this behaviour and
  pointing the library at it:

  ```elixir
  # config/config.exs
  config :aurora_uix, :renderers, MyApp.Renderers

  # lib/my_app/renderers.ex
  defmodule MyApp.Renderers do
    @behaviour Aurora.Uix.RendererRegistrar

    @impl true
    def renderers do
      %{
        # add a brand new renderer
        uppercase: &MyApp.Renderers.Uppercase.render/1,
        # replace a built-in wholesale (host keys win on collision)
        toggle_switch: &MyApp.Renderers.FancyToggle.render/1
      }
    end
  end
  ```

  The resolver (`Aurora.Uix.Renderers`) merges the built-in map with the host map,
  host keys overriding built-ins.
  """

  @doc "Returns the map of renderer name atoms to their arity-1 render functions."
  @callback renderers() :: %{atom() => (map() -> Phoenix.LiveView.Rendered.t())}
end
