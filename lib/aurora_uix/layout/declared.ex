defmodule Aurora.Uix.Layout.Declared do
  @moduledoc """
  Types of the layouts a host declares with `auix_create_ui` and its layout macros.

  ## Key Features
  - `layout()` is one of the three containers: `Aurora.Uix.Layout.Declared.Index`,
    `Aurora.Uix.Layout.Declared.Form` and `Aurora.Uix.Layout.Declared.Show`.
  - `child()` is anything a form or show container can hold.

  ## Key Constraints
  - Declared layouts hold only what the host wrote; ids, tab state and resolved fields are
    added when `Aurora.Uix.Layout.RenderTree` builds the render nodes.
  """

  alias Aurora.Uix.Layout.Declared

  @type layout() :: Declared.Index.t() | Declared.Form.t() | Declared.Show.t()

  @type child() ::
          Declared.Inline.t()
          | Declared.Stacked.t()
          | Declared.Group.t()
          | Declared.Sections.t()
          | Declared.Section.t()
          | Declared.FieldRef.t()
end
