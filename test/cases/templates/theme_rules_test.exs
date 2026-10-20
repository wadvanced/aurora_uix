defmodule Aurora.Uix.Templates.ThemeRulesTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Themes.Base
  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase
  alias Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal
  alias Aurora.Uix.Templates.Theme.Rule
  alias Spark.Error.DslError

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

  describe "theme DSL" do
    test "a local rule replaces an included one and keeps its place" do
      theme =
        compile_theme("""
          rule :auix_button, ".auix-button { color: red; }"
          include Aurora.Uix.Templates.Basic.Themes.Base
        """)

      [first | rest] = theme.rules()

      assert %Rule{name: :auix_button, source: :local} = first
      assert theme.rule(:auix_button) == ".auix-button { color: red; }"
      refute Enum.any?(rest, &(&1.name == :auix_button))
      assert Enum.map(rest, & &1.name) == Base.rule_names() -- [:auix_button]
    end

    test "import_rule copies a rule and renames its selector" do
      theme =
        compile_theme("""
          rule :_auix_shared, ".auix-shared { gap: 1px; }"
          rule :auix_copy, "\#{import_rule(:_auix_shared, :auix_copy)} .auix-copy { gap: 2px; }"
        """)

      assert theme.rule(:auix_copy) == ".auix-copy { gap: 1px; } .auix-copy { gap: 2px; }"
    end

    test "an unknown rule name gives empty CSS" do
      assert compile_theme(~s(rule :auix_one, ".auix-one {}")).rule(:auix_two) == ""
    end

    test "a rule declared twice fails compilation" do
      assert_raise DslError, ~r/rule :auix_one is declared more than once/, fn ->
        compile_theme("""
          rule :auix_one, ".auix-one {}"
          rule :auix_one, ".auix-one {}"
        """)
      end
    end

    test "including a module that is not a theme fails compilation" do
      assert_raise DslError, ~r/Aurora.Uix.Guides.Inventory is not a theme/, fn ->
        compile_theme("include Aurora.Uix.Guides.Inventory")
      end
    end

    test "a second include fails compilation" do
      assert_raise DslError, ~r/a theme has at most one include/, fn ->
        compile_theme("""
          include Aurora.Uix.Templates.Basic.Themes.Base
          include Aurora.Uix.Templates.Basic.Themes.Baseline
        """)
      end
    end

    test "a theme with def rule clauses fails compilation" do
      assert_raise DslError, ~r/def rule\/1 clauses are no longer read/, fn ->
        compile_theme(~s[def rule(:root_colors), do: ":root {}"])
      end
    end

    test "importing an unknown rule fails compilation" do
      assert_raise DslError, ~r/import_rule cannot import _auix_missing/, fn ->
        compile_theme(~S[rule :auix_one, "#{import_rule(:_auix_missing, :auix_one)}"])
      end
    end
  end

  @spec compile_theme(binary()) :: module()
  defp compile_theme(body) do
    [{theme, _binary}] =
      Code.compile_string("""
      defmodule Aurora.Uix.Test.ThemeRulesSample#{System.unique_integer([:positive])} do
        use Aurora.Uix.Templates.Theme

      #{body}
      end
      """)

    theme
  end

  @spec find_rule(module(), atom()) :: Rule.t() | nil
  defp find_rule(theme, name), do: Enum.find(theme.rules(), &(&1.name == name))
end
