defmodule Aurora.Uix.Web.Templates.Basic.Actions do
  @moduledoc """
  Provides helper functions to manage and modify action groups within Aurora UIX templates.

  ## Key Features

    - Adds actions to a given action group in the assigns map.
    - Modifies existing actions in the assigns map based on provided options.
    - Integrates with `Aurora.Uix.Action` and `Aurora.Uix.Web.Templates.Basic.Helpers` for action creation and manipulation.

  ## Key Constraints

    - Expects assigns to contain a nested structure with `:auix` and `:layout_tree` keys for modification.
    - Designed for internal use within Aurora UIX template rendering.
  """

  alias Aurora.Uix.Action
  alias Aurora.Uix.Web.Templates.Basic.Helpers, as: BasicHelpers

  @doc """
  Adds a list of actions to the specified action group in the assigns map.

  ## Parameters

    - `assigns` (map()) - The assigns map to update.
    - `action_group` (atom()) - The target action group.
    - `actions` (list(map() | struct())) - List of actions to add.

  ## Returns

    map() - The updated assigns map with new actions added.

  ## Examples

      iex> assigns = %{}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.add_actions(assigns, :main, [%{name: "edit"}])
      %{}

  """
  @spec add_actions(map(), atom(), list(tuple())) :: map()
  def add_actions(assigns, action_group, actions) do
    Enum.reduce(actions, assigns, &BasicHelpers.add_auix_action(&2, action_group, Action.new(&1)))
  end

  @doc """
  Modifies actions in the assigns map based on the provided actions map.

  Iterates over the options in the assigns' layout tree and applies modifications or removals
  as specified in the `actions` map.

  ## Parameters

    - `assigns` (map()) - The assigns map containing `:auix` and `:layout_tree`.
    - `actions` (map()) - Map of action names to modification instructions.

  ## Returns

    map() - The updated assigns map after modifications.

  ## Examples

      iex> assigns = %{auix: %{layout_tree: %{opts: [edit: %{name: "edit"}]}}}
      iex> actions = %{edit: {:main, :remove_auix_action}}
      iex> Aurora.Uix.Web.Templates.Basic.Actions.modify_actions(assigns, actions)
      %{auix: %{layout_tree: %{opts: [edit: %{name: "edit"}]}}}

  """
  @spec modify_actions(map(), map()) :: map()
  def modify_actions(%{auix: %{layout_tree: %{opts: opts}}} = assigns, actions) do
    Enum.reduce(opts, assigns, &modify_action(&1, &2, actions))
  end

  ## PRIVATE

  # Applies a modification or removal to a single action based on the actions map.
  @spec modify_action({atom(), Action.t() | atom()}, map(), map()) :: map()
  defp modify_action({action_name, action}, assigns, actions) do
    case Map.get(actions, action_name) do
      {action_group, :remove_auix_action} ->
        BasicHelpers.remove_auix_action(assigns, action_group, action)

      {action_group, function} ->
        apply(BasicHelpers, function, [assigns, action_group, Action.new(action)])

      _ ->
        assigns
    end
  end
end
