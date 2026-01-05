defmodule Aurora.Uix.Templates.Basic.Actions.Form do
  @moduledoc """
  Provides helpers for managing form actions in Aurora UIX basic templates.

  This module defines default header and footer actions for forms, and utilities to
  modify or extend these actions. It ensures that forms have consistent action buttons
  (such as save) and allows for further customization via the `Actions` module.

  ## Key Features

    - Adds default header and footer actions to form assigns.
    - Provides a `save_action/1` helper for rendering a save button.
    - Integrates with `Aurora.Uix.Templates.Basic.Actions` for action modification.

  ## Key Constraints

    - Expects assigns to include an `:auix` key with relevant form action maps.
    - Designed for use within Phoenix LiveView templates.
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  @actions Action.available_actions(:form)

  @doc """
  Adds default header and footer actions to the assigns and modifies actions as needed.

  ## Parameters
  - `socket` (Socket.t()) - LiveView socket containing the assigns with auix context.

  ## Returns
  Socket.t() - The updated socket with default actions configured.
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
  Renders a save button for the form.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:auix` (map()) - Aurora UIX context with `:module` and `:name`.

  ## Returns
  Rendered.t() - A Phoenix LiveView rendered button component.
  """
  @spec save_action(map()) :: Rendered.t()
  def save_action(assigns) do
    ~H"""
    <.button phx-disable-with="Saving..." name={"auix-save-#{@auix.module}"}>Save {@auix.name}</.button>
    """
  end

  ## PRIVATE

  # Returns assigns unchanged if form_header_actions already present.
  @spec add_default_header_actions(Socket.t()) :: Socket.t()
  defp add_default_header_actions(%{assigns: %{auix: %{form_header_actions: _}}} = socket),
    do: socket

  # Adds an empty form_header_actions map if not present.
  defp add_default_header_actions(socket),
    do: put_in(socket, [Access.key!(:assigns), :auix, :form_header_actions], [])

  # Adds a default save action to form_footer_actions.
  @spec add_default_footer_actions(Socket.t()) :: Socket.t()
  defp add_default_footer_actions(socket) do
    Actions.add_actions(socket, :form_footer_actions, default_save: &save_action/1)
  end
end
