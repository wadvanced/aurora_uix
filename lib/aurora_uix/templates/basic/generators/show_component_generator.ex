defmodule Aurora.Uix.Templates.Basic.Generators.ShowComponentGenerator do
  @moduledoc """
  Generates show component modules for the Basic template implementation.

  `generate_module/1` returns the code of the show LiveComponent of a resource.

  ## Key Features

  - Generates LiveComponent modules for showing entity data
  - Supports dynamic section switching
  - Handles entity display with preload support
  - Enables section interactions via events
  - Integrates with Aurora UIX context and helpers
  """

  alias Aurora.Uix.Layout.CreateUI
  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponent, as: ShowComponentHandler
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.Uix.Templates.Basic.ModulesGenerator

  @doc """
  Generates a LiveComponent module for showing data.

  ## Parameters
  - `parsed_opts` (map()) - Show configuration with `layout_type: :show` and function references.

  ## Returns
  Macro.t() - The generated component module as quoted code.
  """
  @spec generate_module(map()) :: Macro.t()
  def generate_module(%{layout_type: :show} = parsed_opts) do
    parsed_opts = parsed_opts |> CreateUI.put_defaults() |> ModulesGenerator.component_opts()

    show_component = parsed_opts.artifacts.show_component
    handler_module = ModulesGenerator.handler_module(parsed_opts, ShowComponentHandler)

    quote do
      defmodule unquote(show_component) do
        @moduledoc false

        use unquote(parsed_opts.modules.web), :live_component

        unquote(
          CreateUI.module_code(
            :show_component,
            Map.fetch!(parsed_opts.exposed_layouts, :show_component)
          )
        )

        defp auix_parsed_opts, do: unquote(Macro.escape(parsed_opts))

        @impl true
        def update(%{auix: %{entity: entity, routing_stack: routing_stack}} = assigns, socket) do
          socket
          |> assign(assigns)
          |> Helpers.assign_parsed_opts(auix_parsed_opts())
          |> then(&unquote(handler_module).update(assigns, &1))
        end

        def update(assigns, socket) do
          merged_auix =
            socket.assigns
            |> Map.get(:auix, %{})
            |> Map.merge(Map.get(assigns, :auix, %{}))
            |> Map.merge(Helpers.resource_binding(socket, assigns, __MODULE__, :show))

          socket =
            socket
            |> assign(Map.put(assigns, :auix, merged_auix))
            |> Helpers.assign_parsed_opts(auix_parsed_opts())
            |> Helpers.assign_component_inputs(assigns, :show)

          assigns
          |> Map.put(:auix, Map.take(socket.assigns.auix, [:entity, :routing_stack]))
          |> unquote(handler_module).update(socket)
        end

        @impl true
        def handle_event(event, params, socket) do
          unquote(handler_module).handle_event(event, params, socket)
        end
      end
    end
  end
end
