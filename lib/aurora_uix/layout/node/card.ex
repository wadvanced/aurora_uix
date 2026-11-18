defmodule Aurora.Uix.Layout.Node.Card do
  @moduledoc """
  Node of the card of an index layout, read by the renderers from the index's `card` key.

  ## Key Features
  - `title` and `subtitle` are each a field node, a text, or a function of the assigns.
  - `children` is the body of the card: sub-layouts and fields.
  - `show_on` chooses the breakpoints: `:mobile` shows the cards below the `md` breakpoint,
    `:all` shows them at every breakpoint.

  ## Key Constraints
  - `card_opts` and `__spark_metadata__` are only used while the layout DSL builds the node.
  - The nodes under a card carry no `id`.
  """

  defstruct title: nil,
            subtitle: nil,
            show_on: :mobile,
            children: [],
            card_opts: [],
            __spark_metadata__: nil

  @type text() :: Aurora.Uix.Layout.Node.Field.t() | binary() | (map() -> term()) | nil

  @type t() :: %__MODULE__{
          title: text(),
          subtitle: text(),
          show_on: :mobile | :all,
          children: [Aurora.Uix.Layout.Node.t()],
          card_opts: keyword(),
          __spark_metadata__: term()
        }
end
