defmodule Aurora.Uix.Web.Templates.Basic.Renderers.IndexRenderer do
  @moduledoc """
  Renders index view pages with table-based entity listings and CRUD actions in Aurora UIX.

  ## Key Features

  - Table view with sortable columns
  - New entity creation button
  - Show/Edit/Delete actions per row
  - Modal forms for entity operations
  - Row click navigation
  - Entity field filtering
  - Integrates with Aurora UIX context and helpers
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS

  @doc """
  Renders an index page with a table listing of entities.

  ## Parameters
  - assigns (map()) - LiveView assigns containing:
    - auix: Aurora UIX context with configurations and path info
    - auix_entity: Entity being rendered
    - live_action: Current live action (:new, :edit)
    - page_title: Page title for modals

  ## Returns
  - Phoenix.LiveView.Rendered.t() - Rendered index page with table and actions
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{
          auix: %{
            _path: %{tag: :index} = path,
            configurations: configurations,
            _resource_name: resource_name
          }
        } = assigns
      ) do
    assigns =
      path.inner_elements
      |> Enum.filter(&(&1.tag == :field))
      |> Enum.map(&BasicHelpers.get_field(&1, configurations, resource_name))
      |> Enum.reject(&(&1.type in [:one_to_many_association, :many_to_one_association]))
      |> then(&Map.put(assigns, :index_fields, &1))

    ~H"""
    <div class={get_in(@auix.css_classes, [:index_renderer, :top_container]) || ""}>
      <.header>
        {@auix.layout_options.page_title}
        <:actions>
          <.auix_link patch={"#{@auix[:index_new_link]}"} id={"auix-new-#{@auix.module}"}>
            <.button>New {@auix.name}</.button>
          </.auix_link>
        </:actions>
      </.header>

      <.table
        id={"auix-table-#{@auix.link_prefix}#{@auix.source}-index"}
        auix_css_classes={@auix.css_classes}
        rows={get_in(assigns, @auix.rows)}
        row_click_navigate={fn {_id, entity} -> "/#{@auix.link_prefix}#{@auix.source}/#{entity.id}" end}
      >
        <:col :let={{_id, entity}} :for={field <- @index_fields} label={"#{field.label}"}><.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{entity.id}"}>{Map.get(entity, field.key)}</.auix_link></:col>

        <:action :let={{_id, entity}}>
          <div class="sr-only">
            <.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{entity.id}"} name={"show-#{@auix.module}"}>Show</.auix_link>
          </div>
          <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{entity.id}/edit"} name={"edit-#{@auix.module}"}>Edit</.auix_link>
        </:action>
        <:action :let={{id, entity}}>
          <.link
            phx-click={JS.push("delete", value: %{id: entity.id}) |> hide("##{id}")}
            name={"delete-#{@auix.module}"}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal :if={@live_action in [:new, :edit]} auix_css_classes={@auix.css_classes} id={"auix-#{@auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
        <div>
          <.live_component
            module={@auix._form_component}
            id={@auix_entity.id || :new}
            title={if @live_action == :edit, do: @auix.layout_options.edit_title, else: @auix.layout_options.new_title}
            subtitle={if @live_action == :edit, do: @auix.layout_options.edit_subtitle, else: @auix.layout_options.new_subtitle}
            action={@live_action}
            auix_entity={@auix_entity}
            auix_routing_stack={@auix._routing_stack}
            auix_css_classes={@auix.css_classes}
          />
        </div>
      </.modal>
    </div>
    """
  end
end
