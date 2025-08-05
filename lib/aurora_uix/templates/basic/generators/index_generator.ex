defmodule Aurora.Uix.Templates.Basic.Generators.IndexGenerator do
  @moduledoc """
  Generates index view LiveView modules for the Basic template implementation.

  This module provides a macro to generate LiveView modules for index (listing) pages in Aurora UIX Basic templates.

  ## Key Features

  - Generates LiveView modules for index (listing) views
  - Supports stream-based data loading
  - Handles CRUD operations (create, read, update, delete)
  - Dynamically mounts components
  - Provides responsive event handling
  - Integrates with Aurora UIX context and helpers

  """

  alias Aurora.Uix.Templates.Basic.Handlers.Index, as: IndexHandler
  alias Aurora.Uix.Templates.Basic.ModulesGenerator

  @doc """
  Generates an index view LiveView module with standard CRUD operations in Aurora UIX.

  ## Parameters
  - `parsed_opts` (map()) – Index view configuration with `tag: :index`

  ## Returns
  - `Macro.t()` – The generated index view module as quoted code

  """
  @spec generate_module(map()) :: Macro.t()
  def generate_module(%{layout_tree: %{tag: :index}} = parsed_opts) do
    parsed_opts = ModulesGenerator.remove_omitted_fields(parsed_opts)

    index_module = ModulesGenerator.module_name(parsed_opts, ".Index")
    handler_module = ModulesGenerator.handler_module(parsed_opts, IndexHandler)

    quote do
      defmodule unquote(index_module) do
        @moduledoc false

        use unquote(parsed_opts.modules.web), :live_view

        alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers

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

        @impl true
        def handle_info(input, socket) do
          unquote(handler_module).handle_info(input, socket)
        end
      end
    end
  end
end
