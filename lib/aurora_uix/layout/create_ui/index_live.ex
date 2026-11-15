defmodule Aurora.Uix.Layout.CreateUI.IndexLive do
  @moduledoc """
  One `index_live` line of `auix_create_ui`, as Spark reads it.

  ## Key Features
  - One `index_live` line of `auix_create_ui`: the resource and the name of its LiveView.

  ## Key Constraints
  - It names a module; it is not a layout and has no fields.
  """

  defstruct resource: nil, module_name: nil, __spark_metadata__: nil

  @type t() :: %__MODULE__{
          resource: atom(),
          module_name: atom(),
          __spark_metadata__: term()
        }
end
