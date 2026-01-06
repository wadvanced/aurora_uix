defmodule Aurora.Uix.RouteHelper do
  @moduledoc """
  Provides macros for generating standard LiveView routes for resource-based CRUD operations.
  """

  @doc """
  Generates standard LiveView routes for resource CRUD operations.

  Creates a set of LiveView routes following a consistent pattern for managing resources.
  Routes are bound to action names (:index, :new, :edit, :show, :show_edit) for LiveView event handling.

  The macro expands to up to five live routes with the following pattern:
  - `GET /path` → `.Index` module with `:index` action
  - `GET /path/new` → `.Index` module with `:new` action
  - `GET /path/:id/edit` → `.Index` module with `:edit` action
  - `GET /path/:id/show` → `.Index` module with `:show` action
  - `GET /path/:id/show/edit` → `.Index` module with `:show_edit` action

  ## Parameters
  - `path` (binary()) - Base URL path segment (e.g., `"/users"`, `"/products"`).
  - `module` (module()) - Base LiveView module name. Must have `.Index` and `.Show` submodules.
  - `opts` (Keyword.t()) - Options:
    * `:only` (list(atom())) - Generate only the specified actions. Valid actions: `:index`, `:new`, `:edit`, `:show`, `:show_edit`.
    * `:except` (list(atom())) - Exclude the specified actions from generation.

  ## Returns
  Macro.t() - Quoted expression expanding to `live/3` route definitions.

  ## Examples
  Generate all routes (default):
  ```elixir
  import Aurora.Uix.RouteHelper

  auix_live_resources("/users", MyApp.UserLive)

  # Expands to:
  live "/users", MyApp.UserLive.Index, :index
  live "/users/new", MyApp.UserLive.Index, :new
  live "/users/:id/edit", MyApp.UserLive.Index, :edit
  live "/users/:id/show", MyApp.UserLive.Index, :show
  live "/users/:id/show/edit", MyApp.UserLive.Index, :show_edit
  ```

  Generate only index and show routes:
  ```elixir
  auix_live_resources("/users", MyApp.UserLive, only: [:index, :show])

  # Expands to:
  live "/users", MyApp.UserLive.Index, :index
  live "/users/:id/show", MyApp.UserLive.Index, :show
  ```

  Generate all routes except new and edit (read-only mode):
  ```elixir
  auix_live_resources("/users", MyApp.UserLive, except: [:new, :edit])

  # Expands to:
  live "/users", MyApp.UserLive.Index, :index
  live "/users/:id/show", MyApp.UserLive.Index, :show
  live "/users/:id/show/edit", MyApp.UserLive.Index, :show_edit
  ```
  """
  @spec auix_live_resources(binary(), module(), keyword()) :: Macro.t()
  defmacro auix_live_resources(path, module, opts \\ []) do
    quotes =
      [
        {:index,
         quote do
           live("#{unquote(path)}", unquote(module).Index, :index)
         end},
        {:new,
         quote do
           live("#{unquote(path)}/new", unquote(module).Index, :new)
         end},
        {:edit,
         quote do
           live("#{unquote(path)}/:id/edit", unquote(module).Index, :edit)
         end},
        {:show,
         quote do
           live("#{unquote(path)}/:id/show", unquote(module).Index, :show)
         end},
        {:show_edit,
         quote do
           live("#{unquote(path)}/:id/show/edit", unquote(module).Index, :show_edit)
         end}
      ]
      |> filter_only(opts[:only])
      |> reject_except(opts[:except])
      |> extract_quotes()

    quote do
      (unquote_splicing(quotes))
    end
  end

  ## PRIVATE
  @spec filter_only(list(), list() | nil) :: list()
  defp filter_only(quotes, only) when is_list(only),
    do: Enum.filter(quotes, &(elem(&1, 0) in only))

  defp filter_only(quotes, _only), do: quotes

  @spec reject_except(list(), list() | nil) :: list()
  defp reject_except(quotes, except) when is_list(except),
    do: Enum.reject(quotes, &(elem(&1, 0) in except))

  defp reject_except(quotes, _except), do: quotes

  @spec extract_quotes(list()) :: list()
  defp extract_quotes(quotes), do: Enum.map(quotes, &elem(&1, 1))
end
