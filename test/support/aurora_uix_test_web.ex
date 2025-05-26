defmodule AuroraUixTestWeb do
  @moduledoc """
  The entrypoint for defining web interface components and routes for Aurora UIX tests.
  Provides convenience functions for controllers, views, and components.
  """

  @doc """
  Returns a list of static asset paths.

  Returns: [binary()] - List of static asset paths
  """
  @spec static_paths() :: [binary]
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  @doc """
  Defines Phoenix router configuration.

  Returns: Macro.t() - TestRouter configuration quote
  """
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

  @doc """
  Defines Phoenix LiveView configuration.

  Returns: Macro.t() - LiveView configuration quote
  """
  @spec live_view() :: Macro.t()
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {Aurora.Uix.Web.TestLayouts, :app}

      unquote(html_helpers())
    end
  end

  @doc """
  Defines Phoenix LiveComponent configuration.

  Returns: Macro.t() - LiveComponent configuration quote
  """
  @spec live_component() :: Macro.t()
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  @doc """
  Defines Phoenix verified routes configuration.

  Returns: Macro.t() - Verified routes configuration quote
  """
  @spec verified_routes() :: Macro.t()
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Aurora.Uix.Web.TestEndpoint,
        router: Aurora.Uix.Web.TestRouter,
        statics: AuroraUixTestWeb.static_paths()
    end
  end

  @doc """
  Defines Phoenix HTML configuration.

  Returns: Macro.t() - HTML configuration quote
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
  Defines Aurora UIX test configuration.

  Returns: Macro.t() - Aurora UIX test configuration quote
  """
  @spec aurora_uix_for_test() :: Macro.t()
  def aurora_uix_for_test do
    quote do
      Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)

      use Aurora.Uix
    end
  end

  @doc """
  Dispatches to the appropriate controller/live_view based on the given atom.

  - which: atom() - The component type to dispatch to

  Returns: Macro.t() - Configuration quote for the specified component
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @doc """
  Registers CRUD routes for a given module.

  - module: module() - The module to register CRUD routes for
  - link_prefix: binary() - The URL prefix for the routes

  Returns: Macro.t() - CRUD routes configuration quote
  """
  @spec register_crud(module, binary) :: Macro.t()
  defmacro register_crud(module, link_prefix) do
    routes =
      quote do
        link = "/#{unquote(link_prefix)}"
        index_module = Module.concat(unquote(module), Index)
        show_module = Module.concat(unquote(module), Show)

        live("/#{link}", index_module, :index)
        live("/#{link}/new", index_module, :new)
        live("/#{link}/:id/edit", index_module, :edit)
        live("/#{link}/:id", show_module, :show)
        live("/#{link}/:id/show/edit", show_module, :edit)
      end

    quote do
      unquote(routes)
    end
  end

  ## PRIVATE
  # Helper function to define common HTML functionality for components
  @spec html_helpers() :: Macro.t()
  defp html_helpers do
    quote do
      use Aurora.Uix.Web.Gettext
      use Aurora.Uix.Web.CoreComponentsImporter

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end
end
