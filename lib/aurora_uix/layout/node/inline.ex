defmodule Aurora.Uix.Layout.Node.Inline do
  @moduledoc """
  Render node of an `inline` sub-layout: fields side by side.

  ## Key Features
  - `children` are rendered in order.

  ## Key Constraints
  - `id` comes from the node's position in its layout.
  """

  defstruct id: nil, children: []

  @type t() :: %__MODULE__{
          id: binary() | nil,
          children: [Aurora.Uix.Layout.Node.t()]
        }
end
