defmodule AuroraUixWeb.RouterHelper do
  @moduledoc """
  Provides utilities for dynamically generating routes in a Phoenix application.
  This module includes functionality to generate routes based on module metadata and
  to conditionally include routes depending on specific criteria.
  """

  @ids_placeholder "{ids}"

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
    context_module =
      schema
      |> Module.split()
      |> List.last()
      |> Kernel.<>("Live")

    index_module = Module.concat([context_module, "Index"])
    show_module = Module.concat([context_module, "Show"])

    quote do
      unquote(add_route(schema, web_module, index_module, :index))
      unquote(add_route(schema, web_module, index_module, :new, "new"))
      unquote(add_route(schema, web_module, index_module, :edit, "#{@ids_placeholder}/edit"))

      unquote(add_route(schema, web_module, show_module, :show, "#{@ids_placeholder}"))
      unquote(add_route(schema, web_module, show_module, :edit, "#{@ids_placeholder}/show/edit"))

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

  @spec add_route(module, module, module, atom, Keyword.t()) :: Macro.t()
  defp add_route(schema, web_module, target_module, live_action, path \\ "") do
    module = Module.concat(web_module, target_module)

    case Code.ensure_compiled(module) do
      {:module, module} ->
        live_route? = function_exported?(module, :__live__, 0)
        do_add_route(live_route?, schema, target_module, live_action, path)

      {:error, _} ->
        no_route()
    end
  end

  defp do_add_route(true, schema, target_module, live_action, path) do
    source = schema.__schema__(:source)

    full_path =
      path
      |> process_ids(schema)
      |> then(&("/#{source}/#{&1}"))

    quote do
      live("/#{unquote(full_path)}", unquote(target_module), unquote(live_action))
    end
  end

  defp do_add_route(_, _path, _schema, _target_module, _live_action), do: no_route()

  defp process_ids(path, schema) do
    with true <- String.contains?(path, @ids_placeholder),
      primary_keys when not is_nil(primary_keys) <- schema.__schema__(:primary_key) do
        primary_keys
        |> Enum.map_join("/", &(":#{&1}"))
        |> then(&String.replace(path, @ids_placeholder, &1))
    else
      _ -> path
    end
  end
end
