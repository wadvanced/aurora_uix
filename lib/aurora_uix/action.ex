defmodule Aurora.Uix.Action do
  @moduledoc """
  Represents an action with a name and an associated function component.

  ## Key Features

    * Encapsulates an action's name and its function component.
    * Provides flexible constructors for different input types.
    * Holds the default icon of each default action that renders a button or a link (`default_icons/1`) and the schema of the `action_icons:` layout option (`icons_schema/1`).

  ## Key Constraints

    * The `:name` must be a binary.
    * The `:function_component` must be a function.

  """

  defstruct [:name, :function_component]

  @type t() :: %__MODULE__{
          name: binary(),
          function_component: function()
        }

  @actions %{
    index: %{
      replace_selected_all_action: {:index_selected_all_actions, :replace_auix_action},
      remove_selected_all_action: {:index_selected_all_actions, :remove_auix_action},
      add_selected_action: {:index_selected_actions, :add_auix_action},
      insert_selected_action: {:index_selected_actions, :insert_auix_action},
      replace_selected_action: {:index_selected_actions, :replace_auix_action},
      remove_selected_action: {:index_selected_actions, :remove_auix_action},
      add_header_action: {:index_header_actions, :add_auix_action},
      insert_header_action: {:index_header_actions, :insert_auix_action},
      replace_header_action: {:index_header_actions, :replace_auix_action},
      remove_header_action: {:index_header_actions, :remove_auix_action},
      add_footer_action: {:index_footer_actions, :add_auix_action},
      insert_footer_action: {:index_footer_actions, :insert_auix_action},
      replace_footer_action: {:index_footer_actions, :replace_auix_action},
      remove_footer_action: {:index_footer_actions, :remove_auix_action},
      add_row_action: {:index_row_actions, :add_auix_action},
      insert_row_action: {:index_row_actions, :insert_auix_action},
      replace_row_action: {:index_row_actions, :replace_auix_action},
      remove_row_action: {:index_row_actions, :remove_auix_action},
      add_filters_action: {:index_filters_actions, :add_auix_action},
      insert_filters_action: {:index_filters_actions, :insert_auix_action},
      replace_filters_action: {:index_filters_actions, :replace_auix_action},
      remove_filters_action: {:index_filters_actions, :remove_auix_action}
    },
    form: %{
      add_header_action: {:form_header_actions, :add_auix_action},
      insert_header_action: {:form_header_actions, :insert_auix_action},
      replace_header_action: {:form_header_actions, :replace_auix_action},
      remove_header_action: {:form_header_actions, :remove_auix_action},
      add_footer_action: {:form_footer_actions, :add_auix_action},
      insert_footer_action: {:form_footer_actions, :insert_auix_action},
      replace_footer_action: {:form_footer_actions, :replace_auix_action},
      remove_footer_action: {:form_footer_actions, :remove_auix_action}
    },
    show: %{
      add_header_action: {:show_header_actions, :add_auix_action},
      insert_header_action: {:show_header_actions, :insert_auix_action},
      replace_header_action: {:show_header_actions, :replace_auix_action},
      remove_header_action: {:show_header_actions, :remove_auix_action},
      add_footer_action: {:show_footer_actions, :add_auix_action},
      insert_footer_action: {:show_footer_actions, :insert_auix_action},
      replace_footer_action: {:show_footer_actions, :replace_auix_action},
      remove_footer_action: {:show_footer_actions, :remove_auix_action}
    },
    one_to_many: %{
      add_header_action: {:one_to_many_header_actions, :add_auix_action},
      insert_header_action: {:one_to_many_header_actions, :insert_auix_action},
      replace_header_action: {:one_to_many_header_actions, :replace_auix_action},
      remove_header_action: {:one_to_many_header_actions, :remove_auix_action},
      add_footer_action: {:one_to_many_footer_actions, :add_auix_action},
      insert_footer_action: {:one_to_many_footer_actions, :insert_auix_action},
      replace_footer_action: {:one_to_many_footer_actions, :replace_auix_action},
      remove_footer_action: {:one_to_many_footer_actions, :remove_auix_action},
      add_row_action: {:one_to_many_row_actions, :add_auix_action},
      insert_row_action: {:one_to_many_row_actions, :insert_auix_action},
      replace_row_action: {:one_to_many_row_actions, :replace_auix_action},
      remove_row_action: {:one_to_many_row_actions, :remove_auix_action}
    },
    many_to_many: %{
      add_label_action: {:many_to_many_label_actions, :add_auix_action},
      insert_label_action: {:many_to_many_label_actions, :insert_auix_action},
      replace_label_action: {:many_to_many_label_actions, :replace_auix_action},
      remove_label_action: {:many_to_many_label_actions, :remove_auix_action},
      add_header_action: {:many_to_many_header_actions, :add_auix_action},
      insert_header_action: {:many_to_many_header_actions, :insert_auix_action},
      replace_header_action: {:many_to_many_header_actions, :replace_auix_action},
      remove_header_action: {:many_to_many_header_actions, :remove_auix_action},
      add_footer_action: {:many_to_many_footer_actions, :add_auix_action},
      insert_footer_action: {:many_to_many_footer_actions, :insert_auix_action},
      replace_footer_action: {:many_to_many_footer_actions, :replace_auix_action},
      remove_footer_action: {:many_to_many_footer_actions, :remove_auix_action}
    },
    multi_select: %{
      add_label_action: {:multi_select_label_actions, :add_auix_action},
      insert_label_action: {:multi_select_label_actions, :insert_auix_action},
      replace_label_action: {:multi_select_label_actions, :replace_auix_action},
      remove_label_action: {:multi_select_label_actions, :remove_auix_action},
      add_header_action: {:multi_select_header_actions, :add_auix_action},
      insert_header_action: {:multi_select_header_actions, :insert_auix_action},
      replace_header_action: {:multi_select_header_actions, :replace_auix_action},
      remove_header_action: {:multi_select_header_actions, :remove_auix_action},
      add_footer_action: {:multi_select_footer_actions, :add_auix_action},
      insert_footer_action: {:multi_select_footer_actions, :insert_auix_action},
      replace_footer_action: {:multi_select_footer_actions, :replace_auix_action},
      remove_footer_action: {:multi_select_footer_actions, :remove_auix_action}
    },
    embeds_many: %{
      add_header_action: {:embeds_many_header_actions, :add_auix_action},
      insert_header_action: {:embeds_many_header_actions, :insert_auix_action},
      replace_header_action: {:embeds_many_header_actions, :replace_auix_action},
      remove_header_action: {:embeds_many_header_actions, :remove_auix_action},
      add_footer_action: {:embeds_many_footer_actions, :add_auix_action},
      insert_footer_action: {:embeds_many_footer_actions, :insert_auix_action},
      replace_footer_action: {:embeds_many_footer_actions, :replace_auix_action},
      remove_footer_action: {:embeds_many_footer_actions, :remove_auix_action},
      add_new_entry_action: {:embeds_many_new_entry_actions, :add_auix_action},
      insert_new_entry_action: {:embeds_many_new_entry_actions, :insert_auix_action},
      replace_new_entry_action: {:embeds_many_new_entry_actions, :replace_auix_action},
      remove_new_entry_action: {:embeds_many_new_entry_actions, :remove_auix_action},
      add_existing_action: {:embeds_many_existing_actions, :add_auix_action},
      insert_existing_action: {:embeds_many_existing_actions, :insert_auix_action},
      replace_existing_action: {:embeds_many_existing_actions, :replace_auix_action},
      remove_existing_action: {:embeds_many_existing_actions, :remove_auix_action}
    }
  }

  # The default icon of each default action that renders a button or a link. A key here is a
  # valid `action_icons:` key of its group; a group without keys has no entry.
  @default_icons %{
    index: [
      default_row_show: "hero-eye",
      default_row_edit: "hero-pencil",
      default_row_delete: "hero-trash",
      default_selected_uncheck_all: "hero-x-circle",
      default_selected_delete_all: "hero-trash",
      default_selected_check_all: "hero-check-circle",
      default_toggle_filters: "hero-funnel",
      default_clear: "hero-x-mark",
      default_submit: "hero-magnifying-glass",
      default_new: "hero-plus"
    ],
    form: [default_save: "hero-check"],
    show: [default_edit: "hero-pencil", default_back: "hero-arrow-left"],
    one_to_many: [
      default_new: "hero-plus",
      default_row_show: "hero-eye",
      default_row_edit: "hero-pencil",
      default_row_delete: "hero-trash"
    ],
    embeds_many: [
      default_header_enable_add_entry: "hero-plus",
      default_footer_enable_add_entry: "hero-plus",
      default_add_entry: "hero-plus",
      default_remove_entry: "hero-trash"
    ]
  }

  @icon_type {:or, [:atom, :string, {:fun, 1}]}

  @doc """
  Creates a new action from a name and a function component.

  ## Parameters

    - `name` (atom()) - The name of the action.
    - `function_component` (function()) - The function component to associate.

  ## Returns

  `Aurora.Uix.Action.t()` - An action struct with the given name and function component.

  ## Examples

      iex> Aurora.Uix.Action.new("save", fn -> :ok end)
      %Aurora.Uix.Action{name: "save", function_component: #Function<...>}

  """
  @spec new(atom(), function()) :: t()
  def new(name, function_component) do
    %__MODULE__{name: name, function_component: function_component}
  end

  @doc """
  Creates a new action from a tuple containing the name and function component.

  ## Parameters

    - `{name, function_component}` ({binary(), function()}) - Tuple with the action name and function.

  ## Returns

  `Aurora.Uix.Action.t()` - An action struct with the given name and function component.

  ## Examples

      iex> Aurora.Uix.Action.new({"delete", fn -> :deleted end})
      %Aurora.Uix.Action{name: "delete", function_component: #Function<...>}

  """
  @spec new({binary(), function()}) :: t()
  def new({name, function_component}) do
    %__MODULE__{name: name, function_component: function_component}
  end

  @doc """
  Retrieves all the available actions group.

  ## Returns
  A `list(atom())` with all the available actions groups.
  """
  @spec action_groups() :: list(atom())
  def action_groups do
    @actions
    |> Map.values()
    |> Enum.map(&Map.values/1)
    |> List.flatten()
    |> Keyword.keys()
    |> Enum.uniq()
  end

  @doc """
  Retrieves every host-facing action option name, across all groups.

  These are the keys a host writes in the layout DSL (`add_header_action:`, `remove_row_action:`,
  …). Deriving the list here rather than from one group keeps callers that must recognise an action
  option — such as the layout DSL, which evaluates their function captures at compile time — correct
  when a new group is registered.

  ## Returns
  A `list(atom())` with all the available action option names.
  """
  @spec action_option_names() :: list(atom())
  def action_option_names do
    @actions
    |> Map.values()
    |> Enum.flat_map(&Map.keys/1)
    |> Enum.uniq()
  end

  @doc """
  Retrieves the available actions for the given group.

  ## Parameters
  - `action_group` (atom()) - Name of the group to retrieve.

  ## Returns
  A `map()` or nil if the group does not exists.
  """
  @spec available_actions(atom()) :: map()
  def available_actions(action_group), do: Map.get(@actions, action_group)

  @doc """
  Retrieves the default icons of an action group.

  ## Parameters
  - `action_group` (atom()) - The group, such as `:index` or `:embeds_many`.

  ## Returns
  `keyword()` - The default icon of each default action of the group that renders a button or a
  link, by action name. `[]` for a group without one, such as `:many_to_many`.
  """
  @spec default_icons(atom()) :: keyword()
  def default_icons(action_group), do: Map.get(@default_icons, action_group, [])

  @doc """
  Retrieves the default icon of one default action.

  ## Parameters
  - `action_group` (atom()) - The group, such as `:index`.
  - `action_name` (atom()) - The default action, such as `:default_new`.

  ## Returns
  `binary()` - A `hero-*` icon name. Raises `KeyError` for an action without a default icon.
  """
  @spec default_icon(atom(), atom()) :: binary()
  def default_icon(action_group, action_name),
    do: action_group |> default_icons() |> Keyword.fetch!(action_name)

  @doc """
  Retrieves the `Spark.Options` schema of a group's `action_icons:` keys.

  ## Parameters
  - `action_group` (atom()) - The group, such as `:index`.

  ## Returns
  `keyword()` - One entry per key of `default_icons/1`. A value is a hero icon name (atom,
  `"hero-*"` string), an image URL, a character, a function of arity 1 receiving the action's
  assigns.
  """
  @spec icons_schema(atom()) :: keyword()
  def icons_schema(action_group) do
    action_group
    |> default_icons()
    |> Enum.map(fn {action_name, _icon} -> {action_name, [type: @icon_type]} end)
  end
end
