defmodule Aurora.Uix.Templates.ThemeHelperTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.ThemeHelper

  describe "split stylesheet generation" do
    test "variables stylesheet contains :root declarations but no .auix-* rules" do
      css = ThemeHelper.generate_variables_stylesheet()
      assert css =~ ":root"
      assert css =~ "--auix-"
      refute Regex.match?(~r/\.auix-[a-z-]+\s*\{/, css)
    end

    test "rules stylesheet contains .auix-* selectors but no :root declarations" do
      css = ThemeHelper.generate_rules_stylesheet()
      assert css =~ ".auix-"
      refute Regex.match?(~r/(?:^|\s):root[,\s{]/, css)
    end

    test "split halves recombine to match generate_stylesheet/0 (modulo whitespace)" do
      combined = normalize(ThemeHelper.generate_stylesheet())

      split =
        normalize(
          ThemeHelper.generate_variables_stylesheet() <>
            "\n" <> ThemeHelper.generate_rules_stylesheet()
        )

      assert combined == split
    end
  end

  describe "daisyUI bridge file" do
    test "is shipped and maps base-100 to bg-default" do
      path = Application.app_dir(:aurora_uix, "priv/static/css/auix-bridge-daisyui.css")
      assert File.exists?(path), "bridge file missing at #{path}"
      contents = File.read!(path)
      assert contents =~ "--auix-color-bg-default:"
      assert contents =~ "var(--color-base-100)"
    end
  end

  @spec normalize(String.t()) :: String.t()
  defp normalize(str), do: str |> String.replace(~r/\s+/, " ") |> String.trim()
end
