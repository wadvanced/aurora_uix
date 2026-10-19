defmodule Aurora.Uix.Layout.Declared.Form do
  @moduledoc """
  A form layout as declared by `edit_layout`.

  ## Key Features
  - `children` holds the sub-layouts and fields, in declaration order.

  ## Key Constraints
  - `options` holds the option-set options, read through `Aurora.Uix.Layout.Options`.
  - `actions` keeps the `*_action` entries in declaration order.
  """

  defstruct resource: nil,
            children: [],
            renderers: nil,
            actions: [],
            handler_module: nil,
            options: []

  @type t() :: %__MODULE__{
          resource: atom(),
          children: [Aurora.Uix.Layout.Declared.child()],
          renderers: map() | nil,
          actions: keyword(),
          handler_module: module() | nil,
          options: keyword()
        }
end
