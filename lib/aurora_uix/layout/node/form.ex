defmodule Aurora.Uix.Layout.Node.Form do
  @moduledoc """
  Render node of a form layout, read by the renderers as `@auix.layout_tree`.

  ## Key Features
  - Built from `Aurora.Uix.Layout.Declared.Form` by `Aurora.Uix.Layout.RenderTree`.

  ## Key Constraints
  - `id` is derived from the resource and layout type, so it is stable across compiles.
  """

  defstruct id: nil,
            resource: nil,
            children: [],
            renderers: nil,
            actions: [],
            handler_module: nil,
            options: []

  @type t() :: %__MODULE__{
          id: binary(),
          resource: atom(),
          children: [Aurora.Uix.Layout.Node.t()],
          renderers: map() | nil,
          actions: keyword(),
          handler_module: module() | nil,
          options: keyword()
        }
end
