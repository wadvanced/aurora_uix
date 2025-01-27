defmodule AuroraUixTestWeb.Router do
  use AuroraUixTestWeb, :router

  pipeline :browser do
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {AuroraUixTestWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", AuroraUixTest do
    pipe_through(:browser)
    live("/", LiveViewPage)
  end
end
