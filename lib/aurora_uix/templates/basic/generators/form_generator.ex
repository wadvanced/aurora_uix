defmodule Aurora.Uix.Templates.Basic.Generators.FormGenerator do
  @moduledoc """
  Generates form component modules for the Basic template implementation.

  This module provides a macro to generate LiveComponent modules for handling forms in Aurora UIX Basic templates.

  ## Key Features

  - Generates LiveComponent modules for form handling
  - Supports form validation and submission
  - Handles entity creation and updates
  - Enables dynamic section switching
  - Notifies parent components of changes
  - Integrates with Aurora UIX context and helpers
  """

  alias Aurora.Uix.Templates.Basic.Handlers.Form, as: FormHandler
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.Uix.Templates.Basic.ModulesGenerator

  @doc """
  Generates a LiveComponent module for form handling.

  ## Parameters
  - `parsed_opts` (map()) – Form configuration with `tag: :form` and function references

  ## Returns
  - `Macro.t()` – The generated form component module as quoted code

  """
  @spec generate_module(map()) :: Macro.t()
  def generate_module(%{layout_tree: %{tag: :form}} = parsed_opts) do
    cleaned_parsed_opts = ModulesGenerator.remove_omitted_fields(parsed_opts)

    form_component = ModulesGenerator.module_name(cleaned_parsed_opts, ".FormComponent")
    handler_module = ModulesGenerator.handler_module(cleaned_parsed_opts, FormHandler)

    one2many_preload =
      cleaned_parsed_opts
      |> Helpers.extract_association_preload()
      |> Map.get(:one_to_many_association, [])

    one2many_rendered? =
      cleaned_parsed_opts
      |> Map.get(:layout_tree)
      |> Helpers.flatten_layout_tree()
      |> Enum.filter(&(&1.tag == :field and &1.name in one2many_preload))
      |> Enum.empty?()
      |> Kernel.not()

    parsed_opts = Map.put(cleaned_parsed_opts, :one2many_rendered?, one2many_rendered?)

    quote do
      defmodule unquote(form_component) do
        @moduledoc false

        use unquote(parsed_opts.modules.web), :live_component
        alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers

        @impl true
        def update(%{auix: %{entity: entity, routing_stack: routing_stack}} = assigns, socket) do
          socket
          |> assign(assigns)
          |> BasicHelpers.assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
          |> then(&unquote(handler_module).update(assigns, &1))
        end

        @impl true
        def handle_event(event, params, socket) do
          unquote(handler_module).handle_event(event, params, socket)
        end
      end
    end
  end
end
