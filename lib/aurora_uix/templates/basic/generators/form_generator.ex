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

  alias Aurora.Uix.Layout.Artifacts
  alias Aurora.Uix.Templates.Basic.Handlers.Form, as: FormHandler
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.Uix.Templates.Basic.ModulesGenerator

  @gettext_domain Application.compile_env(:aurora_uix, :gettext_domain, nil)

  @doc """
  Generates a LiveComponent module for form handling.

  ## Parameters
  - `parsed_opts` (map()) - Form configuration with `layout_type: :form` and function references.

  ## Returns
  Macro.t() - The generated form component module as quoted code.
  """
  @spec generate_module(map()) :: Macro.t()
  def generate_module(%{layout_type: :form} = parsed_opts) do
    parsed_opts = parsed_opts |> Artifacts.put_defaults() |> ModulesGenerator.component_opts()

    field_labels =
      parsed_opts
      |> Map.get(:fields, [])
      |> Enum.map(& &1.label)
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()

    gettext_domain = @gettext_domain

    extract_function =
      if gettext_domain && field_labels != [] do
        dgettext_calls =
          Enum.map(field_labels, fn label ->
            quote do: dgettext(unquote(gettext_domain), unquote(label))
          end)

        quote do
          @compile {:nowarn_unused_function, _aurora_uix_extract: 0}
          @doc false
          defp _aurora_uix_extract do
            (unquote_splicing(dgettext_calls))
          end
        end
      else
        quote do: nil
      end

    form_component = parsed_opts.artifacts.form_component
    handler_module = ModulesGenerator.handler_module(parsed_opts, FormHandler)

    quote do
      defmodule unquote(form_component) do
        @moduledoc false

        use unquote(parsed_opts.modules.web), :live_component
        use Aurora.Uix.GettextResolver

        unquote(
          Artifacts.module_code(
            :form_component,
            Map.fetch!(parsed_opts.exposed_layouts, :form_component)
          )
        )

        unquote(extract_function)

        @impl true
        def update(
              %{auix: %{entity: _entity, routing_stack: _routing_stack} = incoming_auix} =
                assigns,
              socket
            ) do
          merged_auix = socket.assigns |> Map.get(:auix, %{}) |> Map.merge(incoming_auix)

          socket
          |> assign(Map.put(assigns, :auix, merged_auix))
          |> Helpers.assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
          |> Helpers.assign_actor_to_auix()
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
