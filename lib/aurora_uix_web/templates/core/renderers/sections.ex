defmodule Aurora.Uix.Web.Templates.Core.Renderers.Sections do
  @moduledoc """
  Renderer for tabbed sections in Aurora UIX.
  Handles rendering of dynamic tabs and their content sections.
  """

  use Aurora.Uix.Web.CoreComponents
  alias Aurora.Uix.Web.Templates.Core.Renderer

  @doc """
  Renders a tabbed section container with dynamic tabs and content.

  ## Parameters
    - assigns (map()) - Contains _auix context with tab configuration

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
    <div id={"sections-#{@unique_id}-#{@_auix._mode}"} class="" data-sections-index={@_auix._path.config[:index]}>
      <div class="auix-button-tabs-container mt-2 flex flex-col sm:flex-row">
        <%= for tab <- @_auix._path.config[:tabs] do %>
          <button type="button"
            class={"tab-button " <> if @_auix._sections[tab.sections_id] == tab.tab_id or (@_auix._sections[tab.sections_id] == nil and tab.active), do: @active_classes, else: @inactive_classes}
            data-button-sections-index={tab.sections_index}
            data-button-tab-index={tab.tab_index}
            phx-click="switch_section"
            phx-target={if @_auix._mode == :form, do: @_auix._myself}
            phx-value-tab-id={Jason.encode!(%{sections_id: tab.sections_id, tab_id: tab.tab_id})}
            >
            <%= tab.label %>
          </button>
        <% end %>
      </div>
      <div class="auix-sections-content p-4 border border-gray-300 rounded-tr-lg rounded-br-lg rounded-bl-lg">
        <Renderer.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
      </div>
    </div>
    """
  end

  @doc """
  Renders a single section within a tabbed container.

  ## Parameters
    - assigns (map()) - Contains _auix context with section configuration

  Returns:
    - Phoenix.LiveView.Rendered.t()
  """
  @spec section(map()) :: Phoenix.LiveView.Rendered.t()
  def section(assigns) do
    ~H"""
    <div
      class={"auix-section-tab " <> if @_auix._sections[@_auix._path.config[:sections_id]] == @_auix._path.config[:tab_id] or (@_auix._sections[@_auix._path.config[:sections_id]] == nil and @_auix._path.config[:active]), do: "", else: "hidden"}
      id={@_auix._path.config[:tab_id]}
      data-tab-label={@_auix._path.config[:label]}
      data-tab-sections-id={@_auix._path.config[:sections_id]}
      data-tab-parent-id={@_auix._path.config[:tab_parent_id]}
      data-tab-sections-index={@_auix._path.config[:sections_index]}
      data-tab-index={@_auix._path.config[:tab_index]}
      data-tab-active={if @_auix._sections[@_auix._path.config[:sections_id]] == @_auix._path.config[:tab_id] or (@_auix._sections[@_auix._path.config[:sections_id]] == nil and @_auix._path.config[:active]), do: "active", else: "inactive"}>
      <Renderer.render_inner_elements _auix={@_auix} auix_entity={@auix_entity} />
    </div>
    """
  end
end
