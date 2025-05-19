defmodule Aurora.Uix.Web.Templates.Basic.Components.Live.AuroraIndexList do
  @moduledoc """
  A specialized index list LiveComponent for displaying tabular data.

  ## Component Features
  - Row-based data presentation in a responsive table format
  - Configurable columns with automatic value extraction
  - Interactive row actions and click handlers
  - Streaming data support using Phoenix LiveView streams
  - Integrated new entity button with configurable path

  ## Expected Assigns
  - `id` (string): Unique identifier for the component
  - `title` (string): Title text for the list header
  - `module_name` (string): Text used for the name of the module
  - `new_link` (string|nil): Path for "New" button action, nil to hide
  - `columns` (list): List of column definitions with `label` and other properties
  - `rows` (list|LiveStream): Data rows for the table
  - `row_id` (function|nil): Function to extract ID from row
  - `row_click` (function|nil): Function to handle row clicks
  - `row_item` (function): Function to transform row for action slots
  - `action` (list): Slots for row actions
  """

  use Phoenix.LiveComponent
  use Aurora.Uix.Web.CoreComponentsImporter

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:row_id, fn -> nil end)
      |> assign_new(:row_click, fn -> nil end)
      |> assign_new(:row_item, fn -> &Function.identity/1 end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"auix-index-list-#{@id}"}>
      <.header>
        {@title}
        <:actions>
          <.link :if={@new_link} patch={@new_link} id={"auix-new-#{@id}"}>
            <.button>New {@module_name}</.button>
          </.link>
        </:actions>
      </.header>

      <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
        <table class="w-[40rem] mt-11 sm:w-full">
          <thead class="text-sm text-left leading-6 text-zinc-500">
            <tr>
              <th :for={col <- @columns} class="p-0 pb-4 pr-6 font-normal">{col.label}</th>
            </tr>
          </thead>
          <tbody
            id={@id}
            phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
            class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
          >
            <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
              <td
                :for={{col, i} <- Enum.with_index(@columns)}
                phx-click={@row_click && @row_click.(row)}
                class={["relative p-0", @row_click && "hover:cursor-pointer"]}
              >
                <div class="block py-4 pr-6">
                  <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                  <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                    {field_row_value(row, col)}
                  </span>
                </div>
              </td>
              <td :if={Map.has_key?(assigns, :action) && @action != []} class="relative w-14 p-0">
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
    </div>
    """
  end

  @spec field_row_value(tuple | map, map) :: any
  defp field_row_value({_row_id, row}, %{field: field}) when is_atom(field) do
    Map.get(row, field)
  end

  defp field_row_value({_row_id, row}, %{field: field}) when is_function(field) do
    field.(row)
  end

  defp field_row_value(row, %{field: field}) when is_atom(field) do
    Map.get(row, field)
  end

  defp field_row_value(row, %{field: field}) when is_function(field) do
    field.(row)
  end
end
