defmodule Aurora.Uix.Layout.Declared.Index do
  @moduledoc """
  An index layout as declared by `index_columns`.

  ## Key Features
  - `columns` holds one `Aurora.Uix.Layout.Declared.FieldRef` per column, in order.
  - `order_by` and `where` set the query of the listed entries.

  ## Key Constraints
  - `options` holds the option-set options (`page_title`, `row_id`, ...), read through
    `Aurora.Uix.Layout.Options`.
  - `actions` keeps the `*_action` entries in declaration order.
  """

  defstruct resource: nil,
            columns: [],
            order_by: nil,
            where: nil,
            renderers: nil,
            actions: [],
            handler_module: nil,
            options: []

  @type t() :: %__MODULE__{
          resource: atom(),
          columns: [Aurora.Uix.Layout.Declared.FieldRef.t()],
          order_by: term(),
          where: term(),
          renderers: map() | nil,
          actions: keyword(),
          handler_module: module() | nil,
          options: keyword()
        }
end
