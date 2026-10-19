defmodule Aurora.Uix.Layout.CreateUI.Call do
  @moduledoc """
  One `auix_create_ui` or `auix_create_layout` call, as Spark reads it.

  ## Key Features
  - `kind` names the call; `children` holds its layout nodes (`Aurora.Uix.Layout.Node`).
  - `Aurora.Uix.Layout.CreateUI.ui_opts/1` reads the options of an `auix_create_ui` call.

  ## Key Constraints
  - `layout_opts` holds the options given before a block. `renderers` and
    `default_fields_layout` hold the options of a call without a block.
  """

  defstruct kind: nil,
            layout_opts: [],
            renderers: nil,
            default_fields_layout: nil,
            children: [],
            __spark_metadata__: nil

  @type t() :: %__MODULE__{
          kind: :auix_create_ui | :auix_create_layout,
          layout_opts: keyword(),
          renderers: map() | nil,
          default_fields_layout: :stacked | :inline | nil,
          children: [Aurora.Uix.Layout.Node.layout()],
          __spark_metadata__: term()
        }
end
