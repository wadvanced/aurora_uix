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

  describe "containers" do
    test "a group is a framed container with a title bar" do
      group_container = Base.rule(:auix_group_container)

      assert group_container =~ "border-radius: var(--auix-border-radius-medium)"
      assert group_container =~ ".auix-group-container .auix-group-container"
      assert Base.rule(:auix_group_title) =~ "border-bottom: "

      assert ThemeBase.rule(:root_color_aliases) =~
               "--auix-color-group-container-border: var(--auix-color-border-secondary);"
    end

    test "embedded and one-to-one records share the title-bar frame" do
      assert Base.rule(:auix_embeds_one_container) =~
               ".auix-embeds-one-container > .auix-header .auix-header-title"

      assert Base.rule(:auix_one_to_one_container) =~
               ".auix-one-to-one-container > .auix-header .auix-header-title"
    end

    test "an empty record shows a dashed box" do
      assert Base.rule(:auix_embeds_one_empty_msg) =~ "dashed"

      one_to_one_empty_msg = Base.rule(:auix_one_to_one_empty_msg)

      assert one_to_one_empty_msg =~ ".auix-one-to-one-empty-msg"
      assert one_to_one_empty_msg =~ "dashed"
    end

    test "section tabs join their panel" do
      assert Base.rule(:auix_sections_tab_button__active) =~
               "border-bottom-color: var(--auix-color-sections-tab-active-bg)"

      tab_container = Base.rule(:auix_sections_tab_container)

      assert tab_container =~ "overflow-x: auto"
      refute tab_container =~ "flex-direction: column"
    end

    test "nested sections use smaller tabs" do
      assert Base.rule(:auix_sections_content) =~
               ~r/\.auix-sections-content \.auix-sections-tab-button--active,\s*\.auix-sections-content \.auix-sections-tab-button--inactive \{\s*height: var\(--auix-control-height-compact\);/
    end

    test "form and show content sit in a bordered container" do
      form_container = Base.rule(:auix_form_container)

      assert form_container =~ "border-color: var(--auix-color-form-container-border)"

      assert form_container =~
               ~r/@media \(max-width: 640px\) \{\s*\.auix-form-container \{[^}]*padding: 0;/

      assert Base.rule(:auix_show_container) =~ ".auix-modal-focus-wrap .auix-show-container"
    end
  end
end
