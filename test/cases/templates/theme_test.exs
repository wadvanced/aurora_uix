defmodule Aurora.Uix.Test.Theme.LocalRule do
  use Aurora.Uix.Templates.Theme

  rule(:auix_button, ".auix-button { color: red; }")
  include(Aurora.Uix.Templates.Basic.Themes.Base)
end

defmodule Aurora.Uix.Test.Theme.ImportedRule do
  use Aurora.Uix.Templates.Theme

  rule(:_auix_shared, ".auix-shared { gap: 1px; }")
  rule(:auix_copy, "#{import_rule(:_auix_shared, :auix_copy)} .auix-copy { gap: 2px; }")
end

defmodule Aurora.Uix.Test.Theme.OneRule do
  use Aurora.Uix.Templates.Theme

  rule(:auix_one, ".auix-one {}")
end

defmodule Aurora.Uix.Test.Cases.ThemeTest do
  use ExUnit.Case, async: false

  alias Aurora.Uix.Templates.Basic
  alias Aurora.Uix.Templates.Basic.Themes.Base
  alias Aurora.Uix.Templates.Basic.Themes.BlueGraphite
  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase
  alias Aurora.Uix.Templates.Basic.Themes.VitreousMarble
  alias Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal
  alias Aurora.Uix.Templates.CssSanitizer
  alias Aurora.Uix.Templates.Theme.Rule
  alias Aurora.Uix.Templates.ThemeHelper
  alias Aurora.Uix.Test.Theme
  alias Spark.Error.DslError

  @themes [WhiteCharcoal, VitreousMarble, BlueGraphite]

  test "every theme emits every rule once, with its CSS" do
    for theme <- @themes do
      names = theme.rule_names()

      assert Enum.map(theme.rules(), & &1.name) == names
      assert names == Enum.uniq(names)
      refute Enum.any?(theme.rules(), &(&1.css in [nil, ""]))
    end

    assert %Rule{source: :local, css: css} = find_rule(WhiteCharcoal, :root_colors)
    assert css == WhiteCharcoal.rule(:root_colors)

    %Rule{source: {:theme, source}} = find_rule(WhiteCharcoal, :auix_button)
    refute source in [WhiteCharcoal, ThemeBase]
    assert %Rule{source: :local} = find_rule(source, :auix_button)
  end

  test "the stylesheet splits into variables and rules that recombine, and ships the daisyUI bridge" do
    variables = ThemeHelper.generate_variables_stylesheet()
    rules = ThemeHelper.generate_rules_stylesheet()

    assert variables =~ ":root"
    assert variables =~ "--auix-"
    refute Regex.match?(~r/\.auix-[a-z-]+\s*\{/, variables)

    assert rules =~ ".auix-"
    refute Regex.match?(~r/(?:^|\s):root[,\s{]/, rules)

    assert normalize(ThemeHelper.generate_stylesheet()) == normalize(variables <> "\n" <> rules)

    path = Application.app_dir(:aurora_uix, "priv/static/css/auix-bridge-daisyui.css")
    assert File.exists?(path), "bridge file missing at #{path}"
    contents = File.read!(path)
    assert contents =~ "--auix-color-bg-default:"
    assert contents =~ "var(--color-base-100)"
  end

  test "every variable a rule uses is declared" do
    variables = ThemeHelper.generate_variables_stylesheet()
    rules = ThemeHelper.generate_rules_stylesheet()

    used =
      ~r/var\((--[a-zA-Z0-9_-]+)/ |> Regex.scan(rules, capture: :all_but_first) |> List.flatten()

    declared =
      ~r/(--[a-zA-Z0-9_-]+)\s*:/
      |> Regex.scan(variables <> rules, capture: :all_but_first)
      |> List.flatten()

    assert Enum.uniq(used) -- declared == []

    # A missing semicolon merges the whole run into one custom property, leaving the rest
    # undeclared and every consumer falling back to full opacity.
    for level <- ["20", "40", "75", "100"] do
      assert variables =~ ~r/--auix-opacity-#{level}:\s*[0-9.]+;/
    end
  end

  test "each theme declares every White Charcoal color, light and dark, under its own name" do
    names =
      ~r/^\s*--((?:auix-color|auix-ring)-[a-z0-9-]+):/m
      |> Regex.scan(WhiteCharcoal.rule(:root_colors), capture: :all_but_first)
      |> List.flatten()
      |> Enum.uniq()

    assert names != []

    status_names =
      ~w(auix-color-focus-ring-halo auix-color-success-bg auix-color-success-border
         auix-color-success-text auix-color-warning-bg auix-color-warning-border
         auix-color-warning-text auix-color-selection-bg auix-color-selection-border)

    white_charcoal_css = WhiteCharcoal.rule(:root_colors)

    for color <- status_names do
      assert white_charcoal_css =~ ~r/^\s*--#{color}: (#|rgba\()/m,
             "WhiteCharcoal lacks --#{color}"

      assert white_charcoal_css =~ ~r/--dark--#{color}: (#|rgba\()/,
             "WhiteCharcoal lacks --dark--#{color}"

      assert length(String.split(white_charcoal_css, "--#{color}: var(--dark--#{color});")) == 3
    end

    for theme <- [VitreousMarble, BlueGraphite] do
      name = Atom.to_string(theme.theme_name())
      css = theme.rule(:root_colors)

      assert ThemeHelper.registered_themes()[theme.theme_name()] == theme
      assert ThemeHelper.generate_variables_stylesheet() =~ ~s([data-theme-name="#{name}"])

      for color <- names do
        assert css =~ ~r/^\s*--#{color}: (#|rgba\()/m, "#{inspect(theme)} lacks --#{color}"
        assert css =~ "--dark--#{color}: ", "#{inspect(theme)} lacks --dark--#{color}"
        assert length(String.split(css, "--#{color}: var(--dark--#{color});")) == 3
      end

      selectors = ~r/(?::root|:host)[^,{]*/ |> Regex.scan(css) |> List.flatten()

      assert selectors != []
      assert Enum.all?(selectors, &String.contains?(&1, ~s([data-theme-name="#{name}"])))
    end

    assert Basic.default_theme_name() == :white_charcoal
  end

  test "the sanitizer keeps allowed values and drops the rest" do
    for value <- ~w(none block both vertical horizontal inline) do
      assert CssSanitizer.sanitize_css(".a { resize: #{value}; }") == ".a { resize: #{value}; }"
    end

    for value <- ["auto", "inherit", "Vertical", "vertical !important", "url(x)"] do
      assert CssSanitizer.sanitize_css(".a { color: red; resize: #{value}; }") ==
               ".a { color: red; }"
    end

    for value <- [~s(""), ~s(''), ~s("*"), ~s('a b')] do
      assert CssSanitizer.sanitize_css(".a { content: #{value}; }") ==
               ".a { content: #{value}; }"
    end

    for value <- [
          "url(a.png)",
          "attr(title)",
          "counter(item)",
          ~s[image-set("a.png" 1x)],
          "none",
          ~S("\201C"),
          ~s("a" "b"),
          ~s["x(y)"],
          ~s["a'b"]
        ] do
      assert CssSanitizer.sanitize_css(".a { color: red; content: #{value}; }") ==
               ".a { color: red; }"
    end

    assert CssSanitizer.sanitize_css(
             ".a { justify-content: center; align-content: start; content-visibility: auto; }"
           ) ==
             ".a { justify-content: center; align-content: start; content-visibility: auto; }"
  end

  describe "theme DSL" do
    test "a theme replaces and imports rules" do
      [first | rest] = Theme.LocalRule.rules()

      assert %Rule{name: :auix_button, source: :local} = first
      assert Theme.LocalRule.rule(:auix_button) == ".auix-button { color: red; }"
      refute Enum.any?(rest, &(&1.name == :auix_button))
      assert Enum.map(rest, & &1.name) == Base.rule_names() -- [:auix_button]

      assert Theme.ImportedRule.rule(:auix_copy) ==
               ".auix-copy { gap: 1px; } .auix-copy { gap: 2px; }"

      assert Theme.OneRule.rule(:auix_two) == ""
    end

    test "theme declarations that must fail compilation" do
      cases = [
        {"a rule declared twice",
         """
           rule :auix_one, ".auix-one {}"
           rule :auix_one, ".auix-one {}"
         """, ~r/rule :auix_one is declared more than once/},
        {"including a module that is not a theme", "include Aurora.Uix.Guides.Inventory",
         ~r/Aurora.Uix.Guides.Inventory is not a theme/},
        {"a second include",
         """
           include Aurora.Uix.Templates.Basic.Themes.Base
           include Aurora.Uix.Templates.Basic.Themes.Baseline
         """, ~r/a theme has at most one include/},
        {"a theme with def rule clauses", ~s[def rule(:root_colors), do: ":root {}"],
         ~r/def rule\/1 clauses are no longer read/},
        {"importing an unknown rule",
         ~S[rule :auix_one, "#{import_rule(:_auix_missing, :auix_one)}"],
         ~r/import_rule cannot import _auix_missing/}
      ]

      for {_label, body, regex} <- cases do
        assert_raise DslError, regex, fn -> compile_theme(body) end
      end
    end
  end

  @spec compile_theme(binary()) :: module()
  defp compile_theme(body) do
    [{theme, _binary}] =
      Code.compile_string("""
      defmodule Aurora.Uix.Test.ThemeSample#{System.unique_integer([:positive])} do
        use Aurora.Uix.Templates.Theme

      #{body}
      end
      """)

    theme
  end

  @spec find_rule(module(), atom()) :: Rule.t() | nil
  defp find_rule(theme, name), do: Enum.find(theme.rules(), &(&1.name == name))

  @spec normalize(String.t()) :: String.t()
  defp normalize(str), do: str |> String.replace(~r/\s+/, " ") |> String.trim()
end
