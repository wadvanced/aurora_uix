defmodule Aurora.Uix.Web.Templates.Basic.Renderers.IndexRenderer do
  @moduledoc """
  Renderer module for index pages in Aurora UIX.

  This module handles the rendering of index (listing) pages, providing a table view
  of entities with actions for show, edit, and delete operations.
  """

  use Aurora.Uix.Web.CoreComponentsImporter
  import Aurora.Uix.Web.Templates.Basic.RoutingComponents
  import Aurora.Uix.Web.Templates.Basic.Helpers, only: [get_field: 3]

  alias Phoenix.LiveView.JS

  @doc """
  Renders an index page with a table listing of entities.

  ## Parameters
    - assigns (map()) - The assigns map (Aurora UIX context)

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
      |> Enum.reject(&(&1.field_type in [:one_to_many_association, :many_to_one_association]))
      |> then(&Map.put(assigns, :index_fields, &1))

    ~H"""
    <.header>
      Listing {@_auix.title}
      <:actions>
        <.auix_link patch={"#{@_auix[:index_new_link]}"} id={"auix-new-#{@_auix.module}"}>
          <.button>New {@_auix.name}</.button>
        </.auix_link>
      </:actions>
    </.header>

    <.table
      id={@_auix.source}
      rows={get_in(assigns, @_auix.rows)}
      row_click_navigate={fn {_id, entity} -> "/#{@_auix.link_prefix}#{@_auix.source}/#{entity.id}" end}
    >
      <:col :let={{_id, entity}} :for={field <- @index_fields} label={"#{field.label}"}><.auix_link navigate={"/#{@_auix.link_prefix}#{@_auix.source}/#{entity.id}"}>{Map.get(entity, field.field)}</.auix_link></:col>

      <:action :let={{_id, entity}}>
        <div class="sr-only">
          <.auix_link navigate={"/#{@_auix.link_prefix}#{@_auix.source}/#{entity.id}"} name={"show-#{@_auix.module}"}>Show</.auix_link>
        </div>
        <.auix_link patch={"/#{@_auix.link_prefix}#{@_auix.source}/#{entity.id}/edit"} name={"edit-#{@_auix.module}"}>Edit</.auix_link>
      </:action>
      <:action :let={{id, entity}}>
        <.link
          phx-click={JS.push("delete", value: %{id: entity.id}) |> hide("##{id}")}
          name={"delete-#{@_auix.module}"}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id={"auix-#{@_auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
      <div>
        <.live_component
          module={@_auix._form_component}
          id={@auix_entity.id || :new}
          title={@page_title}
          action={@live_action}
          auix_entity={@auix_entity}
          auix_routing_stack={@_auix._routing_stack}
        />
      </div>
    </.modal>
    """
  end
end
