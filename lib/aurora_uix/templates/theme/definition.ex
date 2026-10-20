defmodule Aurora.Uix.Templates.Theme.Definition do
  @moduledoc """
  The Spark DSL behind `use Aurora.Uix.Templates.Theme`.

  ## Key Features
  - Brings in the theme extension (`Aurora.Uix.Templates.Theme.Extension`).

  ## Key Constraints
  - Used through `use Aurora.Uix.Templates.Theme`.
  """

  use Spark.Dsl, default_extensions: [extensions: [Aurora.Uix.Templates.Theme.Extension]]
end
