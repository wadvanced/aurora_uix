defmodule Aurora.Uix.Layout.Declared.Inline do
  @moduledoc """
  A `inline` sub-layout: fields side by side.

  ## Key Features
  - `children` holds the nested sub-layouts and fields, in declaration order.

  ## Key Constraints
  - Holds no options of its own.
  """

  defstruct children: []

  @type t() :: %__MODULE__{
          children: [Aurora.Uix.Layout.Declared.child()]
        }
end
