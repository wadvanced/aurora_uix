defmodule Aurora.Uix.Templates.Basic.Actions.ShowComponent do
  @moduledoc """
  Renders default header and footer action links (edit, back) for entities in show layouts.

  ## Key Features

  - Provides LiveView-compatible components for "edit" and "back" actions.
  - Generates links using assigns context for entity and module information.
  - Supplies helpers to add all default header and footer actions to assigns.
  - Supports dynamic modification of actions via layout tree options.
  - The edit and back actions take their icons from the layout's `action_icons:` option; below the `sm` breakpoint they show only their icons.

  ## Key Constraints

  - Assumes assigns contain `:auix` with `:entity`, `:source`, `:module`, `:name`, and `:title`.
  - Only intended for use in show page layouts.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver
  import Aurora.Uix.Templates.Basic.RoutingComponents

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  @actions Action.available_actions(:show)

  @doc """
  Sets up actions for the show layout by adding defaults and applying modifications.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket containing the layout tree and context.
    - Must include `:auix` with `:layout_tree` and action group maps.

  ## Returns
  Socket.t() - The updated socket with default actions configured and modifications applied.
  """
  @spec set_actions(Socket.t()) :: Socket.t()
  def set_actions(socket) do
    socket
    |> Actions.remove_all_actions(@actions)
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders the "edit" action link for an entity in the show layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:source`, `:entity`, `:module`, and `:name`.

  ## Returns
  Rendered.t() - The rendered "edit" action link.

  """
  @spec edit_header_action(map()) :: Rendered.t()
  def edit_header_action(%{auix: %{notify: _notify}} = assigns) do
    assigns =
      put_action(assigns, :default_edit, dt(assigns.auix.layout_options.edit_action_label))

    ~H"""
      <.auix_link phx-click="auix_open" phx-value-action="edit" phx-value-id={BasicHelpers.primary_key_value(@auix.entity, @auix.primary_key)} phx-target={@auix._myself} name={"auix-edit-#{@auix.module}"} title={@title} aria-label={@title}>
        <.button><.action_content icon={@icon} label={@label} /></.button>
      </.auix_link>
    """
  end

  def edit_header_action(assigns) do
    assigns =
      put_action(assigns, :default_edit, dt(assigns.auix.layout_options.edit_action_label))

    ~H"""
      <.auix_link patch={"/#{@auix.uri_path}/#{BasicHelpers.primary_key_value(@auix.entity, @auix.primary_key)}/show-edit"} name={"auix-edit-#{@auix.module}"} title={@title} aria-label={@title}>
        <.button><.action_content icon={@icon} label={@label} /></.button>
      </.auix_link>
    """
  end

  @doc """
  Renders the "back" action link for the footer in the show layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing:
    * `:auix` (map()) - Required context with `:title` for display text.

  ## Returns
  Rendered.t() - The rendered "back" action link.
  """
  @spec back_footer_action(map()) :: Rendered.t()
  def back_footer_action(%{auix: %{notify: _notify}} = assigns) do
    assigns =
      put_action(assigns, :default_back, dt(assigns.auix.layout_options.back_action_label))

    ~H"""
      <div name="auix-show-navigate-back">
        <.auix_back phx-target={@auix._myself} icon={@icon} title={@title} aria-label={@title}><span class="auix-action-label">{@label}</span></.auix_back>
      </div>
    """
  end

  def back_footer_action(assigns) do
    assigns =
      put_action(assigns, :default_back, dt(assigns.auix.layout_options.back_action_label))

    ~H"""
      <div name="auix-show-navigate-back">
        <.auix_back icon={@icon} title={@title} aria-label={@title}><span class="auix-action-label">{@label}</span></.auix_back>
      </div>
    """
  end

  ## PRIVATE

  # Puts the icon, the label and the title of a show default action in the assigns.
  @spec put_action(map(), atom(), term()) :: map()
  defp put_action(assigns, action_name, label) do
    assigns
    |> Map.put(
      :icon,
      Actions.icon(assigns, assigns.auix.layout_options.action_icons, :show, action_name)
    )
    |> Map.put(:label, label)
    |> Map.put(:title, Actions.label_title(label))
  end

  @spec add_default_header_actions(Socket.t()) :: Socket.t()
  defp add_default_header_actions(socket) do
    Actions.add_actions(socket, :show_header_actions, default_edit: &edit_header_action/1)
  end

  @spec add_default_footer_actions(Socket.t()) :: Socket.t()
  defp add_default_footer_actions(socket) do
    Actions.add_actions(socket, :show_footer_actions, default_back: &back_footer_action/1)
  end
end
