defmodule Aurora.Uix.Layout.Node do
  @moduledoc """
  Types and traversal of the layout nodes: the structures the layout macros build and the
  renderers read as `@auix.layout_tree`.

  ## Key Features
  - `t()` is any layout node; `layout()` is one of the three containers.
  - `fields/1` lists the field nodes of a tree in document order.

  ## Key Constraints
  - The layout macros build the nodes with what the host wrote. `Aurora.Uix.Layout.RenderTree`
    then fills what it computes (ids, resolved fields, tab state) on the same structs, before
    any renderer sees them.
  - Renderers that need extra nodes (such as the many-to-one renderer) build them with the
    same structs.
  """

  alias Aurora.Uix.Layout.Node

  @type layout() :: Node.Index.t() | Node.Form.t() | Node.Show.t()

  @type t() ::
          layout()
          | Node.Inline.t()
          | Node.Stacked.t()
          | Node.Group.t()
          | Node.Sections.t()
          | Node.Section.t()
          | Node.Field.t()

  @doc """
  Lists the field nodes of a tree, in document order.

  ## Parameters
  - `node` (t() | [t()]) - The node, or list of nodes, to traverse.

  ## Returns
  `[Aurora.Uix.Layout.Node.Field.t()]` - Every field node under `node`, `node` included.
  """
  @spec fields(t() | [t()]) :: [Node.Field.t()]
  def fields(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &fields/1)
  def fields(%Node.Field{} = field), do: [field]
  def fields(%{children: children}), do: fields(children)
end
