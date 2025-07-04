defmodule Aurora.Uix.Web.Templates.Basic.Actions.Show do
  @moduledoc """
  Renders default header and footer action links (edit, back) for entities in show layouts.

  ## Key Features

  - Provides LiveView-compatible components for "edit" and "back" actions.
  - Generates links using assigns context for entity and module information.
  - Supplies helpers to add all default header and footer actions to assigns.
  - Supports dynamic modification of actions via layout tree options.

  ## Key Constraints

  - Assumes assigns contain `:auix` with `:entity`, `:link_prefix`, `:source`, `:module`, `:name`, and `:title`.
  - Only intended for use in show page layouts.
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Actions
  alias Phoenix.LiveView.Rendered

  @actions %{
    add_header_action: {:show_header_actions, :add_auix_action},
    insert_header_action: {:show_header_actions, :insert_auix_action},
    replace_header_action: {:show_header_actions, :replace_auix_action},
    remove_header_action: {:show_header_actions, :remove_auix_action},
    add_footer_action: {:show_footer_actions, :add_auix_action},
    insert_footer_action: {:show_footer_actions, :insert_auix_action},
    replace_footer_action: {:show_footer_actions, :replace_auix_action},
    remove_footer_action: {:show_footer_actions, :remove_auix_action}
  }

  @doc """
  Sets up actions for the show layout by adding defaults and applying modifications.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` key with required subkeys.

  ## Returns
  map() - The updated assigns with actions set.

  ## Examples

      iex> assigns = %{auix: %{entity: %{id: 1}, module: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Show.set_actions(assigns)
      %{auix: %{entity: %{id: 1}, module: "User"}, ...}
  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders the "edit" action link for an entity in the show layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:link_prefix`, `:source`, `:entity`, `:module`, and `:name`.

  ## Returns
  Rendered.t() - The rendered "edit" action link.

  ## Examples

      iex> assigns = %{auix: %{link_prefix: "admin/", source: "users", entity: %{id: 1}, module: "User", name: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Show.edit_header_action(assigns)
      %Phoenix.LiveView.Rendered{}
  """
  @spec edit_header_action(map()) :: Rendered.t()
  def edit_header_action(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{@auix.entity.id}/show/edit"} name={"auix-edit-#{@auix.module}"}>
        <.button>Edit {@auix.name}</.button>
      </.auix_link>
    """
  end

  @doc """
  Renders the "back" action link for the footer in the show layout.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and other context.
    - Must include `:auix` with `:title`.

  ## Returns
  Rendered.t() - The rendered "back" action link.

  ## Examples

      iex> assigns = %{auix: %{title: "Users"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Show.back_footer_action(assigns)
      %Phoenix.LiveView.Rendered{}
  """
  @spec back_footer_action(map()) :: Rendered.t()
  def back_footer_action(assigns) do
    ~H"""
      <div name="auix-show-navigate-back">
        <.auix_back>Back to {@auix.title}</.auix_back>
      </div>
    """
  end

  ## PRIVATE

  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(assigns) do
    Actions.add_actions(assigns, :show_header_actions, default_edit: &edit_header_action/1)
  end

  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(assigns) do
    Actions.add_actions(assigns, :show_footer_actions, default_back: &back_footer_action/1)
  end
end
