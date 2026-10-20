defmodule Aurora.Uix.Layout.Node.Sections do
  @moduledoc """
  Render node of a `sections` sub-layout: a tab bar over its `Aurora.Uix.Layout.Node.Section` children.

  ## Key Features
  - `tabs` describes each tab button (id, label, indexes and initial state).
  - `index` numbers the sections containers of a layout in document order.

  ## Key Constraints
  - `id`, `index` and `tabs` are set when `Aurora.Uix.Layout.RenderTree` builds the layout.
  - `id` comes from the node's position in its layout and keys the selected tab in
    `@auix._sections`.
  - `__spark_metadata__` is only used while the layout DSL builds the node.
  """

  defstruct id: nil, index: 0, tabs: [], children: [], __spark_metadata__: nil

  @type t() :: %__MODULE__{
          id: binary() | nil,
          index: non_neg_integer(),
          tabs: [map()],
          children: [Aurora.Uix.Layout.Node.t()],
          __spark_metadata__: term()
        }
end
