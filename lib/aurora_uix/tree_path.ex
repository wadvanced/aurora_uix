defmodule Aurora.Uix.TreePath do
  @moduledoc """
  Represents a node in the Uix tree.

  This struct holds information about a specific element in the Uix tree,
  including its tag, name, configuration, and any nested elements. It is used
  to build a hierarchical representation of the Uix components.

  ## Fields
    - `tag`: The type of the node (e.g., `:section`, `:field`).
    - `name`: A unique identifier for the node within its level.
    - `config`: A list of configuration options for the node.
    - `opts`: A list of additional options for the node.
    - `inner_elements`: A list of child `t:t/0` nodes.
  """

  use Accessible
  # use StructInspect, [false_value: true]

  @enforce_keys [:tag]
  defstruct [:tag, :name, config: [], opts: [], inner_elements: []]

  @type t() :: %__MODULE__{
          name: atom(),
          tag: atom(),
          config: list(),
          opts: list(),
          inner_elements: list(t())
        }

  @doc """
  Creates a new `t:t/0` struct.

  ## Parameters
  - `attrs` (list() | map()) - A list of attributes to initialize the struct with.

  ## Returns
  `t:t/0` - A new `t:t/0` struct.
  """
  @spec new(list() | map()) :: t()
  def new(%{tag: tag} = attrs), do: struct(%__MODULE__{tag: tag}, attrs)

  @doc """
  Changes the attributes of a `t:t/0` struct.

  It can take a `t:t/0` struct or a map and a set of attributes to change.

  ## Parameters
  - `tree_path` (`t:t/0` | map()) - The struct or map to be changed.
  - `attrs` (map()) - A map of attributes to change.

  ## Returns
  `t:t/0` - A new `t:t/0` struct with the updated attributes.
  """
  @spec change(t() | map(), map()) :: t()
  def change(tree_path, attrs \\ %{})

  def change(%__MODULE__{tag: _tag} = tree_path, attrs), do: struct(tree_path, attrs)

  def change(tree_path, %{tag: tag} = attrs),
    do: %__MODULE__{tag: tag} |> struct(tree_path) |> change(attrs)

  def change(%{tag: tag} = tree_path, attrs) do
    %__MODULE__{tag: tag}
    |> struct(tree_path)
    |> change(attrs)
  end
end
