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

  describe "buttons and modal" do
    test "buttons share the 40px frame and the focus halo" do
      button_default = Base.rule(:_auix_button_default)

      assert button_default =~ "height: var(--auix-control-height)"
      assert button_default =~ ".auix-button-default:focus-visible"
    end

    test "every variant has a disabled state and the primary a loading state" do
      for rule_name <- [
            :auix_button,
            :auix_button__alt,
            :auix_button__danger,
            :auix_index_all_action_button
          ] do
        assert Base.rule(rule_name) =~ "background-color: var(--auix-color-button-disabled-bg)"
      end

      button = Base.rule(:auix_button)

      assert button =~ ".auix-button.phx-submit-loading::before"
      refute button =~ "[phx-submit-loading]"

      assert ThemeBase.rule(:root_color_aliases) =~
               "--auix-color-button-alt-bg: var(--auix-color-bg-default);"
    end

    test "action buttons become 44px squares on mobile" do
      assert Base.rule(:_auix_button_default) =~
               ~r/@media \(max-width: 640px\) \{\s*\.auix-button-default:has\(> \.auix-action-icon\) \{\s*width: var\(--auix-touch-target-size\);/
    end

    test "the modal floats with its close button at the top right" do
      assert Base.rule(:auix_modal_close_button_container) =~ "position: absolute"

      assert Base.rule(:auix_modal_box) =~
               ~r/@media \(max-width: 640px\) \{\s*\.auix-modal-box \{\s*top: var\(--auix-margin-medium\);/

      close_button = Base.rule(:auix_modal_close_button)

      assert close_button =~ "border-color: var(--auix-color-modal-close-border)"
      refute close_button =~ "opacity"
    end

    test "the record pager centers 32px arrows" do
      navigator_bar = Base.rule(:auix_record_navigator_bar)

      assert navigator_bar =~
               ~r/\.auix-record-navigator-bar > a \{[^}]*width: var\(--auix-row-action-size\);/

      assert navigator_bar =~ ".auix-record-navigator-bar > .auix-icon-inactive"
    end
  end

  describe "index" do
    test "the table sits in a card with a tinted header and marks the sorted column" do
      assert Base.rule(:auix_items_table_container) =~
               "border-radius: var(--auix-border-radius-medium)"

      header = Base.rule(:auix_items_table_header)

      assert header =~ "background-color: var(--auix-color-items-table-header-bg)"
      assert header =~ ~s(th[aria-sort="ascending"])

      assert Base.rule(:auix_items_table_cell) =~ "height: var(--auix-table-row-height)"
    end

    test "a selected row and a selected card use the selection colors" do
      assert Base.rule(:auix_items_table_row) =~
               ".auix-items-table-row:has(> .auix-items-table-cell:first-child .auix-checkbox:checked)"

      assert Base.rule(:auix_items_card_item_content) =~
               "border-color: var(--auix-color-items-card-border-selected)"
    end

    test "row actions are 32px targets" do
      action_cell = Base.rule(:auix_items_table_action_cell)

      assert action_cell =~
               ~r/\.auix-items-table-action-cell \.auix-index-row-action \{[^}]*width: var\(--auix-row-action-size\);/

      refute action_cell =~ "display: flex"
    end

    test "pagination becomes the table card footer" do
      assert Base.rule(:auix_pagination_container) =~
               ~s|.auix-index-container:has(> form .auix-items-desktop) > [name="auix-index-footer-actions"] > .auix-pagination-container|

      assert Base.rule(:auix_pagination_bar_current_page_number) =~
               "border-radius: var(--auix-border-radius-round)"
    end

    test "cards get the new frame and one-to-many lists no outer box" do
      assert Base.rule(:auix_items_card_item_content) =~
               "border-radius: var(--auix-border-radius-medium)"

      refute Base.rule(:auix_one_to_many_container) =~ "border-width"
    end

    test "menus are 12px surfaces with dividers" do
      for rule_name <- [:auix_items_card_menu_list, :auix_index_sort_menu_list] do
        assert Base.rule(rule_name) =~ "border-radius: var(--auix-border-radius-medium)"
      end

      assert Base.rule(:auix_index_sort_menu_group) =~
               "border-top-color: var(--auix-color-menu-divider)"

      assert Base.rule(:auix_index_sort_menu_item) =~
               ":not(:has(.auix-index-sort-menu-check--off))"
    end
  end
end
