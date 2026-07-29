defmodule Aurora.Uix.Templates.Basic.Actions.MultiSelect do
  @moduledoc """
  Provides helpers for managing multi-value select actions in Aurora UIX form layouts.

  This module sets up and modifies actions for the three strips around the checkbox list that
  represents a multi-value select: beside the label, at the top right, and below the list. It is the
  scalar counterpart of `Aurora.Uix.Templates.Basic.Actions.ManyToMany`, which does the same for a
  many-to-many membership.

  ## Key Features

    - Adds `:default_toggle_all`, a tri-state checkbox rendered beside the group label: checked when
      every option is selected, unchecked when none is, and a dash when only some are. Clicking a
      checked toggle clears the selection; clicking it in either other state selects everything.
    - Registers empty header and footer groups, so a host always has an extension point above and
      below the checkbox list even though the library ships no default there.
    - Integrates with the Aurora UIX action modification pipeline, so hosts add, insert, replace or
      remove actions from the layout DSL field options.

  ## Key Constraints

    - Actions render only for `layout_type: :form`; every component falls back to `~H""` otherwise.
    - The toggle rides the parent form's `phx-change="validate"` and is identified by `_target`
      (see `Aurora.Uix.Templates.Basic.Handlers.FormImpl`). It must **not** use `phx-click`: a click
      on a checkbox fires `click` and then `change`, and the trailing change would re-validate with
      the pre-click selection and undo the toggle.
    - Its input name is deliberately outside the resource scope, so the toggle never reaches the
      host's changeset or Ash action as an unknown key. It shares the `auix_toggle_all__` prefix with
      the many-to-many toggle because both are resolved by the same `FormImpl` clause.
    - Expects the `assigns` map to include an `:auix` key with `:layout_type`,
      `:multi_select_toggle_state` and the layout tree options, plus the `:field` being rendered.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext

  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Actions

  alias Phoenix.LiveView.Rendered

  @actions Action.available_actions(:multi_select)

  @doc """
  Sets up actions for the multi-value select field rendering layout by adding defaults and
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
    |> add_default_label_actions()
    |> add_default_header_actions()
    |> add_default_footer_actions()
    |> Actions.modify_actions(@actions)
  end

  @doc """
  Renders the tri-state checkbox that selects or clears every option.

  Checked means every option is selected, unchecked means none is, and the `mixed` modifier paints a
  dash for a partial selection. Only `:all` renders as checked, so clicking from either other state
  selects everything.

  ## Parameters
  - `assigns` (map()) - Assigns map containing the select context.
    - Must include `:auix` (with `:layout_type` and `:multi_select_toggle_state`) and `:field`.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered checkbox component.
  """
  @spec toggle_all(map()) :: Rendered.t()
  def toggle_all(%{auix: %{layout_type: :form, multi_select_toggle_state: state}} = assigns) do
    # Action components are invoked as plain function calls with a hand-built map, which carries no
    # change-tracking metadata -- so `Map.put/3`, not `assign/3`, exactly as `Actions.Index` does.
    assigns =
      assigns
      |> Map.put(:checked?, state == :all)
      |> Map.put(:mixed_class, if(state == :mixed, do: "auix-checkbox--mixed", else: ""))

    ~H"""
    <.input
      id={"auix-multi-select-toggle_all-#{@field.key}"}
      name={"auix_toggle_all__#{@field.key}"}
      type="checkbox"
      label=""
      value={@checked?}
      input_class={@mixed_class}
      title={dt("Select or clear every option")}
    />
    """
  end

  def toggle_all(assigns), do: ~H""

  ## PRIVATE

  @spec add_default_label_actions(map()) :: map()
  defp add_default_label_actions(assigns) do
    Actions.add_actions(assigns, :multi_select_label_actions, default_toggle_all: &toggle_all/1)
  end

  @spec add_default_header_actions(map()) :: map()
  defp add_default_header_actions(%{auix: %{multi_select_header_actions: _}} = assigns),
    do: assigns

  # Adds an empty multi_select_header_actions list if not present. The library ships no default
  # header action, but a host must still be able to place its own above the checkbox list.
  defp add_default_header_actions(assigns),
    do: put_in(assigns, [:auix, :multi_select_header_actions], [])

  @spec add_default_footer_actions(map()) :: map()
  defp add_default_footer_actions(%{auix: %{multi_select_footer_actions: _}} = assigns),
    do: assigns

  # Adds an empty multi_select_footer_actions list if not present. The library ships no default
  # footer action, but a host must still be able to place its own below the checkbox list.
  defp add_default_footer_actions(assigns),
    do: put_in(assigns, [:auix, :multi_select_footer_actions], [])
end
