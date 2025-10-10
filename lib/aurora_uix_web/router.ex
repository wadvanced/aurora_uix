defmodule Aurora.UixWeb.Router do
  @moduledoc """
  Defines the application's routes and pipelines.

  This module is responsible for defining the application's routes and
  the pipelines that requests go through.
  """
  use Aurora.UixWeb, :router

  import Aurora.UixWeb.Test.Routes

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {Aurora.UixWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Aurora.UixWeb do
    pipe_through(:browser)
  end

  if Application.compile_env(:aurora_uix, :test_routes) do
    scope "/", Aurora.UixWeb.Test do
      pipe_through(:browser)
      load_test_routes()
    end
  end

  # inject_test_routes()

  # Other scopes may use custom stacks.
  # scope "/api", Aurora.UixWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:aurora_uix, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: Aurora.UixWeb.Telemetry)
    end
  end
end
