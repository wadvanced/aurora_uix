defmodule Aurora.Uix.Templates.Theme.Extension.Dsl do
  @moduledoc """
  Entities of the theme DSL (`Aurora.Uix.Templates.Theme.Extension`).

  ## Key Features
  - `section/0` is the top-level section holding `rule` and `include`, in the order they are
    written.

  ## Key Constraints
  - A rule's CSS is evaluated when the theme compiles, so it cannot call the theme's own
    functions.
  """

  alias Aurora.Uix.Templates.Theme.Include
  alias Aurora.Uix.Templates.Theme.Rule
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Section

  @rule %Entity{
    name: :rule,
    describe: "Declares one CSS rule of the theme.",
    target: Rule,
    args: [:name, :css],
    schema: [
      name: [type: :atom, required: true, doc: "The rule name, such as `:auix_button`."],
      css: [type: :string, required: true, doc: "The rule's CSS."]
    ]
  }

  @include %Entity{
    name: :include,
    describe: "Takes every rule of another theme, except the ones this theme declares.",
    target: Include,
    args: [:theme],
    schema: [theme: [type: :atom, required: true, doc: "The theme module."]]
  }

  @theme %Section{
    name: :auix_theme,
    top_level?: true,
    describe: "The rules of a theme.",
    entities: [@rule, @include]
  }

  @doc """
  Returns the `auix_theme` top-level section.
  """
  @spec section() :: Section.t()
  def section, do: @theme
end
