defmodule Aurora.Uix.Templates.Basic.Themes.Base do
  @moduledoc """
  The base theme for the Basic template.

  This theme defines a set of CSS rules for the base theme.
  """
  use Aurora.Uix.Templates.Theme

  import Aurora.Uix.Templates.Basic.Themes.Breakpoints, only: [breakpoint: 1]

  # ---  BASE RULES --#
  rule(:_auix_button_default, """
  .auix-button-default {
    display: flex;
    flex-direction: row;
    align-items: center;

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-small);
    padding: var(--auix-padding-minimal);

    font-size: var(--auix-font-size-caption);
    font-weight: var(--auix-font-weight-bold);
  }
  """)

  rule(:_auix_flash, """
  .auix-flash {
    position: fixed;
    top: var(--auix-margin-medium);
    right: var(--auix-margin-medium);
    z-index: 50;

    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);
    max-width: min(var(--auix-flash-max-width), calc(100vw - 1rem));

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-nested);
    padding: var(--auix-padding-control) 0.875rem;
    box-shadow: var(--auix-shadow-lg);

    font-size: var(--auix-font-size-caption);
    line-height: var(--auix-line-height-default);
  }
  """)

  rule(:_auix_actions, """
  .auix-actions {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:_auix_textarea, """
  .auix-textarea {
    box-sizing: border-box;
    display: block;
    min-height: 5.25rem;
    margin: 0;
    padding: var(--auix-padding-default) var(--auix-padding-control);

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-default);

    font-family: inherit;
    font-size: var(--auix-font-size-caption);
    line-height: var(--auix-line-height-default);
    resize: vertical;

    color: var(--auix-color-textarea-text);
    background-color: var(--auix-color-input-bg);
    caret-color: var(--auix-color-textarea-text);
  }

  .auix-textarea:focus {
    outline: none;
    box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
  }

  .auix-textarea:disabled {
    background-color: var(--auix-color-input-bg-disabled);
    border-color: var(--auix-color-input-border-disabled);
    color: var(--auix-color-input-text-disabled);
    cursor: not-allowed;
  }

  .auix-textarea[readonly],
  .auix-show-content .auix-textarea:disabled {
    background-color: var(--auix-color-input-bg-readonly);
    border-color: var(--auix-color-input-border-disabled);
    color: var(--auix-color-textarea-text);
    resize: none;
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-textarea {
      font-size: var(--auix-font-size-input-mobile);
      line-height: var(--auix-line-height-relaxed);
    }
  }
  """)

  rule(:_auix_input, """
  .auix-input {
    box-sizing: border-box;
    height: var(--auix-control-height);
    margin: 0;
    padding: 0 var(--auix-padding-control);

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-default);

    font-size: var(--auix-font-size-caption);
    color: var(--auix-color-input-text);
    background-color: var(--auix-color-input-bg);
    caret-color: var(--auix-color-input-text);
  }

  .auix-input:focus {
    outline: none;
    box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
  }

  .auix-input:disabled {
    background-color: var(--auix-color-input-bg-disabled);
    border-color: var(--auix-color-input-border-disabled);
    color: var(--auix-color-input-text-disabled);
    cursor: not-allowed;
  }

  .auix-input[readonly],
  .auix-show-content .auix-input:disabled {
    background-color: var(--auix-color-input-bg-readonly);
    border-color: var(--auix-color-input-border-disabled);
    color: var(--auix-color-input-text);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-input {
      height: var(--auix-touch-target-size);
      font-size: var(--auix-font-size-input-mobile);
    }
  }
  """)

  rule(:_auix_sections_tab_button, """
  .auix-sections-tab-button {
    flex-shrink: 0;
    height: var(--auix-control-height);
    padding: 0 var(--auix-padding-panel);
    border: var(--auix-border-width-default) var(--auix-border-style-default) transparent;
    border-radius: var(--auix-border-radius-default) var(--auix-border-radius-default) 0 0;
    font-size: var(--auix-font-size-caption);
    white-space: nowrap;
    cursor: pointer;
  }

  .auix-sections-tab-button:focus-visible {
    outline: none;
    border-color: var(--auix-color-focus-ring);
    box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-sections-tab-button {
      height: var(--auix-touch-target-size);
      padding: 0 0.875rem;
    }
  }
  """)

  # --- ACTIVE RULES -- #
  rule(:auix_horizontal_divider, """
  .auix-horizontal-divider {
    border-top: var(--auix-border-width-default) solid var(--auix-color-horizontal-divider);
    margin-top: var(--auix-margin-default);
    margin-bottom: var(--auix-margin-default);
  }
  """)

  rule(:auix_modal, """
    .auix-modal {
      display: none;
      position: relative; 
      z-index: 50; 
    }
  """)

  rule(:auix_modal_background, """
    .auix-modal-background {
      background-color: var(--auix-color-bg-backdrop);

      position: fixed;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;

      transition-property: opacity;
      transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
      transition-duration: 150ms;
    }
  """)

  rule(:auix_modal_container, """
    .auix-modal-container {
      position: fixed;
      top: 0;
      right: 0;
      bottom: 0;
      left: 0;
      overflow-y: auto;
      overflow-x: auto;
    }
  """)

  rule(:auix_modal_content, """
  .auix-modal-content {
    display: flex;
    min-height: 100%;
    align-items: center;
    justify-content: center;
  }
  """)

  rule(:auix_modal_box, """
    .auix-modal-box {
      position: absolute;
      top: 0;
      margin-left: auto;              
      margin-right: auto;             
    }

  """)

  rule(:auix_modal_box_content, """
  .auix-modal-box-content {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_modal_focus_wrap, """
    .auix-modal-focus-wrap {

      position: relative;            

      border-radius: var(--auix-border-radius-large);
      background-color: var(--auix-color-bg-default); 
      padding: var(--auix-padding-xl); 

      --auix-calc-shadow: var(--auix-shadow-lg), var(--auix-shadow-secondary);

      box-shadow:
        var(--auix-ring-offset-shadow),
        var(--auix-ring-secondary),
        var(--auix-calc-shadow);

      border-width: var(--auix-border-width-default);

      transition-property: color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter;
      transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
      transition-duration: 150ms;
    }
  """)

  rule(:auix_modal_close_button_container, """
    .auix-modal-close-button-container {
      display: flex;
      flex-direction: row;
      justify-content: flex-end;
    }
  """)

  rule(:auix_discard_confirm, """
  .auix-discard-confirm {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_discard_confirm_message, """
  .auix-discard-confirm-message {
    font-size: var(--auix-font-size-caption);
  }
  """)

  rule(:auix_discard_confirm_actions, """
  .auix-discard-confirm-actions {
    display: flex;
    justify-content: flex-end;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_modal_close_button, """
    .auix-modal-close-button {
      display: flex;
      padding: 0;
      border-width: var(--auix-border-width-default);
      border-radius: var(--auix-border-radius-small);
      opacity: var(--auix-opacity-20);              
    }

    .auix-modal-close-button:hover {
      cursor: pointer;
      opacity: var(--auix-opacity-40);              
    }
  """)

  rule(:auix_flash__info, """
  /* auix-flash--info */

  #{import_rule(:_auix_flash, :auix_flash__info)}

  .auix-flash--info {
    background-color: var(--auix-color-bg-info);
    border-color: var(--auix-color-info-ring);
    color: var(--auix-color-info-text);
    fill: var(--auix-color-icon-fill);
  }
  """)

  rule(:auix_flash__error, """
  #{import_rule(:_auix_flash, :auix_flash__error)}

  .auix-flash--error {
    background-color: var(--auix-color-error-bg);
    border-color: var(--auix-color-error-ring);
    color: var(--auix-color-error-text);
    fill: var(--auix-color-error-text);
  }
  """)

  rule(:auix_flash__success, """
  #{import_rule(:_auix_flash, :auix_flash__success)}

  .auix-flash--success {
    background-color: var(--auix-color-success-bg);
    border-color: var(--auix-color-success-border);
    color: var(--auix-color-success-text);
    fill: var(--auix-color-success-text);
  }
  """)

  rule(:auix_flash__warning, """
  #{import_rule(:_auix_flash, :auix_flash__warning)}

  .auix-flash--warning {
    background-color: var(--auix-color-warning-bg);
    border-color: var(--auix-color-warning-border);
    color: var(--auix-color-warning-text);
    fill: var(--auix-color-warning-text);
  }
  """)

  rule(:auix_flash_title, """
  .auix-flash-title {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
    gap: var(--auix-gap-medium);

    font-size: var(--auix-font-size-caption);
    font-weight: var(--auix-font-weight-bold);
  }

  .auix-flash-title > div {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: var(--auix-gap-medium);
  }
  """)

  rule(:auix_flash_message, """
  .auix-flash-message {
    font-size: var(--auix-font-size-caption);
    line-height: var(--auix-line-height-default);
  }
  """)

  rule(:auix_flash_close_button, """
  .auix-flash-close-button {
    display: inline-flex;
    align-items: center;
    padding: 0;
    background: transparent;
    border: none;
    color: var(--auix-color-flash-close-text);
    cursor: pointer;
  }
  """)

  rule(:auix_simple_form_content, """
  .auix-simple-form-content {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-xl);
    background-color: transparent;
  }
  """)

  rule(:auix_simple_form_actions, """
  /* auix-simple-form-actions */

  #{import_rule(:_auix_actions, :auix_simple_form_actions)}
  """)

  rule(:auix_button, """
  /* auix-button */
  #{import_rule(:_auix_button_default, :auix_button)}

  .auix-button {
    background-color: var(--auix-color-button-bg);
    color: var(--auix-color-button-text);
  }

  .auix-button:hover {
    background-color: var(--auix-color-bg-hover--reverted);
    cursor: pointer;
  }

  .auix-button:active {
    color: var(--auix-color-text-on-accent-active);
  }

  .auix-button[phx-submit-loading] {
    opacity: var(--auix-opacity-75);
  }
  """)

  rule(:auix_button__alt, """
  /* auix-button--alt */
  #{import_rule(:_auix_button_default, :auix_button__alt)}

  .auix-button--alt {
    background-color: var(--auix-color-button-alt-bg);
    color: var(--auix-color-button-alt-text);
    border-color: var(--auix-color-button-alt-border);         
  }

  .auix-button--alt:disabled {
    background-color: var(--auix-color-bg-backdrop);
    color: var(--auix-color-text-inactive);
  }

  .auix-button--alt:hover {
    background-color: var(--auix-color-bg-hover);
    cursor: pointer;
  }
  """)

  rule(:auix_button_badge, """
  /* auix-button-badge */
  #{import_rule(:_auix_button_default, :auix_button_badge)}

  .auix-button-badge {
    font-size: var(--auix-font-size-small);
    border-radius: var(--auix-border-radius-round);
    padding-top: 0;
    padding-bottom: 0;
    padding-left: var(--auix-padding-minimal);
    padding-right: var(--auix-padding-minimal);
  }
  """)

  rule(:auix_button__iconized, """
  .auix-button--iconized {
    background-color: transparent;
    border: none;
    padding: 0;
    margin: 0;
  }
  .auix-button--iconized:hover {
    background-color: var(--auix-color-bg-secondary);
    cursor: pointer;
  }
  """)

  rule(:auix_action_icon, """
  /* auix-action-icon */
  .auix-action-icon {
    display: none;
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-action-icon {
      display: inline-flex;
      align-items: center;
    }
  }
  """)

  rule(:auix_action_label, """
  /* auix-action-label */
  @media (max-width: #{breakpoint(:sm)}) {
    .auix-action-label {
      display: none;
    }
  }
  """)

  rule(:auix_action_icon_image, """
  /* auix-action-icon-image */
  .auix-action-icon-image {
    display: inline-block;
    vertical-align: middle;
    object-fit: contain;
  }
  """)

  rule(:auix_action_icon_text, """
  /* auix-action-icon-text */
  .auix-action-icon-text {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    line-height: 1;
  }
  """)

  rule(:auix_button_toggle_filters_container, """
  .auix-button-toggle-filters-container {
    border: none;
  }
  """)

  rule(:auix_button_toggle_filters_content, """
  .auix-button-toggle-filters-content {
    display: flex;
    flex-direction: row;
    align-items: center;
    font-size: var(--auix-font-size-caption);
    font-weight: var(--auix-font-weight-bold);
  }
  """)

  rule(:auix_button_toggle_filters_close_link, """
  .auix-button-toggle-filters-close-link {
    display: flex;
    flex-direction: column-reverse;
    align-items: center;
  }
  """)

  rule(:auix_fieldset, """
  .auix-fieldset {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-label);

    min-width: 0;
    margin: 0;
    padding: 0;
    border-width: 0;
    font-size: var(--auix-font-size-caption);
  }
  """)

  rule(:auix_checkbox, """
  .auix-checkbox {
    display: inline-block;
    vertical-align: middle;
    flex-shrink: 0;

    width: var(--auix-checkbox-size);
    height: var(--auix-checkbox-size);
    margin: 0;
    padding: 0;

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-small);
    border-color: var(--auix-color-checkbox-border);
    background-color: var(--auix-color-bg-default);
    color: var(--auix-color-checkbox-text);
    accent-color: var(--auix-color-checkbox-accent);

    box-shadow: none;
    outline: none;
    background-image: none;
  }

  .auix-checkbox:focus-visible {
    box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
  }

  .auix-checkbox:disabled {
    background-color: var(--auix-color-bg-light);
    color: var(--auix-color-text-secondary);

    opacity: var(--auix-opacity-100);
    cursor: not-allowed;
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-checkbox {
      width: var(--auix-checkbox-size-mobile);
      height: var(--auix-checkbox-size-mobile);
    }
  }
  """)

  rule(:auix_checkbox__mixed, """
  /* A partial selection: neither checked nor unchecked, drawn as a dash. The native
     `indeterminate` state is a DOM property that only JavaScript can set, so the box opts out of
     native rendering and paints the dash itself -- same data-URI technique as .auix-select. */
  .auix-checkbox--mixed {
    appearance: none;
    -webkit-appearance: none;
    -moz-appearance: none;

    background-image: url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M6 12H18' stroke='currentColor' stroke-width='3' stroke-linecap='round'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: center;
    background-size: 100% 100%;
  }
  """)

  rule(:auix_confirm_button_container, """
    .auix-confirm-button--container {
      visibility: visible;
    }
  """)

  rule(:auix_confirm_button__modal, """
    .auix-confirm-button--modal {
      display: flex;
      flex-direction: column;
      align-items: center; 
    }
  """)

  rule(:auix_confirm_button__confirm_message, """
    .auix-confirm-button--confirm-message {
    }
  """)

  rule(:auix_confirm_button__actions, """
    .auix-confirm-button--actions {
      margin-top: var(--auix-margin-default);
      display: flex;
      flex-direction: row;
      justify-content: center;
      gap: var(--auix-gap-default);
    }

  """)

  rule(:auix_confirm_button__accept_action, """
    .auix-confirm-button--accept-action {

    }

  """)

  rule(:auix_confirm_button__cancel_action, """
    .auix-confirm-button--cancel-action {

    }

  """)

  rule(:auix_checkbox_label, """
  .auix-checkbox-label {
    display: flex;
    align-items: center;
    gap: var(--auix-gap-medium);
    font-size: var(--auix-font-size-caption);
    color: var(--auix-color-checkbox-label-text);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-checkbox-label {
      min-height: var(--auix-touch-target-size);
    }
  }
  """)

  rule(:auix_checkbox_group, """
    .auix-checkbox-group {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);

      max-height: var(--auix-checkbox-group-max-height);
      overflow-y: auto;
      overflow-x: auto;
    }
  """)

  rule(:auix_checkbox_group_header, """
    .auix-checkbox-group-header {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
      gap: var(--auix-gap-default);
    }
  """)

  rule(:auix_checkbox_group_label, """
  .auix-checkbox-group-label {
    content-visibility: visible;
  }
  """)

  rule(:auix_checkbox_group_label_container, """
    .auix-checkbox-group-label-container {
      display: flex;
      flex-direction: row;
      flex-wrap: nowrap;
      align-items: center;
      gap: var(--auix-gap-default);
    }
  """)

  rule(:auix_checkbox_group_label_actions, """
    .auix-checkbox-group-label-actions {
      display: flex;
      flex-direction: row;
      flex-wrap: nowrap;
      align-items: center;
      gap: var(--auix-gap-default);
    }

    /* The toggle-all renders through `.input`, which wraps every control in a fieldset. Strip
       its block spacing so the checkbox sits on the label's baseline. */
    .auix-checkbox-group-label-actions .auix-fieldset {
      padding-block: 0;
      margin: 0;
    }
  """)

  rule(:auix_checkbox_group_actions, """
  /* auix-checkbox-group-actions */

  #{import_rule(:_auix_actions, :auix_checkbox_group_actions)}
  .auix-checkbox-group-actions {
    flex-direction: row;
    flex-wrap: nowrap;
    justify-content: flex-end;
  }
  """)

  rule(:auix_checkbox_group_option_label, """
    .auix-checkbox-group-option-label {
      font-size: var(--auix-font-size-caption);
      color: var(--auix-color-checkbox-label-text);
      white-space: nowrap;
    }
  """)

  rule(:auix_checkbox_group_empty_msg, """
  .auix-checkbox-group-empty-msg {
     font-size: var(--auix-font-size-small);
     font-style: var(--auix-font-style-mobile-viewmode);
  }
  """)

  rule(:auix_selected_list, """
    .auix-selected-list {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);

      max-height: var(--auix-checkbox-group-max-height);
      overflow-y: auto;
      overflow-x: auto;
    }
  """)

  rule(:auix_selected_list_label, """
  .auix-selected-list-label {
    content-visibility: visible;
  }
  """)

  rule(:auix_selected_list_items, """
    .auix-selected-list-items {
      list-style-type: disc;
      padding-inline-start: var(--auix-gap-large);
      margin: 0;
    }
  """)

  rule(:auix_selected_list_item, """
    .auix-selected-list-item {
      font-size: var(--auix-font-size-caption);
      color: var(--auix-color-checkbox-label-text);
      white-space: nowrap;
    }
  """)

  rule(:auix_selected_list_empty_msg, """
  .auix-selected-list-empty-msg {
     font-size: var(--auix-font-size-small);
     font-style: var(--auix-font-style-mobile-viewmode);
  }
  """)

  rule(:auix_select, """
  .auix-select {
    box-sizing: border-box;
    height: var(--auix-control-height);
    margin: 0;
    padding: 0 var(--auix-padding-control);

    border-radius: var(--auix-border-radius-default);
    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-color: var(--auix-color-select-border);

    appearance: none;
    -webkit-appearance: none;
    -moz-appearance: none;
    background-position: right var(--auix-padding-control) center;
    background-repeat: no-repeat;
    background-size: var(--auix-box-size-unit) var(--auix-box-size-unit);
    background-color: var(--auix-color-input-bg);

    font-size: var(--auix-font-size-caption);
    color: var(--auix-color-input-text);
  }
  .auix-select:not(:disabled) {
    background-image: url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M6 9L12 15L18 9' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
    padding-right: 2.25rem;
  }
  .auix-select:disabled {
    background-image: none;
    background-color: var(--auix-color-input-bg-disabled);
    border-color: var(--auix-color-input-border-disabled);
    color: var(--auix-color-input-text-disabled);
    cursor: not-allowed;
  }
  .auix-show-content .auix-select:disabled {
    background-color: var(--auix-color-input-bg-readonly);
    color: var(--auix-color-input-text);
  }
  .auix-select[multiple] {
    height: auto;
    padding: var(--auix-padding-medium) var(--auix-padding-control);
    background-image: none;
  }

  .auix-select:focus {
    border-color: var(--auix-color-select-border-focus);
    outline: none;
    box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-select {
      height: var(--auix-touch-target-size);
      font-size: var(--auix-font-size-input-mobile);
    }
    .auix-select[multiple] {
      height: auto;
    }
  }
  """)

  rule(:auix_select_label, """
  .auix-select-label {
    content-visibility: visible;
  }
  """)

  rule(:auix_textarea, """
  /* auix-textarea */
  #{import_rule(:_auix_textarea, :auix_textarea)}

  .auix-textarea {
    border-color: var(--auix-color-textarea-border);
  }
  .auix-textarea:focus {
    border-color: var(--auix-color-textarea-border-focus);
  }
  """)

  rule(:auix_textarea__errors, """
  /* auix-textarea--errors */
  #{import_rule(:_auix_textarea, :auix_textarea__errors)}

  .auix-textarea--errors {
    border-color: var(--auix-color-textarea-border-error);
  }

  .auix-textarea--errors:focus {
    border-color: var(--auix-color-textarea-border-error);
  }
  """)

  rule(:auix_input, """
    /* auix-input */
    #{import_rule(:_auix_input, :auix_input)}

    .auix-input {
      border-color: var(--auix-color-input-border);
    }
    .auix-input:focus {
      border-color: var(--auix-color-input-border-focus);
    }
  """)

  rule(:auix_input__errors, """
    /* auix-input--errors */
    #{import_rule(:_auix_input, :auix_input__errors)}

    .auix-input--errors {
      border-color: var(--auix-color-input-border-error); 
    }
    .auix-input--errors:focus {
      border-color: var(--auix-color-input-border-error); 
    }
  """)

  rule(:auix_copyable_button, """
  .auix-copyable-container {
    display: flex;
    align-items: center;
    gap: var(--auix-gap-default);
  }

  .auix-copyable-container .auix-input,
  .auix-copyable-container .auix-input--errors,
  .auix-copyable-container .auix-textarea,
  .auix-copyable-container .auix-textarea--errors {
    flex: 1 1 auto;
  }

  .auix-copyable-container--textarea {
    align-items: flex-start;
  }

  .auix-copyable-button {
    position: relative;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: var(--auix-padding-small);
    cursor: pointer;
    color: var(--auix-color-input-text);
    background-color: transparent;
    border: none;
  }

  .auix-copyable-toast {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 9999;
    padding: var(--auix-padding-small);
    border-radius: var(--auix-border-radius-small);
    font-size: var(--auix-font-size-small);
    white-space: nowrap;
    color: var(--auix-color-info-text);
    background-color: var(--auix-color-bg-info);
    opacity: 0;
    pointer-events: none;
    transition: opacity 150ms ease-in-out;
  }

  .auix-copyable-toast--visible {
    opacity: 1;
  }
  """)

  rule(:auix_label, """
  .auix-label {
    font-size: var(--auix-font-size-label);
    font-weight: var(--auix-font-weight-medium);
    color: var(--auix-color-label-text);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-label {
      font-size: var(--auix-font-size-caption);
    }
  }
  """)

  rule(:auix_error_message, """
  .auix-error-message {
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    align-items: center;
    gap: var(--auix-gap-label);

    margin: 0;
    font-size: var(--auix-font-size-small);
    line-height: 1rem;
    color: var(--auix-color-error-text-default);
  }

  .auix-error-message .auix-icon-size-5 {
    flex-shrink: 0;
    width: 0.875rem;
    height: 0.875rem;
  }
  """)

  rule(:auix_header, """
  .auix-header{
    margin-bottom: 0;
  }
  """)

  rule(:auix_header__top_actions, """
  /* auix-header--top-actions */

  #{import_rule(:_auix_actions, :auix_header__top_actions)}

  .auix-header--top-actions {
    padding: var(--auix-padding-minimal);
  }
  """)

  rule(:auix_header_title_container, """
  .auix-header-title-container {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_header_title, """
  .auix-header-title {
    margin: 0;
    font-size: var(--auix-font-size-title);
    font-weight: var(--auix-font-weight-bold);
    line-height: var(--auix-line-height-title);
    color: var(--auix-color-header-title-text);
  }

  .auix-index-container > .auix-header .auix-header-title,
  .auix-index-container > .auix-header--top-actions .auix-header-title {
    font-size: var(--auix-font-size-page-title);
    line-height: 2rem;
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-header-title {
      font-size: var(--auix-font-size-subtitle);
      line-height: var(--auix-line-height-relaxed);
    }

    .auix-index-container > .auix-header .auix-header-title,
    .auix-index-container > .auix-header--top-actions .auix-header-title {
      font-size: var(--auix-font-size-title);
      line-height: var(--auix-line-height-title);
    }
  }
  """)

  rule(:auix_header_subtitle, """
  .auix-header-subtitle {
    margin-top: 0;
    margin-bottom: 0;
    font-size: var(--auix-font-size-caption);
    line-height: var(--auix-line-height-default);
    color: var(--auix-color-header-subtitle-text);
  }
  """)

  rule(:auix_header__bottom_actions, """
    .auix-header--bottom-actions {
      flex-shrink: 0;
      flex-grow: 0;
    }
  """)

  rule(:auix_list, """
    .auix-list {
      margin-top: 3.5rem; 
    }
  """)

  rule(:auix_list_container, """
    .auix-list-container {
      margin-top: -1rem;
      margin-bottom: -1rem;

      --auix-divide-y-reverse: 0;
    }

    .auix-list-container > :not([hidden]) ~ :not([hidden]) {
      border-top-width: calc(1px * calc(1 - var(--auix-divide-y-reverse)));
      border-bottom-width: calc(1px * var(--auix-divide-y-reverse));
      border-style: var(--auix-border-style-default); 

      border-color: var(--auix-color-list-container-divider);
    }
  """)

  rule(:auix_list_item, """
    .auix-list-item {
      display: flex;                 
      gap: 1rem;                     
      padding-top: 1rem;             
      padding-bottom: 1rem;          
      font-size: var(--auix-font-size-caption);           
      line-height: var(--auix-line-height-relaxed);           
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-list-item {
        gap: 2rem;                   
      }
    }
  """)

  rule(:auix_list_item_title, """
  .auix-list-item-title {
    width: 25%;
    flex-shrink: 0;
    flex-grow: 0;
    color: var(--auix-color-list-item-title-text);
  }
  """)

  rule(:auix_list_item_content, """
  .auix-list-item-content {
    color: var(--auix-color-list-item-content-text);
  }
  """)

  rule(:auix_back_link_container, """
  .auix-back-link-container {
  }
  """)

  rule(:auix_back_link, """
  .auix-back-link {
    font-size: var(--auix-font-size-caption);
    font-weight: 600;
    line-height: var(--auix-line-height-relaxed);
    color: var(--auix-color-back-link-text);
  }

  .auix-back-link:hover {
    color: var(--auix-color-back-link-text-hover);
  }
  """)

  rule(:auix_show_transition, """
    .auix-show-transition {
      transition-property: all;
      transition-timing-function: cubic-bezier(0.0, 0.0, 0.2, 1);
      transition-duration: 300ms;
    }
  """)

  rule(:auix_show_transition__start, """
    .auix-show-transition--start {
      opacity: 0;
      transform: translateY(1rem);
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-show-transition--start {
        transform: translateY(0) scale(0.95);
      }
    }
  """)

  rule(:auix_show_transition__end, """
    .auix-show-transition-end {
      opacity: var(--auix-opacity-100);
      transform: translateY(0);
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-show-transition-end {
        transform: scale(1);
      }
    }
  """)

  rule(:auix_hide_transition, """
    .auix-hide-transition {
      transition-property: all;
      transition-timing-function: cubic-bezier(0.4, 0.0, 1, 1);
      transition-duration: 200ms;
    }
  """)

  rule(:auix_hide_transition__start, """
    .auix-hide-transition--start {
      opacity: var(--auix-opacity-100);
      transform: translateY(0);
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-hide-transition--start {
        transform: scale(1);
      }
    }
  """)

  rule(:auix_hide_transition__end, """
    .auix-hide-transition--end {
      opacity: 0;
      transform: translateY(1rem);
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-hide-transition--end {
        transform: translateY(0) scale(0.95);
      }
    }
  """)

  rule(:auix_show_modal_transition, """
    .auix-show-modal-transition {
      transition-property: all;
      transition-timing-function: cubic-bezier(0.0, 0.0, 0.2, 1);
      transition-duration: 300ms;
    }
  """)

  rule(:auix_show_modal_transition__start, """
    .auix-show-modal-transition--start {
      opacity: 0;
    }
  """)

  rule(:auix_show_modal_transition__end, """
    .auix-show-modal-transition--end {
      opacity: var(--auix-opacity-100);
    }
  """)

  rule(:auix_show_modal, """
    .auix-show-modal {
      overflow-x: hidden;
      overflow-y: hidden;
    }
  """)

  rule(:auix_hide_modal_transition, """
    .auix-hide-modal-transition {
      transition-property: all;
      transition-timing-function: cubic-bezier(0.4, 0.0, 1, 1);
      transition-duration: 200ms;
    }
  """)

  rule(:auix_hide_modal_transition__start, """
    .auix-hide-modal-transition--start {
      opacity: var(--auix-opacity-100);
    }
  """)

  rule(:auix_hide_modal_transition__end, """
    .auix-hide-modal-transition--end {
      opacity: 0;
    }
  """)

  rule(:auix_hide_modal, """
    .auix-hide-modal {
      overflow: hidden;
    }
  """)

  rule(:auix_items_desktop, """
    .auix-items-desktop {
      display: none;
    }

    @media (min-width: #{breakpoint(:md)}) {
      .auix-items-desktop {
        display: block;
      }
    }
  """)

  rule(:auix_items_mobile, """
    .auix-items-mobile {
      margin-top: 0;
    }

    @media (min-width: #{breakpoint(:md)}) {
      .auix-items-mobile {
        visibility: hidden;
        aria-hidden: true;
        position: fixed;
        top: -9999px;
        left: -9999px;
        width: var(--auix-hidden-element-size);
        height: var(--auix-hidden-element-size);
        overflow: hidden;
        pointer-events: none;
        z-index: -9999;
      }
    }
  """)

  rule(:auix_items_cards, """
    .auix-items-cards {
      margin-top: 0;
    }

    .auix-items-cards .auix-items-card-list {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(var(--auix-items-card-min-width), 1fr));
      gap: var(--auix-gap-large);
    }
  """)

  rule(:auix_items_table_container, """
    .auix-items-table-container {
      overflow-y: scroll;               
      padding-left: var(--auix-padding-default);               
      padding-right: var(--auix-padding-default);      
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-items-table-container {
        overflow-y: visible;            
        padding-left: 0;                
        padding-right: 0;               
      }
    }
  """)

  rule(:auix_items_table, """
  .auix-items-table {
    width: 40rem;
    margin-top: 0;
  }

  @media (min-width: #{breakpoint(:sm)}) {
    .auix-items-table {
      width: 100%;
    }
  }
  """)

  rule(:auix_items_table_header, """
  .auix-items-table-header {
    font-size: var(--auix-font-size-caption);
    color: var(--auix-color-items-table-header-text);
  }
  """)

  rule(:auix_items_table_header_row, """
  .auix-items-table-header-row {
    text-align: left;
  }
  """)

  rule(:auix_items_table_header_filter_cell, """
    .auix-items-table-header-filter-cell {
      font-weight: var(--auix-font-weight-bold-semi);
    }
  """)

  rule(:auix_items_table_header_cell, """
  .auix-items-table-header-cell {
    padding-left: var(--auix-padding-default);
    padding-right: var(--auix-padding-default);
  }
  """)

  rule(:auix_items_table_header_cell__first, """
  /* auix-items-table-header-cell--first */

  #{import_rule(:auix_items_table_header_cell, :auix_items_table_header_cell__first)}
  """)

  rule(:auix_items_table_header_sort, """
  .auix-items-table-header-sort {
    display: inline-flex;
    align-items: center;
    gap: var(--auix-gap-minimal);
    padding: 0;
    border: 0;
    background: transparent;
    color: inherit;
    font: inherit;
    cursor: pointer;
  }
  """)

  rule(:auix_items_table_body, """
  .auix-items-table-body {
    position: relative;

    border-top-width: var(--auix-border-width-default);
    border-top-color: var(--auix-color-items-table-body-border);

    font-size: var(--auix-font-size-caption);
    color: var(--auix-color-items-table-body-text);
  }

  .auix-items-table-body > tr:not(:last-child) {
    border-bottom-width: var(--auix-border-width-default);
    border-bottom-color: var(--auix-color-border-tertiary);
  }
  """)

  rule(:auix_items_table_row, """
  .auix-items-table-row {
  }
  .auix-items-table-row:hover {
    background-color: var(--auix-color-items-table-row-bg-hover);
  }
  """)

  rule(:auix_items_table_empty, """
  .auix-items-table-empty {
    width: 100%;
    text-align: center;
    font-size: var(--auix-font-size-empty-state);
    font-weight: var(--auix-font-weight-bold);
  }
  """)

  rule(:auix_items_table_cell, """
  .auix-items-table-cell {
    padding-right: var(--auix-padding-default);
    padding-left: var(--auix-padding-default);
  }
  """)

  rule(:auix_items_table_action_cell, """
    .auix-items-table-action-cell {
      display: flex;
      flex-direction: row;
      justify-content: flex-end;
      gap: var(--auix-gap-default);
      padding-top: var(--auix-padding-small);
      padding-left: 0;
    }
  """)

  rule(:auix_items_card_container, """
    .auix-items-card-container {
      margin-top: var(--auix-margin-medium);
    }
  """)

  rule(:auix_items_card_empty, """
  /* auix-items-card-empty */

  #{import_rule(:auix_items_table_empty, :auix_items_card_empty)}
  """)

  rule(:auix_items_card_item_content, """
  .auix-items-card-item-content {
    display: flex;
    flex-direction: column;
    position: relative;
    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-color: var(--auix-color-border-primary);
    border-radius: var(--auix-border-radius-default);
    background-color: var(--auix-color-bg-default);
    color: var(--auix-color-items-card-item-content-text);
  }
  """)

  rule(:auix_items_card_show, """
  .auix-items-card-show {
    position: absolute;
    inset: 0;
  }

  .auix-items-card-show > .auix-index-row-action,
  .auix-items-card-show > * {
    display: block;
    width: 100%;
    height: 100%;
    opacity: 0;
  }
  """)

  rule(:auix_items_card_item_group, """
  .auix-items-card-item-group {
    display: flex;
    flex-direction: row;
    align-items: flex-start;
    gap: var(--auix-gap-large);
    padding: var(--auix-padding-default);
  }
  """)

  rule(:auix_items_card_item, """
  .auix-items-card-item {
    display: flex;
    flex-direction: column;
    flex: 1;
    gap: var(--auix-gap-default);
    padding: 0 var(--auix-padding-default) var(--auix-padding-default);
  }

  .auix-items-card-item .auix-inline-container {
    flex-direction: row;
    flex-wrap: wrap;
    column-gap: var(--auix-gap-large);
  }
  """)

  rule(:auix_items_card_item_fieldset, """
  .auix-items-card-item-fieldset {
    display: grid;
    grid-template-columns: var(--auix-items-card-label-width) minmax(0, 1fr);
    column-gap: var(--auix-gap-large);
    align-items: baseline;
  }
  """)

  rule(:auix_items_card_item_label, """
  .auix-items-card-item-label {
    font-size: var(--auix-font-size-small);
    font-weight: var(--auix-font-weight-bold);
    color: var(--auix-color-text-tertiary);
  }
  """)

  rule(:auix_items_card_item_value, """
  .auix-items-card-item-value {
    min-width: 0;
    font-size: var(--auix-font-size-caption);
    overflow-wrap: anywhere;
  }
  """)

  rule(:auix_items_card_list, """
  .auix-items-card-list {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-large);
  }
  """)

  rule(:auix_items_card_select, """
  .auix-items-card-select {
    position: relative;
    display: flex;
    align-items: center;
    flex-shrink: 0;
    height: var(--auix-line-height-relaxed);
  }

  .auix-items-card-select .auix-fieldset {
    padding: 0;
    gap: 0;
  }

  .auix-items-card-select .auix-checkbox {
    margin: 0;
  }
  """)

  rule(:auix_items_card_heading, """
  .auix-items-card-heading {
    display: flex;
    flex-direction: column;
    flex: 1;
    gap: var(--auix-gap-minimal);
    min-width: 0;
  }
  """)

  rule(:auix_items_card_title, """
  .auix-items-card-title {
    font-size: var(--auix-font-size-subtitle);
    font-weight: var(--auix-font-weight-bold);
    line-height: var(--auix-line-height-relaxed);
  }
  """)

  rule(:auix_items_card_subtitle, """
  .auix-items-card-subtitle {
    font-size: var(--auix-font-size-caption);
    color: var(--auix-color-text-tertiary);
  }
  """)

  rule(:auix_items_card_menu, """
  .auix-items-card-menu {
    position: relative;
    display: inline-flex;
    flex-shrink: 0;
  }

  .auix-items-card-menu > .auix-items-card-menu-toggle {
    min-width: var(--auix-touch-target-size);
    min-height: var(--auix-touch-target-size);
    justify-content: center;
  }

  .auix-items-card-menu:not(:has(.auix-items-card-menu-item > *)) {
    display: none;
  }
  """)

  rule(:auix_items_card_menu_list, """
  .auix-items-card-menu-list {
    display: none;
    position: absolute;
    inset-inline-end: 0;
    top: 100%;
    z-index: 10;
    flex-direction: column;
    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-color: var(--auix-color-border-primary);
    border-radius: var(--auix-border-radius-default);
    background-color: var(--auix-color-bg-default);
    box-shadow: var(--auix-shadow-md);
  }

  .auix-items-card-menu-toggle[aria-expanded="true"] ~ .auix-items-card-menu-list {
    display: flex;
  }
  """)

  rule(:auix_items_card_menu_group, """
  .auix-items-card-menu-group {
    display: flex;
    flex-direction: column;
  }

  .auix-items-card-menu-group:not(:has(.auix-items-card-menu-item > *)) {
    display: none;
  }

  .auix-items-card-menu-group:has(.auix-items-card-menu-item > *) + .auix-items-card-menu-group--destructive {
    border-top-width: var(--auix-border-width-default);
    border-top-style: var(--auix-border-style-default);
    border-top-color: var(--auix-color-border-primary);
  }
  """)

  rule(:auix_items_card_menu_group__destructive, """
  .auix-items-card-menu-group--destructive {
    color: var(--auix-color-icon-danger);
  }
  """)

  rule(:auix_items_card_menu_item, """
  .auix-items-card-menu-item,
  .auix-items-card-menu-item > .auix-index-row-action,
  .auix-items-card-menu-item > a,
  .auix-items-card-menu-item > button {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: var(--auix-touch-target-size);
    min-height: var(--auix-touch-target-size);
  }

  .auix-items-card-menu-item:not(:has(> *)) {
    display: none;
  }
  """)

  rule(:auix_pagination_bar, """
  .auix-pagination-bar {
    display: flex;
    flex-direction: row;
    gap: var(--auix-gap-large);
    justify-content: center;
    overflow-x: clip;
  }
  """)

  rule(:auix_pagination_bar_link, """
  .auix-pagination-bar-link {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_pagination_bar_current_page, """
  .auix-pagination-bar-current-page {
    margin-top: 0;
    margin-bottom: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_pagination_bar_current_page_number, """
  .auix-pagination-bar-current-page-number {
    border: var(--auix-border-width-default) solid var(--auix-color-pagination-current-border);
    border-radius: var(--auix-border-radius-round);
    padding-top: 0;
    padding-bottom: 0;
    padding-left: var(--auix-padding-default);
    padding-right: var(--auix-padding-default);
    color: var(--auix-color-pagination-current-text);
    background-color: var(--auix-color-pagination-current-bg);
  }
  """)

  rule(:auix_pagination_bar_selected_count, """
  .auix-pagination-bar-selected-count {
    font-size: var(--auix-font-size-small);
    text-align: center;
    vertical-align: sub;
    border-width: var(--auix-border-width-default);
  }
  """)

  rule(:auix_record_navigator_bar, """
  .auix-record-navigator-bar {
    width: 100%;
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
  }
  """)

  rule(:auix_filter_card, """
  .auix-filter-card:not(:nth-child(1)) {
    border-bottom: var(--auix-border-width-default) solid var(--auix-color-filter-card-border);
  }
  """)

  rule(:auix_filter_fieldset, """
  .auix-filter-fieldset {
  }
  """)

  rule(:auix_filter_field, """
    .auix-filter-field {
    }

  """)

  rule(:auix_filter_field_content, """
  .auix-filter-field-content {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_filter_input, """
    .auix-filter-input {
      border-radius: var(--auix-border-radius-small);
      border-color: var(--auix-color-filter-input-border);
      box-shadow: var(--auix-shadow-small);
    }

    .auix-filter-input:focus {
      border-color: var(--auix-color-filter-input-border-focus);
      outline: var(--auix-focus-outline-width) solid transparent;
      outline-offset: 2px;

    box-shadow:
      var(--auix-ring-offset-shadow),
      var(--auix-ring-default),
      var(--auix-shadow-primary);
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-filter-input {
        font-size: var(--auix-font-size-caption);
      }
    }
  """)

  rule(:auix_filter_input_field, """
  .auix-filter-input-field {
    margin: 0;
    height: var(--auix-input-height-default);
  }
  .auix-filter-input-field:disabled {
    background-color: var(--auix-color-bg-disabled);
    opacity: var(--auix-opacity-75);
  }
  """)

  rule(:auix_filter_condition_label, """
  @media (min-width: #{breakpoint(:md)}) {
    .auix-filter-condition-label {
      display: none;
    }
  }
  """)

  rule(:auix_filter_condition_input, """
  .auix-filter-condition-input {
  }
  """)

  rule(:auix_index_container, """
  .auix-index-container {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-medium);
    caret-color: transparent;
  }

  @media (min-width: #{breakpoint(:sm)}) {
    .auix-index-container {
      padding: var(--auix-padding-default);
    }
  }

  @media (min-width: #{breakpoint(:md)}) {
    .auix-index-container {
      margin-left: auto;
      margin-right: auto;
      width: max-content;
      max-width: max-content;
      padding: var(--auix-padding-default);
    }
  }

  @media (min-width: #{breakpoint(:lg)}) {
    .auix-index-container {
      padding-top: var(--auix-padding-xl);
      padding-bottom: var(--auix-padding-xl);
      padding-left: var(--auix-padding-large);
      padding-right: var(--auix-padding-xl);
    } 
  }

  """)

  rule(:auix_index_actions, """
  .auix-index-actions {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
  }
  """)

  rule(:auix_index_row_action, """
  .auix-index-row-action{
  }
  """)

  rule(:auix_index_header_actions, """
    .auix-index-header-actions {
      display: flex;
      flex-direction: row;
      align-items: center;
      gap: var(--auix-gap-default);
    }
  """)

  rule(:auix_index_sort_action, """
    .auix-index-sort-action {
      display: flex;
      flex-direction: row;
      align-items: stretch;
    }

    @media (min-width: #{breakpoint(:md)}) {
      .auix-index-sort-action {
        display: none;
      }
    }
  """)

  rule(:auix_index_sort_action__always, """
    @media (min-width: #{breakpoint(:md)}) {
      .auix-index-sort-action.auix-index-sort-action--always {
        display: flex;
      }
    }
  """)

  rule(:auix_index_sort_select, """
    .auix-index-sort-select {
      display: none;
      flex-direction: row;
      align-items: stretch;
      gap: var(--auix-gap-minimal);
    }

    .auix-index-sort-select form,
    .auix-index-sort-select .auix-fieldset {
      display: flex;
      margin: 0;
      padding: 0;
    }

    /* The hero icon keeps its own 1.5rem box, so the switch drops its vertical padding and
       stretches to the select height, matching the other header buttons. */
    .auix-index-sort-select > .auix-index-sort-select-direction {
      padding-top: 0;
      padding-bottom: 0;
      justify-content: center;
    }

    .auix-index-sort-select .auix-select {
      box-sizing: border-box;
      font-size: var(--auix-font-size-caption);
      font-weight: var(--auix-font-weight-bold);
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-index-sort-select {
        display: flex;
      }
    }
  """)

  rule(:auix_index_sort_menu, """
    .auix-index-sort-menu {
      position: relative;
      display: inline-flex;
      flex-shrink: 0;
    }

    .auix-index-sort-menu > .auix-index-sort-menu-toggle {
      min-width: var(--auix-touch-target-size);
      min-height: var(--auix-touch-target-size);
      justify-content: center;
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-index-sort-menu {
        display: none;
      }
    }
  """)

  rule(:auix_index_sort_menu_toggle__active, """
    .auix-index-sort-menu > .auix-index-sort-menu-toggle--active {
      color: var(--auix-color-icon-info);
      background-color: var(--auix-color-bg-secondary);
    }
  """)

  rule(:auix_index_sort_menu_list, """
    .auix-index-sort-menu-list {
      display: none;
      position: absolute;
      inset-inline-end: 0;
      top: 100%;
      z-index: 10;
      flex-direction: column;
      min-width: max-content;
      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-color: var(--auix-color-border-primary);
      border-radius: var(--auix-border-radius-default);
      background-color: var(--auix-color-bg-default);
      box-shadow: var(--auix-shadow-md);
    }

    .auix-index-sort-menu-toggle[aria-expanded="true"] ~ .auix-index-sort-menu-list {
      display: flex;
    }
  """)

  rule(:auix_index_sort_menu_group, """
    .auix-index-sort-menu-group {
      display: flex;
      flex-direction: column;
    }

    .auix-index-sort-menu-group + .auix-index-sort-menu-group {
      border-top-width: var(--auix-border-width-default);
      border-top-style: var(--auix-border-style-default);
      border-top-color: var(--auix-color-border-primary);
    }
  """)

  rule(:auix_index_sort_menu_item, """
    .auix-index-sort-menu-item {
      display: flex;
      flex-direction: row;
      align-items: center;
      gap: var(--auix-gap-default);
      min-height: var(--auix-touch-target-size);
      padding-inline: var(--auix-padding-default);
      border: none;
      background-color: transparent;
      color: inherit;
      font-size: var(--auix-font-size-caption);
      white-space: nowrap;
      cursor: pointer;
    }

    .auix-index-sort-menu-item:hover {
      background-color: var(--auix-color-bg-hover);
    }

    .auix-index-sort-menu-item:disabled {
      background-color: transparent;
      color: var(--auix-color-text-inactive);
      cursor: default;
    }
  """)

  rule(:auix_index_sort_menu_check__off, """
    .auix-index-sort-menu-check--off {
      visibility: hidden;
    }
  """)

  rule(:auix_index_select_actions, """
  .auix-index-select-actions {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_index_all_action_button, """
  /* auix-index-all-action-button */

  .auix-index-all-action-button {
    background-color: var(--auix-color-button-alt-bg);
    color: var(--auix-color-button-alt-text);
    border-color: var(--auix-color-button-alt-border);
  }

  .auix-index-all-action-button:disabled {
    background-color: var(--auix-color-bg-backdrop);
    color: var(--auix-color-text-inactive);
  }

  .auix-index-all-action-button:hover {
    background-color: var(--auix-color-bg-hover);
    cursor: pointer;
  }

  """)

  rule(:auix_show_container, """
  /* auix-show-container */

  #{import_rule(:auix_index_container, :auix_show_container)}

  @media (min-width: #{breakpoint(:md)}) {
    .auix-show-container {
      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-color: var(--auix-color-show-content-border);
      border-radius: var(--auix-border-radius-large);
      background-color: var(--auix-color-show-content-bg);
      box-shadow: var(--auix-shadow-lg);
    }
  }

  .auix-modal-focus-wrap .auix-show-container {
    padding: 0;
    border-width: 0;
    box-shadow: none;
  }
  """)

  rule(:auix_show_content, """
  /* auix-show-content */

  #{import_rule(:auix_index_container, :auix_show_content)}

  .auix-show-content {
    gap: var(--auix-gap-container);
    padding: var(--auix-padding-container);
    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-color: var(--auix-color-show-content-border);
    border-radius: var(--auix-border-radius-medium);
    box-shadow: none;
    background-color: var(--auix-color-show-content-bg);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-show-content {
      gap: var(--auix-gap-xl);
      padding: 0;
      border-width: 0;
    }
  }
  """)

  rule(:auix_form_container, """
  .auix-form-container {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-container);

    padding: var(--auix-padding-container);
    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-color: var(--auix-color-form-container-border);
    border-radius: var(--auix-border-radius-medium);

    background-color: var(--auix-color-form-container-bg);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-form-container {
      gap: var(--auix-gap-xl);
      padding: 0;
      border-width: 0;
    }
  }
  """)

  rule(:auix_sections_container, """
  .auix-sections-container {
    content-visibility: visible;
  }
  """)

  rule(:auix_sections_tab_container, """
  .auix-sections-tab-container {
    position: relative;
    z-index: 1;
    display: flex;
    flex-direction: row;
    gap: var(--auix-gap-minimal);
    margin-top: var(--auix-margin-medium);
    margin-bottom: calc(-1 * var(--auix-border-width-default));
    padding: var(--auix-focus-ring-width) var(--auix-padding-control) 0;
    overflow-x: auto;
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-sections-tab-container {
      padding: var(--auix-focus-ring-width) var(--auix-padding-medium) 0;
    }
  }
  """)

  rule(:auix_sections_tab_button__active, """
  /* auix-sections-tab-button--active */
  #{import_rule(:_auix_sections_tab_button, :auix_sections_tab_button__active)}

  .auix-sections-tab-button--active {
    font-weight: var(--auix-font-weight-bold);
    color: var(--auix-color-sections-tab-active-text);
    background-color: var(--auix-color-sections-tab-active-bg);
    border-color: var(--auix-color-sections-tab-active-border);
    border-bottom-color: var(--auix-color-sections-tab-active-bg);
  }
  """)

  rule(:auix_sections_tab_button__inactive, """
  /* auix-sections-tab-button--inactive */
  #{import_rule(:_auix_sections_tab_button, :auix_sections_tab_button__inactive)}

  .auix-sections-tab-button--inactive {
    font-weight: var(--auix-font-weight-medium);
    color: var(--auix-color-sections-tab-inactive-text);
    background-color: var(--auix-color-sections-tab-inactive-bg);
  }

  .auix-sections-tab-button--inactive:hover {
    color: var(--auix-color-sections-tab-active-text);
    background-color: var(--auix-color-sections-tab-hover-bg);
  }
  """)

  rule(:auix_sections_content, """
  .auix-sections-content {
    padding: var(--auix-padding-container);

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-color: var(--auix-color-sections-content-border);
    border-radius: var(--auix-border-radius-medium);
    background-color: var(--auix-color-sections-content-bg);
  }

  .auix-sections-content .auix-sections-tab-button--active,
  .auix-sections-content .auix-sections-tab-button--inactive {
    height: var(--auix-control-height-compact);
    padding: 0 0.875rem;
    font-size: var(--auix-font-size-label);
  }

  .auix-sections-content .auix-sections-content {
    padding: var(--auix-padding-panel);
    border-radius: var(--auix-border-radius-nested);
  }

  @media (max-width: #{breakpoint(:sm)}) {
    .auix-sections-content {
      padding: var(--auix-padding-panel);
    }
  }
  """)

  rule(:auix_form_field_container, """
  .auix-form-field-container {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    width: stretch;
  }
  .auix-form-field-container > * {
    flex: 1;
  }
  .auix-form-field-container .auix-input,
  .auix-form-field-container .auix-input--errors,
  .auix-form-field-container .auix-textarea,
  .auix-form-field-container .auix-textarea--errors,
  .auix-form-field-container .auix-select {
    width: 100%;
  }
  """)

  rule(:auix_form_field_input, """
    .auix-form-field-input {
      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-radius: var(--auix-border-radius-small);
      border-color: var(--auix-color-form-field-input-border);

      box-shadow: var(--auix-shadow-small);

      font-size: var(--auix-font-size-subtitle);
    }

    .auix-form-field-input:focus {
      outline: var(--auix-focus-outline-width) solid transparent;
      outline-offset: 2px;

      border-color: var(--auix-color-form-field-input-border-focus);

      box-shadow:
        0 0 0 3px var(--auix-color-form-field-input-border-focus), var(--auix-shadow-small); 
    }

    @media (min-width: #{breakpoint(:sm)}) {
      .auix-form-field-input {
        font-size: var(--auix-font-size-caption);
      }
    }
  """)

  rule(:auix_one_to_many_field, """
    .auix-one-to-many-field {
      display: flex;
      flex-direction: column;
      width: stretch;
      gap: var(--auix-gap-default);
    }
  """)

  rule(:auix_one_to_many_header, """
    .auix-one-to-many-header {
      display: flex;
    }
  """)

  rule(:auix_one_to_many_header_actions, """
    .auix-one-to-many-header-actions {
      display: inline;
    }
  """)

  rule(:auix_one_to_many_container, """
    .auix-one-to-many-container {
      width: auto;
      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-radius: var(--auix-border-radius-default);

      padding-left: var(--auix-padding-minimal);
      padding-right: var(--auix-padding-minimal);

      color: var(--auix-color-one-to-many-text);
      border-color: var(--auix-color-one-to-many-border);
    }


    @media (min-width: #{breakpoint(:sm)}) {
      .auix-one-to-many-container {
        font-size: var(--auix-font-size-caption);
      }
    }
  """)

  rule(:auix_one_to_many_footer, """
    .auix-one-to-many-footer {
      display: flex;
      flex-direction: row;
    }
  """)

  rule(:auix_one_to_many_footer_actions, """
    .auix-one-to-many-footer-actions {
      display: flex;
      flex-direction: column;
    }
  """)

  rule(:auix_visually_hidden, """
    .auix-visually-hidden {
      position: absolute;
      width: var(--auix-hidden-element-size);
      height: var(--auix-hidden-element-size);
      padding: 0;
      margin: -1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      clip-path: inset(50%);
      white-space: nowrap;
      border-width: 0;
    }
  """)

  rule(:auix_pagination_container, """
    .auix-pagination-container {
      margin-top: 0;
    }
  """)

  rule(:auix_pagination_breakpoint_xl2, """
    .auix-pagination-breakpoint-xl2 {

      height: 0;
      visibility: hidden;
    }


    @media (min-width: #{breakpoint(:xxl)}) {
      .auix-pagination-breakpoint-xl2 {
        visibility: visible;
        height: auto;
      }
    }
  """)

  rule(:auix_pagination_breakpoint_xl, """
    .auix-pagination-breakpoint-xl {

      height: 0;
      visibility: hidden;
    }


    @media (min-width: #{breakpoint(:xl)}) {
      .auix-pagination-breakpoint-xl {
        visibility: visible;
        height: auto;
      }
    }


    @media (min-width: #{breakpoint(:xxl)}) {
      .auix-pagination-breakpoint-xl {
        visibility: hidden;
        height: 0;
      }
    }
  """)

  rule(:auix_pagination_breakpoint_lg, """
    .auix-pagination-breakpoint-lg {

      height: 0;                
      visibility: hidden;         
    }


    @media (min-width: #{breakpoint(:lg)}) {
      .auix-pagination-breakpoint-lg {
        visibility: visible;
        height: auto;
      }
    }


    @media (min-width: #{breakpoint(:xl)}) {
      .auix-pagination-breakpoint-lg {
        visibility: hidden;
        height: 0;
      }
    }
  """)

  rule(:auix_pagination_breakpoint_md, """
    .auix-pagination-breakpoint-md {

      height: 0;                
      visibility: hidden;         

      font-size: var(--auix-font-size-caption);        
    }


    @media (min-width: #{breakpoint(:md)}) {
      .auix-pagination-breakpoint-md {
        visibility: visible;
        height: auto;
      }
    }


    @media (min-width: #{breakpoint(:lg)}) {
      .auix-pagination-breakpoint-md {
        visibility: hidden;
        height: 0; 
      }
    }
  """)

  rule(:auix_group_container, """
  .auix-group-container {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    width: stretch;

    gap: var(--auix-gap-xl);
    padding: var(--auix-padding-panel);

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-medium);
    border-color: var(--auix-color-group-container-border);

    background-color: var(--auix-color-group-container-bg);
  }

  .auix-group-container > * {
    flex: 1;
  }

  .auix-group-container .auix-group-container {
    border-radius: var(--auix-border-radius-nested);
  }
  """)

  rule(:auix_group_title, """
  .auix-group-container > .auix-group-title {
    flex: none;
  }

  .auix-group-title {
    margin: calc(-1 * var(--auix-padding-panel)) calc(-1 * var(--auix-padding-panel)) 0;
    padding: var(--auix-padding-default) var(--auix-padding-panel);
    border-bottom: var(--auix-border-width-default) var(--auix-border-style-default) var(--auix-color-group-title-border);
    font-weight: var(--auix-font-weight-bold);
    font-size: var(--auix-font-size-group-title);
    line-height: var(--auix-line-height-default);
  }
  """)

  rule(:auix_inline_container, """
  .auix-inline-container {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-xl);
  }

  @media (min-width: #{breakpoint(:md)}) {
    .auix-inline-container {
      flex-direction: row;
    }
  }
  """)

  rule(:auix_stacked_container, """
  .auix-stacked-container {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-xl);
  }
  """)

  rule(:auix_icon_size_3, """
  .auix-icon-size-3 {
    width: var(--auix-icon-size-3);          
    height: var(--auix-icon-size-3);         
  }
  """)

  rule(:auix_icon_size_4, """
  .auix-icon-size-4 {
    width: var(--auix-icon-size-4);          
    height: var(--auix-icon-size-4);         
  }
  """)

  rule(:auix_icon_size_5, """
  .auix-icon-size-5 {
    width: var(--auix-icon-size-5);          
    height: var(--auix-icon-size-5);         
  }
  """)

  rule(:auix_icon_size_6, """
  .auix-icon-size-6 {
    width: var(--auix-icon-size-6);          
    height: var(--auix-icon-size-6);         
  }
  """)

  rule(:auix_icon_size_button, """
  .auix-icon-size-button {
    width: var(--auix-icon-size-button);          
    height: var(--auix-icon-size-button);         
  }
  """)

  rule(:auix_icon_default, """
  .auix-icon-default {
    color: var(--auix-color-icon-default)
  }
  """)

  rule(:auix_icon_safe, """
  .auix-icon-safe:hover {
    color: var(--auix-color-icon-safe)
  }
  """)

  rule(:auix_icon_info, """
  .auix-icon-info:hover {
    color: var(--auix-color-icon-info)
  }
  """)

  rule(:auix_icon_danger, """
  .auix-icon-danger {
    color: var(--auix-color-icon-danger)
  }
  """)

  rule(:auix_icon_inactive, """
  .auix-icon-inactive {
    color: var(--auix-color-icon-inactive)
  }
  """)

  rule(:auix_vertical_align_super, """
  .auix-vertical-align-super {
    vertical-align: super;
  }
  """)

  rule(:auix_animate_spin, """
    .auix-animate-spin {
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      from {
        transform: rotate(0deg);
      }
      to {
        transform: rotate(360deg);
      }
    }
  """)

  rule(:auix_embeds_one_container, """
  .auix-embeds-one-container {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    width: stretch;

    gap: var(--auix-gap-xl);
    padding: var(--auix-padding-panel);

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-medium);
    border-color: var(--auix-color-embeds-border);
    background-color: var(--auix-color-embeds-bg);
  }
  .auix-embeds-one-container > * {
    flex: 1;
  }
  .auix-embeds-one-container > .auix-header {
    flex: none;
    margin: calc(-1 * var(--auix-padding-panel)) calc(-1 * var(--auix-padding-panel)) 0;
  }
  .auix-embeds-one-container > .auix-header .auix-header-title {
    padding: var(--auix-padding-default) var(--auix-padding-panel);
    border-bottom: var(--auix-border-width-default) var(--auix-border-style-default) var(--auix-color-embeds-border);
    font-size: var(--auix-font-size-caption);
    line-height: var(--auix-line-height-default);
  }
  .auix-embeds-one-container > .auix-header .auix-header-subtitle {
    margin: var(--auix-padding-panel) var(--auix-padding-panel) 0;
  }
  """)

  rule(:auix_embeds_one_empty_msg, """
  .auix-embeds-one-empty-msg {
    display: block;
    padding: var(--auix-padding-default) var(--auix-padding-control);
    border: var(--auix-border-width-default) dashed var(--auix-color-embeds-empty-border);
    border-radius: var(--auix-border-radius-default);
    background-color: var(--auix-color-bg-default);
    font-size: var(--auix-font-size-caption);
    font-style: var(--auix-font-style-mobile-viewmode);
    line-height: var(--auix-line-height-default);
    color: var(--auix-color-embeds-empty-text);
  }
  """)

  rule(:auix_many_to_many_container, """
  .auix-many-to-many-container {
    display: flex;
    flex-direction: column;
    width: stretch;
  }
  .auix-many-to-many-container > * {
    flex: 1;
  }
  """)

  rule(:auix_many_to_many_footer_actions, """
  /* auix-many-to-many-footer-actions */

  #{import_rule(:_auix_actions, :auix_many_to_many_footer_actions)}
  .auix-many-to-many-footer-actions {
    flex-direction: row;
    justify-content: flex-end;
  }
  """)

  rule(:auix_multi_select_container, """
  .auix-multi-select-container {
    display: flex;
    flex-direction: column;
    width: stretch;
  }
  .auix-multi-select-container > * {
    flex: 1;
  }
  """)

  rule(:auix_multi_select_footer_actions, """
  /* auix-multi-select-footer-actions */

  #{import_rule(:_auix_actions, :auix_multi_select_footer_actions)}
  .auix-multi-select-footer-actions {
    flex-direction: row;
    justify-content: flex-end;
  }
  """)

  rule(:auix_one_to_one_container, """
  /* auix-one-to-one-container */

  #{import_rule(:auix_embeds_one_container, :auix_one_to_one_container)}
  """)

  rule(:auix_one_to_one_empty_msg, """
  /* auix-one-to-one-empty-msg */

  #{import_rule(:auix_embeds_one_empty_msg, :auix_one_to_one_empty_msg)}
  """)

  rule(:auix_embeds_many_container, """
  .auix-embeds-many-container {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    width: stretch;

    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-default);                             
    border-color: var(--auix-color-embeds-border);
    background-color: var(--auix-color-embeds-bg);
  }
  .auix-embeds-many-container > * {
    flex: 1;
  }
  """)

  rule(:auix_embeds_many_details, """
  .auix-embeds-many-details {
    display: flex;
    flex-direction: column;
    gap: 0;

    padding: 0;
  }
  """)

  rule(:auix_embeds_many_summary, """
  .auix-embeds-many-summary {
    padding: var(--auix-padding-default) var(--auix-padding-control);
    font-size: var(--auix-font-size-caption);
    font-weight: var(--auix-font-weight-medium);
    line-height: var(--auix-line-height-default);
  }

  .auix-embeds-many-summary:hover {
    cursor: pointer;
  }
  """)

  rule(:auix_embeds_many_summary_content, """
  .auix-embeds-many-summary-content {
    display: inline-flex;
    flex-direction: row;
    gap: var(--auix-gap-default);
  }
  """)

  rule(:auix_embeds_many_content, """
  .auix-embeds-many-content {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-large);
    padding: 0 var(--auix-padding-control) var(--auix-padding-control);
  }

  .auix-embeds-many-content > .auix-header .auix-header-title {
    font-size: var(--auix-font-size-caption);
  }
  """)

  rule(:auix_embeds_many_header_container, """
    .auix-embeds-many-header-container {
      display: flex;
      flex-direction: row;
      gap: var(--auix-gap-default);
    }
  """)

  rule(:auix_embeds_many_header_actions, """
    .auix-embeds-many-header-actions {
      display: flex;
      gap: var(--auix-gap-default);
    }
  """)

  rule(:auix_embeds_many_footer_container, """
    .auix-embeds-many-footer-container {
    }
  """)

  rule(:auix_embeds_many_footer_actions, """
  /* auix-embeds-many-footer-actions */

  #{import_rule(:_auix_actions, :auix_embeds_many_footer_actions)}
  .auix-embeds-many-footer-actions {
    flex-direction: row;
    justify-content: flex-end;
  }
  """)

  rule(:auix_embeds_many_new_entry_container, """
    .auix-embeds-many-new-entry-container {
    }
  """)

  rule(:auix_embeds_many_new_entry_actions, """
  /* auix-embeds-many-new-entry-actions */

  #{import_rule(:_auix_actions, :auix_embeds_many_new_entry_actions)}
  """)

  rule(:auix_embeds_many_existing_container, """
    .auix-embeds-many-existing-container {
      display: flex;
      justify-content: flex-end;
    }
  """)

  rule(:auix_embeds_many_existing_actions, """
  /* auix-embeds-many-existing-actions */

  #{import_rule(:_auix_actions, :auix_embeds_many_existing_actions)}
  """)

  rule(:auix_embeds_many__remove_entry_action, """
  .auix-embeds-many--remove-entry-action {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  """)

  rule(:auix_embeds_many_entry_contents, """
  .auix-embeds-many-entry-contents {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-default);

    padding: var(--auix-padding-default);
    border-width: var(--auix-border-width-default);
    border-style: var(--auix-border-style-default);
    border-radius: var(--auix-border-radius-default);                             
    border-color: var(--auix-color-embeds-border);
    background-color: var(--auix-color-embeds-bg);
  }
  """)

  rule(:auix_embeds_many_entry__badge, """
  .auix-embeds-many-entry--badge {
    display: flex;
    flex-direction: row-reverse;
  }
  """)

  rule(:auix_embeds_many_entry__badge_text, """
  .auix-embeds-many-entry--badge-text {
    padding: var(--auix-padding-small) var(--auix-padding-medium);
    background-color: var(--auix-color-embeds-many-badge-bg);
    color: var(--auix-color-embeds-many-badge-text);
    border-radius: var(--auix-border-radius-round);
    font-size: var(--auix-font-size-small);
    font-weight: var(--auix-font-weight-bold);
  }
  """)

  # --- PREDEFINED RENDERERS --- #

  rule(:auix_show_field, """
  .auix-show-field {
    display: flex;
    flex-direction: column;
    gap: var(--auix-gap-label);
  }
  """)

  rule(:auix_toggle_pill, """
  .auix-checkbox.auix-toggle-switch {
    appearance: none;
    -webkit-appearance: none;
    align-self: flex-start;
    width: var(--auix-toggle-width);
    height: var(--auix-toggle-height);
    margin: 0;
    border: none;
    border-radius: var(--auix-border-radius-round);
    background-color: var(--auix-color-toggle-off);
    background-image: radial-gradient(circle 0.625rem at 0.75rem 0.75rem, var(--auix-color-toggle-knob) 100%, transparent 0);
    background-repeat: no-repeat;
    box-shadow: none;
    cursor: pointer;
    transition: background-color 0.2s ease, background-position 0.2s ease;
  }
  .auix-checkbox.auix-toggle-switch:checked {
    background-color: var(--auix-color-toggle-on);
    background-position: 1.25rem 0;
  }
  .auix-checkbox.auix-toggle-switch:disabled {
    opacity: var(--auix-opacity-100);
    cursor: default;
  }
  """)

  rule(:auix_color, """
  .auix-color {
    display: inline-flex;
    align-items: center;
    align-self: flex-start;
    padding: var(--auix-padding-small) var(--auix-padding-medium);
    border-radius: var(--auix-border-radius-small);
    border: 1px solid rgba(0, 0, 0, 0.2);
    font-family: monospace;
    font-size: var(--auix-font-size-small);
  }
  """)

  rule(:auix_badge, """
  .auix-badge {
    display: inline-flex;
    align-items: center;
    align-self: flex-start;
    padding: var(--auix-padding-small) var(--auix-padding-medium);
    border-radius: var(--auix-border-radius-round);
    font-size: var(--auix-font-size-small);
    font-weight: var(--auix-font-weight-bold);
    background-color: #dbeafe;
    color: #1e40af;
  }
  """)

  rule(:auix_progress, """
  .auix-progress {
    position: relative;
    height: 1rem;
    width: 100%;
    min-width: 6rem;
    background-color: #e5e7eb;
    border-radius: var(--auix-border-radius-round);
    overflow: hidden;
  }
  .auix-progress-bar {
    height: 100%;
    background-color: #3b82f6;
    border-radius: inherit;
    transition: width 0.2s ease;
  }
  .auix-progress-label {
    position: absolute;
    top: 0;
    left: 50%;
    transform: translateX(-50%);
    font-size: var(--auix-font-size-small);
    line-height: 1rem;
  }
  """)

  rule(:auix_url, """
  .auix-url {
    color: #2563eb;
    text-decoration: underline;
  }
  """)

  rule(:auix_rating, """
  .auix-rating,
  .auix-rating-stars {
    display: inline-flex;
    gap: 0.125rem;
  }
  .auix-rating-star {
    color: #d1d5db;
    font-size: 1.1em;
    line-height: 1;
  }
  .auix-rating-star--on {
    color: #f59e0b;
  }
  .auix-rating-star-label {
    cursor: pointer;
  }
  .auix-rating-radio {
    position: absolute;
    width: 0;
    height: 0;
    opacity: 0;
  }
  """)
end
