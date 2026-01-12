defmodule Aurora.Uix.Templates.Basic.Renderers.ShowComponentRenderer do
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

  use Aurora.Uix.CoreComponentsImporter
  use Phoenix.LiveView

  import Aurora.Uix.Templates.Basic.Components, only: [record_navigator_bar: 1]
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a detail view page for an individual entity.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with configurations and layout_tree info.
    * `:live_action` (atom()) - Current live action (`:edit`).

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered detail view with entity information and actions.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: %{layout_tree: %{tag: :show}}} = assigns) do
    ~H"""
    <div>
      <div class="auix-show-container">
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

        <div class="auix-show-content" data-layout="#{name}">
          <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
        </div>

        <div name="auix-show-footer-actions">
          <%= for %{function_component: action} <- @auix.show_footer_actions do %>
            {action.(%{auix: @auix})}
          <% end %>
        </div>
        <.record_navigator_bar pagination={@auix.pagination} item_index={@auix.item_index} />
      </div>
    </div>
    """
  end
end
