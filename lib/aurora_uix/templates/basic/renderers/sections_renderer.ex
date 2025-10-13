defmodule Aurora.Uix.Templates.Basic.Renderers.SectionsRenderer do
  @moduledoc """
  Renders tabbed sections and dynamic content areas in Aurora UIX.

  ## Key Features

  - Renders dynamic tabbed sections and their content
  - Supports flexible tab and section configuration
  - Integrates with Aurora UIX context and helpers
  - Provides section-level rendering for custom layouts
  """

  use Aurora.Uix.CoreComponentsImporter
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a tabbed section container with dynamic tabs and content.

  ## Parameters
    - assigns (map()) - Contains auix context with tab configuration

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    unique_id = :erlang.unique_integer([:positive])

    assigns = 
      assigns
      |> assign(:unique_id, unique_id)

    ~H"""
    <div id={"sections-#{@unique_id}-#{@auix.layout_type}"} class="sections-container" data-sections-index={@auix.layout_tree.config[:index]}>
      <div class="tab-container">
        <%= for tab <- @auix.layout_tree.config[:tabs] do %>
          <button type="button"
            class={"tab-button " <> if @auix._sections[tab.sections_id] == tab.tab_id or (@auix._sections[tab.sections_id] == nil and tab.active), do: "tab-button-active", else: ""}
            data-button-sections-index={tab.sections_index}
            data-button-tab-index={tab.tab_index}
            phx-click="switch_section"
            phx-target={if @auix.layout_type == :form, do: @auix._myself}
            phx-value-tab-id={Jason.encode!(%{sections_id: tab.sections_id, tab_id: tab.tab_id})}
            >
            <%= tab.label %>
          </button>
        <% end %>
      </div>
      <div class="tab-content">
        <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
      </div>
    </div>
    """
  end

  @doc """
  Renders a single section within a tabbed container.

  ## Parameters
    - assigns (map()) - Contains auix context with section configuration

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec section(map()) :: Phoenix.LiveView.Rendered.t()
  def section(assigns) do
    ~H"""
    <div
      class={"tab-panel " <> if @auix._sections[@auix.layout_tree.config[:sections_id]] == @auix.layout_tree.config[:tab_id] or (@auix._sections[@auix.layout_tree.config[:sections_id]] == nil and @auix.layout_tree.config[:active]), do: "", else: "hidden"}
      id={@auix.layout_tree.config[:tab_id]}
      data-tab-label={@auix.layout_tree.config[:label]}
      data-tab-sections-id={@auix.layout_tree.config[:sections_id]}
      data-tab-parent-id={@auix.layout_tree.config[:tab_parent_id]}
      data-tab-sections-index={@auix.layout_tree.config[:sections_index]}
      data-tab-index={@auix.layout_tree.config[:tab_index]}
      data-tab-active={if @auix._sections[@auix.layout_tree.config[:sections_id]] == @auix.layout_tree.config[:tab_id] or (@auix._sections[@auix.layout_tree.config[:sections_id]] == nil and @auix.layout_tree.config[:active]), do: "active", else: "inactive"}>
      <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} />
    </div>
    """
  end
end