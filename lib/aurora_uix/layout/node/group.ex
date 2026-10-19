defmodule Aurora.Uix.Layout.Node.Group do
  @moduledoc """
  Render node of a `group` sub-layout: children framed under a title.

  ## Key Features
  - `id` is the DOM id of the group container.

  ## Key Constraints
  - `id` comes from the node's position in its layout, or from the field for the groups
    built by the many-to-one renderer.
  """

  defstruct id: nil, title: nil, children: []

  @type t() :: %__MODULE__{
          id: binary(),
          title: binary() | nil,
          children: [Aurora.Uix.Layout.Node.t()]
        }
end
