defmodule Aurora.Uix.Templates.Basic.Components do
  @moduledoc """
  Provides the core set of reusable UI components for Aurora UIX, including modals, tables, forms, flash messages, and more.

  Most functions in this module are equivalent to those in the original Phoenix Framework's `core_components.ex`,
  with some stylistic changes for Aurora UIX, but retaining 100% compatibility with the Phoenix API and usage patterns.

  ## Key Features
  - Provides modal, table, form, flash, and input components for LiveView UIs.
  - All components are built with Tailwind CSS utility classes for easy customization.
    See the [Tailwind CSS documentation](https://tailwindcss.com).
  - Includes icon support via [Heroicons](https://heroicons.com). See `icon/1` for usage.
  - Designed for extensibility and override in your own application.
  - Well-documented with doc strings and declarative assigns for each component.
  - All components are compatible with Phoenix LiveView and Phoenix.Component.

  > #### Note {: .info}
  > This module may be injected as the core components module depending on the Aurora UIX template configuration.
  > Dynamic selection and import of the core components module is handled via `use Aurora.Uix.CoreComponentsImporter`,
  > which will import either this module or a custom one as configured in your application or template.

  """
  use Aurora.Uix.Gettext
  use Aurora.Uix.CoreComponentsImporter
  use Phoenix.Component

  alias Aurora.Uix.Templates.Basic.Components.FilteringComponents
  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr(:for, :any, required: true, doc: "the data structure for the form")
  attr(:as, :any, default: nil, doc: "the server side parameter to collect all input under")

  attr(:rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  slot(:inner_block, required: true)
  slot(:actions, doc: "the slot for form actions, such as a submit button")

  @spec auix_simple_form(map) :: Rendered.t()
  def auix_simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-0 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc ~S"""
  Renders a table or card with generic styling.

  ## Examples

      <.auix_items id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.auix_items>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_click_navigate, :any,
    default: nil,
    doc: "the function for handling phx-click on each row using auix_route_forward"
  )

  attr(:row_click_patch, :any,
    default: nil,
    doc: "the function for handling phx-click on each row using auix_route_forward"
  )

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  attr(:auix, :map, default: %{})

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:filter_action,
    doc: "the slot for showing filter actions in the last table heading column"
  )

  slot(:action, doc: "the slot for showing user actions in the last table column")

  @spec auix_items(map) :: Rendered.t()
  def auix_items(assigns) do
    ~H"""
    <div class="hidden md:block">
      {auix_items_table(assigns)}
    </div>

    <div class="md:hidden">
      {auix_items_card(assigns)}
    </div>

    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.auix_items_table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.auix_items>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_click_navigate, :any,
    default: nil,
    doc: "the function for handling phx-click on each row using auix_route_forward"
  )

  attr(:row_click_patch, :any,
    default: nil,
    doc: "the function for handling phx-click on each row using auix_route_forward"
  )

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  attr(:auix, :map, default: %{})

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:filter_action,
    doc: "the slot for showing filter actions in the last table heading column"
  )

  slot(:action, doc: "the slot for showing user actions in the last table column")

  @spec auix_items_table(map()) :: Rendered.t()
  def auix_items_table(assigns) do
    ~H"""
    <div class="overflow-y-scroll px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-0 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr :if={Map.get(@auix, :filters_enabled?)} >
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal h-full align-bottom">
              <FilteringComponents.filter_field
                  field={col.field}
                  filter={get_in(@auix, [:index_layout_form, col.field.key, Access.key!(:value)])}
                  auix={@auix}/>
            </th>
            <th :if={@filter_action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @filter_action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
                  {render_slot(action)}
                </span>
              </div>
            </th>
          </tr>
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal h-full align-bottom">
              <div class="font-bold inline-flex">
                <div name="auix-column-label">
                  <.table_column_label auix={@auix} label={col.label} />
                </div>
              </div>
            </th>
            <th :if={Map.get(@auix, :filters) != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <%= if Map.get(@auix, :filters_enabled?) do %>
                  <a href="#" phx-click="filter-toggle" name="auix-filter_toggle_close" class="-space-x-2">
                    <.icon name="hero-funnel" class=""/>
                    <.icon name="hero-x-mark" class="align-super size-3"/>
                  </a>
                <% else %>
                  <a href="#" phx-click="filter-toggle" name="auix-filter_toggle_open" class="hero-funnel" />
                <% end %>
              </div>
            </th>
          </tr>
        </thead>

        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          phx-viewport-top={@auix.layout_options.pagination_disabled? && "pagination_previous"}
          phx-viewport-bottom={@auix.layout_options.pagination_disabled? && "pagination_next"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700 h-svh"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={evaluate_phx_click(assigns, row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc ~S"""
  Renders a list of cards with generic styling.

  ## Examples

      <.auix_items_card id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.auix_items>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_click_navigate, :any,
    default: nil,
    doc: "the function for handling phx-click on each row using auix_route_forward"
  )

  attr(:row_click_patch, :any,
    default: nil,
    doc: "the function for handling phx-click on each row using auix_route_forward"
  )

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  attr(:auix, :map, default: %{})

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:filter_action,
    doc: "the slot for showing filter actions in the last table heading column"
  )

  slot(:action, doc: "the slot for showing user actions in the last table column")

  @spec auix_items_card(map()) :: Rendered.t()
  def auix_items_card(assigns) do
    ~H"""
    <div class="space-y-4">
      <div id={"#{@id}-mobile"}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          phx-viewport-top={@auix.layout_options.pagination_disabled? && "pagination_previous"}
          phx-viewport-bottom={@auix.layout_options.pagination_disabled? && "pagination_next"}
          class="overflow-y-scroll block h-[calc(50svh)]"
        >

        <div :for={row <- @rows} id={@row_id && "#{@row_id.(row)}-mobile"} class="bg-white rounded-lg shadow p-4 border border-gray-200">
          <div :for={col <- @col}>
            <div class="font-bold inline-flex">
              <div :if={!is_function(col.label, 1)}  name="auix-column-label">
                <.table_column_label auix={@auix} label={col.label} />
                <span>: </span>
              </div>
              <div name="auix-column-value">
                {render_slot(col, @row_item.(row))}
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
    """
  end

  attr(:pagination, :map, required: true)
  attr(:pages_bar_range_offset, :integer, required: true)
  attr(:selected_in_page, :map, default: %{})
  @spec pages_selection(map()) :: map()
  def pages_selection(assigns) do
    assigns =
      assigns
      |> page_calculate_indexes()
      |> maybe_augment_range()

    ~H"""
      <div class="flex flex-row gap-3 justify-center overflow-x-clip">
        <a :if={@pagination.page > 1} name="auix-pages_bar_page-previous" phx-click="pagination_to_page" phx-value-page={@pages_start_index}><.icon name="hero-chevron-left" /></a>
        <%= if @pages_start_index > 1 do %>
          <a name="auix-pages_bar_page-first" class="flex flex-col gap-1" phx-click="pagination_to_page" phx-value-page={1}>
            <span>1</span>
            <.selected_count selected_in_page={@selected_in_page} page={1} />
          </a>
          <a name="auix-pages_bar_page-left"class="flex flex-col gap-1" phx-click="pagination_to_page" phx-value-page={@pages_left_index}>
            <span>...</span>
            <.selected_count selected_in_page={@selected_in_page} from={1} to={@pages_start_index} />
          </a>
        <% end %>
        <div :for={page_index <- @pages_start_index..@pages_end_index}>
          <%= if page_index == @pagination.page do %>
            <div class="mt-0 mb-0 p-0 flex flex-col gap-1">
              <span name="auix-pages_bar_page-current" class="border border-zinc-400 rounded-full py-0 px-1">
                {page_index}
              </span>
              <.selected_count selected_in_page={@selected_in_page} page={page_index} />
            </div>
          <% else %>
            <a name={"auix-pages_bar_page-#{page_index}"} class="flex flex-col gap-1" phx-click="pagination_to_page" phx-value-page={page_index}>
              <span>{page_index}</span>
              <.selected_count selected_in_page={@selected_in_page} page={page_index} />
            </a>
          <% end %>
        </div>

        <%= if @pages_end_index < @pagination.pages_count do %>
          <a name="auix-pages_bar_page-right"class="flex flex-col gap-1" phx-click="pagination_to_page" phx-value-page={@pages_right_index}>
            <span>...</span>
            <.selected_count selected_in_page={@selected_in_page} from={@pages_end_index} to={@pagination.pages_count} />
          </a>
          <a name="auix-pages_bar_page-last" class="flex flex-col gap-1" phx-click="pagination_to_page" phx-value-page={@pagination.pages_count}>
            <span>{@pagination.pages_count}</span>
            <.selected_count selected_in_page={@selected_in_page} page={@pagination.pages_count} />
          </a>
        <% end %>
        <a name="auix-pages_bar_page-next" :if={@pagination.page < @pagination.pages_count} phx-click="pagination_to_page" phx-value-page={@pages_end_index}><.icon name="hero-chevron-right"/></a>
      </div>
    """
  end

  ## PRIVATE
  attr(:label, :any, required: true)
  attr(:auix, :map)
  @spec table_column_label(map()) :: Rendered.t()
  defp table_column_label(%{label: label} = assigns) when is_function(label, 1) do
    ~H"""
    {@label.(assigns)}
    """
  end

  defp table_column_label(assigns) do
    ~H"""
    {@label}
    """
  end

  attr(:selected_in_page, :map, default: %{})
  attr(:page, :integer)
  attr(:from, :integer)
  attr(:to, :integer)
  @spec selected_count(map()) :: Rendered.t()
  defp selected_count(%{selected_in_page: selected_in_page, from: from, to: to} = assigns) do
    assigns =
      selected_in_page
      |> Enum.reject(fn {page, _items} -> page <= from or page >= to end)
      |> Enum.map(fn {_page, items} -> MapSet.size(items) end)
      |> Enum.sum()
      |> then(&Map.put(assigns, :count, &1))

    ~H"""
    <%= if @count > 0 do %>
      <span class="text-xs text-center align-sub border">
        {@count}
      </span>
    <% end %>
    """
  end

  defp selected_count(%{selected_in_page: selected_in_page, page: page}) do
    assigns = %{items: Map.get(selected_in_page, page, MapSet.new())}

    ~H"""
    <%= if MapSet.size(@items) > 0 do %>
      <span class="text-xs text-center align-sub border">
        {MapSet.size(@items)}
      </span>
    <% end %>

    """
  end

  @spec evaluate_phx_click(map(), function() | nil) :: any()
  defp evaluate_phx_click(%{row_click: row_click}, row) when is_function(row_click) do
    row_click.(row)
  end

  defp evaluate_phx_click(%{row_click_navigate: row_click_navigate}, _row)
       when is_function(row_click_navigate) do
    "auix_route_forward"
  end

  defp evaluate_phx_click(%{row_click_patch: row_click_patch}, _row)
       when is_function(row_click_patch) do
    "auix_route_forward"
  end

  defp evaluate_phx_click(_assigns, _row), do: nil

  @spec page_calculate_indexes(map()) :: map()
  defp page_calculate_indexes(
         %{pagination: %{page: page}, pages_bar_range_offset: offset} = assigns
       ) do
    assigns
    |> Map.put(:pages_start_index, page - offset)
    |> Map.put(:pages_end_index, page + offset)
    |> page_fix_indexes_bounds()
  end

  @spec maybe_augment_range(map()) :: map()
  defp maybe_augment_range(
         %{
           pagination: %{page: page},
           pages_start_index: start_index,
           pages_end_index: end_index,
           pages_bar_range_offset: offset
         } = assigns
       ) do
    add_to_end_index = offset - (page - start_index)
    subtract_from_start_index = offset - (end_index - page)

    assigns
    |> Map.put(:pages_start_index, start_index - subtract_from_start_index)
    |> Map.put(:pages_end_index, end_index + add_to_end_index)
    |> page_fix_indexes_bounds()
  end

  @spec page_fix_indexes_bounds(map()) :: map()
  defp page_fix_indexes_bounds(
         %{
           pagination: %{pages_count: pages_count},
           pages_start_index: start_index,
           pages_end_index: end_index
         } = assigns
       ) do
    start_index = if start_index < 1, do: 1, else: start_index
    end_index = if end_index > pages_count, do: pages_count, else: end_index

    left_index = Integer.floor_div(1 + start_index, 2)
    right_index = Integer.floor_div(end_index + pages_count, 2)

    assigns
    |> Map.put(:pages_start_index, start_index)
    |> Map.put(:pages_end_index, end_index)
    |> Map.put(:pages_left_index, left_index)
    |> Map.put(:pages_right_index, right_index)
  end
end
