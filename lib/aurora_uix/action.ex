defmodule Aurora.Uix.Action do
  @moduledoc """
  Represents an action with a name and an associated function component.

  ## Key Features

    * Encapsulates an action's name and its function component.
    * Provides flexible constructors for different input types.

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
      remove_row_action: {:index_row_actions, :remove_auix_action}
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
    }
  }

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
  Retrieves the available actions for the given group.

  ## Parameters
  - `action_group` (atom()) - Name of the group to retrieve.

  ## Returns
  A `map()` or nil if the group does not exists.
  """
  @spec available_actions(atom()) :: map()
  def available_actions(action_group), do: Map.get(@actions, action_group)
end
