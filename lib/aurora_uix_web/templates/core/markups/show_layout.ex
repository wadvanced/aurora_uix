defmodule AuroraUixWeb.Templates.Core.Markups.ShowLayout do
  @moduledoc """
  Provides functionality for generating show view layout markup in HEEX templates.
  This module handles the parsing and generation of detail views with edit capabilities
  according to the Aurora UI specifications.
  """

  import AuroraUixWeb.Templates.Core, only: [parse_layout: 5]

  alias AuroraUixWeb.Template

  @doc """
  Parses the show layout configuration and generates the corresponding HEEX markup
  for displaying detailed information about a resource.

  Parameters:
  - path: %{tag: :show, name: String.t()} | list - The show layout configuration map or list
  - configurations: map - Configuration options for the show view
  - parsed_opts: map - Parsed options including display fields and settings
  - resource_name: atom - The name of the resource being displayed

  Returns:
  - binary - Generated HEEX markup for the show layout
  """
  @spec parse_layout(map | list, map, map, atom) :: binary
  def parse_layout(
        %{tag: :show, name: name} = path,
        configurations,
        parsed_opts,
        resource_name
      ) do
    mode = :show
    layout_classes = "auix-#{mode}-container p-4 border rounded-lg shadow bg-white"

    show_fields =
      ~s(
      <div class="#{layout_classes}" data-layout="#{name}">
        #{parse_layout(path.inner_elements, configurations, parsed_opts, resource_name, mode)}
      </div>
    )

    parsed_opts
    |> Map.put(:show_fields, show_fields)
    |> Template.build_html(~S"""
    <.header>
      [[name]] {@auix_entity.id}
      <:subtitle>{@subtitle}</:subtitle>
      <:actions>
        <.link patch={"/[[link_prefix]][[source]]/#{@auix_entity.id}/show/edit#{@_auix_source_link}"} phx-click={JS.push_focus()} id="auix-edit-[[source]]">
          <.button>Edit [[name]]</.button>
        </.link>
      </:actions>
    </.header>

    [[show_fields]]

    <.back navigate={"/[[link_prefix]]#{@_auix_source}"}>Back to [[title]]</.back>

    <.modal :if={@live_action == :edit}
      id="auix-[[module]]-modal"
      show
      on_cancel={JS.patch("/[[link_prefix]]#{@_auix_source}/#{@auix_entity.id}")}
    >
      <.live_component
        module={[[module_name]]FormComponent}
        id={@auix_entity.id}
        title={@page_title}
        action={@live_action}
        source={@_auix_source}
        auix_entity={@auix_entity}
        patch={"/[[link_prefix]]#{@_auix_source}/#{@auix_entity.id}"}
      />
    </.modal>
    """)
  end
end
