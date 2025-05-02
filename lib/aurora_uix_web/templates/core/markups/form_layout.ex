defmodule AuroraUixWeb.Templates.Core.Markups.FormLayout do
  @moduledoc """
  Provides functionality for generating form layout markup in HEEX templates.
  This module handles the parsing and generation of form containers with proper styling
  and structure according to the Aurora UI specifications.
  """

  import AuroraUixWeb.Templates.Core, only: [parse_layout: 5]

  alias AuroraUixWeb.Template

  @doc """
  Parses the form layout configuration and generates the corresponding HEEX markup.

  Parameters:
  - path: %{tag: :form, name: String.t()} | list - The form layout configuration map or list
  - configurations: map - Configuration options for the form
  - parsed_opts: map - Parsed options including form fields and other settings
  - resource_name: atom - The name of the resource being managed by the form

  Returns:
  - binary - Generated HEEX markup for the form layout
  """
  @spec parse_layout(map | list, map, map, atom) :: binary
  def parse_layout(
        %{tag: :form, name: name} = path,
        configurations,
        parsed_opts,
        resource_name
      ) do
    mode = :form
    layout_classes = "auix-#{mode}-container p-4 border rounded-lg shadow bg-white"

    form_fields =
      ~s(
      <div class="#{layout_classes}" data-layout="#{name}">
        #{parse_layout(path.inner_elements, configurations, parsed_opts, resource_name, mode)}
      </div>
    )

    parsed_opts
    |> Map.put(:form_fields, form_fields)
    |> Template.build_html(~S"""
      <div>
        <.header>
          {@title}
          <:subtitle>Use this form to manage [[module]] records in your database.</:subtitle>

        </.header>

        <.flash kind={:error} flash={@flash} title="Error!" />
        <.simple_form
          for={@form}
          id="auix-[[module]]-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          [[form_fields]]
          <:actions>
            <.button phx-disable-with="Saving..." id="auix-save-[[source]]">Save [[name]]</.button>
          </:actions>
        </.simple_form>
      </div>
    """)
  end
end
