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
  use Aurora.Uix.GettextResolver
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a tabbed section container with dynamic tabs and content.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing `:auix` context with tab configuration.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered tabbed section container.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    active_classes =
      "auix-sections-tab-button--active"

    inactive_classes =
      "auix-sections-tab-button--inactive"

    unique_id = :erlang.unique_integer([:positive])

    assigns =
      assigns
      |> assign(:active_classes, active_classes)
      |> assign(:inactive_classes, inactive_classes)
      |> assign(:unique_id, unique_id)

    ~H"""
    <div id={"sections-#{@unique_id}-#{@auix.layout_type}"} class="auix-sections-container" data-sections-index={@auix.layout_tree.index}>
      <div class="auix-sections-tab-container">
        <%= for tab <- @auix.layout_tree.tabs do %>
          <button type="button"
            class={if @auix._sections[tab.sections_id] == tab.id or (@auix._sections[tab.sections_id] == nil and tab.active?), do: @active_classes, else: @inactive_classes}
            data-button-sections-index={tab.sections_index}
            data-button-tab-index={tab.tab_index}
            phx-click="switch_section"
            phx-target={@auix._myself}
            phx-value-tab-id={Jason.encode!(%{sections_id: tab.sections_id, tab_id: tab.id})}
            >
            <%= dt(tab.label) %>
          </button>
        <% end %>
      </div>
      <div class="auix-sections-content">
        <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} uploads={assigns[:uploads] || %{}} />
      </div>
    </div>
    """
  end

  @doc """
  Renders a single section within a tabbed container.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing `:auix` context with section configuration.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered section content.
  """
  @spec section(map()) :: Phoenix.LiveView.Rendered.t()
  def section(assigns) do
    ~H"""
    <div
      class={"auix-section-tab " <> if active_tab?(@auix), do: "", else: "auix-visually-hidden"}
      id={"#{@auix.layout_tree.id}-#{@auix.layout_type}"}
      data-tab-label={@auix.layout_tree.label}
      data-tab-sections-id={@auix.layout_tree.sections_id}
      data-tab-parent-id={@auix.layout_tree.tab_parent_id}
      data-tab-sections-index={@auix.layout_tree.sections_index}
      data-tab-index={@auix.layout_tree.tab_index}
      data-tab-active={if active_tab?(@auix), do: "active", else: "inactive"}>
      <Renderer.render_inner_elements auix={@auix} auix_entity={@auix.entity} uploads={assigns[:uploads] || %{}} />
    </div>
    """
  end

  # A tab is shown when the user picked it, or when nothing was picked and it is the default.
  @spec active_tab?(map()) :: boolean()
  defp active_tab?(%{_sections: sections, layout_tree: section}) do
    case sections[section.sections_id] do
      nil -> section.active?
      tab_id -> tab_id == section.id
    end
  end
end
