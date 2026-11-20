defmodule Aurora.Uix.Templates.ThemeFramingTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Themes.Base
  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase

  describe "form controls" do
    test "inputs, selects and text areas share the control frame" do
      input = Base.rule(:_auix_input)

      assert input =~ "height: var(--auix-control-height)"
      assert input =~ "border-radius: var(--auix-border-radius-default)"

      assert input =~
               ~r/@media \(max-width: 640px\) \{\s*\.auix-input \{\s*height: var\(--auix-touch-target-size\);/

      select = Base.rule(:auix_select)

      assert select =~ "height: var(--auix-control-height)"
      assert select =~ ~r/\.auix-select\[multiple\] \{\s*height: auto;/

      assert Base.rule(:_auix_textarea) =~ "resize: vertical"
    end

    test "a focused control shows the 3px halo" do
      for rule_name <- [:_auix_input, :_auix_textarea, :auix_select] do
        assert Base.rule(rule_name) =~
                 "box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo)"
      end

      assert ThemeBase.rule(:root_color_aliases) =~
               "--auix-color-input-border-focus: var(--auix-color-focus-ring);"
    end

    test "disabled and read-only controls differ" do
      input = Base.rule(:_auix_input)

      assert input =~
               ~r/\.auix-input:disabled \{\s*background-color: var\(--auix-color-input-bg-disabled\);/

      assert input =~
               ~r/\.auix-input\[readonly\],\s*\.auix-show-content \.auix-input:disabled \{\s*background-color: var\(--auix-color-input-bg-readonly\);/
    end

    test "the error message sits left with a small icon" do
      error_message = Base.rule(:auix_error_message)

      assert error_message =~ "justify-content: flex-start"
      assert error_message =~ ".auix-error-message .auix-icon-size-5"
    end

    test "checkboxes and toggles use the primary color" do
      checkbox = Base.rule(:auix_checkbox)

      assert checkbox =~ "accent-color: var(--auix-color-checkbox-accent)"
      assert checkbox =~ "width: var(--auix-checkbox-size-mobile)"

      toggle = Base.rule(:auix_toggle_pill)

      assert toggle =~ "background-color: var(--auix-color-toggle-on)"
      refute toggle =~ "#16a34a"
    end
  end
end
