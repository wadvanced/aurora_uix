defmodule Aurora.Uix.Layout.Node.Field do
  @moduledoc """
  Render node of a field.

  ## Key Features
  - `field` is the resolved `Aurora.Uix.Field`: the resource field with the layout's overrides.
  - `path` follows many-to-one associations from `key`, as in `Aurora.Uix.Layout.Declared.FieldRef`.

  ## Key Constraints
  - `actions`, `order_by` and `where` apply to association fields.
  """

  defstruct key: nil, path: [], field: nil, actions: [], order_by: nil, where: nil

  @type t() :: %__MODULE__{
          key: atom(),
          path: [atom()],
          field: Aurora.Uix.Field.t(),
          actions: keyword(),
          order_by: term(),
          where: term()
        }
end
