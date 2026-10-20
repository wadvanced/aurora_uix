defmodule Aurora.Uix.Layout.Options.Extension.Dsl do
  @moduledoc """
  Entities of the layout option set DSL (`Aurora.Uix.Layout.Options.Extension`).

  ## Key Features
  - `section/0` is the top-level section holding the `option` entities, in the order they are
    written.

  ## Key Constraints
  - An option's type is a `Spark.Options` type.
  """

  alias Aurora.Uix.Layout.Options.Option
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Section

  @option %Entity{
    name: :option,
    describe: "Declares one option the layout type accepts.",
    target: Option,
    args: [:name, :type],
    schema: [
      name: [type: :atom, required: true, doc: "The option, such as `:page_title`."],
      type: [type: :any, required: true, doc: "The `Spark.Options` type of the option's value."]
    ]
  }

  @options %Section{
    name: :auix_layout_options,
    top_level?: true,
    describe: "The options of a layout type.",
    entities: [@option]
  }

  @doc """
  Returns the `auix_layout_options` top-level section.
  """
  @spec section() :: Section.t()
  def section, do: @options
end
