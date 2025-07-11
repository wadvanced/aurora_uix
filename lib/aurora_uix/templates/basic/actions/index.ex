defmodule Aurora.Uix.Web.Templates.Basic.Actions.Index do
  @moduledoc """
  Renders default row and header action links (show, edit, delete, new) for entities in index layouts.

  ## Key Features

  - Provides LiveView-compatible components for "show", "edit", "delete", and "new" actions.
  - Generates links using assigns context for entity and module information.
  - Supplies helpers to add all default row and header actions to assigns.
  - Supports dynamic modification of actions via layout tree options.

  ## Key Constraints

  - Assumes assigns contain `:auix` with `:row_info`, `:link_prefix`, `:source`, and `:module`.
  - Only intended for use in index page layouts.
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  import Phoenix.Component, only: [sigil_H: 2, link: 1]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Web.Templates.Basic.Actions
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  @actions Action.available_actions(:index)

  @doc """
  Sets up actions for the index layout by adding defaults and applying modifications.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` key with required subkeys.

  ## Returns
  map() - The updated assigns with actions set.

  ## Examples

      iex> assigns = %{auix: %{row_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.set_actions(assigns)
      %{auix: %{row_info: {:user, %{id: 1}}, module: "User"}, ...}
  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> add_default_row_actions()
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders the "show" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:link_prefix`, `:source`, `:row_info`, and `:module`.

  ## Returns
  Rendered.t() - The rendered "show" action link.

  ## Examples

      iex> assigns = %{auix: %{link_prefix: "admin/", source: "users", row_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.show_row_action(assigns)
      %Phoenix.LiveView.Rendered{}
  """
  @spec show_row_action(map()) :: Rendered.t()
  def show_row_action(assigns) do
    ~H"""
      <div class="sr-only">
        <.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{row_info_id(@auix)}"} name={"auix-show-#{@auix.module}"}>Show</.auix_link>
      </div>
    """
  end

  @doc """
  Renders the "edit" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:link_prefix`, `:source`, `:row_info`, and `:module`.

  ## Returns
  Rendered.t() - The rendered "edit" action link.

  ## Examples

      iex> assigns = %{auix: %{link_prefix: "admin/", source: "users", row_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.edit_row_action(assigns)
      %Phoenix.LiveView.Rendered{}
  """
  @spec edit_row_action(map()) :: Rendered.t()
  def edit_row_action(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{row_info_id(@auix)}/edit"} name={"auix-edit-#{@auix.module}"}>Edit</.auix_link>
    """
  end

  @doc """
  Renders the "delete" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:row_info` and `:module`.

  ## Returns
  Rendered.t() - The rendered "delete" action link.

  ## Examples

      iex> assigns = %{auix: %{row_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.remove_row_action(assigns)
      %Phoenix.LiveView.Rendered{}

  ## Edge Cases

  - If `@auix.row_info` is missing or malformed, the link may not render correctly.
  """
  @spec remove_row_action(map()) :: Rendered.t()
  def remove_row_action(assigns) do
    ~H"""
      <.link
            phx-click={JS.push("delete", value: %{id: row_info_id(@auix)}) |> hide("##{row_info_id(@auix)}")}
            name={"auix-delete-#{@auix.module}"}
            data-confirm="Are you sure?"
          >
            Delete
      </.link>
    """
  end

  @doc """
  Renders the "new" action link for the header in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:index_new_link`, `:module`, and `:name`.

  ## Returns
  Rendered.t() - The rendered "new" action link.

  ## Examples

      iex> assigns = %{auix: %{index_new_link: "/users/new", module: "User", name: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.new_header_action(assigns)
      %Phoenix.LiveView.Rendered{}
  """
  @spec new_header_action(map()) :: Rendered.t()
  def new_header_action(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}"}>
      <.button>New {@auix.name}</.button>
    </.auix_link>
    """
  end

  ## PRIVATE

  @spec add_default_row_actions(map()) :: map()
  defp add_default_row_actions(assigns) do
    Actions.add_actions(assigns, :index_row_actions,
      default_row_show: &show_row_action/1,
      default_row_edit: &edit_row_action/1,
      default_row_delete: &remove_row_action/1
    )
  end

  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(%{auix: %{index_footer_actions: _}} = assigns), do: assigns

  # Adds an empty form_header_actions map if not present.
  defp add_default_footer_actions(assigns),
    do: put_in(assigns, [:auix, :index_footer_actions], [])

  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(assigns) do
    Actions.add_actions(assigns, :index_header_actions, default_new: &new_header_action/1)
  end

  @spec row_info_id(map()) :: term() | nil
  defp row_info_id(%{row_info: {_, row_entity}, primary_key: primary_key}) do
    BasicHelpers.primary_key_value(row_entity, primary_key)
  end
end
