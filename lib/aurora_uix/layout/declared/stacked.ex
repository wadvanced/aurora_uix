defmodule Aurora.Uix.Layout.Declared.Stacked do
  @moduledoc """
  A `stacked` sub-layout: fields one below the other.

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
