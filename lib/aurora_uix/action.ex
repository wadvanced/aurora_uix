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
end
