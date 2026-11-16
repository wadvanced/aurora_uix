defmodule Aurora.Uix.Templates.Basic.Generators.IndexGenerator do
  @moduledoc """
  Generates index view LiveView modules for the Basic template implementation.

  This module provides a macro to generate LiveView modules for index (listing) pages in Aurora UIX Basic templates.

  ## Key Features

  - Generates LiveView modules for index (listing) views
  - Generates the index component: the list of a resource as a LiveComponent
  - Supports stream-based data loading
  - Handles CRUD operations (create, read, update, delete)
  - Dynamically mounts components
  - Provides responsive event handling
  - Integrates with Aurora UIX context and helpers

  """

  alias Aurora.Uix.Layout.CreateUI
  alias Aurora.Uix.Templates.Basic.Handlers.Index, as: IndexHandler
  alias Aurora.Uix.Templates.Basic.Handlers.IndexComponent, as: IndexComponentHandler
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.Uix.Templates.Basic.ModulesGenerator

  @doc """
  Generates the index view LiveView module and the index component of a resource, each when
  `generate` holds its kind.

  ## Parameters
  - `parsed_opts` (map()) - Index view configuration with `layout_type: :index`.

  ## Returns
  Macro.t() - The generated modules as quoted code.
  """
  @spec generate_module(map()) :: Macro.t()
  def generate_module(%{layout_type: :index} = parsed_opts) do
    parsed_opts =
      parsed_opts |> CreateUI.put_defaults() |> ModulesGenerator.remove_omitted_fields()

    live_view = if :index_live in parsed_opts.generate, do: live_view_module(parsed_opts)
    component = if :index_component in parsed_opts.generate, do: component_module(parsed_opts)

    quote do
      unquote(live_view)
      unquote(component)
    end
  end

  @spec live_view_module(map()) :: Macro.t()
  defp live_view_module(parsed_opts) do
    index_module = parsed_opts.artifacts.index_live
    handler_module = ModulesGenerator.handler_module(parsed_opts, IndexHandler)

    quote do
      defmodule unquote(index_module) do
        @moduledoc false

        use unquote(parsed_opts.modules.web), :live_view

        unquote(CreateUI.module_code(:index_live, nil))

        @impl true
        def mount(params, session, socket) do
          socket
          |> Helpers.assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
          |> then(&unquote(handler_module).mount(params, session, &1))
        end

        @impl true
        def handle_params(params, url, socket) do
          unquote(handler_module).handle_params(params, url, socket)
        end

        @impl true
        def handle_event(event, params, socket) do
          unquote(handler_module).handle_event(event, params, socket)
        end

        @impl true
        def handle_info(input, socket) do
          unquote(handler_module).handle_info(input, socket)
        end

        @impl true
        def handle_async(task, result, socket) do
          unquote(handler_module).handle_async(task, result, socket)
        end
      end
    end
  end

  @spec component_module(map()) :: Macro.t()
  defp component_module(parsed_opts) do
    component_handler =
      Map.get(parsed_opts.layout_tree, :component_handler_module) || IndexComponentHandler

    quote do
      defmodule unquote(parsed_opts.artifacts.index_component) do
        @moduledoc false

        use unquote(parsed_opts.modules.web), :live_component

        unquote(
          CreateUI.module_code(
            :index_component,
            Map.fetch!(parsed_opts.exposed_layouts, :index_component)
          )
        )

        @impl true
        def update(assigns, socket) do
          merged_auix =
            socket.assigns
            |> Map.get(:auix, %{})
            |> Map.merge(Map.get(assigns, :auix, %{}))
            |> Map.merge(Helpers.resource_binding(socket, assigns, __MODULE__, :index))

          socket
          |> assign(assigns |> Map.delete(:auix_event) |> Map.put(:auix, merged_auix))
          |> Helpers.assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
          |> Helpers.assign_actor_to_auix()
          |> then(&unquote(component_handler).update(assigns, &1))
        end

        @impl true
        def handle_event(event, params, socket),
          do: unquote(component_handler).handle_event(event, params, socket)

        @impl true
        def handle_async(task, result, socket),
          do: unquote(component_handler).handle_async(task, result, socket)
      end
    end
  end
end
