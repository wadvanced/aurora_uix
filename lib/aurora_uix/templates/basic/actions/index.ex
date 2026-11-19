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
  - Offers a card-view sort control (a select of default order plus the sortable fields, and a direction switch; below the `sm` breakpoint, one icon button with a menu of the fields and directions)
  - Every button and link action takes its icon from the layout's `action_icons:` option (defaults in `Aurora.Uix.Action.default_icons/1`); below the `sm` breakpoint a text button shows only its icon

  ## Key Constraints

  - Assumes assigns contain `:auix` with required subkeys:
    * `:row_info` - Entity row information
    * `:source` - Data source identifier
    * `:module` - Context module name
  - Only intended for use in index page layouts
  - Pagination requires specific assigns structure
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver
  use Phoenix.Component

  import Aurora.Uix.Templates.Basic.Components
  import Aurora.Uix.Templates.Basic.RoutingComponents
  # import Phoenix.Component, only: [sigil_H: 2, link: 1, live_component: 1, slot: 2]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions
  alias Aurora.Uix.Templates.Basic.ConfirmButton
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  @actions Action.available_actions(:index)
  @filters_button_class "auix-button--alt"
  @selected_button_class "auix-index-all-action-button"

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
  Renders the "show" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:row_info` (tuple()) - Entity row information
      - `:module` (atom()) - Context module name

  ## Returns
  Rendered.t() - The rendered "show" action link.
  """
  slot(:contents)
  @spec show_row_action(map()) :: Rendered.t()
  def show_row_action(%{auix: %{notify: _notify}} = assigns) do
    assigns =
      assigns
      |> Map.put(:icon, resolve_icon(assigns, :default_row_show))
      |> Map.put(:title, if(Map.get(assigns, :contents, []) == [], do: dt("Show")))

    ~H"""
      <.auix_link class="auix-index-row-action" href="#" phx-click="auix_open" phx-value-action="show" phx-value-id={row_info_id(@auix)} phx-target={@auix._myself} name={"auix-show-#{@auix.module}"} title={@title} aria-label={@title}>
        <%= if Map.get(assigns, :contents) == [] do %>
          <.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-info" />
        <% else %>
          {render_slot(@contents)}
        <% end %>
      </.auix_link>
    """
  end

  def show_row_action(assigns) do
    assigns =
      assigns
      |> Map.put(:icon, resolve_icon(assigns, :default_row_show))
      |> Map.put(:title, if(Map.get(assigns, :contents, []) == [], do: dt("Show")))

    ~H"""
      <.auix_link class="auix-index-row-action" href="#" patch={"/#{@auix.uri_path}/#{row_info_id(@auix)}/show"} name={"auix-show-#{@auix.module}"} title={@title} aria-label={@title}>
        <%= if Map.get(assigns, :contents) == [] do %>
          <.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-info" />
        <% else %>
          {render_slot(@contents)}
        <% end %>
      </.auix_link>
    """
  end

  @doc """
  Renders the "edit" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:row_info` (tuple()) - Entity row information
      - `:module` (atom()) - Context module name

  ## Returns
  Rendered.t() - The rendered "edit" action link
  """
  slot(:contents)
  @spec edit_row_action(map()) :: Rendered.t()
  def edit_row_action(%{auix: %{notify: _notify}} = assigns) do
    assigns =
      assigns
      |> Map.put(:icon, resolve_icon(assigns, :default_row_edit))
      |> Map.put(:title, if(Map.get(assigns, :contents, []) == [], do: dt("Edit")))

    ~H"""
      <.auix_link class="auix-index-row-action" href="#" phx-click="auix_open" phx-value-action="edit" phx-value-id={row_info_id(@auix)} phx-target={@auix._myself} name={"auix-edit-#{@auix.module}"} title={@title} aria-label={@title}>
        <%= if Map.get(assigns, :contents) == [] do %>
          <.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-safe" />
        <% else %>
          {render_slot(@contents)}
        <% end %>
      </.auix_link>
    """
  end

  def edit_row_action(assigns) do
    assigns =
      assigns
      |> Map.put(:icon, resolve_icon(assigns, :default_row_edit))
      |> Map.put(:title, if(Map.get(assigns, :contents, []) == [], do: dt("Edit")))

    ~H"""
      <.auix_link class="auix-index-row-action" href="#" patch={"/#{@auix.uri_path}/#{row_info_id(@auix)}/edit"} name={"auix-edit-#{@auix.module}"} title={@title} aria-label={@title}>
        <%= if Map.get(assigns, :contents) == [] do %>
          <.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-safe" />
        <% else %>
          {render_slot(@contents)}
        <% end %>
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
  slot(:contents)
  @spec remove_row_action(map()) :: Rendered.t()
  def remove_row_action(assigns) do
    assigns =
      assigns
      |> Map.put(:icon, resolve_icon(assigns, :default_row_delete))
      |> Map.put(:title, if(Map.get(assigns, :contents, []) == [], do: dt("Delete")))

    ~H"""
      <.auix_link
            phx-click={JS.push("delete", BasicHelpers.target_opts(@auix, value: %{id: row_info_id(@auix)})) |> uix_hide(row_dom_selector(@auix))}
            name={"auix-delete-#{@auix.module}"}
            data-confirm={dt("Are you sure?")}
            title={@title}
            aria-label={@title}
          >
        <%= if Map.get(assigns, :contents) == [] do %>
          <.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-danger" />
        <% else %>
          {render_slot(@contents)}
        <% end %>
      </.auix_link>
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
    assigns =
      assigns
      |> Map.put(:selected_button_class, @selected_button_class)
      |> put_action(:default_selected_delete_all, dt("Delete selected"))

    ~H"""
      <.live_component 
        id={BasicHelpers.instance_dom_id(@auix, "auix-delete-all-button")}
        module={ConfirmButton}
        class={@selected_button_class}
        title={@title}
        value={%{delete_all: true}}
        event="selected-delete_all"
        target={uix_id_selector(@auix.index_form_id)}
      >
        <:content>
          <.action_content icon={@icon} label={@label} /> <span class="auix-button-badge">{@auix.selection.selected_count}</span>
        </:content>

        <:confirm_message>
          <div>
            <%= if @auix.selection.selected_count == 1 do %>
              <span>{dt("Do you want to remove the selected item?")}</span>
            <% else %>
              <span>{dt("Do you want to remove all the selected items?")}</span>
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
    assigns =
      assigns
      |> Map.put(:selected_button_class, @selected_button_class)
      |> put_action(:default_selected_uncheck_all, dt("Uncheck all"))

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-toggle_all" phx-value-state="false" phx-target={@auix[:_myself]}
        name={"auix-selected-uncheck_all-#{@auix.module}"} title={@title} aria-label={@title}>
      <.action_content icon={@icon} label={@label} />
    </.button>
    """
  end

  def selected_uncheck_all_action(
        %{auix: %{selection: %{toggle_all_mode: toggle_all_mode}}} = assigns
      )
      when toggle_all_mode == :uncheck do
    assigns =
      assigns
      |> Map.put(:selected_button_class, @selected_button_class)
      |> put_action(
        :default_selected_uncheck_all,
        dt("De-selecting all items. Selection is disabled for a while... Click to cancel")
      )

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-cancel_toggle_all" phx-target={@auix[:_myself]} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
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
    assigns =
      assigns
      |> Map.put(:selected_button_class, @selected_button_class)
      |> put_action(:default_selected_check_all, dt("Check all"))

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-toggle_all" phx-value-state="true" phx-target={@auix[:_myself]}
        name={"auix-selected_check_all-#{@auix.module}"} disabled={@auix.selection.toggle_all_mode != :none} title={@title} aria-label={@title}>
      <.action_content icon={@icon} label={@label} />
    </.button>
    """
  end

  def selected_check_all_action(
        %{auix: %{selection: %{toggle_all_mode: toggle_all_mode}}} = assigns
      )
      when toggle_all_mode == :check do
    assigns =
      assigns
      |> Map.put(:selected_button_class, @selected_button_class)
      |> put_action(
        :default_selected_check_all,
        dt("Selecting all items. Selection is disabled for a while... Click to cancel")
      )

    ~H"""
    <.button type="button" class={@selected_button_class} phx-click="selected-cancel_toggle_all" phx-target={@auix[:_myself]} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
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
  def new_header_action(%{auix: %{notify: _notify}} = assigns) do
    assigns = put_action(assigns, :default_new, dt(assigns.auix.layout_options.new_action_label))

    ~H"""
    <.auix_link phx-click="auix_open" phx-value-action="new" phx-target={@auix._myself} name={"auix-new-#{@auix.module}"} role="button" title={@title} aria-label={@title}>
      <.button><.action_content icon={@icon} label={@label} /></.button>
    </.auix_link>
    """
  end

  def new_header_action(assigns) do
    assigns = put_action(assigns, :default_new, dt(assigns.auix.layout_options.new_action_label))

    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}"} role="button" title={@title} aria-label={@title}>
      <.button><.action_content icon={@icon} label={@label} /></.button>
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
    assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_toggle_filters))

    ~H"""
      <div :if={Map.get(@auix, :filters) != []} class="auix-button-toggle-filters-container">
        <div class="auix-button-toggle-filters-content">
          <%= if Map.get(@auix, :filters_enabled?) do %>
            <a href="#" phx-click="filter-toggle" phx-target={@auix[:_myself]} name="auix-filter_toggle_close" class="auix-button-toggle-filters-close-link">
              <.action_icon icon={@icon} class={if @auix.filters_selected_count > 0, do: "auix-icon-inactive auix-icon-size-5", else: "auix-icon-info auix-icon-size-5"} />
              <.icon name="hero-x-mark" class="auix-icon-size-3 auix-vertical-align-super"/>
            </a>
            <div :if={@auix.filters_selected_count > 0} class="auix-button-badge">{@auix.filters_selected_count}</div>
          <% else %>
            <a href="#" phx-click="filter-toggle" phx-target={@auix[:_myself]} name="auix-filter_toggle_open"><.action_icon icon={@icon} class="auix-icon-info auix-icon-size-5" /></a>
            <div :if={@auix.filters_selected_count > 0} class="auix-button-badge">{@auix.filters_selected_count}</div>

          <% end %>
        </div>
      </div>
    """
  end

  @doc """
  Renders the sort control for the index card view. From the `sm` breakpoint up it is a select
  of "Default order" (the backend order, no user sort) and the sortable index fields, plus a
  switch button that reverses the direction of the active sort; the switch is disabled while
  the default order is shown. Below the `sm` breakpoint it is one icon button that opens a menu
  of "Default order", the sortable fields, "Ascending" and "Descending": a check marks the
  active field and direction, the directions are disabled while the default order is shown,
  and the button is highlighted while a field sort is on. The control shows below the `md`
  breakpoint; with the card's `show_on: :all` it shows at every breakpoint.

  The select and the menu's field options emit `"index-sort"` with `"sort"` set to the field
  key (`""` for "Default order"). The switch emits `"index-sort-direction"`; the menu's
  direction options emit it with `"direction"` set to `"asc"` and `"desc"`.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with:
      - `:index_fields` (list()) - Index fields; only those with `sortable?: true` are offered
      - `:sort` (map() | nil) - The active sort, `%{key: atom(), direction: :asc | :desc}`
      - `:layout_options` (map()) - Must contain `:sort_disabled?`
      - `:module` (binary()) - Context module name

  ## Returns
  Rendered.t() - The sort control, or an empty fragment when sorting is disabled or no
  field is sortable
  """
  @spec sort_header_action(map()) :: Rendered.t()
  def sort_header_action(%{auix: %{layout_options: %{sort_disabled?: false}} = auix} = assigns) do
    sort_options =
      for %{sortable?: true} = field <- auix.index_fields,
          do: {dt(field.label), to_string(field.key)}

    assigns =
      assigns
      |> Map.put(:sort_options, sort_options)
      |> Map.put(:sort_key, auix.sort && to_string(auix.sort.key))
      |> Map.put(:sort_icon, BasicHelpers.sort_icon(auix.sort && auix.sort.direction))
      |> Map.put(:sort_direction, auix.sort && auix.sort.direction)
      |> Map.put(:menu_toggle_class, sort_menu_toggle_class(auix.sort))
      |> Map.put(:always?, match?(%{card: %{show_on: :all}}, auix.layout_tree))

    ~H"""
    <div :if={@sort_options != []} class={["auix-index-sort-action", @always? && "auix-index-sort-action--always"]} name={"auix-sort_action-#{@auix.module}"}>
      <div class="auix-index-sort-select">
        <.form for={%{}} id={BasicHelpers.instance_dom_id(@auix, "auix-sort-form")} phx-change="index-sort" phx-target={@auix[:_myself]}>
          <.input type="select" id={BasicHelpers.instance_dom_id(@auix, "auix-sort-key")} name="sort"
              options={@sort_options}
              value={@sort_key}
              prompt={dt("Default order")}
              omit_label?={true} />
        </.form>
        <.button type="button" class="auix-button--alt"
            name={"auix-sort_direction-#{@auix.module}"}
            disabled={is_nil(@auix.sort)}
            phx-click="index-sort-direction"
            phx-target={@auix[:_myself]}
            aria-label={dt("Reverse sort direction")}>
          <.icon name={@sort_icon} />
        </.button>
      </div>
      <div class="auix-index-sort-menu" name="auix-sort_menu"
          phx-click={toggle_sort_menu()} phx-click-away={hide_sort_menu()}>
        <.button type="button" class={@menu_toggle_class} name="auix-sort_menu_toggle"
            title={dt("Sort")} aria-label={dt("Sort")} aria-haspopup="menu" aria-expanded="false">
          <.icon name="hero-arrows-up-down" />
        </.button>
        <div class="auix-index-sort-menu-list" name="auix-sort_menu_list" role="menu">
          <div class="auix-index-sort-menu-group" role="group" aria-label={dt("Sort by")}>
            <.button type="button" class="auix-index-sort-menu-item" name="auix-sort_menu_default"
                role="menuitemradio" aria-checked={to_string(is_nil(@auix.sort))}
                phx-click={push_sort_menu(@auix, "index-sort", %{sort: ""})}>
              <.icon name="hero-check" class={sort_menu_check_class(is_nil(@auix.sort))} />
              {dt("Default order")}
            </.button>
            <.button :for={{label, key} <- @sort_options} type="button" class="auix-index-sort-menu-item"
                name={"auix-sort_menu_field-#{key}"}
                role="menuitemradio" aria-checked={to_string(@sort_key == key)}
                phx-click={push_sort_menu(@auix, "index-sort", %{sort: key})}>
              <.icon name="hero-check" class={sort_menu_check_class(@sort_key == key)} />
              {label}
            </.button>
          </div>
          <div class="auix-index-sort-menu-group" role="group" aria-label={dt("Sort direction")}>
            <.button type="button" class="auix-index-sort-menu-item" name="auix-sort_menu_direction-asc"
                role="menuitemradio" aria-checked={to_string(@sort_direction == :asc)}
                disabled={is_nil(@auix.sort)}
                phx-click={push_sort_menu(@auix, "index-sort-direction", %{direction: "asc"})}>
              <.icon name="hero-check" class={sort_menu_check_class(@sort_direction == :asc)} />
              {dt("Ascending")}
            </.button>
            <.button type="button" class="auix-index-sort-menu-item" name="auix-sort_menu_direction-desc"
                role="menuitemradio" aria-checked={to_string(@sort_direction == :desc)}
                disabled={is_nil(@auix.sort)}
                phx-click={push_sort_menu(@auix, "index-sort-direction", %{direction: "desc"})}>
              <.icon name="hero-check" class={sort_menu_check_class(@sort_direction == :desc)} />
              {dt("Descending")}
            </.button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def sort_header_action(assigns), do: ~H""

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
    assigns =
      assigns
      |> Map.put(:filters_button_class, @filters_button_class)
      |> put_action(:default_clear, dt("Clear Filters"))

    ~H"""
    <.button type="button" class={@filters_button_class} phx-click="filters-clear" phx-target={@auix[:_myself]} name={"auix-filters_clear-#{@auix.module}"} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
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
    assigns =
      assigns
      |> Map.put(:filters_button_class, @filters_button_class)
      |> put_action(:default_submit, dt("Submit"))

    ~H"""
    <.button type="button" class={@filters_button_class} phx-click="filters-submit" phx-target={@auix[:_myself]} name={"auix-filters_submit-#{@auix.module}"} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
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
              selected_in_page={@auix.selection.selected_in_page}
              target={@auix[:_myself]}/>
        </div>
        <div class="auix-pagination-breakpoint-xl" name={"auix-pages_bar-#{@auix.source}-xl"}>
          <.pages_selection pagination={@auix.pagination}
              pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :xl)}
              selected_in_page={@auix.selection.selected_in_page}
              target={@auix[:_myself]}/>
        </div>
        <div class="auix-pagination-breakpoint-lg " name={"auix-pages_bar-#{@auix.source}-lg"}>
          <.pages_selection pagination={@auix.pagination}
              pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :lg)}
              selected_in_page={@auix.selection.selected_in_page}
              target={@auix[:_myself]}/>
        </div>
        <div class="auix-pagination-breakpoint-md" name={"auix-pages_bar-#{@auix.source}-md"}>
          <.pages_selection pagination={@auix.pagination}
              pages_bar_range_offset={@auix.layout_options.pages_bar_range_offset.(nil, :md)}
              selected_in_page={@auix.selection.selected_in_page}
              target={@auix[:_myself]}/>
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
      default_row_show: &show_row_action/1,
      default_row_edit: &edit_row_action/1,
      default_row_delete: &remove_row_action/1
    )
  end

  # Adds action when any item is selected to assigns
  @spec add_default_selected_actions(Socket.t()) :: Socket.t()
  defp add_default_selected_actions(socket) do
    Actions.add_actions(socket, :index_selected_actions,
      default_selected_uncheck_all: &selected_uncheck_all_action/1,
      default_selected_delete_all: &selected_delete_all_action/1,
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
      default_sort: &sort_header_action/1,
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

  # The icon of an index default action: the layout's `action_icons:` entry, else its default.
  @spec resolve_icon(map(), atom()) :: atom() | binary()
  defp resolve_icon(assigns, action_name),
    do: Actions.icon(assigns, assigns.auix.layout_options.action_icons, :index, action_name)

  # Puts the icon, the label and the title of an index default action in the assigns.
  @spec put_action(map(), atom(), term()) :: map()
  defp put_action(assigns, action_name, label) do
    assigns
    |> Map.put(:icon, resolve_icon(assigns, action_name))
    |> Map.put(:label, label)
    |> Map.put(:title, Actions.label_title(label))
  end

  # The class of the sort menu button; highlighted while a field sort is on
  @spec sort_menu_toggle_class(map() | nil) :: binary()
  defp sort_menu_toggle_class(nil), do: "auix-button--iconized"

  defp sort_menu_toggle_class(_sort),
    do: "auix-button--iconized auix-index-sort-menu-toggle--active"

  # The class of a sort menu option's check; an inactive option keeps it invisible
  @spec sort_menu_check_class(boolean()) :: binary() | nil
  defp sort_menu_check_class(true), do: nil
  defp sort_menu_check_class(false), do: "auix-index-sort-menu-check--off"

  # Opens or closes the sort menu, addressed relative to the menu element
  @spec toggle_sort_menu() :: JS.t()
  defp toggle_sort_menu do
    %JS{}
    |> JS.toggle(to: {:inner, "[name='auix-sort_menu_list']"}, display: "flex")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"},
      to: {:inner, "[name='auix-sort_menu_toggle']"}
    )
    |> JS.focus_first(to: {:inner, "[name='auix-sort_menu_list']"})
  end

  # Closes the sort menu, addressed relative to the menu element
  @spec hide_sort_menu() :: JS.t()
  defp hide_sort_menu do
    %JS{}
    |> JS.hide(to: {:inner, "[name='auix-sort_menu_list']"})
    |> JS.set_attribute({"aria-expanded", "false"},
      to: {:inner, "[name='auix-sort_menu_toggle']"}
    )
  end

  # Pushes a sort event from a sort menu option, then runs the menu's own hide
  @spec push_sort_menu(map(), binary(), map()) :: JS.t()
  defp push_sort_menu(auix, event, value) do
    event
    |> JS.push(BasicHelpers.target_opts(auix, value: value))
    |> JS.exec("phx-click-away", to: {:closest, "[name='auix-sort_menu']"})
  end

  # The id comes from the same :row_id function that renders the row.
  @spec row_dom_selector(map()) :: String.t()
  defp row_dom_selector(%{row_info: row_info, layout_options: %{row_id: row_id}}),
    do: uix_id_selector(row_id.(row_info))

  # Extracts primary key value from row_info tuple {index, entity_map}
  @spec row_info_id(map()) :: term() | nil
  defp row_info_id(%{row_info: {_, row_entity}, primary_key: primary_key}) do
    BasicHelpers.primary_key_value(row_entity, primary_key)
  end
end
