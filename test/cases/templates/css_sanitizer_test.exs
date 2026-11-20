defmodule Aurora.Uix.Templates.CssSanitizerTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Themes.Base
  alias Aurora.Uix.Templates.CssSanitizer

  describe "resize" do
    test "the text area rule keeps its resize declarations" do
      css = :_auix_textarea |> Base.rule() |> CssSanitizer.sanitize_css()

      assert css =~ "resize: vertical;"
      assert css =~ "resize: none;"
    end

    test "resize keeps the six keywords and drops any other value" do
      for value <- ~w(none block both vertical horizontal inline) do
        assert CssSanitizer.sanitize_css(".a { resize: #{value}; }") ==
                 ".a { resize: #{value}; }"
      end

      for value <- ["auto", "inherit", "Vertical", "vertical !important", "url(x)"] do
        assert CssSanitizer.sanitize_css(".a { color: red; resize: #{value}; }") ==
                 ".a { color: red; }"
      end
    end
  end
end
