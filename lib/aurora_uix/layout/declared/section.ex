defmodule Aurora.Uix.Layout.Declared.Section do
  @moduledoc """
  A `section`: one tab of a `sections` sub-layout.

  ## Key Features
  - `default?` marks the tab shown first.

  ## Key Constraints
  - Only meaningful inside `Aurora.Uix.Layout.Declared.Sections`.
  """

  defstruct label: nil, default?: false, children: []

  @type t() :: %__MODULE__{
          label: binary() | nil,
          default?: boolean(),
          children: [Aurora.Uix.Layout.Declared.child()]
        }
end
