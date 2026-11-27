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
    - `action_group` (atom()) - The target action group (e.g., `:index_row_actions`, `:form_footer_actions`).
    - `actions` (list(map() | struct())) - List of actions to add. Each action must be convertible via `Aurora.Uix.Action.new/1`:
      a `{name, function}` tuple, or a `{name, function, opts}` tuple taking options (such as `destructive?:`) as a third element.

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

    - `assigns` (Socket.t() | map()) - Must contain `:auix.layout_tree.actions` with action definitions.
    - `actions` (map()) - Map of action names to tuples specifying:
      * `{action_group, :remove_auix_action}` - Removes the action
      * `{action_group, function_name}` - Applies the named `Aurora.Uix.Templates.Basic.Helpers`
      function

    The layout's action value is a `{name, function}` tuple, or a `{name, function, opts}` tuple that takes
    options (such as `destructive?:`) as a third element; see `Aurora.Uix.Action.new/1`.

  ## Returns

    (Socket.t() | map()) - The updated container after applying all modifications.


  """
  @spec modify_actions(Socket.t() | map(), map()) :: map()
  def modify_actions(%Socket{assigns: %{auix: %{layout_tree: layout_tree}}} = socket, actions) do
    layout_tree
    |> Map.get(:actions, [])
    |> Enum.reduce(socket, &modify_action(&1, &2, actions))
  end

  def modify_actions(%{auix: %{layout_tree: layout_tree}} = assigns, actions) do
    layout_tree
    |> Map.get(:actions, [])
    |> Enum.reduce(assigns, &modify_action(&1, &2, actions))
  end

  @doc """
  Resolves the icon of a default action.

  ## Parameters
  - `assigns` (map()) - The assigns the action renders with; a function icon receives them.
  - `icons` (keyword()) - The `action_icons:` entries that apply, by action name.
  - `action_group` (atom()) - The group of the action, such as `:index`.
  - `action_name` (atom()) - The default action, such as `:default_new`.

  ## Returns
  `atom() | binary()` - The entry of `icons`, the result of a function entry, else the default
  icon of `Aurora.Uix.Action.default_icon/2`.
  """
  @spec icon(map(), keyword(), atom(), atom()) :: atom() | binary()
  def icon(assigns, icons, action_group, action_name) do
    case Keyword.get(icons, action_name) do
      nil -> Action.default_icon(action_group, action_name)
      icon when is_function(icon, 1) -> icon.(assigns)
      icon -> icon
    end
  end

  @doc """
  Returns the text a default action puts in its `title` and `aria-label`.

  ## Parameters
  - `label` (term()) - The action's label: a binary, an atom, `nil`, a rendered template.

  ## Returns
  `binary() | nil` - The label as text; `nil` for `nil` and for a rendered template, so the
  attributes are left out.
  """
  @spec label_title(term()) :: binary() | nil
  def label_title(nil), do: nil
  def label_title(label) when is_binary(label), do: label
  def label_title(label) when is_atom(label), do: Atom.to_string(label)
  def label_title(_label), do: nil

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
