defmodule Aurora.Uix.Layout.Options.Option do
  @moduledoc """
  One option a layout type accepts, declared with `option name, type` in an option set and listed
  by its `options/0`.

  ## Key Features
  - `layout_type` is the layout the option belongs to (`:index`, `:form`, `:show`, or a host's).
  - `name` is the option as written in the layout, such as `:page_title`.
  - `type` is a `Spark.Options` type. A layout's value for the option is validated against it
    when the layout compiles.

  ## Key Constraints
  - The option's default stays in the option set's `get_default/2`, because most defaults depend
    on the assigns.
  """

  defstruct layout_type: nil, name: nil, type: :any, __spark_metadata__: nil

  @type t() :: %__MODULE__{
          layout_type: atom(),
          name: atom(),
          type: term(),
          __spark_metadata__: term()
        }
end
