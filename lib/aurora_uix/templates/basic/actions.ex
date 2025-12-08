defmodule Aurora.Uix.Templates.Basic.Actions do
  @moduledoc """
  Provides helper functions to manage and modify action groups within Aurora UIX templates.

  Adds, modifies, and removes actions from action groups in the assigns map. Supports both
  removal and modification of individual actions. Integrates with `Aurora.Uix.Action` and
  `Aurora.Uix.Templates.Basic.Helpers` for action creation and manipulation.
  """

  alias Aurora.Uix.Action
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.Socket

  @doc """
  Removes all actions from the specified action groups in the container.

  ## Parameters
  - `assigns_or_socket` (Socket.t() | map()) - The container to modify (either Socket or assigns map).
  - `actions` (map()) - Map of actions where each value is a tuple {action_group, _}.

  ## Returns
  Socket.t() | map() - The modified container with all specified actions removed.
  """
  @spec remove_all_actions(Socket.t() | map(), map()) :: map()
  def remove_all_actions(assigns_or_socket, actions) do
    actions
    |> Enum.map(fn {_action, {actions_group, _}} -> actions_group end)
    |> Enum.uniq()
    |> Enum.reduce(assigns_or_socket, &BasicHelpers.assign_auix(&2, &1, []))
  end

  @doc """
  Adds a list of actions to the specified action group in the assigns map.

  ## Parameters

    - `container` (Socket.t() | map()) - The assigns map or Socket to update.
    - `action_group` (atom()) - The target action group (e.g., `:main`, `:secondary`).
    - `actions` (list(map() | struct())) - List of actions to add. Each action must be convertible via `Aurora.Uix.Action.new/1`.

  ## Returns

    (Socket.t() | map()) - The updated container with new actions added to the specified group.

  """
  @spec add_actions(Socket.t() | map(), atom(), list(tuple())) :: Socket.t() | map()
  def add_actions(assigns_or_socket, action_group, actions) do
    Enum.reduce(
      actions,
      assigns_or_socket,
      &BasicHelpers.add_auix_action(&2, action_group, Action.new(&1))
    )
  end

  @doc """
  Modifies actions in the assigns map based on the provided actions map.

  Iterates over the options in the assigns' layout tree and applies modifications or removals
  as specified in the `actions` map.

  ## Parameters

    - `assigns` (Socket.t() | map()) - Must contain `:auix.layout_tree.opts` with action definitions.
    - `actions` (map()) - Map of action names to tuples specifying:
      * `{action_group, :remove_auix_action}` - Removes the action
      * `{action_group, function}` - Applies the specified BasicHelpers function

  ## Returns

    (Socket.t() | map()) - The updated container after applying all modifications.


  """
  @spec modify_actions(Socket.t() | map(), map()) :: map()
  def modify_actions(%Socket{assigns: %{auix: %{layout_tree: %{opts: opts}}}} = socket, actions) do
    Enum.reduce(opts, socket, &modify_action(&1, &2, actions))
  end

  def modify_actions(%{auix: %{layout_tree: %{opts: opts}}} = assigns, actions) do
    Enum.reduce(opts, assigns, &modify_action(&1, &2, actions))
  end

  ## PRIVATE

  # Handles individual action modification based on the actions specification map.
  # Returns the unmodified container if no matching action specification exists.
  @spec modify_action({atom(), Action.t() | atom()}, Socket.t() | map(), map()) ::
          Socket.t() | map()
  defp modify_action({action_name, action}, assigns_or_socket, actions) do
    case Map.get(actions, action_name) do
      {action_group, :remove_auix_action} ->
        BasicHelpers.remove_auix_action(assigns_or_socket, action_group, action)

      {action_group, function} ->
        apply(BasicHelpers, function, [assigns_or_socket, action_group, Action.new(action)])

      _ ->
        assigns_or_socket
    end
  end
end
