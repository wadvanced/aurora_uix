defmodule AuroraUixWeb.Templates.Core.Markups.IndexLayout do
  @moduledoc """
  Provides functionality for generating index view layout markup in HEEX templates.
  This module handles the parsing and generation of list views with sorting, filtering,
  and action buttons according to the Aurora UI specifications.
  """

  import AuroraUixWeb.Templates.Core, only: [get_field: 3]
  alias AuroraUixWeb.Template

  @doc """
  Parses the index layout configuration and generates the corresponding HEEX markup
  for displaying data in a table format with actions.

  Parameters:
  - path: %{tag: :index} | list - The index layout configuration map or list
  - configurations: map - Configuration options for the index view
  - parsed_opts: map - Parsed options including columns and display settings
  - resource_name: atom - The name of the resource being listed

  Returns:
  - binary - Generated HEEX markup for the index layout
  """
  @spec parse_layout(map | list, map, map, atom) :: binary
  def parse_layout(
        %{tag: :index} = path,
        configurations,
        parsed_opts,
        resource_name
      ) do
    parsed_opts =
      path.inner_elements
      |> Enum.filter(&(&1.tag == :field))
      |> Enum.map(&get_field(&1, configurations, resource_name))
      |> Enum.reject(&(&1.field_type in [:many_to_one_association, :one_to_many_association]))
      |> Enum.map(fn field ->
        %{label: field.label, field: field.field, field_type: field.field_type}
      end)
      |> then(&Map.put(parsed_opts, :index_columns, &1))

    Template.build_html(
      parsed_opts,
      ~S"""
        <.live_component
          module={AuroraUixWeb.Templates.Core.Components.Live.AuroraIndexList}
          id="[[source]]"
          title="Listing [[title]]"
          module_name="[[title]]"
          rows={get_in(assigns, @_auix.rows)}
          columns={[[index_columns]]}
          row_id={fn {id, _auix_entity} -> id end}
          new_link={@_auix[:index_new_link]}
          row_click={@_auix[:index_row_click]}
          >
          <:action :let={{id, entity}}>
            <div class="sr-only">
              <.link navigate={index_show_entity_link(@_auix, entity)} id={"auix-show-#{id}"}>Show</.link>
            </div>
            <.link patch={~p"/[[link_prefix]][[source]]/#{entity}/edit"} id={"auix-edit-#{id}"}>Edit</.link>
          </:action>
          <:action :let={{id, entity}}>
            <.link
              phx-click={JS.push("delete", value: %{id: entity.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
              id={"auix-delete-#{id}"}
            >
              Delete
            </.link>
          </:action>
        </.live_component>

        <div class="hidden">
          <a href={~p"/[[link_prefix]][[source]]"}>-</a>
        </div>
        <.modal :if={@live_action in [:new, :edit]} id="auix-[[module]]-modal" show on_cancel={JS.patch("/[[link_prefix]]#{@_auix_source}")}>
          <div>
            <.live_component
              module={[[module_name]]FormComponent}
              id={@auix_entity.id || :new}
              title={@page_title}
              source={@_auix_source}
              action={@live_action}
              auix_entity={@auix_entity}
              patch={"/[[link_prefix]]#{@_auix_source}"}
            />
          </div>
        </.modal>
      """
    )
  end
end
