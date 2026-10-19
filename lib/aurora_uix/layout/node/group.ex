defmodule Aurora.Uix.Layout.Node.Group do
  @moduledoc """
  Render node of a `group` sub-layout: children framed under a title.

  ## Key Features
  - `id` is the DOM id of the group container.

  ## Key Constraints
  - `id` is set when `Aurora.Uix.Layout.RenderTree` builds the layout, from the node's
    position in it. The many-to-one renderer sets it from the field for the groups it builds.
  """

  defstruct id: nil, title: nil, children: []

  @type t() :: %__MODULE__{
          id: binary() | nil,
          title: binary() | nil,
          children: [Aurora.Uix.Layout.Node.t()]
        }
end
