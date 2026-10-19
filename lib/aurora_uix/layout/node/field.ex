defmodule Aurora.Uix.Layout.Node.Field do
  @moduledoc """
  Node of a field placed in a layout.

  ## Key Features
  - `overrides` is a partial `Aurora.Uix.Field` with the options the layout sets for the field,
    e.g. `name: [label: "Product"]`.
  - `field` is the resolved `Aurora.Uix.Field`: the resource field with `overrides` merged over it.
  - `path` follows many-to-one associations from `key`: `{:category_id, :name}` becomes
    `key: :category_id, path: [:name]`.

  ## Key Constraints
  - `field` is `nil` until `Aurora.Uix.Layout.RenderTree` builds the layout.
  - `actions`, `order_by` and `where` apply to association fields.
  """

  defstruct key: nil, path: [], overrides: nil, field: nil, actions: [], order_by: nil, where: nil

  @type t() :: %__MODULE__{
          key: atom(),
          path: [atom()],
          overrides: Aurora.Uix.Field.t() | nil,
          field: Aurora.Uix.Field.t() | nil,
          actions: keyword(),
          order_by: term(),
          where: term()
        }
end
