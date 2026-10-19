defmodule Aurora.Uix.Layout.Declared.Group do
  @moduledoc """
  A `group` sub-layout: fields framed under a title.

  ## Key Features
  - `children` holds the nested sub-layouts and fields, in declaration order.

  ## Key Constraints
  - `title` is shown as declared.
  """

  defstruct title: nil, children: []

  @type t() :: %__MODULE__{
          title: binary() | nil,
          children: [Aurora.Uix.Layout.Declared.child()]
        }
end
