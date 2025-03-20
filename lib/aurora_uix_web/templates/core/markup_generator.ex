defmodule AuroraUixWeb.Templates.Core.MarkupGenerator do
  @moduledoc """
  Responsible for generating standardized HEEx template fragments for different UI component types.

  ## Template Generation Capabilities
  Supports multiple UI template types with predefined structures:
  - `:index`: Comprehensive listing view with tables, actions, and modals
  - `:show`: Detailed entity view with dynamic sections and editing capabilities
  - `:form`: Interactive form generation with validation and section management

  ## Key Features
  - Dynamic template generation based on configuration
  - Consistent UI component structure
  - Integrated with Phoenix LiveView components
  - Supports interpolation and custom configuration

  ## Template Rendering Strategy
  1. Accept configuration map
  2. Apply interpolation via `Template.build_html/2`
  3. Generate semantically structured HEEx templates
  4. Support extensible rendering through parsed options

  ## Supported Template Types
  - Index Listings: Table-based views with CRUD actions
  - Show Views: Detailed entity representation
  - Form Views: Interactive data entry interfaces

  ### Design Principles
  - Minimal configuration overhead
  - Consistent UI/UX across generated templates
  - Flexible and extensible template generation

  ## Examples

  ```elixir
  iex> AuroraUixWeb.Templates.Core.MarkupGenerator.generate_view(:index, %{})
  # => "<h1>Base Template</h1>list"

  iex> AuroraUixWeb.Templates.Core.MarkupGenerator.generate_view(:index, %{})
  # => "<h1>Base Template</h1>card"

  iex> AuroraUixWeb.Templates.Core.MarkupGenerator.generate_view(:form, %{})
  # => "<h1>Base Template</h1>form"
  ```

  Provides a standardized approach to generating complex UI templates
  with minimal manual intervention.
  """

  alias AuroraUixWeb.Template

  @doc """
  Generates a HEEx template fragment for the specified UI component type.

  ## Parameters

  - `type` (atom): Specifies the template type (:index, :show, :form)
  - `parsed_opts` (map): Configuration options for template generation

  ## Returns
  A binary representing the HEEx template fragment

  ## Examples

  ```elixir
  generate(:index, %{})
  # => "<h1>Base Template</h1>list"

  generate(:show, %{})
  # => "<h1>Base Template</h1>card"

  generate(:form, %{})
  # => "<h1>Base Template</h1>form"
  ```
  """
  @spec generate_view(atom, map) :: binary
  def generate_view(:index, parsed_opts) do
    Template.build_html(
      parsed_opts,
      ~S"""
        <.header>
          Listing [[title]]
          <:actions>
            <.link patch={~p"/[[link]]/new"} id="auix-new-[[source]]">
              <.button>New [[title]]</.button>
            </.link>
          </:actions>
        </.header>

        <.table
            id={"auix-list-[[link]]"}
            rows={get_in(assigns, @_uix.rows)}
            row_click={fn {_id, row} -> JS.navigate(~p"/[[link]]/#{row}") end}
        >
          [[index_columns]]
          <:action :let={{id, [[module]]}}>
            <div class="sr-only">
              <.link navigate={~p"/[[link]]/#{[[module]]}"} id={"auix-show-#{id}"}>Show</.link>
            </div>
            <.link patch={~p"/[[link]]/#{[[module]]}/edit"} id={"auix-edit-#{id}"}>Edit</.link>
          </:action>
          <:action :let={{id, _[[module]]}}>
            <.link
              phx-click={JS.push("delete", value: %{id: id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
              id={"auix-delete-#{id}"}
            >
              Delete
            </.link>
          </:action>
        </.table>

        <.modal :if={@live_action in [:new, :edit]} id="auix-[[module]]-modal" show on_cancel={JS.patch(~p"/[[link]]")}>
          <.live_component
            module={[[module_name]]FormComponent}
            id={@_entity.id || :new}
            title={@page_title}
            action={@live_action}
            entity={@_entity}
            patch={~p"/[[link]]"}
          />
        </.modal>
      """
    )
  end

  def generate_view(:show, parsed_opts) do
    Template.build_html(
      parsed_opts,
      ~S"""
      <.header>
        [[name]] {@_entity.id}
        <:subtitle>{@subtitle}</:subtitle>
        <:actions>
          <.link patch={~p"/[[link]]/#{@_entity}/show/edit"} phx-click={JS.push_focus()} id="auix-edit-[[source]]">
            <.button>Edit [[name]]</.button>
          </.link>
        </:actions>
      </.header>

      [[show_fields]]

      <.back navigate={~p"/[[link]]"}>Back to [[title]]</.back>

      <.modal :if={@live_action == :edit}
        id="auix-[[module]]-modal"
        show
        on_cancel={JS.patch(~p"/[[link]]/#{@_entity}")}
      >
        <.live_component
          module={[[module_name]]FormComponent}
          id={@_entity.id}
          title={@page_title}
          action={@live_action}
          entity={@_entity}
          patch={~p"/[[link]]/#{@_entity}"}
        />
      </.modal>
      """
    )
  end

  def generate_view(:form, parsed_opts) do
    Template.build_html(
      parsed_opts,
      ~S"""
        <div>
          <.header>
            {@title}
            <:subtitle>Use this form to manage [[module]] records in your database.</:subtitle>
          </.header>

          <.simple_form
            for={@form}
            id="auix-[[module]]-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
          >
            [[form_fields]]
            <:actions>
              <.button phx-disable-with="Saving..." id="auix-save-[[source]]">Save [[name]]</.button>
            </:actions>
          </.simple_form>
        </div>
      """
    )
  end

  def generate_view(:card, _parsed_opts) do
    ~S"""
      <h1>Base Template</h1>
    card
    """
  end
end
