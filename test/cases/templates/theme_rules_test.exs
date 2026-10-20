defmodule Aurora.Uix.Templates.ThemeRulesTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase
  alias Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal
  alias Aurora.Uix.Templates.Theme.Rule

  describe "rules/0" do
    test "lists each rule name once, in rule_names/0 order" do
      names = Enum.map(WhiteCharcoal.rules(), & &1.name)

      assert names == WhiteCharcoal.rule_names()
      assert names == Enum.uniq(names)
    end

    test "a rule defined by the theme is local and carries its CSS" do
      assert %Rule{source: :local, css: css} = find_rule(WhiteCharcoal, :root_colors)
      assert css == WhiteCharcoal.rule(:root_colors)
    end

    test "a delegated rule keeps the theme that defines it" do
      %Rule{source: {:theme, source}} = find_rule(WhiteCharcoal, :auix_button)

      refute source in [WhiteCharcoal, ThemeBase]
      assert %Rule{source: :local} = find_rule(source, :auix_button)
    end
  end

  @spec find_rule(module(), atom()) :: Rule.t() | nil
  defp find_rule(theme, name), do: Enum.find(theme.rules(), &(&1.name == name))
end
