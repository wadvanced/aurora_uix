defmodule Aurora.Uix.Templates.Theme.Extension do
  @moduledoc """
  Spark extension behind `use Aurora.Uix.Templates.Theme`.

  ## Key Features
  - Declares the `rule` and `include` entities (`Aurora.Uix.Templates.Theme.Extension.Dsl`).
  - `Aurora.Uix.Templates.Theme.Extension.BuildRules` turns them into the theme's rule list and functions.

  ## Key Constraints
  - Used through `use Aurora.Uix.Templates.Theme`.
  """

  use Spark.Dsl.Extension,
    sections: [__MODULE__.Dsl.section()],
    transformers: [__MODULE__.BuildRules]
end
