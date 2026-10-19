defmodule Aurora.Uix.Layout.Node.Section do
  @moduledoc """
  Render node of a `section`: the contents of one tab.

  ## Key Features
  - `active?` marks the tab shown until the user picks another.
  - `sections_id`, `tab_parent_id` and the indexes place the tab within nested sections.

  ## Key Constraints
  - `id` is the tab id, derived from the node's position in its layout.
  """

  defstruct id: nil,
            label: nil,
            active?: false,
            sections_id: nil,
            sections_index: 0,
            tab_parent_id: nil,
            tab_index: 0,
            children: []

  @type t() :: %__MODULE__{
          id: binary(),
          label: binary() | nil,
          active?: boolean(),
          sections_id: binary(),
          sections_index: non_neg_integer(),
          tab_parent_id: binary() | nil,
          tab_index: non_neg_integer(),
          children: [Aurora.Uix.Layout.Node.t()]
        }
end
