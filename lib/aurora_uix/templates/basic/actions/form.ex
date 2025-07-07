defmodule Aurora.Uix.Web.Templates.Basic.Actions.Form do
  @moduledoc """
  Provides helpers for managing form actions in Aurora UIX basic templates.

  This module defines default header and footer actions for forms, and utilities to
  modify or extend these actions. It ensures that forms have consistent action buttons
  (such as save) and allows for further customization via the `Actions` module.

  ## Key Features

    - Adds default header and footer actions to form assigns.
    - Provides a `save_action/1` helper for rendering a save button.
    - Integrates with `Aurora.Uix.Web.Templates.Basic.Actions` for action modification.

  ## Key Constraints

    - Expects assigns to include an `:auix` key with relevant form action maps.
    - Designed for use within Phoenix LiveView templates.
  """

  use Aurora.Uix.Web.CoreComponentsImporter

  alias Aurora.Uix.Web.Templates.Basic.Actions
  alias Phoenix.LiveView.Rendered

  @actions %{
    add_header_action: {:form_header_actions, :add_auix_action},
    insert_header_action: {:form_header_actions, :insert_auix_action},
    replace_header_action: {:form_header_actions, :replace_auix_action},
    remove_header_action: {:form_header_actions, :remove_auix_action},
    add_footer_action: {:form_footer_actions, :add_auix_action},
    insert_footer_action: {:form_footer_actions, :insert_auix_action},
    replace_footer_action: {:form_footer_actions, :replace_auix_action},
    remove_footer_action: {:form_footer_actions, :remove_auix_action}
  }

  @doc """
  Adds default header and footer actions to the assigns and modifies actions as needed.

  ## Parameters

    - `assigns` (map()) - The assigns map, expected to include an `:auix` key.

  ## Returns

    map() - The updated assigns with default actions set.

  ## Examples

      iex> assigns = %{auix: %{form_header_actions: %{}, form_footer_actions: %{}}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Form.set_actions(assigns)
      %{auix: %{form_header_actions: %{}, form_footer_actions: %{}}}

  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders a save button for the form.

  ## Parameters

    - `assigns` (map()) - The assigns map, expected to include `:auix` with `:module` and `:name`.

  ## Returns

    Rendered.t() - A Phoenix LiveView rendered button component.

  ## Examples

      iex> assigns = %{auix: %{module: "user", name: "User"}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.Form.save_action(assigns)
      #=> #Phoenix.LiveView.Rendered<...>

  """
  @spec save_action(map()) :: Rendered.t()
  def save_action(assigns) do
    ~H"""
    <.button phx-disable-with="Saving..." name={"auix-save-#{@auix.module}"}>Save {@auix.name}</.button>
    """
  end

  ## PRIVATE

  # Returns assigns unchanged if form_header_actions already present.
  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(%{auix: %{form_header_actions: %{}}} = assigns), do: assigns

  # Adds an empty form_header_actions map if not present.
  defp add_default_header_actions(assigns),
    do: put_in(assigns, [:auix, :form_header_actions], %{})

  # Adds a default save action to form_footer_actions.
  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(assigns) do
    Actions.add_actions(assigns, :form_footer_actions, default_save: &save_action/1)
  end
end
