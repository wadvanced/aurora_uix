defmodule Aurora.Uix.Layout.Options.Extension do
  @moduledoc """
  Spark extension behind `use Aurora.Uix.Layout.Options`.

  ## Key Features
  - Declares the `option` entity (`Aurora.Uix.Layout.Options.Extension.Dsl`).
  - `Aurora.Uix.Layout.Options.Extension.BuildOptions` turns the options into `options/0` and
    `get/2`.

  ## Key Constraints
  - Used through `use Aurora.Uix.Layout.Options`.
  """

  use Spark.Dsl.Extension,
    sections: [__MODULE__.Dsl.section()],
    transformers: [__MODULE__.BuildOptions]
end
