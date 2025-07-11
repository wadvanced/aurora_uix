defmodule Aurora.Uix.Web.Templates.Basic.Renderers.ShowRenderer do
  @moduledoc """
  Renders detail (show) views for individual entities in Aurora UIX.

  ## Key Features

  - Displays entity attributes with layout support
  - Provides edit functionality via modal popup form
  - Consistent navigation with back button
  - Supports CSS class customization
  - Layout-aware content rendering
  - Integrates with Aurora UIX context and helpers
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Actions.Show, as: ShowActions
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Web.Templates.Basic.Renderer

  alias Phoenix.LiveView.JS

  @doc """
  Renders a detail view page for an individual entity.

  ## Parameters
  - assigns (map()) - LiveView assigns containing:
    - auix: Aurora UIX context with configurations and layout_tree info
    - live_action: Current live action (:edit)
    - page_title: Title for edit modal
    - subtitle: Optional subtitle for the header

  ## Returns
  - Phoenix.LiveView.Rendered.t() - Rendered detail view with entity information and actions
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: %{layout_tree: %{tag: :show}}} = assigns) do
    assigns =
      assigns
      |> get_layout_options()
      |> ShowActions.set_actions()

    ~H"""
    <div class={get_in(@auix.css_classes, [:show_renderer, :top_container]) || ""}>
      <.header>
        {@auix.layout_options.page_title}
        <:subtitle :if={@auix.layout_options.page_subtitle != nil}>{@auix.layout_options.page_subtitle}</:subtitle>
        <:actions>
          <div name="auix-show-header-actions">
            <%= for %{function_component: action} <- @auix.show_header_actions do %>
              {action.(%{auix: @auix})}
            <% end %>
          </div>
        </:actions>
      </.header>

      <div class="auix-show-container p-4 border rounded-lg shadow bg-white" data-layout="#{name}">
        <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
      </div>

      <div name="auix-show-footer-actions">
        <%= for %{function_component: action} <- @auix.show_footer_actions do %>
          {action.(%{auix: @auix})}
        <% end %>
      </div>
      <.modal :if={@live_action == :edit} auix={%{css_classes: @auix.css_classes}} id={"auix-#{@auix.module}-modal"} show on_cancel={JS.push("auix_route_back")}>
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
