defmodule Aurora.Uix.Layout.Options.Definition do
  @moduledoc """
  The Spark DSL behind `use Aurora.Uix.Layout.Options`.

  ## Key Features
  - Brings in the option set extension (`Aurora.Uix.Layout.Options.Extension`).

  ## Key Constraints
  - Used through `use Aurora.Uix.Layout.Options`.
  """

  use Spark.Dsl, default_extensions: [extensions: [Aurora.Uix.Layout.Options.Extension]]
end
