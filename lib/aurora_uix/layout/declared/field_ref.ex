defmodule Aurora.Uix.Layout.Declared.FieldRef do
  @moduledoc """
  A field placed in a layout, with the options the layout sets for it.

  ## Key Features
  - `overrides` is a partial `Aurora.Uix.Field`, merged over the resource field with
    `Aurora.Uix.Field.merge/2`.
  - `path` follows many-to-one associations: `{:category_id, :name}` is `key: :category_id,
    path: [:name]`.

  ## Key Constraints
  - `actions`, `order_by` and `where` apply to association fields.
  """

  defstruct key: nil, path: [], overrides: nil, actions: [], order_by: nil, where: nil

  @type t() :: %__MODULE__{
          key: atom(),
          path: [atom()],
          overrides: Aurora.Uix.Field.t() | nil,
          actions: keyword(),
          order_by: term(),
          where: term()
        }
end
