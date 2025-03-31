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
  alias AuroraUixWeb.Templates.Core.LiveComponents.AuroraIndexList

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
    parsed_opts = Map.update(parsed_opts, :index_columns, [], &:erlang.binary_to_term/1)

    Template.build_html(
      parsed_opts,
      ~S"""
        <.live_component
          module={AuroraUixWeb.LiveComponents.AuroraIndexList}
          id="[[source]]"
          title="Listing [[title]]"
          module_name="[[title]]"
          rows={get_in(assigns, @_auix.rows)}
          columns={[[index_columns]]}
          row_id={fn {id, _auix_entity} -> id end}
          new_link={@_auix[:index_new_link]}
          row_click={@_auix[:index_row_click]}
          >
          <:action :let={{id, entity}}>
            <div class="sr-only">
              <.link navigate={index_show_entity_link(@_auix, entity)} id={"auix-show-#{id}"}>Show</.link>
            </div>
            <.link patch={~p"/[[link_prefix]][[source]]/#{entity}/edit"} id={"auix-edit-#{id}"}>Edit</.link>
          </:action>
          <:action :let={{id, entity}}>
            <.link
              phx-click={JS.push("delete", value: %{id: entity.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
              id={"auix-delete-#{id}"}
            >
              Delete
            </.link>
          </:action>
        </.live_component>

        <div class="hidden">
          <a href={~p"/[[link_prefix]][[source]]"}>-</a>
        </div>
        <.modal :if={@live_action in [:new, :edit]} id="auix-[[module]]-modal" show on_cancel={JS.patch("/[[link_prefix]]#{@_auix_source}")}>
          <div>
            <.live_component
              module={[[module_name]]FormComponent}
              id={@auix_entity.id || :new}
              title={@page_title}
              source={@_auix_source}
              action={@live_action}
              auix_entity={@auix_entity}
              patch={"/[[link_prefix]]#{@_auix_source}"}
            />
          </div>
        </.modal>
      """
    )
  end

  def generate_view(:show, parsed_opts) do
    Template.build_html(
      parsed_opts,
      ~S"""
      <.header>
        [[name]] {@auix_entity.id}
        <:subtitle>{@subtitle}</:subtitle>
        <:actions>
          <.link patch={"/[[link_prefix]][[source]]/#{@auix_entity.id}/show/edit#{@_auix_source_link}"} phx-click={JS.push_focus()} id="auix-edit-[[source]]">
            <.button>Edit [[name]]</.button>
          </.link>
        </:actions>
      </.header>

      [[show_fields]]

      <.back navigate={"/[[link_prefix]]#{@_auix_source}"}>Back to [[title]]</.back>

      <.modal :if={@live_action == :edit}
        id="auix-[[module]]-modal"
        show
        on_cancel={JS.patch("/[[link_prefix]]#{@_auix_source}/#{@auix_entity.id}")}
      >
        <.live_component
          module={[[module_name]]FormComponent}
          id={@auix_entity.id}
          title={@page_title}
          action={@live_action}
          source={@_auix_source}
          auix_entity={@auix_entity}
          patch={"/[[link_prefix]]#{@_auix_source}/#{@auix_entity.id}"}
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

          <.flash kind={:error} flash={@flash} title="Error!" />
          HELLO WORLD!
          {@source}
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

  def generate_view(:aurora_index_list = type, parsed_opts) do
    AuroraIndexList.generate_view(type, parsed_opts)
  end
end
