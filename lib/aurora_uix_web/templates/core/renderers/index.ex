defmodule Aurora.Uix.Web.Templates.Core.Renderers.Index do
  @moduledoc """
  Renderer module for index pages in Aurora UIX.

  This module handles the rendering of index (listing) pages, providing a table view
  of entities with actions for show, edit, and delete operations.
  """

  use Aurora.Uix.Web.CoreComponents
  import Aurora.Uix.Web.Templates.Core, only: [get_field: 3]

  alias Phoenix.LiveView.JS

  @doc """
  Renders an index page with a table listing of entities.

  ## Parameters
    - assigns (map()) - The assigns map containing:
      - _auix: A map with configuration details including:
        - _path: Index path configuration with inner_elements
        - _configurations: General configurations
        - _resource_name: Name of the resource being listed
        - title: Title to display in the header
        - name: Resource name for the "New" button
        - source: Source identifier for the table
        - rows: Path to access the rows data

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{
          _auix: %{
            _path: %{tag: :index} = path,
            _configurations: configurations,
            _resource_name: resource_name
          }
        } = assigns
      ) do
    assigns =
      path.inner_elements
      |> Enum.filter(&(&1.tag == :field))
      |> Enum.map(&get_field(&1, configurations, resource_name))
      |> Enum.reject(& &1.field_type in [:one_to_many_association, :many_to_one_association])
      |> then(&Map.put(assigns, :index_fields, &1))

    ~H"""
    <.header>
      Listing {@_auix.title}
      <:actions>
        <.link patch={"#{@_auix[:index_new_link]}"}>
          <.button>New {@_auix.name}</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id={@_auix.source}
      rows={get_in(assigns, @_auix.rows)}
      row_click={fn {_id, entity} -> JS.navigate("/#{@_auix.source}/#{entity.id}") end}
    >
      <:col :let={{_id, entity}} :for={field <- @index_fields} label={"#{field.label}"}>{Map.get(entity, field.field)}</:col>

      <:action :let={{_id, entity}}>
        <div class="sr-only">
          <.link navigate={"/#{@_auix.source}/#{entity.id}"}>Show</.link>
        </div>
        <.link patch={"/#{@_auix.source}/#{entity.id}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, entity}}>
        <.link
          phx-click={JS.push("delete", value: %{id: entity.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id={"auix-#{@_auix.module}-modal"} show on_cancel={JS.patch("/#{@_auix.link_prefix}#{@_auix.source}")}>
      <div>
        <.live_component
          module={@_auix._form_component}
          id={@auix_entity.id || :new}
          title={@page_title}
          source={@_auix.source}
          action={@live_action}
          auix_entity={@auix_entity}
          patch={"/#{@_auix.link_prefix}#{@_auix.source}"}
        />
      </div>
    </.modal>
    """
  end
end
