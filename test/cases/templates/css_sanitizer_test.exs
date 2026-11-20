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

  describe "content" do
    test "the loading button keeps its spinner box" do
      css = :auix_button |> Base.rule() |> CssSanitizer.sanitize_css()

      assert css =~ ~s(.auix-button.phx-submit-loading::before { content: "";)
    end

    test "content keeps one plain string and drops any other value" do
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
  end
end
