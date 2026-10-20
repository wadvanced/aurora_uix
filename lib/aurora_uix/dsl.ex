defmodule Aurora.Uix.Dsl do
  @moduledoc """
  The Spark DSL behind `use Aurora.Uix`.

  ## Key Features
  - Brings in the resource metadata DSL (`Aurora.Uix.Layout.ResourceMetadata`) and the UI and
    layout DSL (`Aurora.Uix.Layout.CreateUI`).

  ## Key Constraints
  - Used through `use Aurora.Uix`.
  """

  use Spark.Dsl,
    default_extensions: [
      extensions: [Aurora.Uix.Layout.ResourceMetadata, Aurora.Uix.Layout.CreateUI]
    ]
end
