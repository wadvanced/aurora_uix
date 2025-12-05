defmodule Aurora.Uix.Templates.Basic.Themes.Base do
  @moduledoc """
  The base theme for the Basic template.

  This theme defines a set of CSS rules for the base theme.
  """
  use Aurora.Uix.Templates.Theme

  import Aurora.Uix.Templates.ThemeHelper, only: [import_rule: 2]

  # ---  BASE RULES --#
  @impl true
  @spec rule(atom()) :: binary()
  def rule(:_auix_html) do
    """
    html, :host {
      -webkit-text-size-adjust: 100%;
      tab-size: 4;
      font-family: var(--auix-font-family-default, ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji');
      font-feature-settings: var(--auix-default-font-feature-settings, normal);
      font-variation-settings: var(--auix-default-font-variation-settings, normal);
      -webkit-tap-highlight-color: transparent;
    }
    """
  end

  def rule(:_auix_tag_a) do
    """
    a {
      color: inherit;
      -webkit-text-decoration: inherit;
      text-decoration: inherit;
    }

    a:hover {
      cursor: pointer;
    }
    """
  end

  def rule(:_auix_button_default) do
    """
    .-auix-button-default {
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
    """
  end

  def rule(:_auix_flash) do
    """
      .-auix-flash {
        position: fixed;                 
        top: var(--auix-margin-default);                     
        right: var(--auix-margin-default);                   
        margin-right: var(--auix-margin-default);            
        z-index: 50;

        display: flex;
        flex-direction: column;
        gap: var(--auix-gap-minimal);

        border-radius: var(--auix-border-radius-default);           
        padding: var(--auix-padding-default);
      }
    """
  end

  def rule(:_auix_actions) do
    """
    .-auix-actions {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: var(--auix-gap-default);
    }
    """
  end

  # --- ACTIVE RULES -- #
  def rule(:auix_horizontal_divider) do
    """
    .auix-horizontal-divider {
      border-top: 1px solid var(--auix-color-border-primary);
      margin-top: 0.125rem;
      margin-bottom: 0.250rem;
    }
    """
  end

  def rule(:auix_modal) do
    """
      .auix-modal {
        position: relative; 
        z-index: 50; 
        display: none;
      }
    """
  end

  def rule(:auix_modal_background) do
    """
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
    """
  end

  def rule(:auix_modal_container) do
    """
      .auix-modal-container {
        position: fixed;
        top: 0;
        right: 0;
        bottom: 0;
        left: 0;
        overflow-y: auto;
        overflow-x: auto;
      }
    """
  end

  def rule(:auix_modal_content) do
    """
    .auix-modal-content {
      display: flex;
      min-height: 100%;
      align-items: center;
      justify-content: center;
    }
    """
  end

  def rule(:auix_modal_box) do
    """
      .auix-modal-box {
        margin-left: auto;              
        margin-right: auto;             
      }

    """
  end

  def rule(:auix_modal_box_content) do
    """
    .auix-modal-box-content {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);
    }
    """
  end

  def rule(:auix_modal_focus_wrap) do
    """
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
    """
  end

  def rule(:auix_modal_close_button_container) do
    """
      .auix-modal-close-button-container {
        display: flex;
        flex-direction: row;
        justify-content: flex-end;
      }
    """
  end

  def rule(:auix_modal_close_button) do
    """
      .auix-modal-close-button {
        padding: 0;
        border-width: var(--auix-border-width-default);
        border-radius: var(--auix-border-radius-small);
        opacity: var(--auix-opacity-20);              
      }

      .auix-modal-close-button:hover {
        cursor: pointer;
        opacity: var(--auix-opacity-40);              
      }
    """
  end

  def rule(:auix_flash__info) do
    """
    /* auix-flash--info */

    #{import_rule(:_auix_flash, :auix_flash__info)}

    .auix-flash--info {
      background-color: var(--auix-color-bg-info);

      color: var(--auix-color-info-text);
      fill: var(--auix-color-icon-fill);

      --auix-calc-shadow: var(--auix-shadow-primary);
      box-shadow:
        var(--auix-ring-offset-shadow),
        var(--auix-ring-info),
        var(--auix-calc-shadow);
    }
    """
  end

  def rule(:auix_flash__error) do
    """
    #{import_rule(:_auix_flash, :auix_flash__error)}

    .auix-flash--error {
      background-color: var(--auix-color-error-bg);

      color: var(--auix-color-error-text);
      fill: var(--auix-color-error-text);

      --auix-calc-ring-shadow: var(--auix-ring-inset) 0 0 0 calc(1px + var(--auix-ring-offset-width)) var(--auix-color-error-ring);
      --auix-calc-shadow: var(--auix-shadow-md);
      box-shadow:
        var(--auix-ring-offset-shadow),
        var(--auix-calc-ring-shadow),
        var(--auix-calc-shadow);
    }
    """
  end

  def rule(:auix_flash_title) do
    """
      .auix-flash-title {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        
        font-size: var(--auix-font-size-caption);   
        font-weight: var(--auix-font-weight-bold);      
      }
    """
  end

  def rule(:auix_flash_message) do
    """
      .auix-flash-message {
        font-size: var(--auix-font-size-caption);  
      }
    """
  end

  def rule(:auix_flash_close_button) do
    """
    .auix-flash-close-button {
      background: transparent;
      border: none;
      color: var(--auix-color-text-secondary);
    }
    """
  end

  def rule(:auix_simple_form_content) do
    """
      .auix-simple-form-content {
        display: flex;
        flex-direction: column;
        gap: var(--auix-gap-default);
        background-color: var(--auix-color-bg-default);
      }
    """
  end

  def rule(:auix_simple_form_actions) do
    """
    /* auix-simple-form-actions */

    #{import_rule(:_auix_actions, :auix_simple_form_actions)}
    """
  end

  def rule(:auix_button) do
    """
    /* auix-button */
    #{import_rule(:_auix_button_default, :auix_button)}

    .auix-button {
      background-color: var(--auix-color-bg-default--reverted);
      color: var(--auix-color-text-on-accent);
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
    """
  end

  def rule(:auix_button__alt) do
    """
    /* auix-button--alt */
    #{import_rule(:_auix_button_default, :auix_button__alt)}

    .auix-button--alt {
      background-color: var(--auix-color-bg-light);
      color: var(--auix-color-text-tertiary);
      border-color: var(--auix-color-text-label);         
    }

    .auix-button--alt:disabled {
      background-color: var(--auix-color-bg-backdrop);
      color: var(--auix-color-text-inactive);
    }

    .auix-button--alt:hover {
      background-color: var(--auix-color-bg-hover);
      cursor: pointer;
    }
    """
  end

  def rule(:auix_button_badge) do
    """
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
    """
  end

  def rule(:auix_button__iconized) do
    """
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
    """
  end

  def rule(:auix_button_toggle_filters_container) do
    """
    .auix-button-toggle-filters-container {
      border: none;
    }
    """
  end

  def rule(:auix_button_toggle_filters_content) do
    """
    .auix-button-toggle-filters-content {
      font-size: var(--auix-font-size-caption);
      font-weight: var(--auix-font-weight-bold);
    }
    """
  end

  def rule(:auix_button_toggle_filters_close_link) do
    """
    .auix-button-toggle-filters-close-link {
      display: flex;
      flex-direction: column-reverse;
      align-items: center;
    }
    """
  end

  def rule(:auix_filter_selected_count) do
    """
    .auix-filter-selected-count {    
      position: absolute;
      display: flex;
      background-color: transparent;
      width: 100%;
      height: 2.5rem;
      align-content: center;
      justify-content: space-around;
      flex-wrap: wrap;
    }
    """
  end

  def rule(:auix_fieldset) do
    """
    .auix-fieldset {
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);
      border-width: 0;
    }
    """
  end

  def rule(:auix_checkbox) do
    """
    .auix-checkbox {
        padding: 0;
        display: inline-block;
        vertical-align: middle;
        flex-shrink: 0;
        height: 1rem;
        width: 1rem;
        border-width: 1px;
        border-style: solid;

        border-radius: 0.25rem;
        border-color: var(--auix-color-border-primary);
        background-color: var(--auix-color-bg-default);
        color: var(--auix-color-text-primary);

        box-shadow: none;
        outline: none;
        background-image: none;
      }

      .auix-checkbox:disabled {
        background-color: var(--auix-color-bg-light);
        color: var(--auix-color-text-secondary);

        opacity: 1;
        cursor: not-allowed;
      }
    """
  end

  def rule(:auix_confirm_button_container) do
    """
      .auix-confirm-button--container {
        visibility: visible;
      }
    """
  end

  def rule(:auix_confirm_button__modal) do
    """
      .auix-confirm-button--modal {
        display: flex;
        flex-direction: column;
        align-items: center; 
      }
    """
  end

  def rule(:auix_confirm_button__confirm_message) do
    """
      .auix-confirm-button--confirm-message {
      }
    """
  end

  def rule(:auix_confirm_button__actions) do
    """
      .auix-confirm-button--actions {
        margin-top: 1rem;
        display: flex;
        flex-direction: row;
        justify-content: center;
        gap: 0.75rem;
      }

    """
  end

  def rule(:auix_confirm_button__accept_action) do
    """
      .auix-confirm-button--accept-action {

      }

    """
  end

  def rule(:auix_confirm_button__cancel_action) do
    """
      .auix-confirm-button--cancel-action {

      }

    """
  end

  def rule(:auix_checkbox_label) do
    """
      .auix-checkbox-label {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        line-height: 1.5rem;
        color: var(--auix-color-text-secondary);
      }
    """
  end

  def rule(:auix_select) do
    """
      .auix-select {
        margin-top: 0.5rem;
        padding: 0.25rem;
        display: block;
        width: 100%;
        border-radius: 0.375rem;
        background-color: var(--auix-color-bg-default);
        box-shadow: var(--auix-shadow-small);
        border-width: 1px;
        border-style: solid;
        border-color: var(--auix-color-border-primary);
        -webkit-appearance: none;
        -moz-appearance: none;
        appearance: none;
      }
      .auix-select:not(:disabled) {
        background-image: url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M6 9L12 15L18 9' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
        background-position: right 0.5rem center;
        background-repeat: no-repeat;
        background-size: 1rem 1rem;
        padding-right: 1.5rem;
      }
      .auix-select:disabled {
        background-image: none;
        background-position: right 0.5rem center;
        background-repeat: no-repeat;
        background-size: 1rem 1rem;
        padding-right: 0.5rem;
        cursor: not-allowed;
      }

      .auix-select:focus {
        border-color: var(--auix-color-border-focus);
        --auix-ring-color: transparent;
        box-shadow: none;
        outline: none;
      }

      @media (min-width: 640px) {
        .auix-select {
          font-size: 0.875rem;
          line-height: 1.25rem;
        }
      }
    """
  end

  def rule(:auix_select_label) do
    """
    .auix-select-label {
      content-visibility: visible;
    }
    """
  end

  def rule(:auix_textarea) do
    """
      #{common_text_area_css()}
      .auix-textarea {
        border-color: var(--auix-color-border-primary);
      }
      .auix-textarea:focus {
        border-color: var(--auix-color-border-focus);
      }
    """
  end

  def rule(:auix_textarea__errors) do
    """
      #{common_text_area_css("--errors")}
      .auix-textarea--errors {
        border-color: var(--auix-color-error);
      }
      .auix-textarea--errors:focus {
        border-color: var(--auix-color-error);
      }
    """
  end

  def rule(:auix_input) do
    """
      #{common_input_css()}
      .auix-input {
        border-color: var(--auix-color-border-primary);
      }
      .auix-input:focus {
        border-color: var(--auix-color-border-focus);
      }
    """
  end

  def rule(:auix_input__errors) do
    """
      #{common_input_css("--errors")}
      .auix-input--errors {
        border-color: var(--auix-color-error); 
      }
      .auix-input--errors:focus {
        border-color: var(--auix-color-error); 
      }
    """
  end

  def rule(:auix_label) do
    """
    .auix-label {
      font-size: var(--auix-font-size-caption);             
      font-weight: var(--auix-font-weight-bold);                
      color: var(--auix-color-text-label); 
    }
    """
  end

  def rule(:auix_error_message) do
    """
    .auix-error-message {
      display: flex;
      flex-direction: row;
      justify-content: center;
      align-items: center;

      margin: 0;                       
      font-size: var(--auix-font-size-caption);                       
      color: var(--auix-color-error-text-default); 
    }
    """
  end

  def rule(:auix_header) do
    """
    .auix-header{
      margin-bottom: 0;
    }
    """
  end

  def rule(:auix_header__top_actions) do
    """
    /* auix-header--top-actions */

    #{import_rule(:_auix_actions, :auix_header__top_actions)}

    .auix-header--top-actions {
      padding: var(--auix-padding-minimal);
    }
    """
  end

  def rule(:auix_header_title_container) do
    """
      .auix-header-title-container {
        display: flex;         
        flex-direction: column;
      }
    """
  end

  def rule(:auix_header_title) do
    """
      .auix-header-title {
        font-size: var(--auix-font-size-title);                      
        font-weight: var(--auix-font-weight-bold);                         
        color: var(--auix-color-text-label);
        margin: 0;
      }
    """
  end

  def rule(:auix_header_subtitle) do
    """
      .auix-header-subtitle {
        margin-top: 0rem;
        margin-bottom: 0rem;
        font-size: var(--auix-font-size-subtitle);
        color: var(--auix-color-text-secondary);   
      }
    """
  end

  def rule(:auix_header__bottom_actions) do
    """
      .auix-header--bottom-actions {
        flex-shrink: 0;
        flex-grow: 0;
      }
    """
  end

  def rule(:auix_list) do
    """
      .auix-list {
        margin-top: 3.5rem; 
      }
    """
  end

  def rule(:auix_list_container) do
    """
      .auix-list-container {
        margin-top: -1rem;
        margin-bottom: -1rem;

        --auix-divide-y-reverse: 0;
      }

      .auix-list-container > :not([hidden]) ~ :not([hidden]) {
        border-top-width: calc(1px * calc(1 - var(--auix-divide-y-reverse)));
        border-bottom-width: calc(1px * var(--auix-divide-y-reverse));
        border-style: solid; 

        border-color: var(--auix-color-bg-light);
      }
    """
  end

  def rule(:auix_list_item) do
    """
      .auix-list-item {
        display: flex;                 
        gap: 1rem;                     
        padding-top: 1rem;             
        padding-bottom: 1rem;          
        font-size: 0.875rem;           
        line-height: 1.5rem;           
      }

      @media (min-width: 640px) {
        .auix-list-item {
          gap: 2rem;                   
        }
      }
    """
  end

  def rule(:auix_list_item_title) do
    """
    .auix-list-item-title {
      width: 25%;
      flex-shrink: 0;
      flex-grow: 0;
      color: var(--auix-color-text-tertiary);
    }
    """
  end

  def rule(:auix_list_item_content) do
    """
    .auix-list-item-content {
      color: var(--auix-color-text-hover);
    }
    """
  end

  def rule(:auix_back_link_container) do
    """
    .auix-back-link-container {
    }
    """
  end

  def rule(:auix_back_link) do
    """
    .auix-back-link {
      font-size: 0.875rem;
      font-weight: 600;
      line-height: 1.5rem;
      color: var(--auix-color-text-primary);
    }

    .auix-back-link:hover {
      color: var(--auix-color-text-hover);
    }
    """
  end

  def rule(:auix_show_transition) do
    """
      .auix-show-transition {
        transition-property: all;
        transition-timing-function: cubic-bezier(0.0, 0.0, 0.2, 1);
        transition-duration: 300ms;
      }
    """
  end

  def rule(:auix_show_transition__start) do
    """
      .auix-show-transition--start {
        opacity: 0;
        transform: translateY(1rem);
      }

      @media (min-width: 640px) {
        .auix-show-transition--start {
          transform: translateY(0) scale(0.95);
        }
      }
    """
  end

  def rule(:auix_show_transition__end) do
    """
      .auix-show-transition-end {
        opacity: 1;
        transform: translateY(0);
      }

      @media (min-width: 640px) {
        .auix-show-transition-end {
          transform: scale(1);
        }
      }
    """
  end

  def rule(:auix_hide_transition) do
    """
      .auix-hide-transition {
        transition-property: all;
        transition-timing-function: cubic-bezier(0.4, 0.0, 1, 1);
        transition-duration: 200ms;
      }
    """
  end

  def rule(:auix_hide_transition__start) do
    """
      .auix-hide-transition--start {
        opacity: 1;
        transform: translateY(0);
      }

      @media (min-width: 640px) {
        .auix-hide-transition--start {
          transform: scale(1);
        }
      }
    """
  end

  def rule(:auix_hide_transition__end) do
    """
      .auix-hide-transition--end {
        opacity: 0;
        transform: translateY(1rem);
      }

      @media (min-width: 640px) {
        .auix-hide-transition--end {
          transform: translateY(0) scale(0.95);
        }
      }
    """
  end

  def rule(:auix_show_modal_transition) do
    """
      .auix-show-modal-transition {
        transition-property: all;
        transition-timing-function: cubic-bezier(0.0, 0.0, 0.2, 1);
        transition-duration: 300ms;
      }
    """
  end

  def rule(:auix_show_modal_transition__start) do
    """
      .auix-show-modal-transition--start {
        opacity: 0;
      }
    """
  end

  def rule(:auix_show_modal_transition__end) do
    """
      .auix-show-modal-transition--end {
        opacity: 1;
      }
    """
  end

  def rule(:auix_show_modal) do
    """
      .auix-show-modal {
        overflow-x: hidden;
        overflow-y: hidden;
      }
    """
  end

  def rule(:auix_hide_modal_transition) do
    """
      .auix-hide-modal-transition {
        transition-property: all;
        transition-timing-function: cubic-bezier(0.4, 0.0, 1, 1);
        transition-duration: 200ms;
      }
    """
  end

  def rule(:auix_hide_modal_transition__start) do
    """
      .auix-hide-modal-transition--start {
        opacity: 1;
      }
    """
  end

  def rule(:auix_hide_modal_transition__end) do
    """
      .auix-hide-modal-transition--end {
        opacity: 0;
      }
    """
  end

  def rule(:auix_hide_modal) do
    """
      .auix-hide-modal {
        overflow: hidden;
      }
    """
  end

  def rule(:auix_items_desktop) do
    """
      .auix-items-desktop {
        display: none;
      }

      @media (min-width: 768px) {
        .auix-items-desktop {
          display: block;
        }
      }
    """
  end

  def rule(:auix_items_mobile) do
    """
      .auix-items-mobile {
        margin-top: 0;
      }

      @media (min-width: 768px) {
        .auix-items-mobile {
          visibility: hidden;
          aria-hidden: true;
          position: fixed;
          top: -9999px;
          left: -9999px;
          width: 1px;
          height: 1px;
          overflow: hidden;
          pointer-events: none;
          z-index: -9999;
        }
      }
    """
  end

  def rule(:auix_items_table_container) do
    """
      .auix-items-table-container {
        overflow-y: scroll;               
        padding-left: 1rem;               
        padding-right: 1rem;              
      }

      @media (min-width: 640px) {
        .auix-items-table-container {
          overflow-y: visible;            
          padding-left: 0;                
          padding-right: 0;               
        }
      }
    """
  end

  def rule(:auix_items_table) do
    """
    .auix-items-table {
      width: 40rem;
      margin-top: 0;
    }

    @media (min-width: 640px) {
      .auix-items-table {
        width: 100%;
      }
    }
    """
  end

  def rule(:auix_items_table_header) do
    """
    .auix-items-table-header {
      font-size: 0.875rem;
      color: var(--auix-color-text-tertiary);
    }
    """
  end

  def rule(:auix_items_table_header_row) do
    """
    .auix-items-table-header-row {
      text-align: left;
    }
    """
  end

  def rule(:auix_items_table_header_filter_cell) do
    """
      .auix-items-table-header-filter-cell {
        padding: 0;
        padding-bottom: 0.125rem;
        font-weight: 400;
        height: 100%;
        vertical-align: bottom;
      }
    """
  end

  def rule(:auix_items_table_header_cell) do
    """
    .auix-items-table-header-cell {
    }
    """
  end

  def rule(:auix_items_table_header_cell__first) do
    """
    /* auix-items-table-header-cell--first */

    #{import_rule(:auix_items_table_header_cell, :auix_items_table_header_cell__first)}
    .auix-items-table-header-cell--first {
    }
    """
  end

  def rule(:auix_items_table_body) do
    """
    .auix-items-table-body {
      position: relative;

      border-top-width: 1px;
      border-top-color: var(--auix-color-border-secondary);

      font-size: 0.875rem;
      line-height: 1.5rem;
      color: var(--auix-color-text-hover);
    }

    .auix-items-table-body > tr:not(:last-child) {
      border-bottom-width: 1px;
      border-bottom-color: var(--auix-color-border-tertiary);
    }
    """
  end

  def rule(:auix_items_table_row) do
    """
    .auix-items-table-row {
    }
    .auix-items-table-row:hover {
      background-color: var(--auix-color-bg-hover);
    }
    """
  end

  def rule(:auix_items_table_empty) do
    """
    .auix-items-table-empty {
      width: 100%;
      text-align: center;
      font-size: 1.5em;
      font-weight: bold;
    }
    """
  end

  def rule(:auix_items_table_cell) do
    """
    .auix-items-table-cell {
      padding-right: 0.625rem;
    }
    """
  end

  def rule(:auix_items_table_action_cell) do
    """
      .auix-items-table-action-cell {
        display: flex;
        flex-direction: row;
        justify-content: flex-end;
        gap: 0.5rem;
        padding-top: 0.250rem;
        padding-left: 0rem;
      }
    """
  end

  def rule(:auix_items_card_container) do
    """
      .auix-items-card-container {
        margin-top: 0.5rem;
      }
    """
  end

  def rule(:auix_items_card_empty) do
    """
    /* auix-items-card-empty */

    #{import_rule(:auix_items_table_empty, :auix_items_card_empty)}
    """
  end

  def rule(:auix_items_card_item_content) do
    """
    .auix-items-card-item-content {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
      gap: 0.5rem;
      padding-top: 0.25rem;
      padding-right: 0.5rem;
      padding-bottom: 0.25rem;
      margin-bottom: 0.25rem;
      border-radius: 0.5rem;
    }
    """
  end

  def rule(:auix_items_card_item_content__even) do
    """
    /* auix-items-card-item-content--even */

    #{import_rule(:auix_items_card_item_content, :auix_items_card_item_content__even)}
    .auix-items-card-item-content--even {
      background-color: var(--auix-color-bg-secondary);
    }
    """
  end

  def rule(:auix_items_card_item_content__odd) do
    """
    /* auix-items-card-item-content--odd */

    #{import_rule(:auix_items_card_item_content, :auix_items_card_item_content__odd)}
    .auix-items-card-item-content--odd {
      background-color: var(--auix-color-bg-default);
    }
    """
  end

  def rule(:auix_items_card_item_group) do
    """
    .auix-items-card-item-group {
      display: flex;
      flex-direction: row;
      gap: 0.5rem;
      align-items: center;
    }
    """
  end

  def rule(:auix_items_card_item) do
    """
    .auix-items-card-item {
    }
    """
  end

  def rule(:auix_items_card_item_fieldset) do
    """
    .auix-items-card-item-fieldset {
      line-height: 1rem;
    }
    """
  end

  def rule(:auix_items_card_item_label) do
    """
    .auix-items-card-item-label {
      font-size: 0.875rem;
      font-weight: bold;
    }
    """
  end

  def rule(:auix_items_card_item_value) do
    """
    .auix-items-card-item-value {
      padding-left: 0.250rem;
      font-style: italic;
    }
    """
  end

  def rule(:auix_items_card_actions) do
    """
    .auix-items-card-actions{

    }
    """
  end

  def rule(:auix_pagination_bar) do
    """
    .auix-pagination-bar {
      display: flex;
      flex-direction: row;
      gap: 0.75rem;
      justify-content: center;
      overflow-x: clip;
    }
    """
  end

  def rule(:auix_pagination_bar_link) do
    """
    .auix-pagination-bar-link {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    """
  end

  def rule(:auix_pagination_bar_current_page) do
    """
    .auix-pagination-bar-current-page {
      margin-top: 0;
      margin-bottom: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
    }
    """
  end

  def rule(:auix_pagination_bar_current_page_number) do
    """
    .auix-pagination-bar-current-page-number {
      border: 1px solid var(--auix-color-border-focus);
      border-radius: 9999px;
      padding-top: 0;
      padding-bottom: 0;
      padding-left: 0.250rem;
      padding-right: 0.250rem;
      color: var(--auix-color-text-on-accent);
      background-color: var(--auix-color-bg-default--reverted);
    }
    """
  end

  def rule(:auix_pagination_bar_selected_count) do
    """
    .auix-pagination-bar-selected-count {
      font-size: 0.75rem;
      text-align: center;
      vertical-align: sub;
      border-width: 1px;
    }
    """
  end

  def rule(:auix_filter_card) do
    """
    .auix-filter-card:not(:nth-child(1)) {
      border-bottom: 1px solid var(--auix-color-border-primary);
      margin-bottom: 0.25rem;
    }
    """
  end

  def rule(:auix_filter_fieldset) do
    """
    .auix-filter-fieldset {
      width: 100%;
    }
    """
  end

  def rule(:auix_filter_field) do
    """
      .auix-filter-field {
      }

    """
  end

  def rule(:auix_filter_field_content) do
    """
    .auix-filter-field-content {
    }
    """
  end

  def rule(:auix_filter_input) do
    """
      .auix-filter-input {
        display: block;
        width: 100%;
        padding-bottom: 0;
        padding-top: 0;
        margin-top: 0.1rem;
        border-radius: 0.125rem;
        border-color: var(--auix-color-border-primary);
        box-shadow: var(--auix-shadow-small);
      }

      .auix-filter-input:focus {
        border-color: var(--auix-color-focus-ring);
        outline: 2px solid transparent;
        outline-offset: 2px;

      box-shadow:
        var(--auix-ring-offset-shadow),
        var(--auix-ring-default),
        var(--auix-shadow-primary);
      }

      @media (min-width: 640px) {
        .auix-filter-input {
          font-size: 0.875rem;
          line-height: 1.25rem;
        }
      }
    """
  end

  def rule(:auix_filter_input_field) do
    """
    .auix-filter-input-field {
      padding-bottom: 0;
      padding-top: 0;
      margin-top: -0.250rem;
    }
    """
  end

  def rule(:auix_filter_input_field__disabled) do
    """
    /* auix-filter-input-field--disabled */

    #{import_rule(:auix_filter_input_field, :auix_filter_input_field__disabled)}

    .auix-filter-input-field--disabled {
      background-color: var(--auix-color-bg-disabled) !important;
    }
    """
  end

  def rule(:auix_filter_condition_label) do
    """
    .auix-filter-condition-label {
      height: 0.8rem !important;
      margin-top: 1rem;
    }


    @media (min-width: 768px) {
      .auix-filter-condition-label {
        display: none;
      }
    }
    """
  end

  def rule(:auix_filter_condition_input) do
    """
    .auix-filter-condition-input {
      margin-top: 0px;
    }
    """
  end

  def rule(:auix_index_container) do
    """
    .auix-index-container {
      display: flex;
      flex-direction: column;
      gap: calc(var(--auix-gap-default) * 2);
      caret-color: transparent;
    }

    @media (min-width: 640px) {
      .auix-index-container {
        padding: var(--auix-padding-default);
      }
    }

    @media (min-width: 768px) {
      .auix-index-container {
        margin-left: auto;
        margin-right: auto;
        width: max-content;
        max-width: max-content;
        padding: var(--auix-padding-large);
      }
    }

    @media (min-width: 1024px) {
      .auix-index-container {
        padding-top: var(--auix-padding-xl);
        padding-bottom: var(--auix-padding-xl);
        padding-left: var(--auix-padding-large);
        padding-right: var(--auix-padding-xl);
      } 
    }

    """
  end

  def rule(:auix_index_actions) do
    """
    .auix-index-actions {
      display: flex;
      flex-direction: row;
      justify-content: space-between;
    }
    """
  end

  def rule(:auix_index_row_action) do
    """
    .auix-index-row-action{
    }
    """
  end

  def rule(:auix_index_header_actions) do
    """
      .auix-index-header-actions {
        display: flex;
        flex-direction: row;
        align-items: center;
        gap: var(--auix-gap-default);
      }
    """
  end

  def rule(:auix_index_filter_element_actions) do
    """
    /* auix-index-filter-element-actions */

    #{import_rule(:_auix_actions, :auix_index_filter_element_actions)}
    .auix-index-filter-element-actions {
      width: 100%;
    }
    """
  end

  def rule(:auix_index_filter_element_actions_content) do
    """
      .auix-index-filter-element-actions-content {
        position: relative;            
        white-space: nowrap;
        padding-top: 1rem;
        padding-bottom: 1rem;
        text-align: right;
        font-size: 0.875rem;
        font-weight: 500; 
      }
    """
  end

  def rule(:auix_index_filter_element_action_button) do
    """
      .auix-index-filter-element-action-button {
        position: relative;            
        margin-left: 1rem;
        font-weight: 600; 
        line-height: 1.5rem; 
        color: var(--color-text-primary);
      }

      .auix-index-filter-element-action-button:hover {
        color: var(--color-text-hover);
      }
    """
  end

  def rule(:auix_index_select_actions) do
    """
    .auix-index-select-actions {
      display: flex;
      flex-direction: row;
      align-items: center;
      gap: var(--auix-gap-default);
    }
    """
  end

  def rule(:auix_index_all_action_button) do
    """
    /* auix-index-all-action-button */

    #{import_rule(:auix_button__alt, :auix_index_all_action_button)}

    .auix-index-all-action-button {
      gap: var(--auix-gap-default);
    }

    """
  end

  def rule(:auix_show_container) do
    """
    /* auix-show-container */

    #{import_rule(:auix_index_container, :auix_show_container)}

    @media (min-width: 768px) {
      .auix-show-container {
        border-width: var(--auix-border-width-default);
        border-radius: var(--auix-border-radius-default);
        box-shadow: var(--auix-shadow-lg);
      }
    }
    """
  end

  def rule(:auix_show_content) do
    """
    .auix-show-content {
      padding: var(--auix-padding-minimal);
      border-width: var(--auix-border-width-default);
      border-radius: var(--auix-border-radius-default);
      box-shadow: var(--auix-shadow-md);
      background-color: var(--auix-color-bg-default);
    }
    """
  end

  def rule(:auix_form_container) do
    """
    .auix-form-container {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);

      padding: var(--auix-padding-default);
      border-radius: var(--auix-border-radius-default);
      border-width: var(--auix-border-width-default);

      background-color: var(--auix-color-bg-default);
      box-shadow: var(--auix-shadow-default);
    }
    """
  end

  def rule(:auix_sections_container) do
    """
    .auix-sections-container {
      content-visibility: visible;
    }
    """
  end

  def rule(:auix_sections_tab_container) do
    """
    .auix-sections-tab-container {
      margin-top: var(--auix-margin-medium);
      display: flex;
      flex-direction: column;
    }

    @media (min-width: 640px) {
      .auix-sections-tab-container {
        flex-direction: row;
      }
    }
    """
  end

  def rule(:auix_sections_tab_button__active) do
    """
    #{common_sections_tab_button_css("--active")}
    .auix-sections-tab-button--active {
      font-weight: var(--auix-font-weight-bold);
      color: var(--auix-color-text-label);
      background-color: var(--auix-color-bg-light);
      border-left-width: var(--auix-border-width-default);
      border-color: var(--auix-color-bg-light);
      border-style: var(--auix-border-style-default);
    }
    """
  end

  def rule(:auix_sections_tab_button__inactive) do
    """
    #{common_sections_tab_button_css("--inactive")}
    .auix-sections-tab-button--inactive {
      font-weight: var(--auix-font-weight-bold);
      color: var(--auix-color-text-inactive);
      background-color: var(--auix-color-bg-hover);
    }
    """
  end

  def rule(:auix_sections_content) do
    """
    .auix-sections-content {

      padding: var(--auix-padding-default);            

      border-width: var(--auix-border-width-default);        
      border-color: var(--auix-color-bg-light); 
      border-style: var(--auix-border-style-default);
      border-top-left-radius: 0;
      border-top-right-radius: var(--auix-border-radius-default);
      border-bottom-left-radius: var(--auix-border-radius-default);
      border-bottom-right-radius: var(--auix-border-radius-default);

    }
    """
  end

  def rule(:auix_form_field_container) do
    """
      .auix-form-field-container {
        display: flex;         
        flex-direction: column; 
      }
    """
  end

  def rule(:auix_form_field_input) do
    """
      .auix-form-field-input {
        display: block;
        width: 100%;

        border-width: 1px;
        border-style: solid;
        border-radius: 0.375rem;
        border-color: var(--auix-color-border-primary);

        box-shadow: var(--auix-shadow-small);

        font-size: 1rem;
        line-height: 1.5rem;
      }

      .auix-form-field-input:focus {
        outline: 2px solid transparent;
        outline-offset: 2px;

        border-color: var(--auix-color-focus-ring);

        box-shadow:
          0 0 0 3px var(--auix-color-focus-ring), var(--auix-shadow-small); 
      }

      @media (min-width: 640px) {
        .auix-form-field-input {
          font-size: 0.875rem;
          line-height: 1.25rem;
        }
      }
    """
  end

  def rule(:auix_one_to_many_field) do
    """
      .auix-one-to-many-field {
        display: flex;
        flex-direction: column;
        gap: 0.375rem;
        width: 100%;
      }
    """
  end

  def rule(:auix_one_to_many_header) do
    """
      .auix-one-to-many-header {
        display: flex;
      }
    """
  end

  def rule(:auix_one_to_many_header_actions) do
    """
      .auix-one-to-many-header-actions {
        display: inline;
      }
    """
  end

  def rule(:auix_one_to_many_container) do
    """
      .auix-one-to-many-container {
        width: auto;
        border-width: 1px;
        border-style: solid;
        border-radius: 0.5rem;

        padding-left: 0.125rem;
        padding-right: 0.125rem;

        color: var(--auix-color-text-primary);
        border-color: var(--auix-color-border-primary);
      }


      @media (min-width: 640px) {
        .auix-one-to-many-container {
          font-size: 0.875rem;
          line-height: 1.5rem;
        }
      }
    """
  end

  def rule(:auix_one_to_many_footer) do
    """
      .auix-one-to-many-footer {
        display: flex;
        flex-direction: row;
      }
    """
  end

  def rule(:auix_one_to_many_footer_actions) do
    """
      .auix-one-to-many-footer-actions {
        display: flex;
        flex-direction: column;
      }
    """
  end

  def rule(:auix_visually_hidden) do
    """
      .auix-visually-hidden {
        position: absolute;
        width: 1px;
        height: 1px;
        padding: 0;
        margin: -1px;
        overflow: hidden;
        clip: rect(0, 0, 0, 0);
        clip-path: inset(50%);
        white-space: nowrap;
        border-width: 0;
      }
    """
  end

  def rule(:auix_pagination_container) do
    """
      .auix-pagination-container {
        margin-top: 0;
      }
    """
  end

  def rule(:auix_pagination_breakpoint_xl2) do
    """
      .auix-pagination-breakpoint-xl2 {

        height: 0;
        visibility: hidden;
      }


      @media (min-width: 1536px) {
        .auix-pagination-breakpoint-xl2 {
          visibility: visible;
          height: auto;
        }
      }
    """
  end

  def rule(:auix_pagination_breakpoint_xl) do
    """
      .auix-pagination-breakpoint-xl {

        height: 0;
        visibility: hidden;
      }


      @media (min-width: 1280px) {
        .auix-pagination-breakpoint-xl {
          visibility: visible;
          height: auto;
        }
      }


      @media (min-width: 1536px) {
        .auix-pagination-breakpoint-xl {
          visibility: hidden;
          height: 0;
        }
      }
    """
  end

  def rule(:auix_pagination_breakpoint_lg) do
    """
      .auix-pagination-breakpoint-lg {

        height: 0;                
        visibility: hidden;         
      }


      @media (min-width: 1024px) {
        .auix-pagination-breakpoint-lg {
          visibility: visible;
          height: auto;
        }
      }


      @media (min-width: 1280px) {
        .auix-pagination-breakpoint-lg {
          visibility: hidden;
          height: 0;
        }
      }
    """
  end

  def rule(:auix_pagination_breakpoint_md) do
    """
      .auix-pagination-breakpoint-md {

        height: 0;                
        visibility: hidden;         

        font-size: 0.875rem;        
      }


      @media (min-width: 768px) {
        .auix-pagination-breakpoint-md {
          visibility: visible;
          height: auto;
        }
      }


      @media (min-width: 1024px) {
        .auix-pagination-breakpoint-md {
          visibility: hidden;
          height: 0; 
        }
      }
    """
  end

  def rule(:auix_group_container) do
    """
    .auix-group-container {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);
      padding: var(--auix-padding-minimal);

      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-radius: var(--auix-border-radius-default);
      border-color: var(--auix-color-border-primary);

      background-color: var(--auix-color-bg-light);
    }
    """
  end

  def rule(:auix_group_title) do
    """
    .auix-group-title {
      margin: 0;
      font-weight: var(--auix-font-weight-bold);     
      font-size: var(--auix-font-size-title);
    }
    """
  end

  def rule(:auix_inline_container) do
    """
      .auix-inline-container {
        display: flex;             
        flex-direction: column;    
        gap: var(--auix-gap-minimal);               
      }


      @media (min-width: 768px) {
        .auix-inline-container {
          flex-direction: row;
        }
      }
    """
  end

  def rule(:auix_stacked_container) do
    """
      .auix-stacked-container {
        display: flex;             
        flex-direction: column;    
        gap: var(--auix-gap-minimal);               
      }
      
      @media (min-width: 768px) {
        .auix-inline-container {
          gap: var(--auix-gap-default);               
        }
      }
    """
  end

  def rule(:auix_icon_size_3) do
    """
    .auix-icon-size-3 {
      width: var(--auix-icon-size-3);          
      height: var(--auix-icon-size-3);         
    }
    """
  end

  def rule(:auix_icon_size_4) do
    """
    .auix-icon-size-4 {
      width: var(--auix-icon-size-4);          
      height: var(--auix-icon-size-4);         
    }
    """
  end

  def rule(:auix_icon_size_5) do
    """
    .auix-icon-size-5 {
      width: var(--auix-icon-size-5);          
      height: var(--auix-icon-size-5);         
    }
    """
  end

  def rule(:auix_icon_size_6) do
    """
    .auix-icon-size-6 {
      width: var(--auix-icon-size-6);          
      height: var(--auix-icon-size-6);         
    }
    """
  end

  def rule(:auix_icon_size_button) do
    """
    .auix-icon-size-button {
      width: var(--auix-icon-size-button);          
      height: var(--auix-icon-size-button);         
    }
    """
  end

  def rule(:auix_icon_default) do
    """
    .auix-icon-default {
      color: var(--auix-color-icon-default)
    }
    """
  end

  def rule(:auix_icon_safe) do
    """
    .auix-icon-safe:hover {
      color: var(--auix-color-icon-safe)
    }
    """
  end

  def rule(:auix_icon_info) do
    """
    .auix-icon-info:hover {
      color: var(--auix-color-icon-info)
    }
    """
  end

  def rule(:auix_icon_danger) do
    """
    .auix-icon-danger {
      color: var(--auix-color-icon-danger)
    }
    """
  end

  def rule(:auix_icon_inactive) do
    """
    .auix-icon-inactive {
      color: var(--auix-color-icon-inactive)
    }
    """
  end

  def rule(:auix_vertical_align_super) do
    """
    .auix-vertical-align-super {
      vertical-align: super;
    }
    """
  end

  def rule(:auix_animate_spin) do
    """
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
    """
  end

  def rule(:auix_embeds_one_container) do
    """
    .auix-embeds-one-container {
      padding: var(--auix-padding-default);

      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-radius: var(--auix-border-radius-default);                             
      border-color: var(--auix-color-border-secondary);
      background-color: var(--auix-color-bg-inner-container);
      box-shadow: var(--auix-shadow-default);            
    }
    """
  end

  def rule(:auix_embeds_many_container) do
    """
    .auix-embeds-many-container {
      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-radius: var(--auix-border-radius-default);                             
      border-color: var(--auix-color-border-secondary);
      background-color: var(--auix-color-bg-inner-container);
      box-shadow: var(--auix-shadow-default);            
    }
    """
  end

  def rule(:auix_embeds_many_details) do
    """
    .auix-embeds-many-details {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);

      padding: var(--auix-padding-default)
    }
    """
  end

  def rule(:auix_embeds_many_summary) do
    """
    .auix-embeds-many-summary:hover {
      cursor: pointer;
    }
    """
  end

  def rule(:auix_embeds_many_summary_content) do
    """
    .auix-embeds-many-summary-content {
      display: inline-flex;
      flex-direction: row;
      gap: var(--auix-gap-default);
    }
    """
  end

  def rule(:auix_embeds_many_content) do
    """
    .auix-embeds-many-content {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);
    }
    """
  end

  def rule(:auix_embeds_many_header_container) do
    """
      .auix-embeds-many-header-container {
        display: flex;
        flex-direction: row;
        gap: 0.5rem;
      }
    """
  end

  def rule(:auix_embeds_many_header_actions) do
    """
      .auix-embeds-many-header-actions {
        display: flex;
        gap: 0.5rem;
      }
    """
  end

  def rule(:auix_embeds_many_footer_container) do
    """
      .auix-embeds-many-footer-container {
      }
    """
  end

  def rule(:auix_embeds_many_footer_actions) do
    """
    /* auix-embeds-many-footer-actions */

    #{import_rule(:_auix_actions, :auix_embeds_many_footer_actions)}
    .auix-embeds-many-footer-actions {
      flex-direction: row;
      justify-content: flex-end;
    }
    """
  end

  def rule(:auix_embeds_many_new_entry_container) do
    """
      .auix-embeds-many-new-entry-container {
      }
    """
  end

  def rule(:auix_embeds_many_new_entry_actions) do
    """
    /* auix-embeds-many-new-entry-actions */

    #{import_rule(:_auix_actions, :auix_embeds_many_new_entry_actions)}
    """
  end

  def rule(:auix_embeds_many_existing_container) do
    """
      .auix-embeds-many-existing-container {
        display: flex;
        justify-content: flex-end;
      }
    """
  end

  def rule(:auix_embeds_many_existing_actions) do
    """
    /* auix-embeds-many-existing-actions */

    #{import_rule(:_auix_actions, :auix_embeds_many_existing_actions)}
    """
  end

  def rule(:auix_embeds_many__remove_entry_action) do
    """
    .auix-embeds-many--remove-entry-action {
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    """
  end

  def rule(:auix_embeds_many_entry_contents) do
    """
    .auix-embeds-many-entry-contents {
      display: flex;
      flex-direction: column;
      gap: var(--auix-gap-default);

      padding: var(--auix-padding-default);
      border-width: var(--auix-border-width-default);
      border-style: var(--auix-border-style-default);
      border-radius: var(--auix-border-radius-default);                             
      border-color: var(--auix-color-border-secondary);
      background-color: var(--auix-color-bg-inner-container);
      box-shadow: var(--auix-shadow-default);            
    }
    """
  end

  def rule(:auix_embeds_many_entry__badge) do
    """
    .auix-embeds-many-entry--badge {
      display: flex;
      flex-direction: row-reverse;
    }
    """
  end

  def rule(:auix_embeds_many_entry__badge_text) do
    """
    .auix-embeds-many-entry--badge-text {
      padding: var(--auix-padding-small) var(--auix-padding-medium);
      background-color: var(--auix-color-bg-default--reverted);
      color: var(--auix-color-text-on-accent);
      border-radius: var(--auix-border-radius-round);
      font-size: var(--auix-font-size-small);
      font-weight: var(--auix-font-weight-bold);
    }
    """
  end

  def rule(_), do: ""

  ## PRIVATE
  @spec common_text_area_css(binary()) :: binary()
  defp common_text_area_css(suffix \\ "") do
    """
      .auix-textarea#{suffix} {
        margin: 0;               
        color: var(--auix-color-text-primary); 
        padding: var(--auix-padding-minimal);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-small);            
      }

      @media (max-width: 640px) {
        .auix-textarea#{suffix} {
          font-size: var(--auix-font-size-caption);            
        }
      }
    """
  end

  @spec common_input_css(binary()) :: binary()
  defp common_input_css(suffix \\ "") do
    """
      .auix-input#{suffix} {
        padding: var(--auix-padding-minimal);
        color: var(--color-text-primary);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-small);
        caret-color: var(--auix-color-text-primary);
      }

      .auix-input#{suffix}:focus {
        --auix-ring-color: transparent;
        box-shadow: none;
        outline: none;
      }

      @media (max-width: 640px) {
        .auix-input#{suffix} {
          font-size: var(--auix-font-size-caption);
        }
      }
    """
  end

  @spec common_sections_tab_button_css(binary()) :: binary()
  defp common_sections_tab_button_css(suffix) do
    """
    .auix-sections-tab-button#{suffix} {
        padding: var(--auix-padding-minimal) var(--auix-padding-default);
        font-size: var(--auix-font-size-caption);
        border-bottom-width: var(--auix-border-width-thick);
        border-color: transparent;
        border-top-left-radius: var(--auix-border-radius-default);
        border-top-right-radius: var(--auix-border-radius-default);
      }
    """
  end
end
