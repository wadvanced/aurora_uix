defmodule Aurora.Uix.Templates.Basic.Actions.ManyToMany do
  @moduledoc """
  Provides helpers for managing many-to-many association actions in Aurora UIX form layouts.

  This module sets up and modifies actions for the header and footer of the checkbox list that
  represents a many-to-many membership. It ensures the default bulk-selection actions are present
  and allows further customization via `Aurora.Uix.Templates.Basic.Actions.modify_actions/2`.

  ## Key Features

    - Adds `:default_check_all` / `:default_uncheck_all` header actions that select or clear the
      whole candidate list in a single server round trip.
    - Registers an empty footer group, so a host always has an extension point below the checkbox
      list even though the library ships no default footer action.
    - Integrates with the Aurora UIX action modification pipeline, so hosts add, insert, replace or
      remove actions from the layout DSL field options.

  ## Key Constraints

    - Actions render only for `layout_type: :form`; every component falls back to `~H""` otherwise.
    - Toggling is a server event (`"auix_many_to_many_toggle_all"`, handled by
      `Aurora.Uix.Templates.Basic.Handlers.FormImpl`), never client-side DOM mutation: the new
      membership must land in `auix.form.params` or the next `phx-change` would discard it.
    - The buttons render inside the parent form, so they must declare `type="button"` — a bare
      `<button>` defaults to `submit` and would persist a half-filled record.
    - Expects the `assigns` map to include an `:auix` key with `:layout_type`, `:_myself` and the
      layout tree options, plus the `:field` being rendered.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions

  alias Phoenix.LiveView.Rendered

  @actions Action.available_actions(:many_to_many)

  @doc """
  Sets up actions for the many-to-many field rendering layout by adding defaults and
  applying modifications.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the layout tree and context.
    - Must include `:auix` key with required subkeys.

  ## Returns
  map() - The updated assigns with actions set.
  """
  @spec set_actions(map()) :: map()
  def set_actions(assigns) do
    assigns
    |> Actions.remove_all_actions(@actions)
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders a button that checks every candidate of a many-to-many field.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the association context.
    - Must include `:auix` (with `:layout_type` and `:_myself`) and `:field`.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered button component.
  """
  @spec check_all(map()) :: Rendered.t()
  def check_all(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
    <.button
      type="button"
      class="auix-button--alt"
      name={"auix-many-to-many-check_all-#{@field.key}"}
      phx-click="auix_many_to_many_toggle_all"
      phx-value-field={@field.key}
      phx-value-state="true"
      phx-target={@auix._myself}
    >
      {dt("Check all")}
    </.button>
    """
  end

  def check_all(assigns), do: ~H""

  @doc """
  Renders a button that clears the membership of a many-to-many field.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the association context.
    - Must include `:auix` (with `:layout_type` and `:_myself`) and `:field`.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered button component.
  """
  @spec uncheck_all(map()) :: Rendered.t()
  def uncheck_all(%{auix: %{layout_type: :form}} = assigns) do
    ~H"""
    <.button
      type="button"
      class="auix-button--alt"
      name={"auix-many-to-many-uncheck_all-#{@field.key}"}
      phx-click="auix_many_to_many_toggle_all"
      phx-value-field={@field.key}
      phx-value-state="false"
      phx-target={@auix._myself}
    >
      {dt("Uncheck all")}
    </.button>
    """
  end

  def uncheck_all(assigns), do: ~H""

  ## PRIVATE

  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(assigns) do
    Actions.add_actions(assigns, :many_to_many_header_actions,
      default_check_all: &check_all/1,
      default_uncheck_all: &uncheck_all/1
    )
  end

  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(%{auix: %{many_to_many_footer_actions: _}} = assigns),
    do: assigns

  # Adds an empty many_to_many_footer_actions list if not present. The library ships no default
  # footer action, but a host must still be able to place its own below the checkbox list.
  defp add_default_footer_actions(assigns),
    do: put_in(assigns, [:auix, :many_to_many_footer_actions], [])
end
