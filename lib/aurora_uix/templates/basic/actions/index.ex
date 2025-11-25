defmodule Aurora.Uix.Templates.Basic.Actions.Index do
  @moduledoc """
  Renders default row and header action links (show, edit, delete, new) for entities in index layouts.

  ## Key Features

  - Provides LiveView-compatible components for "show", "edit", "delete", and "new" actions
  - Generates links using assigns context for entity and module information
  - Supplies helpers to add all default row and header actions to assigns
  - Supports dynamic modification of actions via layout tree options
  - Includes responsive pagination controls with multiple breakpoints
  - Offers filter management actions (clear/submit)

  ## Key Constraints

  - Assumes assigns contain `:auix` with required subkeys:
    * `:row_info` - Entity row information
    * `:source` - Data source identifier
    * `:module` - Context module name
  - Only intended for use in index page layouts
  - Pagination requires specific assigns structure
  """

  use Aurora.Uix.Gettext
  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.Components
  import Aurora.Uix.Templates.Basic.RoutingComponents
  import Phoenix.Component, only: [sigil_H: 2, link: 1, live_component: 1]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions
  alias Aurora.Uix.Templates.Basic.ConfirmButton
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  @actions Action.available_actions(:index)
  @filters_button_class "auix-button--alt"
  @selected_button_class "auix-index-delete-all-action-button"

  @doc """
  Sets up actions for the index layout by adding defaults and applying modifications.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket containing the layout state

  ## Returns
  Socket.t() - The updated socket with all default actions configured

  """
  @spec set_actions(Socket.t()) :: Socket.t()
  def set_actions(socket) do
    socket
    |> Actions.remove_all_actions(@actions)
    |> add_default_row_actions()
    |> add_default_selected_actions()
    |> add_default_select_all_actions()
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders the "edit" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:source` (binary()) - Data source identifier
      - `:row_info` (tuple()) - Entity row information
      - `:module` (atom()) - Context module name

  ## Returns
  Rendered.t() - The rendered "edit" action link
  """
  @spec edit_row_action(map()) :: Rendered.t()
  def edit_row_action(assigns) do
    ~H"""
      <.auix_link class="auix-index-row-action" href="#" patch={"/#{@auix.uri_path}/#{row_info_id(@auix)}/edit"} name={"auix-edit-#{@auix.module}"}>
        <.icon class="auix-icon-size-5 auix-icon-safe" name="hero-pencil-square" />
      </.auix_link>
    """
  end

  @doc """
  Renders the "delete" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:row_info` (tuple()) - Entity row information
      - `:module` (atom()) - Context module name

  ## Returns
  Rendered.t() - The rendered "delete" action link with confirmation

  ## Edge Cases
  - If `@auix.row_info` is missing or malformed, returns malformed link
  """
  @spec remove_row_action(map()) :: Rendered.t()
  def remove_row_action(assigns) do
    ~H"""
      <.link
            phx-click={JS.push("delete", value: %{id: row_info_id(@auix)}) |> uix_hide("##{row_info_id(@auix)}")}
            name={"auix-delete-#{@auix.module}"}
            data-confirm={gettext("Are you sure?")}
          >
        <.icon class="auix-icon-size-5 auix-icon-danger" name="hero-trash" />
      </.link>
    """
  end

  @doc """
  Renders a button to delete the selected items.

  ## Parameters
  - `assigns` (map()) - Assigns map.

  ## Returns
  Rendered.t() - Button that triggers the event
  """
  @spec selected_delete_all_action(map()) :: Rendered.t()
  def selected_delete_all_action(
        %{auix: %{selection: %{selected_count: selected_count, toggle_all_mode: toggle_all_mode}}} =
          assigns
      )
      when toggle_all_mode == :none and selected_count > 0 do
    assigns = Map.put(assigns, :selected_button_class, @selected_button_class)

    ~H"""
      <.live_component 
        id={"auix-delete-all-button-#{@auix.module}"}
        module={ConfirmButton}
        class={@selected_button_class}
        value={%{delete_all: true}}
        event="selected-delete_all"
        target={"##{@auix.index_form_id}"}
      >
        <:content>
          {gettext("Delete selected")} <span class="auix-button-badge">{@auix.selection.selected_count}</span>
        </:content>

        <:confirm_message>
          <div>
            <%= if @auix.selection.selected_count == 1 do %>
              <span>{gettext("Do you want to remove the selected item?")}</span>
            <% else %>
              <span>{gettext("Do you want to remove all the selected items?")}</span>
            <% end %>
          </div>
        </:confirm_message>
        
      </.live_component>
    """
  end

  def selected_delete_all_action(assigns), do: ~H""

  @doc """
  Renders a button to unselect all items.

  ## Parameters
  - `assigns` (map()) - Assigns map.

  ## Returns
  Rendered.t() - Button that triggers the event
  """
  @spec selected_uncheck_all_action(map()) :: Rendered.t()
  def selected_uncheck_all_action(
        %{
          auix: %{
            selection: %{selected_count: selected_count, toggle_all_mode: toggle_all_mode}
          }
        } =
          assigns
      )
      when toggle_all_mode == :none and selected_count > 0 do
    assigns = Map.put(assigns, :selected_button_class, @selected_button_class)

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-toggle_all" phx-value-state="false"
        name={"auix-selected-uncheck_all-#{@auix.module}"}>
      {gettext("Uncheck all")}
    </.button>
    """
  end

  def selected_uncheck_all_action(
        %{auix: %{selection: %{toggle_all_mode: toggle_all_mode}}} = assigns
      )
      when toggle_all_mode == :uncheck do
    assigns = Map.put(assigns, :selected_button_class, @selected_button_class)

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-cancel_toggle_all">{gettext("De-selecting all items. Selection is disabled for a while... Click to cancel")}</.button>
    """
  end

  def selected_uncheck_all_action(assigns), do: ~H""

  @doc """
  Renders a button to select all items.

  ## Parameters
  - `assigns` (map()) - Assigns map.

  ## Returns
  Rendered.t() - Button that triggers the event
  """
  @spec selected_check_all_action(map()) :: Rendered.t()
  def selected_check_all_action(
        %{
          auix: %{
            pagination: %{entries_count: entries_count},
            selection: %{selected_count: selected_count, toggle_all_mode: toggle_all_mode}
          }
        } = assigns
      )
      when toggle_all_mode == :none and selected_count < entries_count do
    assigns = Map.put(assigns, :selected_button_class, @selected_button_class)

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-toggle_all" phx-value-state="true"
        name={"auix-selected_check_all-#{@auix.module}"} disabled={@auix.selection.toggle_all_mode != :none}>
      {gettext("Check all")}
    </.button>
    """
  end

  def selected_check_all_action(
        %{auix: %{selection: %{toggle_all_mode: toggle_all_mode}}} = assigns
      )
      when toggle_all_mode == :check do
    assigns = Map.put(assigns, :selected_button_class, @selected_button_class)

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-cancel_toggle_all">{gettext("Selecting all items. Selection is disabled for a while... Click to cancel")}</.button>
    """
  end

  def selected_check_all_action(assigns), do: ~H""

  @doc """
  Renders checkbox to toggle selection of all rows in index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:selection` (map()) - Current selection states for the page

  ## Returns
  Rendered.t() - Checkbox input that triggers "selected-toggle-all" event
  """
  @spec toggle_selected_all_in_page_action(map()) :: Rendered.t()
  def toggle_selected_all_in_page_action(
        %{auix: %{selection: %{toggle_all_mode: toggle_all_mode}}} = assigns
      )
      when toggle_all_mode == :none do
    ~H"""
      <.input
          name="selected_in_page__"
          value={Map.get(@auix.selection, :selected_any_in_page?, false)}
          type="checkbox"
          label=""
          disabled={@auix.selection.toggle_all_mode != :none}
        />
    """
  end

  def toggle_selected_all_in_page_action(assigns), do: ~H""

  @doc """
  Renders the "new" action link for the header in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:index_new_link` (binary()) - Path for new entity creation
      - `:module` (atom()) - Context module name
      - `:name` (binary()) - Display name for the entity type

  ## Returns
  Rendered.t() - Button link for creating new entities
  """
  @spec new_header_action(map()) :: Rendered.t()
  def new_header_action(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}"} role="button">
      <.button>{gettext("New")} {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc """
  Renders a open filters or close filters buttons.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:

  ## Returns
  Rendered.t() - Button link for creating new entities
  """
  @spec toggle_filters_action(map()) :: Rendered.t()
  def toggle_filters_action(assigns) do
    ~H"""
      <div :if={Map.get(@auix, :filters) != []} class="auix-button-toggle-filters-container">
        <div class="auix-button-toggle-filters-content">
          <%= if Map.get(@auix, :filters_enabled?) do %>
            <a href="#" phx-click="filter-toggle" name="auix-filter_toggle_close" class="auix-button-toggle-filters-close-link">
            <.icon name="hero-funnel" class={if @auix.filters_selected_count > 0, do: "auix-icon-inactive"}/>
              <.icon name="hero-x-mark" class="auix-icon-size-3 auix-vertical-align-super"/>
            <div :if={@auix.filters_selected_count > 0} class="auix-filter-selected-count">{@auix.filters_selected_count}</div>
            </a>
          <% else %>
            <a href="#" phx-click="filter-toggle" name="auix-filter_toggle_open" class="hero-funnel" />
            <div :if={@auix.filters_selected_count > 0} class="auix-filter-selected-count">{@auix.filters_selected_count}</div>
          <% end %>
        </div>
      </div>
    """
  end

  @doc """
  Renders a button to clear all applied filters in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map (no specific requirements)

  ## Returns
  Rendered.t() - Button that triggers "filters-clear" event

  ## Notes
  - Uses predefined button styling from module attribute @filters_button_class
  """
  @spec clear_filters_action(map()) :: Rendered.t()
  def clear_filters_action(%{auix: %{filters_enabled?: true}} = assigns) do
    assigns = Map.put(assigns, :filters_button_class, @filters_button_class)

    ~H"""
    <.button type="button" class={@filters_button_class} phx-click="filters-clear" name={"auix-filters_clear-#{@auix.module}"}>{gettext("Clear Filters")}</.button>
    """
  end

  def clear_filters_action(assigns), do: ~H""

  @doc """
  Renders a button to submit current filter selections in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map (no specific requirements)

  ## Returns
  Rendered.t() - Button that triggers "filters-submit" event

  ## Notes
  - Uses predefined button styling from module attribute @filters_button_class
  """
  @spec submit_filters_action(map()) :: Rendered.t()
  def submit_filters_action(%{auix: %{filters_enabled?: true}} = assigns) do
    assigns = Map.put(assigns, :filters_button_class, @filters_button_class)

    ~H"""
    <.button type="button" class={@filters_button_class} phx-click="filters-submit" name={"auix-filters_submit-#{@auix.module}"}>{gettext("Submit")}</.button>
    """
  end

  def submit_filters_action(assigns), do: ~H""

  @doc """
  Renders pagination controls for the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:layout_options` (map()) - Must contain:
        * `:pagination_disabled?` (boolean()) - False to enable
        * `:pages_bar_range_offset` (function()) - Breakpoint sizing function
      - `:pagination` (map()) - Must contain:
        * `:page` (integer()) - Current page
        * `:pages_count` (integer()) - Total pages (>1 to render)
      - `:source` (binary()) - Data source identifier

  ## Returns
  Rendered.t() - Responsive pagination controls or empty fragment

  ## Breakpoints
  - Renders different pagination ranges for:
    * xl2 (2xl): widest range
    * xl: medium range
    * lg: smaller range
    * md: minimal range
    * sm: mobile-optimized
  """
  @spec pagination_action(map()) :: Rendered.t()
  def pagination_action(
        %{
          auix: %{
            layout_options: %{pagination_disabled?: false},
            pagination: %{page: _page, pages_count: pages_count}
          }
        } = assigns
      )
      when pages_count > 1 do
    ~H"""
      <div name={"auix-pages_bar-#{@auix.source}"} class="auix-pagination-container">
        <div class="auix-horizontal-divider"></div>
        <div class="auix-pagination-breakpoint-xl2" name={"auix-pages_bar-#{@auix.source}-xl2"}>
          <.pages_selection pagination={@auix.pagination}
              pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :xl2)}
              selected_in_page={@auix.selection.selected_in_page}/>
        </div>
        <div class="auix-pagination-breakpoint-xl" name={"auix-pages_bar-#{@auix.source}-xl"}>
          <.pages_selection pagination={@auix.pagination}
              pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :xl)}
              selected_in_page={@auix.selection.selected_in_page}/>
        </div>
        <div class="auix-pagination-breakpoint-lg " name={"auix-pages_bar-#{@auix.source}-lg"}>
          <.pages_selection pagination={@auix.pagination}
              pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :lg)}
              selected_in_page={@auix.selection.selected_in_page}/>
        </div>
        <div class="auix-pagination-breakpoint-md" name={"auix-pages_bar-#{@auix.source}-md"}>
          <.pages_selection pagination={@auix.pagination}
              pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :md)}
              selected_in_page={@auix.selection.selected_in_page}/>
        </div>
      </div>
    """
  end

  def pagination_action(assigns) do
    ~H""
  end

  ## PRIVATE

  # Adds default row actions (show, edit, delete) using component functions
  @spec add_default_row_actions(Socket.t()) :: Socket.t()
  defp add_default_row_actions(socket) do
    Actions.add_actions(socket, :index_row_actions,
      default_row_edit: &edit_row_action/1,
      default_row_delete: &remove_row_action/1
    )
  end

  # Adds action when any item is selected to assigns
  @spec add_default_selected_actions(Socket.t()) :: Socket.t()
  defp add_default_selected_actions(socket) do
    Actions.add_actions(socket, :index_selected_actions,
      default_selected_delete_all: &selected_delete_all_action/1,
      default_selected_uncheck_all: &selected_uncheck_all_action/1,
      default_selected_check_all: &selected_check_all_action/1
    )
  end

  # Adds all row selection toggle action to assigns
  @spec add_default_select_all_actions(Socket.t()) :: Socket.t()
  defp add_default_select_all_actions(socket) do
    Actions.add_actions(socket, :index_selected_all_actions,
      default_toggle_all_selected: &toggle_selected_all_in_page_action/1
    )
  end

  # Adds default header action (new entity) to assigns
  @spec add_default_header_actions(Socket.t()) :: Socket.t()
  defp add_default_header_actions(socket) do
    Actions.add_actions(socket, :index_header_actions,
      default_toggle_filters: &toggle_filters_action/1,
      default_clear: &clear_filters_action/1,
      default_submit: &submit_filters_action/1,
      default_new: &new_header_action/1
    )
  end

  # Adds pagination controls to footer actions in assigns
  @spec add_default_footer_actions(Socket.t()) :: Socket.t()
  defp add_default_footer_actions(socket),
    do:
      Actions.add_actions(socket, :index_footer_actions, default_pagination: &pagination_action/1)

  # Extracts primary key value from row_info tuple {index, entity_map}
  @spec row_info_id(map()) :: term() | nil
  defp row_info_id(%{row_info: {_, row_entity}, primary_key: primary_key}) do
    BasicHelpers.primary_key_value(row_entity, primary_key)
  end
end
