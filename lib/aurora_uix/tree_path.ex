defmodule Aurora.Uix.TreePath do
  use Aurora.Uix.AccessHelper

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

  @enforce_keys [:tag]
  defstruct [:tag, :name, config: [], opts: [], inner_elements: []]

  @type t() :: %__MODULE__{
          name: atom(),
          tag: atom(),
          config: list(),
          opts: list(),
          inner_elements: list(t())
        }
end
