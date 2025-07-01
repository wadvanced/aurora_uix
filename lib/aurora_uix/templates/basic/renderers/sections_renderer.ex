defmodule Aurora.Uix.Web.Templates.Basic.Renderers.SectionsRenderer do
  @moduledoc """
  Renders tabbed sections and dynamic content areas in Aurora UIX.

  ## Key Features

  - Renders dynamic tabbed sections and their content
  - Supports flexible tab and section configuration
  - Integrates with Aurora UIX context and helpers
  - Provides section-level rendering for custom layouts
  """

  use Aurora.Uix.Web.CoreComponentsImporter
  alias Aurora.Uix.Web.Templates.Basic.Renderer

  @doc """
  Renders a tabbed section container with dynamic tabs and content.

  ## Parameters
    - assigns (map()) - Contains auix context with tab configuration

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    active_classes =
      "auix-tab-button active px-4 py-2 text-sm font-semibold transition-all duration-200 text-zinc-800 bg-zinc-100 border-b-2 border-transparent rounded-t-md"

    inactive_classes =
      "auix-tab-button px-4 py-2 text-sm font-medium transition-all duration-200 text-zinc-400 bg-zinc-50 hover:bg-zinc-200 border-b-2 border-transparent rounded-t-md"

    unique_id = :erlang.unique_integer([:positive])

    assigns =
      assigns
      |> assign(:active_classes, active_classes)
      |> assign(:inactive_classes, inactive_classes)
      |> assign(:unique_id, unique_id)

    ~H"""
    <div id={"sections-#{@unique_id}-#{@auix.layout_type}"} class="" data-sections-index={@auix._path.config[:index]}>
      <div class="auix-button-tabs-container mt-2 flex flex-col sm:flex-row">
        <%= for tab <- @auix._path.config[:tabs] do %>
          <button type="button"
            class={"tab-button " <> if @auix._sections[tab.sections_id] == tab.tab_id or (@auix._sections[tab.sections_id] == nil and tab.active), do: @active_classes, else: @inactive_classes}
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
      <div class="auix-sections-content p-4 border border-gray-300 rounded-tr-lg rounded-br-lg rounded-bl-lg">
        <Renderer.render_inner_elements auix={@auix} auix_entity={@auix_entity} />
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
      class={"auix-section-tab " <> if @auix._sections[@auix._path.config[:sections_id]] == @auix._path.config[:tab_id] or (@auix._sections[@auix._path.config[:sections_id]] == nil and @auix._path.config[:active]), do: "", else: "hidden"}
      id={@auix._path.config[:tab_id]}
      data-tab-label={@auix._path.config[:label]}
      data-tab-sections-id={@auix._path.config[:sections_id]}
      data-tab-parent-id={@auix._path.config[:tab_parent_id]}
      data-tab-sections-index={@auix._path.config[:sections_index]}
      data-tab-index={@auix._path.config[:tab_index]}
      data-tab-active={if @auix._sections[@auix._path.config[:sections_id]] == @auix._path.config[:tab_id] or (@auix._sections[@auix._path.config[:sections_id]] == nil and @auix._path.config[:active]), do: "active", else: "inactive"}>
      <Renderer.render_inner_elements auix={@auix} auix_entity={@auix_entity} />
    </div>
    """
  end
end
