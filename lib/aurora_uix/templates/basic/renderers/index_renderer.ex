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
  import Aurora.Uix.Templates.Basic.Components
  import Aurora.Uix.Templates.Basic.RoutingComponents

  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

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
    ~H"""
    <div class="max-w-max max-w-3xl p-4 sm:p-6 lg:py-8 mx-auto">
      <.header>
        <div>
          {@auix.layout_options.page_title}
        </div>
      </.header>
      <div class="flex justify-between w-full mt-2">
        <div class="justify-self-start align-middle" name="auix-index-select-actions">
          <%= for %{function_component: action} <- @auix.index_selected_actions do %>
            {action.(%{auix: @auix})}
          <% end %>
        </div>
        <div class="justify-self-end align-middle" name="auix-index-header-actions">
          <%= for %{function_component: action} <- @auix.index_header_actions do %>
            {action.(%{auix: @auix})}
          <% end %>
        </div>
      </div>
      <.auix_simple_form :let={index_layout_form} for={@auix.index_layout_form} name="auix-index_layout_form" phx-change="index-layout-change">
        <.auix_table
          id={"auix-table-#{@auix.link_prefix}#{@auix.source}-index"}
          auix={%{configurations: @auix.configurations,
              filters: Map.get(@auix, :filters, %{}),
              index_layout_form: index_layout_form,
              filters_enabled?: @auix.filters_enabled?,
              selection: @auix.selection,
              layout_options: @auix.layout_options
              }}
          rows={@auix.layout_options.get_rows.(assigns)}
          row_id={Map.get(@auix.layout_options, :row_id)}
        >
          <:filter_action :for={%{function_component: action} <- @auix.index_filters_actions}>
            {action.(%{auix: @auix})}
          </:filter_action>

          <:col :let={{_id, entity}} :for={field <- @auix.index_fields} label={field.label} field={field}>
            <%= if field.key == :selected_check__ do %>
              <.field_value entity={entity} field={field} auix={@auix}/>
            <% else %>
              <.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{BasicHelpers.primary_key_value(entity, @auix.primary_key)}"}>
                <.field_value entity={entity} field={field} auix={@auix}/>
              </.auix_link>
            <% end %>
          </:col>

          <:action :let={row_info} :for={%{function_component: action} <- @auix.index_row_actions}>
            {action.(%{auix: Map.put(@auix, :row_info, row_info)})}
          </:action>

        </.auix_table>
      </.auix_simple_form>

      <div name="auix-index-footer-actions">
        <%= for %{function_component: action} <- @auix.index_footer_actions do %>
          {action.(%{auix: @auix})}
        <% end %>
      </div>

      <.modal :if={@live_action in [:new, :edit]} id={"auix-#{@auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
        <div>
          <.live_component
            module={@auix.form_component}
            id={entity_id(@auix) || :new}
            action={@live_action}
            auix={%{entity: @auix.entity, routing_stack: @auix.routing_stack}}
          />
        </div>
      </.modal>
    </div>
    """
  end

  # PRIVATE
  @spec entity_id(map()) :: term() | list() | nil
  defp entity_id(%{entity: entity, primary_key: primary_key}),
    do: BasicHelpers.primary_key_value(entity, primary_key)

  defp entity_id(_auix), do: nil

  @spec field_value(map()) :: Rendered.t()
  defp field_value(%{field: %{html_type: :select, data: %{option_label: label_field}}} = assigns)
       when is_atom(label_field) do
    ~H"""
      {Map.get(@entity, @field.data.option_label)}
    """
  end

  defp field_value(%{field: %{html_type: :select, data: %{option_label: option_label}}} = assigns)
       when is_function(option_label, 1) do
    ~H"""
    {@field.data.option_label.(@entity)}
    """
  end

  defp field_value(%{field: %{html_type: :select, data: %{option_label: option_label}}} = assigns)
       when is_function(option_label, 2) do
    ~H"""
      {@field.data.option_label.(assigns, @entity)}
    """
  end

  defp field_value(%{field: %{key: :selected_check__}, entity: entity, auix: auix} = assigns) do
    assigns =
      Map.put(assigns, :selected_id, BasicHelpers.primary_key_value(entity, auix.primary_key))

    ~H"""
      <.input
          name={"#{@field.key}#{@selected_id}"}
          value={MapSet.member?(@auix.selection.selected, @selected_id)}
          type={"#{@field.html_type}"}
          label={@field.label}
        />
    """
  end

  defp field_value(assigns) do
    ~H"""
    {Map.get(@entity, @field.key)}
    """
  end
end
