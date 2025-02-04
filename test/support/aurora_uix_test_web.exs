defmodule AuroraUixTestWeb do
  @spec static_paths() :: [binary]
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  @spec router() :: Macro.t()
  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @spec live_view() :: Macro.t()
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {AuroraUixTestWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  @spec live_component() :: Macro.t()
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  @spec verified_routes() :: Macro.t()
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AuroraUixTestWeb.Endpoint,
        router: AuroraUixTestWeb.Router,
        statics: AuroraUixTestWeb.static_paths()
    end
  end

  @spec aurora_uix_for_test() :: Macro.t()
  def aurora_uix_for_test do
    quote do
      Module.register_attribute(__MODULE__, :_auix_schema_configs, persist: true)
      Module.register_attribute(__MODULE__, :_auix_layouts, persist: true)

      use AuroraUixWeb.Uix
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  ## PRIVATE
  @spec html_helpers() :: Macro.t()
  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import AuroraUixTestWeb.CoreComponents
      import AuroraUixTestWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end
end
