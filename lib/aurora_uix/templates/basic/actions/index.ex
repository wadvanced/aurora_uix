defmodule Aurora.Uix.Web.Templates.Basic.Actions.Index do
  @moduledoc """
  Renders default row and header action links (show, edit, delete, new) for entities in index layouts.

  ## Key Features

  - Provides LiveView-compatible components for "show", "edit", "delete", and "new" actions.
  - Generates links using assigns context for entity and module information.
  - Supplies helpers to add all default row and header actions to assigns.
  - Supports dynamic modification of actions via layout tree options.

  ## Key Constraints

  - Assumes assigns contain `:auix` with `:entity_info`, `:link_prefix`, `:source`, and `:module`.
  - Only intended for use in index page layouts.
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  import Phoenix.Component, only: [sigil_H: 2, link: 1]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  @add_actions %{
    add_row_action: :row_actions,
    add_header_action: :header_actions
  }

  @remove_actions %{
    remove_row_action: :row_actions,
    remove_header_action: :header_actions
  }

  @allowed_add_actions Map.keys(@add_actions)
  @allowed_remove_actions Map.keys(@remove_actions)

  @doc """
  Sets up actions for the index layout by adding defaults and applying modifications.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.

  ## Returns
  map() - The updated assigns with actions set.
  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> add_default_actions()
    |> modify_actions()
  end

  @doc """
  Renders the "show" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.

  ## Returns
  Rendered.t() - The rendered "show" action link.

  ## Examples

      iex> assigns = %{auix: %{link_prefix: "admin/", source: "users", entity_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.show_row_action(assigns)
      #=> %Phoenix.LiveView.Rendered{...}
  """
  @spec show_row_action(map()) :: Rendered.t()
  def show_row_action(assigns) do
    ~H"""
      <div class="sr-only">
        <.auix_link navigate={"/#{@auix.link_prefix}#{@auix.source}/#{elem(@auix.entity_info, 1).id}"} name={"show-#{@auix.module}"}>Show</.auix_link>
      </div>
    """
  end

  @doc """
  Renders the "edit" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.

  ## Returns
  Rendered.t() - The rendered "edit" action link.

  ## Examples

      iex> assigns = %{auix: %{link_prefix: "admin/", source: "users", entity_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.edit_row_action(assigns)
      #=> %Phoenix.LiveView.Rendered{...}
  """
  @spec edit_row_action(map()) :: Rendered.t()
  def edit_row_action(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{elem(@auix.entity_info, 1).id}/edit"} name={"edit-#{@auix.module}"}>Edit</.auix_link>
    """
  end

  @doc """
  Renders the "delete" action link for an entity in the index layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.

  ## Returns
  Rendered.t() - The rendered "delete" action link.

  ## Examples

      iex> assigns = %{auix: %{entity_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.remove_row_action(assigns)
      #=> %Phoenix.LiveView.Rendered{...}
  """
  @spec remove_row_action(map()) :: Rendered.t()
  def remove_row_action(assigns) do
    ~H"""
      <.link
            phx-click={JS.push("delete", value: %{id: elem(@auix.entity_info, 1).id}) |> hide("##{elem(@auix.entity_info, 1).id}")}
            name={"delete-#{@auix.module}"}
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

  ## Returns
  Rendered.t() - The rendered "new" action link.

  ## Examples

      iex> assigns = %{auix: %{index_new_link: "/users/new", module: "User", name: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.new_header_action(assigns)
      #=> %Phoenix.LiveView.Rendered{...}
  """
  @spec new_header_action(map()) :: Rendered.t()
  def new_header_action(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} id={"auix-new-#{@auix.module}"}>
      <.button>New {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc """
  Adds the default row and header actions to the assigns for index layouts.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.

  ## Returns
  map() - The updated assigns with default actions added.

  ## Examples

      iex> assigns = %{auix: %{}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Index.add_default_actions(assigns)
      #=> %{auix: %{row_actions: [%Aurora.Uix.Action{...}, ...], header_actions: [%Aurora.Uix.Action{...}]}}
  """
  @spec add_default_actions(map()) :: map()
  def add_default_actions(assigns) do
    assigns
    |> add_default_row_actions()
    |> add_default_header_actions()
  end

  ## PRIVATE

  @spec modify_actions(map()) :: map()
  defp modify_actions(%{auix: %{layout_tree: %{opts: opts}}} = assigns) do
    Enum.reduce(opts, assigns, &modify_action/2)
  end

  @spec modify_action(Action.t(), map()) :: map()
  defp modify_action({action_name, action}, assigns) when action_name in @allowed_add_actions do
    BasicHelpers.add_auix_action(assigns, @add_actions[action_name], Action.new(action))
  end

  defp modify_action({action_name, action}, assigns)
       when action_name in @allowed_remove_actions do
    BasicHelpers.remove_auix_action(assigns, @remove_actions[action_name], action)
  end

  defp modify_action(_option, assigns), do: assigns

  @spec add_default_row_actions(map()) :: map()
  defp add_default_row_actions(assigns) do
    assigns
    |> BasicHelpers.add_auix_action(:row_actions, Action.new(:default_show, &show_row_action/1))
    |> BasicHelpers.add_auix_action(:row_actions, Action.new(:default_edit, &edit_row_action/1))
    |> BasicHelpers.add_auix_action(
      :row_actions,
      Action.new(:default_delete, &remove_row_action/1)
    )
  end

  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(assigns) do
    BasicHelpers.add_auix_action(
      assigns,
      :header_actions,
      Action.new(:default_new, &new_header_action/1)
    )
  end
end
