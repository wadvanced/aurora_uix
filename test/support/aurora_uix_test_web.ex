defmodule Aurora.Uix.Test.Web do
  @moduledoc """
  Entrypoint for defining web interface components and routes for Aurora UIX tests.

  ## Key Features
  - Provides convenience functions for controllers, views, and components.
  - Defines router, LiveView, LiveComponent, and verified routes configuration.
  - Registers CRUD routes for test modules.
  """

  alias Aurora.Uix.Test.Web

  @doc """
  Returns a list of static asset paths.

  ## Returns
  list(binary()) - List of static asset paths.
  """
  @spec static_paths() :: [binary()]
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  @doc """
  Defines Phoenix router configuration.

  ## Returns
  Macro.t() - Router configuration quote.
  """
  @spec router() :: Macro.t()
  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  @doc """
  Defines Phoenix LiveView configuration.

  ## Returns
  Macro.t() - LiveView configuration quote.
  """
  @spec live_view() :: Macro.t()
  def live_view do
    quote do
      use Phoenix.LiveView, layout: {Web.Layouts, :app}
      unquote(html_helpers())
    end
  end

  @doc """
  Defines Phoenix LiveComponent configuration.

  ## Returns
  Macro.t() - LiveComponent configuration quote.
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

  ## Returns
  Macro.t() - Verified routes configuration quote.
  """
  @spec verified_routes() :: Macro.t()
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Web.Endpoint,
        router: Web.Router,
        statics: Web.static_paths()
    end
  end

  @doc """
  Defines Phoenix HTML configuration.

  ## Returns
  Macro.t() - HTML configuration quote.
  """
  @spec html() :: Macro.t()
  def html do
    quote do
      use Phoenix.Component
      import Phoenix.Controller, only: [get_csrf_token: 0, view_module: 1, view_template: 1]
      unquote(html_helpers())
    end
  end

  @doc """
  Defines Aurora UIX test configuration.

  ## Returns
  Macro.t() - Aurora UIX test configuration quote.
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

  ## Parameters
  - `which` (atom()) - The component type to dispatch to.

  ## Returns
  Macro.t() - Configuration quote for the specified component.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @doc """
  Registers CRUD routes for a given module.

  ## Parameters
  - `module` (module()) - The module to register CRUD routes for.
  - `link_prefix` (binary()) - The URL prefix for the routes.

  ## Returns
  Macro.t() - CRUD routes configuration quote.
  """
  @spec register_crud(module(), binary()) :: Macro.t()
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

  @doc """
  Registers CRUD routes for product-related modules.

  ## Parameters
  - `module` (module()) - The base module.
  - `prefix` (binary()) - The URL prefix for the routes.

  ## Returns
  Macro.t() - CRUD routes configuration quote for product modules.
  """
  @spec register_product_crud(module(), binary()) :: Macro.t()
  defmacro register_product_crud(module, prefix) do
    quote do
      unquote(module)
      |> Module.concat(TestModule.Product)
      |> Web.register_crud("#{unquote(prefix)}products")

      unquote(module)
      |> Module.concat(TestModule.ProductTransaction)
      |> Web.register_crud("#{unquote(prefix)}product_transactions")

      unquote(module)
      |> Module.concat(TestModule.ProductLocation)
      |> Web.register_crud("#{unquote(prefix)}product_locations")
    end
  end

  ## PRIVATE
  # Helper function to define common HTML functionality for components
  @spec html_helpers() :: Macro.t()
  defp html_helpers do
    quote do
      use Aurora.Uix.Web.Gettext
      use Aurora.Uix.Web.CoreComponentsImporter
      import Phoenix.HTML
      alias Phoenix.LiveView.JS
      unquote(verified_routes())
    end
  end
end
