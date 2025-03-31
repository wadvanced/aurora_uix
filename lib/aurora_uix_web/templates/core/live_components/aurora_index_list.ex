defmodule AuroraUixWeb.Templates.Core.LiveComponents.AuroraIndexList do
  @moduledoc """
  Specialized index list component generator extending the core LogicModulesGenerator functionality.

  This module provides implementations for generating advanced list component views and modules
  with customizable table layouts, column configurations, and interaction capabilities.

  ## Component Features
  - Row-based data presentation in a responsive table format
  - Configurable columns with automatic value extraction
  - Interactive row actions and click handlers
  - Streaming data support using Phoenix LiveView streams
  - Integrated new entity button with configurable path

  ## Integration with Core Generator
  Works as an extension to the LogicModulesGenerator, handling the specialized
  `:aurora_index_list` component type with enhanced listing capabilities beyond
  the standard index view.
  """

  alias AuroraUixWeb.Template
  alias AuroraUixWeb.Templates.Core.LogicModulesGenerator

  @doc """
  Generates the HEEx template for an Aurora index list component.

  Creates a fully-formed table layout with support for:
  - Column headers based on provided column configuration
  - Data streaming with Phoenix LiveView
  - Row click handlers for navigation
  - Custom actions per row
  - Consistent styling with hover effects

  ## Parameters
  - `type` (atom): Must be `:aurora_index_list`
  - `parsed_opts` (map): Options for template generation

  ## Returns
  A compiled HEEx template string ready for rendering

  ## Template Expected Assigns
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
  @spec generate_view(atom, map) :: binary
  def generate_view(:aurora_index_list, parsed_opts) do
    Template.build_html(
      parsed_opts,
      ~S"""
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
    )
  end

  def generate_view(:aurora_index_listx, parsed_opts) do
    Template.build_html(
      parsed_opts,
      ~S"""
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
        </div>
      """
    )
  end

  @doc """
  Dynamically generates a specialized index list LiveComponent module.

  Builds a LiveComponent with enhanced listing capabilities beyond the standard index view,
  supporting streaming data, customizable columns, and interactive row actions.

  ## Parameters
  - `modules` (map): Configuration for module generation
  - `web`: Web module for LiveComponent integration
  - Other module dependencies
  - `type` (atom): Must be `:aurora_index_list`
  - `parsed_opts` (map): Detailed generation options
  - All standard options supported by LogicModulesGenerator
  - Component-specific configuration options

  ## Returns
  A quoted Elixir module definition for the AuroraIndexList component

  ## Generated Component Features
  - Flexible column rendering with `field_row_value/2` support
  - Default identity row transformation
  - Support for Phoenix LiveView streams
  - Configurable row click handling and custom actions

  ## Integration Points
  The generated module integrates with the core rendering system through
  the `compile_heex/2` function, providing consistent rendering behavior.
  """
  @spec generate_module(map, atom, map) :: Macro.t()
  def generate_module(modules, :aurora_index_list = type, parsed_opts) do
    aurora_index_list = AuroraUixWeb.LiveComponents.AuroraIndexList

    parsed_opts =
      parsed_opts
      |> LogicModulesGenerator.remove_omitted_fields()
      |> Map.put(:aurora_index_list, aurora_index_list)

    quote do
      defmodule unquote(aurora_index_list) do
        @moduledoc false

        use unquote(modules.web), :live_component

        import AuroraUixWeb.Template, only: [build_html: 2, compile_heex: 2, field_row_value: 2]

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) =
            Map.merge(
              %{
                row_id: nil,
                row_click: nil,
                row_item: &Function.identity/1
              },
              assigns
            )

          compile_heex(unquote(type), unquote(parsed_opts))
        end

        @impl true
        def update(%{columns: _columns, rows: _rows} = assigns, socket) do
          {:ok, assign(socket, assigns)}
        end
      end
    end
  end
end
