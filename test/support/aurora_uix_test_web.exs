defmodule AuroraUixTestWeb do
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {AuroraUixTestWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  ## PRIVATE
  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      #      import AuroraUixTestWeb.CoreComponents
      #      import AuroraUixTestWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AuroraUixTestWeb.Endpoint,
        router: AuroraUixTestWeb.Router,
        statics: AuroraUixTestWeb.static_paths()
    end
  end

  def persist_attributes do
    quote do
      Module.register_attribute(__MODULE__, :auix_schemas, persist: true)
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
