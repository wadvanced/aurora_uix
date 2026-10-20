defmodule Aurora.Uix.Layout.Node.Form do
  @moduledoc """
  Render node of a form layout, read by the renderers as `@auix.layout_tree`.

  ## Key Features
  - The layout macro builds it; `Aurora.Uix.Layout.RenderTree` fills `id` and the fields.

  ## Key Constraints
  - `id` is `nil` until the build. It is derived from the resource and layout type, so it is stable across compiles.
  - `__spark_metadata__` is only used while the layout DSL builds the node.
  """

  defstruct id: nil,
            resource: nil,
            children: [],
            renderers: nil,
            actions: [],
            handler_module: nil,
            options: [],
            __spark_metadata__: nil

  @type t() :: %__MODULE__{
          id: binary() | nil,
          resource: atom(),
          children: [Aurora.Uix.Layout.Node.t()],
          renderers: map() | nil,
          actions: keyword(),
          handler_module: module() | nil,
          options: keyword(),
          __spark_metadata__: term()
        }
end
