defmodule Aurora.Uix.Web.Templates.Basic.Generators.ShowGenerator do
  @moduledoc """
  Provides a macro to generate LiveView modules for detail (show) pages in Aurora UIX Basic templates.

  ## Key Features

  - Generates LiveView modules for detail (show) views
  - Supports dynamic section switching
  - Displays entity data with preload support
  - Integrates with form components
  - Integrates with Aurora UIX context and helpers
  """
  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator

  @doc """
  Generates a show view LiveView module with detail display and section handling.

  ## Parameters
  - `modules` (map()) – Map containing web, context modules, and component references
  - `parsed_opts` (map()) – Show view configuration with `tag: :show`

  ## Returns
  - `Macro.t()` – The generated show view module as quoted code.

  """
  @spec generate_module(map(), map()) :: Macro.t()
  def generate_module(modules, %{layout_tree: %{tag: :show}} = parsed_opts) do
    parsed_opts = ModulesGenerator.remove_omitted_fields(parsed_opts)

    show_module = ModulesGenerator.module_name(modules, parsed_opts, ".Show")
    handler_module = Aurora.Uix.Web.Templates.Basic.Handlers.Show

    quote do
      defmodule unquote(show_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers

        @impl true
        def mount(params, session, socket) do
          socket
          |> BasicHelpers.assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
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
      end
    end
  end
end
