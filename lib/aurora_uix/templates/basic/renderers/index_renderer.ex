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

  alias Aurora.Uix.Web.Templates.Basic.Actions.Index, as: IndexActions
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS

  @doc """
  Renders an index page with a table listing of entities.

  ## Parameters
  - assigns (map()) - LiveView assigns containing:
    - auix: Aurora UIX context with configurations and layout_tree info
    - live_action: Current live action (:new, :edit)
    - page_title: Page title for modals

  ## Returns
  - Phoenix.LiveView.Rendered.t() - Rendered index page with table and actions
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{
          auix: %{
            layout_tree: %{tag: :index} = layout_tree,
            configurations: configurations,
            resource_name: resource_name
          }
        } = assigns
      ) do
    assigns =
      layout_tree.inner_elements
      |> Enum.filter(&(&1.tag == :field))
      |> Enum.map(&BasicHelpers.get_field(&1, configurations, resource_name))
      |> Enum.reject(&(&1.type in [:one_to_many_association, :many_to_one_association]))
      |> then(&Map.put(assigns, :index_fields, &1))
      |> get_layout_options()
      |> IndexActions.set_actions()

    ~H"""
    <div class={get_in(@auix, [:css_classes, :index_renderer, :top_container]) || ""}>
      <.header>
        {@auix.layout_options.page_title}
        <:actions>
          <div name="auix-index-header-actions">
            <%= for %{function_component: action} <- @auix.index_header_actions do %>
              {action.(%{auix: @auix})}
            <% end %>
          </div>
        </:actions>
      </.header>

      <.table
        id={"auix-table-#{@auix.link_prefix}#{@auix.source}-index"}
        auix={%{css_classes: @auix.css_classes}}
        rows={get_in(assigns, @auix.rows)}
      >
        <:col :let={{_id, entity}} :for={field <- @index_fields} label={"#{field.label}"}><.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{entity_id(@auix)}"}>{Map.get(entity, field.key)}</.auix_link></:col>

        <:action :let={row_info} :for={%{function_component: action} <- @auix.index_row_actions}>
          {action.(%{auix: Map.put(@auix, :row_info, row_info)})}
        </:action>

      </.table>

      <div name="auix-index-footer-actions">
        <%= for %{function_component: action} <- @auix.index_footer_actions do %>
          {action.(%{auix: @auix})}
        <% end %>
      </div>

      <.modal :if={@live_action in [:new, :edit]} auix={%{css_classes: @auix.css_classes}} id={"auix-#{@auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
        <div>
          <.live_component
            module={@auix.form_component}
            id={entity_id(@auix) || :new}
            action={@live_action}
            auix={%{css_classes: @auix.css_classes, entity: @auix.entity, routing_stack: @auix.routing_stack}}
          />
        </div>
      </.modal>
    </div>
    """
  end

  # PRIVATE
  @spec get_layout_options(map()) :: map()
  defp get_layout_options(assigns) do
    assigns
    |> BasicHelpers.assign_auix_option(:page_title)
    |> BasicHelpers.assign_auix_option(:page_subtitle)
  end

  @spec entity_id(map()) :: term() | list() | nil
  defp entity_id(%{entity: entity, primary_key: primary_key}),
    do: BasicHelpers.primary_key_value(entity, primary_key)

  defp entity_id(_auix), do: nil
end
