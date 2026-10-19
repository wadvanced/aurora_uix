defmodule Aurora.Uix.Dsl do
  @moduledoc """
  The Spark DSL behind `use Aurora.Uix`.

  ## Key Features
  - Brings in the resource metadata DSL (`Aurora.Uix.Layout.ResourceMetadata`).

  ## Key Constraints
  - Used through `use Aurora.Uix`, which also sets up the layout macros.
  """

  use Spark.Dsl, default_extensions: [extensions: [Aurora.Uix.Layout.ResourceMetadata]]
end
