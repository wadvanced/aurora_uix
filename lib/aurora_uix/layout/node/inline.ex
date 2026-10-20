defmodule Aurora.Uix.Layout.Node.Inline do
  @moduledoc """
  Render node of an `inline` sub-layout: fields side by side.

  ## Key Features
  - `children` are rendered in order.

  ## Key Constraints
  - `id` comes from the node's position in its layout.
  - `fields` and `__spark_metadata__` are only used while the layout DSL builds the node.
  """

  defstruct id: nil, children: [], fields: [], __spark_metadata__: nil

  @type t() :: %__MODULE__{
          id: binary() | nil,
          children: [Aurora.Uix.Layout.Node.t()],
          fields: list(),
          __spark_metadata__: term()
        }
end
