Code.require_file("test/support/aurora_uix_test_web.exs")

defmodule AuroraUixTestWeb.Router do
  use AuroraUixTestWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {AuroraUixTestWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AuroraUixTestWeb do
    pipe_through(:browser)

    live("/products", CrudTest.TestModule.Product.Index, :index)
    live("/products/new", CrudTest.TestModule.Product.Index, :new)
    live("/products/:id/edit", CrudTest.TestModule.Product.Index, :edit)
  end
end
