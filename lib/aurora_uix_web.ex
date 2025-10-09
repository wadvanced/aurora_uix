defmodule Aurora.UixWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use Aurora.UixWeb, :controller
      use Aurora.UixWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  @doc """
  Returns the list of static paths.
  """
  @spec static_paths() :: [String.t()]
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  @doc """
  Defines the router with all the necessary imports and helpers.
  """
  @spec router() :: Macro.t()
  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router

      import Aurora.UixWeb, only: [inject_test_routes: 0]
    end
  end

  @doc """
  Defines a channel with all the necessary imports.
  """
  @spec channel() :: Macro.t()
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  @doc """
  Defines a live view with all the necessary imports and helpers.
  """
  @spec live_view() :: Macro.t()
  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  @doc """
  Defines a live component with all the necessary imports and helpers.
  """
  @spec live_component() :: Macro.t()
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  @doc """
  Defines an HTML component with all the necessary imports and helpers.
  """
  @spec html() :: Macro.t()
  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  @doc """
  Returns a quote with the verified routes configuration.
  """
  @spec verified_routes() :: Macro.t()
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Aurora.UixWeb.Endpoint,
        router: Aurora.UixWeb.Router,
        statics: Aurora.UixWeb.static_paths()
    end
  end

  @doc """
  Injects test routes into the router.

  This function checks if the `Aurora.UixWeb.Test.Routes` module is loaded
  and, if so, injects the test routes into the router.
  """
  @spec inject_test_routes() :: Macro.t()
  defmacro inject_test_routes do
    routes =
      if Code.ensure_loaded?(Aurora.UixWeb.Test.Routes) do
        quote do
          scope "/", Aurora.UixWeb.Test do
            pipe_through(:browser)
            use Aurora.UixWeb.Test.Routes
          end
        end
      else
        :ok
      end

    quote do
      unquote(routes)
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  @spec __using__(atom()) :: Macro.t()
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  ## PRIVATE ##

  @spec html_helpers() :: Macro.t()
  defp html_helpers do
    quote do
      use Aurora.Uix.CoreComponentsImporter
      # Translation
      use Gettext, backend: Aurora.UixWeb.Gettext
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      # import Aurora.UixWeb.CoreComponents

      # Common modules used in templates
      alias Aurora.UixWeb
      alias Aurora.UixWeb.Layouts
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end
end
