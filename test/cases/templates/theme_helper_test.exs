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

    test "checkbox-group and selected-list labels keep their nowrap declaration" do
      css = normalize(ThemeHelper.generate_rules_stylesheet())

      assert css =~ ~r/\.auix-checkbox-group-option-label \{[^}]*white-space: nowrap;/
      assert css =~ ~r/\.auix-selected-list-item \{[^}]*white-space: nowrap;/
    end

    test "group-title and empty-state sizes do not resolve through the page title" do
      css = ThemeHelper.generate_variables_stylesheet()

      assert css =~ "--auix-font-size-group-title: 1.125rem;"
      assert css =~ "--auix-font-size-empty-state: 1.125rem;"
      refute css =~ ~r/--auix-font-size-(?:group-title|empty-state):\s*var\(/
    end

    # Each must be its own terminated declaration: a missing semicolon silently merges the
    # whole run into one custom property, leaving the rest undeclared and every consumer
    # falling back to full opacity.
    test "every opacity variable is a separately terminated numeric declaration" do
      css = ThemeHelper.generate_variables_stylesheet()

      for level <- ["20", "40", "75", "100"] do
        assert css =~ ~r/--auix-opacity-#{level}:\s*[0-9.]+;/
      end
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
