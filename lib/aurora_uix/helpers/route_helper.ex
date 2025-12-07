defmodule Aurora.Uix.RouteHelper do
  @moduledoc """
  Provides macros for generating standard LiveView routes for resource-based CRUD operations.
  """

  @doc """
  Generates standard LiveView routes for resource CRUD operations.

  Creates a set of LiveView routes following a consistent pattern for managing resources.
  Routes are bound to action names (:index, :new, :edit, :show) for LiveView event handling.

  The macro expands to five live routes with the following pattern:
  - `GET /path` → `.Index` module with `:index` action
  - `GET /path/new` → `.Index` module with `:new` action
  - `GET /path/:id/edit` → `.Index` module with `:edit` action
  - `GET /path/:id` → `.Show` module with `:show` action
  - `GET /path/:id/show/edit` → `.Show` module with `:edit` action

  ## Parameters
  - `path` (binary()) - Base URL path segment (e.g., `"/users"`, `"/products"`).
  - `module` (module()) - Base LiveView module name. Must have `.Index` and `.Show` submodules.

  ## Returns
  Macro.t() - Quoted expression expanding to five `live/3` route definitions.

  ## Examples
  ```elixir
  import Aurora.Uix.RouteHelper

  auix_live_resources("/users", MyApp.UserLive)

  # Expands to:
  live "/users", MyApp.UserLive.Index, :index
  live "/users/new", MyApp.UserLive.Index, :new
  live "/users/:id/edit", MyApp.UserLive.Index, :edit
  live "/users/:id", MyApp.UserLive.Show, :show
  live "/users/:id/show/edit", MyApp.UserLive.Show, :edit
  ```
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
