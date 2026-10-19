defmodule Aurora.Uix.Layout.Node.Index do
  @moduledoc """
  Render node of an index layout, read by the renderers as `@auix.layout_tree`.

  ## Key Features
  - `children` holds one `Aurora.Uix.Layout.Node.Field` per column.
  - The layout macro builds it; `Aurora.Uix.Layout.RenderTree` fills `id` and the fields.

  ## Key Constraints
  - `id` is `nil` until the build. It is derived from the resource and layout type, so it is stable across compiles.
  """

  defstruct id: nil,
            resource: nil,
            children: [],
            order_by: nil,
            where: nil,
            renderers: nil,
            actions: [],
            handler_module: nil,
            options: []

  @type t() :: %__MODULE__{
          id: binary() | nil,
          resource: atom(),
          children: [Aurora.Uix.Layout.Node.Field.t()],
          order_by: term(),
          where: term(),
          renderers: map() | nil,
          actions: keyword(),
          handler_module: module() | nil,
          options: keyword()
        }
end
