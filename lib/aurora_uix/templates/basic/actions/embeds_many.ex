defmodule Aurora.Uix.Templates.Basic.Actions.EmbedsMany do
  @moduledoc """
  Provides helpers for managing one-to-many association actions in Aurora UIX index layouts.

  This module sets up and modifies actions for header, footer, and row elements in form layouts
  that represent embeds-many associations. It ensures that default actions are present and
  allows for further customization via the `Actions.modify_actions/2` function.

  ## Key Features

    - Adds default actions for headers, footers, and rows in embeds-many association tables.
    - Integrates with the Aurora UIX action modification pipeline.
    - Provides helpers for rendering "new", "show", "edit", and "delete" child links in form layouts.

  ## Key Constraints

    - Expects the `assigns` map to include an `:auix` key with required subkeys for actions.
    - Designed for use within Phoenix LiveView templates and Aurora UIX layouts.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext

  import Phoenix.Component, only: [sigil_H: 2, live_component: 1]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions
  alias Aurora.Uix.Templates.Basic.ConfirmButton

  alias Phoenix.LiveView.Rendered

  @actions Action.available_actions(:embeds_many)

  @doc """
  Sets up actions for the one to many field rendering layout by adding defaults and applying modifications.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and context.
    - Must include `:auix` key with required subkeys.

  ## Returns
  map() - The updated assigns with actions set.

  ## Examples

      iex> assigns = %{auix: %{row_info: {:user, %{id: 1}}, module: "User"}}
      iex> Aurora.Uix.Templates.Basic.Actions.OneToMany.set_actions(assigns)
      %{auix: %{row_info: {:user, %{id: 1}}, module: "User", one_to_many_row_actions: %{}, one_to_many_header_actions: %{}, one_to_many_footer_actions: %{}}, ...}
  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> Actions.remove_all_actions(@actions)
    |> add_default_footer_actions()
    |> add_default_new_entry_actions()
    |> add_default_existing_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders a button for enabling the addition of a new entry for a embeds-many association form.

  ## Parameters
  - `assigns` (map()) - Assigns map containing association and entity context.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered button component.

  """
  @spec enable_add_entry(map()) :: Rendered.t()
  def enable_add_entry(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
      <.button type="button" phx-click="toggle-add-embeds" phx-target={@myself}>
        <.icon name="hero-plus" />
        <span>{gettext("Add new entry")}</span>
      </.button>
    """
  end

  def enable_add_entry(assigns), do: ~H""

  @doc """
  Renders a button for adding / save a new entry in a embeds-many association form.

  ## Parameters
  - `assigns` (map()) - Assigns map containing association and entity context.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered button component.

  """
  @spec add_entry(map()) :: Rendered.t()
  def add_entry(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
      <.button type="submit" phx-target={@myself}>
        <.icon name="hero-plus" />
        <span>{gettext("Add")}</span>
      </.button>
    """
  end

  def add_entry(assigns), do: ~H""

  @doc """
  Renders a button for removing a existing entry in a embeds-many association form.

  ## Parameters
  - `assigns` (map()) - Assigns map containing association and entity context.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered button component.

  """
  @spec remove_entry(map()) :: Rendered.t()
  def remove_entry(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
      <.live_component 
        id={"#{@entry_id}-remove-button"}
        module={ConfirmButton}
        class="auix-button--danger"
        value={%{entry_id: @entry_id}}
        event="remove-entry"
        target={@myself}
      >
        <:content>
          <.icon name="hero-minus-circle" />
          <span>{gettext("Remove")}</span>
        </:content>

        <:confirm_message>
          <div class="auix-embeds-many--remove-entry-action">
            <span>{@entry_id}</span>
            <span>{gettext("Do you want to remove this entry?")}</span>
          </div>
        </:confirm_message>
        
      </.live_component>
    """
  end

  def remove_entry(assigns), do: ~H""

  ## PRIVATE
  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(assigns) do
    Actions.add_actions(assigns, :embeds_many_footer_actions,
      default_enable_add_entry: &enable_add_entry/1
    )
  end

  @spec add_default_new_entry_actions(map()) :: map()
  defp add_default_new_entry_actions(assigns) do
    Actions.add_actions(assigns, :embeds_many_new_entry_actions, default_add_entry: &add_entry/1)
  end

  @spec add_default_existing_actions(map()) :: map()
  defp add_default_existing_actions(assigns) do
    Actions.add_actions(assigns, :embeds_many_existing_actions,
      default_remove_entry: &remove_entry/1
    )
  end
end
