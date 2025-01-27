defmodule AuroraUixWeb.RouterHelper do
  @moduledoc """
  Provides utilities for dynamically generating routes in a Phoenix application.
  This module includes functionality to generate routes based on module metadata and
  to conditionally include routes depending on specific criteria.
  """

  @doc """
  Generates routes for a given module if the condition is met.

  ## Parameters
  - `generate_route?` (boolean): Determines whether routes should be generated.
  - `web_module` (module): The base web module (e.g., `MyAppWeb`).
  - `schema` (module): The Ecto schema module to base routes on.

  ## Returns
  - Quoted expressions defining the routes, or no routes if `generate_route?` is `false`.
  """
  @spec generate_routes(boolean, module, module) :: Macro.t()
  def generate_routes(true, web_module, schema) do
    source = schema.__schema__(:source)

    context_module =
      schema
      |> Module.split()
      |> List.last()
      |> Kernel.<>("Live")

    index_module = Module.concat([context_module, "Index"])
    show_module = Module.concat([context_module, "Show"])

    quote do
      unquote(add_route(source, web_module, index_module, :index))
      unquote(add_route(source, web_module, index_module, :new, path: "new"))
      unquote(add_route(source, web_module, index_module, :edit, path: "edit", include_id: true))

      live("/#{unquote(source)}/:id/edit", unquote(index_module), :edit)

      live("/#{unquote(source)}/:id", unquote(show_module), :show)
      live("/#{unquote(source)}/:id/show/edit", unquote(show_module), :edit)
    end
  end

  def generate_routes(_generate_route?, _web_module, _module), do: no_route()

  @doc """
  Do not generate a route entry.
  """
  @spec no_route() :: Macro.t()
  def no_route do
    quote do
    end
  end

  @spec add_route(binary, module, module, atom, Keyword.t()) :: Macro.t()
  defp add_route(source, web_module, target_module, live_action, opts \\ []) do
    module = Module.concat(web_module, target_module)

    case Code.ensure_compiled(module) do
      {:module, module} ->
        live_route? = function_exported?(module, :__live__, 0)
        do_add_route(live_route?, source, target_module, live_action, opts)

      {:error, _} ->
        no_route()
    end
  end

  @spec do_add_route(boolean, binary, module, atom, Keyword.t()) :: Macro.t()
  defp do_add_route(true = _live_route?, source, target_module, live_action, opts) do
    path = parse_opts(source, opts)

    quote do
      live("/#{unquote(path)}", unquote(target_module), unquote(live_action))
    end
  end

  defp do_add_route(_live_route?, _source, _target_module, _live_action, _opts), do: no_route()

  defp parse_opts(source, opts) do
    opts
    |> Enum.reduce({"", ""}, &do_parse_opts/2)
    |> then(fn {path, query} -> "/#{source}#{path}#{query}" end)
  end

  defp do_parse_opts({:path, "/" <> path}, {current_path, query}),
    do: {current_path <> path, query}

  defp do_parse_opts({:path, path}, {current_path, query}),
    do: {current_path <> "/#{path}", query}

  defp do_parse_opts(_, full_path), do: full_path
end
