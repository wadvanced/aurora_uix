defmodule AuroraUixWeb.Templates.Basic.MarkupGenerator do
  @moduledoc """
  A module for generating basic HEEx templates for different UI component types.

  This module provides the, `generate_view/2` function implementations,
  which creates HEEx template fragments based on the specified type.
  Currently, it supports the following types:

  - `:index`: Generates a template for a list.
  - `:show`: Generates a template for showing an entity.
  - `:form`: Generates a template for a form.

  ## Examples

  ```elixir
  iex> AuroraUixWeb.Templates.Basic.MarkupGenerator.generate_view(:index, %{})
  # => "<h1>Base Template</h1>list"

  iex> AuroraUixWeb.Templates.Basic.MarkupGenerator.generate_view(:index, %{})
  # => "<h1>Base Template</h1>card"

  iex> AuroraUixWeb.Templates.Basic.MarkupGenerator.generate_view(:form, %{})
  # => "<h1>Base Template</h1>form"
  ```
  """

  alias AuroraUixWeb.Template

  @doc """
  Generates a basic HEEx template fragment for the specified type.

  ## Parameters

  - `type` (atom): Specifies the type of template to generate.
    Supported values: `:index`, `:card`, `:form`.

  - `parsed_opts` (map): A map of options (currently unused in this implementation).

  ## Returns

  - `binary`: A HEEx template corresponding to the specified type.

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
