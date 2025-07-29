defmodule Aurora.Uix.Templates.Basic.Renderers.IndexRenderer do
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

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Templates.Basic.Actions.Index, as: IndexActions
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
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
  def render(assigns) do
    assigns =
      assigns
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

      <.simple_form :let={filters_form} for={@auix.filters_form} name="auix-filters_form" phx-change="filter-change">
        <.table
          id={"auix-table-#{@auix.link_prefix}#{@auix.source}-index"}
          auix={%{css_classes: @auix.css_classes,
              configurations: @auix.configurations,
              filters: Map.get(@auix, :filters, %{}), filters_form: filters_form,
              filters_enabled?: @auix.filters_enabled?}}
          rows={get_in(assigns, @auix.rows)}
        >
          <:filter_action :for={%{function_component: action} <- @auix.index_filters_actions}>
            {action.(%{auix: @auix})}
          </:filter_action>

          <:col :let={{_id, entity}} :for={field <- @auix.index_fields} label={"#{field.label}"} field={field}><.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{BasicHelpers.primary_key_value(entity, @auix.primary_key)}"}>{field_value(entity, Map.put(assigns, :field, field))}</.auix_link></:col>

          <:action :let={row_info} :for={%{function_component: action} <- @auix.index_row_actions}>
            {action.(%{auix: Map.put(@auix, :row_info, row_info)})}
          </:action>

        </.table>
      </.simple_form>

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

  @spec field_value(term(), map()) :: term()
  defp field_value(entity, %{field: %{html_type: :select, data: %{option_label: label_field}}})
       when is_atom(label_field) do
    Map.get(entity, label_field)
  end

  defp field_value(entity, %{field: %{html_type: :select, data: %{option_label: option_label}}})
       when is_function(option_label, 1) do
    option_label.(entity)
  end

  defp field_value(
         entity,
         %{field: %{html_type: :select, data: %{option_label: option_label}}} = assigns
       )
       when is_function(option_label, 2) do
    option_label.(assigns, entity)
  end

  defp field_value(entity, %{field: field}) do
    Map.get(entity, field.key)
  end
end
