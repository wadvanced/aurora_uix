defmodule Aurora.Uix.RouteHelper do
  @moduledoc """
  Provides route generation macros for Aurora UI LiveView resource-based routing.
  Generates standardized CRUD-like routes for index/show/edit operations with
  consistent URL patterns.
  """

  @doc """
  Generates standard LiveView routes for resource operations.

  ## Parameters
    - `path` (binary): Base URL path segment (e.g., `"/users"`)
    - `module` (module): LiveView module handling the routes

  ## Returns
    (Macro.t): Quote expression containing LiveView route definitions

  Creates the following route structure:
    - Index: `GET /path`
    - New: `GET /path/new`
    - Edit: `GET /path/:id/edit`
    - Show: `GET /path/:id/show`
    - Edit from Show: `GET /path/:id/show/edit`

  ## Example
  |||elixir
  # Generates routes for user management
  import Aurora.Uix.RouteHelper
  auix_live_resources("/users", MyApp.UserLive)
  # Equivalent to:
  live "/users", MyApp.UserLive.Index, :index
  live "/users/new", MyApp.UserLive.Index, :new
  live "/users/:id/edit", MyApp.UserLive.Index, :edit
  live "/users/:id/show", MyApp.UserLive.Show, :show
  live "/users/:id/show/edit", MyApp.UserLive.Index, :edit
  |||
  """
  @spec auix_live_resources(binary(), module()) :: Macro.t()
  defmacro auix_live_resources(path, module) do
    quote do
      live("#{unquote(path)}", unquote(module).Index, :index)
      live("#{unquote(path)}/new", unquote(module).Index, :new)
      live("#{unquote(path)}/:id/edit", unquote(module).Index, :edit)
      live("#{unquote(path)}/:id", unquote(module).Show, :show)
      live("#{unquote(path)}/:id/show/edit", unquote(module).Show, :edit)
    end
  end
end
