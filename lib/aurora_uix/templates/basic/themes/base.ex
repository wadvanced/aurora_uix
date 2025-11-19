defmodule Aurora.Uix.Templates.Basic.Themes.Base do
  @moduledoc """
  The base theme for the Basic template.

  This theme defines a set of CSS rules for the base theme.
  """
  use Aurora.Uix.Templates.Theme

  import Aurora.Uix.Templates.ThemeHelper, only: [import_rule: 2]

  @impl true
  @spec rule(atom()) :: binary()

  def rule(:auix_html) do
    """
        html, :host {
          line-height: 1.5;
          -webkit-text-size-adjust: 100%;
          tab-size: 4;
          font-family: var(--auix-default-font-family, ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji');
          font-feature-settings: var(--auix-default-font-feature-settings, normal);
          font-variation-settings: var(--auix-default-font-variation-settings, normal);
          -webkit-tap-highlight-color: transparent;
        }
    """
  end

  def rule(:auix_horizontal_divider) do
    """
    .auix-horizontal-divider {
      border-top: 1px solid var(--auix-color-border-default);
      margin-top: 0.125rem;
      margin-bottom: 0.250rem;
    }
    """
  end

  def rule(:auix_tag_a) do
    """
      a {
        color: inherit;
        -webkit-text-decoration: inherit;
        text-decoration: inherit;
      }
    """
  end

  def rule(:auix_modal) do
    """
      .auix-modal {
        
        position: relative; 
        z-index: 50;        /* z-50 */
        display: none;
      }
    """
  end

  def rule(:auix_modal_background) do
    """
      .auix-modal-background {
        background-color: var(--auix-color-bg-backdrop);

        /* fixed inset-0 */
        position: fixed;
        top: 0;
        right: 0;
        bottom: 0;
        left: 0;

        /* transition-opacity */
        transition-property: opacity;
        transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
        transition-duration: 150ms; /* Default Tailwind duration */
      }
    """
  end

  def rule(:auix_modal_container) do
    """
      .auix-modal-container {
        /* fixed inset-0 overflow-y-auto */
        position: fixed;
        top: 0;
        right: 0;
        bottom: 0;
        left: 0;
        overflow-y: auto;
      }
    """
  end

  def rule(:auix_modal_content) do
    """
    .auix-modal-content {
      /* flex min-h-full items-center justify-center */
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
        /* max-w-max max-w-3xl p-4 sm:p-6 lg:py-8 mx-auto */
        max-width: max-content;         /* max-w-max (Overridden by max-w-3xl) */
        padding: 1rem;                  /* p-4 (4 * 0.25rem = 1rem) */
        margin-left: auto;              /* mx-auto */
        margin-right: auto;             /* mx-auto */
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-modal-box {
          padding: 1.5rem;              /* sm:p-6 (6 * 0.25rem = 1.5rem) */
        }
      }

      /* Large breakpoint (lg) and up */
      @media (min-width: 1024px) {
        .auix-modal-box {
          padding-top: 2rem;            /* lg:py-8 (8 * 0.25rem = 2rem) */
          padding-bottom: 2rem;         /* lg:py-8 */
        }
      }
    """
  end

  def rule(:auix_modal_focus_wrap) do
    """
      .auix-modal-focus-wrap {
        /* shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition */

        /* POSITIONING & VISIBILITY */
        position: relative;            
        display: none;                 /* hidden */

        /* BOX STYLES */
        border-radius: 1rem;           /* rounded-2xl (16px) */
        background-color: var(--auix-color-bg-default); /* bg-white */
        padding: 3.5rem;               /* p-14 (14 * 0.25rem = 3.5rem) */

        /* RING */
        --auix-calc-shadow: var(--auix-shadow-lg), var(--auix-shadow-secondary);

        box-shadow:
          var(--auix-ring-offset-shadow),
          var(--auix-ring-secondary),
          var(--auix-calc-shadow);

        border-width: 1px;

        /* TRANSITION */
        transition-property: color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter; /* transition (all properties) */
        transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
        transition-duration: 150ms;
      }
    """
  end

  def rule(:auix_modal_close_button_container) do
    """
      .auix-modal-close-button-container {
        /* absolute top-6 right-5 */
        position: absolute;
        top: 1.5rem;   /* top-6 (6 * 0.25rem = 1.5rem) */
        right: 1.25rem; /* right-5 (5 * 0.25rem = 1.25rem) */
      }
    """
  end

  def rule(:auix_modal_close_button) do
    """
      .auix-modal-close-button {
        /* -m-3 flex-none p-3 opacity-20 hover:opacity-40 */
        margin: -0.75rem;          /* -m-3 (-3 * 0.25rem = -0.75rem) */
        flex-shrink: 0;            /* flex-none (shorthand for flex-shrink: 0 and flex-grow: 0) */
        flex-grow: 0;              /* flex-none */
        padding: 0.75rem;          /* p-3 (3 * 0.25rem = 0.75rem) */
        opacity: 0.2;              /* opacity-20 */
      }

      /* Hover state */
      .auix-modal-close-button:hover {
        opacity: 0.4;              /* hover:opacity-40 */
      }
    """
  end

  def rule(:auix_flash) do
    """
      .auix-flash {
        /* POSITIONING & SIZE */
        position: fixed;                 /* fixed */
        top: 0.5rem;                     /* top-2 (2 * 0.25rem = 0.5rem) */
        right: 0.5rem;                   /* right-2 */
        margin-right: 0.5rem;            /* mr-2 */
        width: max-content;                    /* w-80 (80 * 0.25rem = 20rem) */
        z-index: 50;                     /* z-50 */

        /* BOX STYLES */
        border-radius: 0.5rem;           /* rounded-lg */
        padding: 0.125rem;                /* p-3 (3 * 0.25rem = 0.75rem) */
      }
    """
  end

  def rule(:auix_flash__info) do
    """
      #{import_rule(:auix_flash, :auix_flash__info)}

      .auix-flash--info {
        background-color: var(--auix-color-bg-info);

        /* TEXT & ICON */
        color: var(--auix-color-info-text);
        fill: var(--auix-color-icon-fill);

        /* RING */
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
      .auix-flash--error {
        #{common_flash_css()}
        background-color: var(--auix-color-error-bg);

        /* TEXT & ICON */
        color: var(--auix-color-error-text);
        fill: var(--auix-color-error-text);

        /* RING & SHADOW */
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
        /* flex items-center gap-1.5 text-sm font-semibold leading-6 */
        display: flex;         /* flex */
        align-items: center;   /* items-center */
        gap: 0.375rem;         /* gap-1.5 (1.5 * 0.25rem = 0.375rem) */
        font-size: 0.875rem;   /* text-sm */
        font-weight: 600;      /* font-semibold */
        line-height: 1.5rem;   /* leading-6 (6 * 0.25rem = 1.5rem) */
        margin-top: 0.125rem;
        margin-bottom: 0.5rem;
        padding-left: 0.5rem;
      }
    """
  end

  def rule(:auix_flash_message) do
    """
      .auix-flash-message {
        /* mt-2 text-sm leading-5 */
        margin-top: 0.250rem;   /* mt-2 (2 * 0.25rem = 0.5rem) */
        margin-bottom: 0.5rem;
        font-size: 0.875rem;  /* text-sm */
        line-height: 1.25rem; /* leading-5 (5 * 0.25rem = 1.25rem) */
        padding-left: 0.5rem;
        padding-right: 0.5rem;
      }
    """
  end

  def rule(:auix_flash_close_button) do
    """
      .auix-flash-close-button {
        position: absolute;       /* absolute */
        inset-inline-end: 0.25rem;  /* right-1 */
        inset-block-start: 0.25rem;             /* top-1 (1 * 0.25rem = 0.25rem) */
        padding: 0.125rem;
        background: transparent;
        border: none;
      }
    """
  end

  def rule(:auix_simple_form_content) do
    """
      .auix-simple-form-content {
        /* mt-10 space-y-8 bg-white */
        margin-top: 1rem;             /* mt-10 (10 * 0.25rem = 2.5rem) */
        background-color: var(--auix-color-bg-default); /* bg-white */
      }
    """
  end

  def rule(:auix_simple_form_actions) do
    """
      .auix-simple-form-actions {
        #{common_actions_css()}
      }
    """
  end

  def rule(:auix_button) do
    """
      .auix-button {
        border-radius: 0.5rem;
        background-color: var(--auix-color-bg-default--reverted);
        padding: 0.5rem 0.75rem;
        font-size: 0.875rem;
        font-weight: 600;
        line-height: 1.5rem;
        color: var(--auix-color-text-on-accent);
      }

      .auix-button:hover {
        background-color: var(--auix-color-bg-hover--reverted);
      }

      .auix-button:active {
        color: var(--auix-color-text-on-accent-active);
      }

      .auix-button[phx-submit-loading] {
        opacity: 0.75;
      }
    """
  end

  def rule(:auix_button__alt) do
    """
    .auix-button--alt {
      background-color: var(--auix-color-bg-light) !important;

      color: var(--auix-color-text-tertiary) !important;

      border-width: 1px;
      border-style: solid;
      border-color: var(--auix-color-text-label);         
    }

    .auix-button--alt:disabled {
      background-color: var(--auix-color-bg-backdrop) !important;
      color: var(--auix-color-text-inactive) !important;
    }

    .auix-button--alt:hover {
      background-color: var(--auix-color-bg-hover) !important;
    }
    """
  end

  def rule(:auix_button_badge) do
    """
      .auix-button-badge {
        /* text-xs align-sub border */

        /* TYPOGRAPHY */
        font-size: 0.75rem;     /* text-xs (12px) */
        vertical-align: sub;    /* align-sub */

        /* BORDER */
        border-width: 1px;      /* border */
        border-style: solid;    /* Implicit border style */
      }
    """
  end

  def rule(:auix_button__danger) do
    """
      .auix-button--danger {
        border-radius: 0.5rem;
        background-color: var(--auix-color-bg-danger);
        padding: 0.5rem 0.75rem;
        font-size: 0.875rem;
        font-weight: 600;
        line-height: 1.5rem;
        color: var(--auix-color-text-on-accent);
      }

      .auix-button--danger:hover {
        background-color: var(--auix-color-bg-danger-hover);
      }

      .auix-button--danger:active {
        color: var(--auix-color-text-on-accent-active);
      }

      .auix-button--danger[phx-submit-loading] {
        opacity: 0.75;
      }
    """
  end

  def rule(:auix_button_toggle_filters_container) do
    """
      .auix-button-toggle-filters-container {
        

        /* POSITIONING & LAYOUT */
        position: relative;         
        width: max-content;              /* w-14 (14 * 0.25rem = 3.5rem / 56px) */

        /* SPACING */
        padding-right: 0.25rem;     /* pr-1 (1 * 0.25rem = 0.25rem / 4px) */

        border: 0;
      }
    """
  end

  def rule(:auix_button_toggle_filters_content) do
    """
      .auix-button-toggle-filters-content {
        

        /* POSITIONING & CONTENT FLOW */
        position: relative;         
        white-space: nowrap;        /* whitespace-nowrap (Prevents text wrapping) */
        width: max-content;

        /* PADDING & ALIGNMENT */
        padding-top: 0.5rem;        /* py-2 (2 * 0.25rem = 0.5rem) */
        padding-bottom: 0.5rem;     /* py-2 */
        text-align: right;          /* text-right */

        /* TYPOGRAPHY */
        font-size: 0.875rem;        /* text-sm (14px) */
        font-weight: 500;           /* font-medium */
      }
    """
  end

  def rule(:auix_button_toggle_filters_focus_ring) do
    """
      .auix-button-toggle-filters-focus-ring {
        /* absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl */

        /* POSITIONING & SIZE */
        position: absolute;         /* absolute */
        top: -1px;                  /* -inset-y-px */
        bottom: -1px;               /* -inset-y-px (The -y-px means top: -1px and bottom: -1px) */
        right: 0rem;               /* -right-4 (4 * 0.25rem = 1rem, negative value) */
        left: -0.25rem;
        width: 1.5rem;

        /* SHAPE */
        border-top-right-radius: 0;   /* Reset any default rounding */
        border-bottom-right-radius: 0;/* Reset any default rounding */

        /* BACKGROUND (Default state - usually transparent) */
        background-color: transparent;
      }

      /* --- Group Hover State (Triggered when the parent group is hovered) --- */

      .auix-button-toggle-filters-container:hover .auix-button-toggle-filters-focus-ring {
        /* group-hover:bg-zinc-50 */
        background-color: var(--auix-color-bg-hover); /* bg-zinc-50 */
      }

      /* --- Responsive Overrides (Small screens and up: sm) --- */

      @media (min-width: 640px) {
        .auix-button-toggle-filters-focus-ring {
          /* sm:rounded-r-xl */
          border-top-right-radius: 0.75rem;    /* rounded-r-xl (8 * 0.25rem = 2rem, but xl is 0.75rem or 12px) */
          border-bottom-right-radius: 0.75rem; /* rounded-r-xl */
        }
      }
    """
  end

  def rule(:auix_button_toggle_filters_close_link) do
    """
      .auix-button-toggle-filters-close-link {
        /* -space-x-2 (Applies to the container's margin to compensate for internal spacing) */
        margin-left: -0.5rem;    /* -2 * 0.25rem = -0.5rem */
      }
    """
  end

  def rule(:auix_fieldset) do
    """
      .auix-fieldset {
        display: grid;
        gap: calc(0.25rem * 1.5);
        padding-block: calc(0.25rem * 1);
        font-size: 0.75rem;
        grid-template-columns: 1fr;
        grid-auto-rows: max-content;
        margin-inline: 0rem;
        border-width: 0rem;
        padding-inline: 0rem;
        width: fit-content;
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
        border-color: var(--auix-color-border-default);
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
        box-shadow: var(--auix-shadow-sm);
        border-width: 1px;
        border-style: solid;
        border-color: var(--auix-color-border-default);
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
        border-color: var(--auix-color-border-default); /* border-zinc-300 */
      }
      .auix-textarea:focus {
        border-color: var(--auix-color-border-focus); /* focus:border-zinc-400 */
      }
    """
  end

  def rule(:auix_textarea__errors) do
    """
      #{common_text_area_css("--errors")}
      .auix-textarea--errors {
        border-color: var(--auix-color-error); /* border-rose-400 */
      }
      .auix-textarea--errors:focus {
        border-color: var(--auix-color-error); /* focus:border-rose-400 */
      }
    """
  end

  def rule(:auix_input) do
    """
      #{common_input_css()}
      .auix-input {
        border-color: var(--auix-color-border-default); /* border-zinc-300 */
      }
      .auix-input:focus {
        border-color: var(--auix-color-border-focus); /* focus:border-zinc-400 */
      }
    """
  end

  def rule(:auix_input__errors) do
    """
      #{common_input_css("--errors")}
      .auix-input--errors {
        border-color: var(--auix-color-error); /* border-rose-400 */
      }
      .auix-input--errors:focus {
        border-color: var(--auix-color-error); /* focus:border-rose-400 */
      }
    """
  end

  def rule(:auix_label) do
    """
      .auix-label {
        /* block text-sm font-semibold leading-6 text-zinc-800 */
        display: block;                  /* block */
        font-size: 0.875rem;             /* text-sm */
        font-weight: 600;                /* font-semibold */
        line-height: 1rem;
        color: var(--auix-color-text-label); /* text-zinc-800 */
      }
    """
  end

  def rule(:auix_error_message) do
    """
      .auix-error-message {
        /* mt-3 flex gap-3 text-sm leading-6 text-rose-600 */
        margin-top: 0.125rem;                       /* mt-3 (3 * 0.25rem = 0.75rem) */
        margin-bottom: 0.5rem;
        display: flex;                             /* flex */
        gap: 0.75rem;                              /* gap-3 (3 * 0.25rem = 0.75rem) */
        font-size: 0.875rem;                       /* text-sm */
        line-height: 1.5rem;                       /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--auix-color-error-text-default); /* text-rose-600 */
      }
    """
  end

  def rule(:auix_header) do
    """
      .auix-header{
        margin-bottom: 0.5rem;
      }
    """
  end

  def rule(:auix_header__top_actions) do
    """
      .auix-header--top-actions {
        #{common_actions_css()}
        width: 100%;
      }
    """
  end

  def rule(:auix_header_title_container) do
    """
      .auix-header-title-container {
        /* flex flex-col */
        display: flex;         /* flex */
        flex-direction: column; /* flex-col */
      }
    """
  end

  def rule(:auix_header_title) do
    """
      .auix-header-title {
        /* text-lg font-semibold leading-8 text-zinc-800 */
        font-size: 1.125rem;                      /* text-lg */
        font-weight: 600;                         /* font-semibold */
        line-height: 2rem;
        margin: 0;
        color: var(--auix-color-text-label);      /* text-zinc-800 */
      }
    """
  end

  def rule(:auix_header_subtitle) do
    """
      .auix-header-subtitle {
        /* mt-2 text-sm leading-6 text-zinc-600 */
        margin-top: 0rem;
        margin-bottom: 0rem;
        font-size: 1rem;
        line-height: 1.5rem;                
        color: var(--auix-color-text-secondary);   /* text-zinc-600 */
      }
    """
  end

  def rule(:auix_header__bottom_actions) do
    """
      .auix-header--bottom-actions {
        /* flex-none */
        flex-shrink: 0;
        flex-grow: 0;
      }
    """
  end

  def rule(:auix_list) do
    """
      .auix-list {
        /* mt-14 */
        margin-top: 3.5rem; /* 14 * 0.25rem = 3.5rem */
      }
    """
  end

  def rule(:auix_list_container) do
    """
      .auix-list-container {
        /* -my-4 divide-y divide-zinc-100 */
        margin-top: -1rem;                  /* -my-4 (-4 * 0.25rem = -1rem) */
        margin-bottom: -1rem;               /* -my-4 */

        /* Divide-y (applies horizontal border/divider between vertical siblings) */
        /* This is the complex CSS needed to mimic Tailwind's divide-y utility */
        --auix-divide-y-reverse: 0;
      }

      /* Selector to apply the divider styles to all children except the first one */
      .auix-list-container > :not([hidden]) ~ :not([hidden]) {
        /* Divide-y */
        border-top-width: calc(1px * calc(1 - var(--auix-divide-y-reverse)));
        border-bottom-width: calc(1px * var(--auix-divide-y-reverse));
        border-style: solid; /* Default Tailwind border style for dividers */

        /* divide-zinc-100 */
        border-color: var(--auix-color-bg-light); /* Using zinc-100 for the divider color */
      }
    """
  end

  def rule(:auix_list_item) do
    """
      .auix-list-item {
        /* flex gap-4 py-4 text-sm leading-6 sm:gap-8 */
        display: flex;                 /* flex */
        gap: 1rem;                     /* gap-4 (4 * 0.25rem = 1rem) */
        padding-top: 1rem;             /* py-4 */
        padding-bottom: 1rem;          /* py-4 */
        font-size: 0.875rem;           /* text-sm */
        line-height: 1.5rem;           /* leading-6 (6 * 0.25rem = 1.5rem) */
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-list-item {
          gap: 2rem;                   /* sm:gap-8 (8 * 0.25rem = 2rem) */
        }
      }
    """
  end

  def rule(:auix_list_item_title) do
    """
      .auix-list-item-title {
        /* w-1/4 flex-none text-zinc-500 */
        width: 25%;                              /* w-1/4 */
        flex-shrink: 0;                          /* flex-none */
        flex-grow: 0;                            /* flex-none */
        color: var(--auix-color-text-tertiary);  /* text-zinc-500 */
      }
    """
  end

  def rule(:auix_list_item_content) do
    """
      .auix-list-item-content {
        /* text-zinc-700 */
        color: var(--auix-color-text-hover); /* text-zinc-700 (Alias for --auix-color-text-hover) */
      }
    """
  end

  def rule(:auix_back_link_container) do
    """
      .auix-back-link-container {
        /* mt-16 */
        margin-top: 4rem; /* 16 * 0.25rem = 4rem */
      }
    """
  end

  def rule(:auix_back_link) do
    """
      .auix-back-link {
        /* text-sm font-semibold leading-6 text-zinc-900 */
        font-size: 0.875rem;                       /* text-sm */
        font-weight: 600;                          /* font-semibold */
        line-height: 1.5rem;                       /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--auix-color-text-primary);     /* text-zinc-900 */
      }

      /* Hover state */
      .auix-back-link:hover {
        /* hover:text-zinc-700 */
        color: var(--auix-color-text-hover);       /* hover:text-zinc-700 */
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
          /* sm:translate-y-0 sm:scale-95 */
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
          /* sm:scale-100 (translateY(0) is already set, only need to reset scale) */
          transform: scale(1);
        }
      }
    """
  end

  def rule(:auix_hide_transition) do
    """
      .auix-hide-transition {
        transition-property: all;
        transition-timing-function: cubic-bezier(0.4, 0.0, 1, 1); /* Tailwind default ease-in */
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
          /* sm:scale-100 */
          transform: scale(1);
        }
      }
    """
  end

  def rule(:auix_hide_transition__end) do
    """
      .auix-hide-transition--end {
        opacity: 0;
        transform: translateY(1rem); /* Base size */
      }

      @media (min-width: 640px) {
        .auix-hide-transition--end {
          /* sm:translate-y-0 sm:scale-95 */
          transform: translateY(0) scale(0.95);
        }
      }
    """
  end

  def rule(:auix_show_modal_transition) do
    """
      .auix-show-modal-transition {
        transition-property: all;
        transition-timing-function: cubic-bezier(0.0, 0.0, 0.2, 1); /* Tailwind default ease-out */
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
        /* overflow-hidden */
        overflow: hidden;
      }
    """
  end

  def rule(:auix_hide_modal_transition) do
    """
      .auix-hide-modal-transition {
        /* transition-all ease-in duration-200 */
        transition-property: all;
        transition-timing-function: cubic-bezier(0.4, 0.0, 1, 1); /* Tailwind default ease-in */
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
        /* overflow-y-scroll px-4 */
        overflow-y: scroll;               /* overflow-y-scroll */
        padding-left: 1rem;               /* px-4 (4 * 0.25rem = 1rem) */
        padding-right: 1rem;              /* px-4 */
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-items-table-container {
          /* sm:overflow-visible sm:px-0 */
          overflow-y: visible;            /* sm:overflow-visible (allows content to flow outside) */
          padding-left: 0;                /* sm:px-0 */
          padding-right: 0;               /* sm:px-0 */
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
        padding-bottom: 1rem;
        padding-right: 1.5rem;
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

  def rule(:auix_items_table_cell) do
    """
    .auix-items-table-cell {
    }
    """
  end

  def rule(:auix_items_table_action_cell) do
    """
      .auix-items-table-action-cell {
        display: flex;
        flex-direction: row;
        gap: 0.5rem;
        padding-top: 0.250rem;
        padding-left: 0.875rem;
      }
    """
  end

  def rule(:auix_items_card_container) do
    """
      .auix-items-card-container {
      }
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
    #{import_rule(:auix_items_card_item_content, :auix_items_card_item_content__even)}
    .auix-items-card-item-content--even {
      background-color: var(--auix-color-bg-secondary);
    }
    """
  end

  def rule(:auix_items_card_item_content__odd) do
    """
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

  def rule(:auix_filter_field) do
    """
      .auix-filter-field {
        display: flex;         /* flex */
        flex-direction: column; /* flex-col */
        gap: 0;                /* gap-0 */
        align-items: center;   /* items-center */
      }

    """
  end

  def rule(:auix_filter_field_content) do
    """
      .auix-filter-field-content {
        width: 100%;                  /* w-full */
        text-align: center;           /* text-center */
        padding-bottom: 0.5rem;       /* pb-2 (2 * 0.25rem = 0.5rem) */
      }
    """
  end

  def rule(:auix_filter_input) do
    """
      .auix-filter-input {
        /* block w-full pb-0 pt-0 mt-1 rounded-sm border-zinc-300 shadow-sm */
        display: block;
        width: 100%;
        padding-bottom: 0;
        padding-top: 0;
        margin-top: 0.1rem;
        border-radius: 0.125rem;
        border-color: var(--auix-color-border-default);
        box-shadow: var(--auix-shadow-sm);
      }

      /* Focus state (focus:border-indigo-500 focus:ring-indigo-500) */
      .auix-filter-input:focus {
        border-color: var(--auix-color-focus-ring);
        outline: 2px solid transparent;
        outline-offset: 2px;

      box-shadow:
        var(--auix-ring-offset-shadow),
        var(--auix-ring-default),
        var(--auix-shadow-primary);
      }

      /* Small breakpoint (sm) and up (sm:text-sm) */
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
      #{common_filter_input_field_css()}
    """
  end

  def rule(:auix_filter_input_field__disabled) do
    """
      #{common_filter_input_field_css("--disabled")}

      .auix-filter-input-field--disabled {
        background-color: var(--auix-color-bg-disabled) !important;
      }
    """
  end

  def rule(:auix_filter_condition_input) do
    """
      .auix-filter-condition-label {
        /* !h-[0.8rem] */
        height: 0.8rem !important;
      }

      /* Medium breakpoint (md) and up */
      @media (min-width: 768px) {
        .auix-filter-condition-label {
          /* md:hidden */
          display: none;
        }
      }
    """
  end

  def rule(:auix_index_container) do
    """
      .auix-index-container {
        max-widtH: 100%;
        padding: 1rem;
        caret-color: transparent;
      }

      @media (min-width: 640px) {
        .auix-index-container {
          padding: 1.5rem;
        }
      }

      @media (min-width: 768px) {
        .auix-index-container {
          max-width: max-content;
          margin-left: auto;
          margin-right: auto;
        }
      }

      @media (min-width: 1024px) {
        .auix-index-container {
          padding-top: 2rem;
          padding-bottom: 2rem;
          padding-left: 1.5rem;
          padding-right: 1.5rem;
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
        display: flex;                /* flex */
        justify-self: end;            /* justify-self-end (Aligns the item to the end of its grid area/cell) */
        vertical-align: middle;       /* align-middle (Aligns the element's content/vertical position) */
      }
    """
  end

  def rule(:auix_index_filter_element_actions) do
    """
      .auix-index-filter-element-actions {
        #{common_actions_css()}
        width: 100%;
      }
    """
  end

  def rule(:auix_index_filter_element_actions_content) do
    """
      .auix-index-filter-element-actions-content {
        position: relative;            
        white-space: nowrap;           /* whitespace-nowrap */
        padding-top: 1rem;             /* py-4 (4 * 0.25rem = 1rem) */
        padding-bottom: 1rem;          /* py-4 */
        text-align: right;             /* text-right */
        font-size: 0.875rem;           /* text-sm */
        font-weight: 500;              /* font-medium */
      }
    """
  end

  def rule(:auix_index_filter_element_actions_focus_ring) do
    """
      .auix-index-filter-element-actions-focus-ring {
        position: absolute;             /* absolute */
        top: -1px;                      /* -inset-y-px */
        bottom: -1px;                   /* -inset-y-px */
        right: -1rem;                   /* -right-4 (4 * 0.25rem = 1rem) */
        left: 0;                        /* left-0 */
      }

      /* Hover state for parent group */
      .group:hover .auix-index-filter-element-actions-focus-ring {
        background-color: var(--color-bg-hover);
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-index-filter-element-actions-focus-ring {
          border-top-right-radius: 1rem;    /* sm:rounded-r-xl */
          border-bottom-right-radius: 1rem; /* sm:rounded-r-xl */
        }
      }
    """
  end

  def rule(:auix_index_filter_element_action_button) do
    """
      .auix-index-filter-element-action-button {
        position: relative;            
        margin-left: 1rem;             /* ml-4 (4 * 0.25rem = 1rem) */
        font-weight: 600;              /* font-semibold */
        line-height: 1.5rem;           /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--color-text-primary);
      }

      /* Hover state */
      .auix-index-filter-element-action-button:hover {
        color: var(--color-text-hover);
      }
    """
  end

  def rule(:auix_show_container) do
    """
      .auix-show-container {
        /* max-w-max max-w-3xl p-4 sm:p-6 lg:py-8 mx-auto */
        width: max-content; /* max-w-max (Sets max-width based on content size) */
        padding: 1rem;          /* p-4 */
        margin-left: auto;      /* mx-auto (Centers the block horizontally) */
        margin-right: auto;     /* mx-auto */
      }

      /* --- Responsive Overrides (from Tailwind's default breakpoints) --- */

      /* Small screens (sm) - typically >= 640px */
      @media (min-width: 640px) {
        .auix-show-container {
          padding: 1.5rem;      /* sm:p-6 (6 * 0.25rem = 1.5rem) */
        }
      }

      /* Large screens (lg) - typically >= 1024px */
      @media (min-width: 1024px) {
        .auix-show-container {
          padding-top: 2rem;    /* lg:py-8 (8 * 0.25rem = 2rem) */
          padding-bottom: 2rem; /* lg:py-8 */
        }
      }
    """
  end

  def rule(:auix_show_content) do
    """
      .auix-show-content {
        /* p-4 border rounded-lg shadow bg-white */
        padding: 1rem;                                     /* p-4 (4 * 0.25rem = 1rem) */
        border-width: 1px;                                 /* border */
        border-radius: 0.5rem;                             /* rounded-lg (8px) */
        box-shadow: var(--auix-shadow-md);
        background-color: var(--auix-color-bg-default);
        width: max-content;
      }
    """
  end

  def rule(:auix_form_container) do
    """
        .auix-form-container {
          /* p-4 border rounded-lg shadow bg-white */

          /* BOX MODEL */
          padding: 1rem;                                     /* p-4 (4 * 0.25rem = 1rem) */
          border-radius: 0.5rem;                             /* rounded-lg (8px) */
          border-width: 1px;                                 /* border */

          background-color: var(--auix-color-bg-default);   /* bg-white */
          box-shadow: var(--auix-shadow-default);            /* shadow (Replaces 0 1px 3px 0 rgb(0 0 0 / 0.1), ...) */
        }
    """
  end

  def rule(:auix_sections_container) do
    """
      .auix-sections-container {
        /* Ensures block is not empty for linters */
        content-visibility: visible;
      }
    """
  end

  def rule(:auix_sections_tab_container) do
    """
      .auix-sections-tab-container {
        /* mt-2 flex flex-col sm:flex-row */

        /* BASE STYLES (Mobile-first, applies to all screen sizes) */
        margin-top: 0.5rem;   /* mt-2 (2 * 0.25rem = 0.5rem) */
        display: flex;        /* flex */
        flex-direction: column; /* flex-col (Stacks items vertically by default) */
      }

      /* --- Responsive Overrides (Small screens and up: sm) --- */

      @media (min-width: 640px) {
        .auix-sections-tab-container {
          flex-direction: row; /* sm:flex-row (Arranges items horizontally on small screens and up) */
        }
      }
    """
  end

  def rule(:auix_sections_tab_button__active) do
    """
      #{common_sections_tab_button_css("--active")}
      .auix-sections-tab-button--active {
        /* PADDING & SIZE, BORDERS, TRANSITION properties MOVED to shared base */

        /* FONT WEIGHT & COLORS ONLY REMAIN HERE */
        font-weight: 600;              /* font-semibold */
        color: var(--auix-color-text-label); /* text-zinc-800 */
        background-color: var(--auix-color-bg-light); /* bg-zinc-100 */
      }
    """
  end

  def rule(:auix_sections_tab_button__inactive) do
    """
      #{common_sections_tab_button_css("--inactive")}
      .auix-sections-tab-button--inactive {
        /* PADDING & SIZE, BORDERS, TRANSITION properties MOVED to shared base */

        /* FONT WEIGHT & COLORS ONLY REMAIN HERE */
        font-weight: 500;
        color: var(--auix-color-text-inactive);
        background-color: var(--auix-color-bg-hover);
      }
    """
  end

  def rule(:auix_sections_content) do
    """
      .auix-sections-content {
        /* p-4 border border-gray-300 rounded-tr-lg rounded-br-lg rounded-bl-lg */

        /* PADDING */
        padding: 1rem;            /* p-4 (4 * 0.25rem = 1rem) */

        /* BORDER */
        border-width: 1px;        /* border */
        /* Using semantic variable for border color */
        border-color: var(--auix-color-border-default); /* border-gray-300 (Maps to #D4D4D8 / zinc-300) */

        /* BORDER RADIUS */
        border-top-right-radius: 0.5rem;  /* rounded-tr-lg */
        border-bottom-right-radius: 0.5rem; /* rounded-br-lg */
        border-bottom-left-radius: 0.5rem;  /* rounded-bl-lg */
      }
    """
  end

  def rule(:auix_form_field_container) do
    """
      .auix-form-field-container {
        /* flex flex-col */
        display: flex;         /* flex */
        flex-direction: column; /* flex-col */
      }
    """
  end

  def rule(:auix_form_field_input) do
    """
      .auix-form-field-input {
        /* block w-full rounded-md border-zinc-300 shadow-sm sm:text-sm */

        /* BASE STYLES */
        display: block;                               /* block */
        width: 100%;                                  /* w-full */

        /* BORDER & SHAPE */
        border-width: 1px;                            /* Default border width */
        border-style: solid;                          /* Default border style */
        border-radius: 0.375rem;                      /* rounded-md (6px) */
        border-color: var(--auix-color-border-default); /* border-zinc-300 */

        /* SHADOW */
        box-shadow: var(--auix-shadow-sm);             /* shadow-sm */

        /* Default text size (will be overridden by sm:text-sm) */
        font-size: 1rem;
        line-height: 1.5rem;
      }

      /* --- Focus State (focus:border-indigo-500 focus:ring-indigo-500) --- */

      .auix-form-field-input:focus {
        /* Prevent default browser focus outline */
        outline: 2px solid transparent;
        outline-offset: 2px;

        /* BORDER COLOR */
        border-color: var(--auix-color-focus-ring);   /* focus:border-indigo-500 */

        /* RING & SHADOW: Stacks the focus ring ON TOP of the base shadow */
        box-shadow:
          0 0 0 3px var(--auix-color-focus-ring),      /* The visible focus ring (3px wide) */
          var(--auix-shadow-sm);                       /* The base elevation shadow */
      }

      /* --- Responsive Override --- */

      /* Small screens (sm) - typically >= 640px */
      @media (min-width: 640px) {
        .auix-form-field-input {
          font-size: 0.875rem;                       /* sm:text-sm (14px) */
          line-height: 1.25rem;                      /* sm:text-sm (Default line height for text-sm) */
        }
      }
    """
  end

  def rule(:auix_one_to_many_field) do
    """
      .auix-one-to-many-field {
        /* flex flex-col */
        display: flex;         /* flex */
        flex-direction: column; /* flex-col */
      }
    """
  end

  def rule(:auix_one_to_many_header) do
    """
      .auix-one-to-many-header {
        /* flex-row gap-4 mt-1 */

        /* FLEX CONTAINER */
        display: flex;             /* Implicit 'flex' */
        flex-direction: row;       /* flex-row (Arranges items horizontally) */

        /* SPACING */
        gap: 1rem;                 /* gap-4 (4 * 0.25rem = 1rem) */
        margin-top: 0.25rem;       /* mt-1 (1 * 0.25rem = 0.25rem) */
      }
    """
  end

  def rule(:auix_one_to_many_header_actions) do
    """
      .auix-one-to-many-header-actions {
        /* inline */
        display: inline;
      }
    """
  end

  def rule(:auix_one_to_many_container) do
    """
      .auix-one-to-many-container {
        /* w-full rounded-lg text-zinc-900 sm:text-sm sm:leading-6 border border-zinc-300 px-4 */

        /* LAYOUT & BORDER */
        width: 100%;                                  /* w-full */
        border-width: 1px;                            /* border */
        border-style: solid;                          /* Implicit border style */
        border-radius: 0.5rem;                        /* rounded-lg (8px) */

        /* SPACING */
        padding-left: 1rem;                           /* px-4 (4 * 0.25rem = 1rem) */
        padding-right: 1rem;                          /* px-4 */

        /* COLORS */
        color: var(--auix-color-text-primary);        /* text-zinc-900 */
        border-color: var(--auix-color-border-default); /* border-zinc-300 */
      }

      /* --- Responsive Overrides (Small screens and up: sm) --- */

      @media (min-width: 640px) {
        .auix-one-to-many-container {
          font-size: 0.875rem;                       /* sm:text-sm (14px) */
          line-height: 1.5rem;                       /* sm:leading-6 (6 * 0.25rem = 1.5rem) */
        }
      }
    """
  end

  def rule(:auix_one_to_many_footer) do
    """
      .auix-one-to-many-footer {
        /* flex-row */

        /* FLEX CONTAINER */
        display: flex;         /* Implicit 'flex' (required for flex-direction to work) */
        flex-direction: row;   /* flex-row (Arranges items horizontally) */
      }
    """
  end

  def rule(:auix_one_to_many_footer_actions) do
    """
      .auix-one-to-many-footer-actions {
        /* flex flex-col */
        display: flex;         /* flex */
        flex-direction: column; /* flex-col */
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
        clip: rect(0, 0, 0, 0); /* Older standard */
        clip-path: inset(50%); /* Modern standard, moves element out of view */
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
        /* h-0 invisible */

        /* Initial state (for screens < 1536px): Hidden and takes no height */
        height: 0;
        visibility: hidden;
      }

      /* --- 2XL Breakpoint (min-width: 1536px) --- */

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
        /* h-0 invisible */

        /* Initial state (for screens < 1280px): Hidden and takes no height */
        height: 0;
        visibility: hidden;
      }

      /* --- XL Breakpoint (min-width: 1280px) --- */

      @media (min-width: 1280px) {
        .auix-pagination-breakpoint-xl {
          visibility: visible;
          height: auto;
        }
      }

      /* --- 2XL Breakpoint (min-width: 1536px) --- */

      @media (min-width: 1536px) {
        .auix-pagination-breakpoint-xl {
          /* 2xl:invisible (Hides it again on larger screens) */
          visibility: hidden;
          height: 0;
        }
      }
    """
  end

  def rule(:auix_pagination_breakpoint_lg) do
    """
      .auix-pagination-breakpoint-lg {
        /* h-0 invisible */

        /* Initial state (for screens < 1024px): Hidden and takes no height */
        height: 0;                /* h-0 */
        visibility: hidden;         /* invisible */
      }

      /* --- LG Breakpoint (min-width: 1024px) --- */

      @media (min-width: 1024px) {
        .auix-pagination-breakpoint-lg {
          visibility: visible;
          height: auto;
        }
      }

      /* --- XL Breakpoint (min-width: 1280px) --- */

      @media (min-width: 1280px) {
        .auix-pagination-breakpoint-lg {
          /* xl:invisible (Hides it again on larger screens) */
          visibility: hidden;
          height: 0;
        }
      }
    """
  end

  def rule(:auix_pagination_breakpoint_md) do
    """
      .auix-pagination-breakpoint-md {
        /* h-0 invisible text-sm (Default styles for screens < 768px) */

        /* Initial State: Hidden and takes no height */
        height: 0;                /* h-0 */
        visibility: hidden;         /* invisible */

        /* Default Typography */
        font-size: 0.875rem;        /* text-sm (14px) */
      }

      /* --- MD Breakpoint (min-width: 768px) --- */

      @media (min-width: 768px) {
        .auix-pagination-breakpoint-md {
          visibility: visible;
          height: auto;
        }
      }

      /* --- LG Breakpoint (min-width: 1024px) --- */

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
        /* p-3 border rounded-md bg-gray-100 */

        /* SPACING */
        padding: 0.75rem;                       /* p-3 (3 * 0.25rem = 0.75rem / 12px) */

        /* BORDERS & SHAPE */
        border-width: 1px;                      /* border */
        border-style: solid;                    /* Implicit border style */
        border-color: var(--auix-color-border-default); /* Assuming border is standard */
        border-radius: 0.375rem;                /* rounded-md (6px) */

        /* BACKGROUND COLOR */
        background-color: var(--auix-color-bg-light); /* bg-gray-100 */
      }
    """
  end

  def rule(:auix_group_title) do
    """
      .auix-group-title {
        /* font-semibold text-lg */

        /* TYPOGRAPHY */
        font-weight: 600;     /* font-semibold */
        font-size: 1.125rem;  /* text-lg (18px) */
        line-height: 1.75rem; /* Standard line-height for text-lg (lh-7) */
      }
    """
  end

  def rule(:auix_inline_container) do
    """
      .auix-inline-container {
        /* flex flex-col gap-2 */

        /* BASE STYLES (Mobile-First: flex-col) */
        display: flex;             /* flex */
        flex-direction: column;    /* flex-col (Stacks items vertically) */
        gap: 0.5rem;               /* gap-2 (2 * 0.25rem = 0.5rem) */
        width: max-content;
      }

      /* --- Responsive Override (Small screens and up: sm) --- */

      @media (min-width: 640px) {
        .auix-inline-container {
          /* sm:flex-row (Overrides flex-col to arrange items horizontally) */
          flex-direction: row;
        }
      }
    """
  end

  def rule(:auix_stacked_container) do
    """
      .auix-stacked-container {
        /* flex flex-col gap-2 */

        /* FLEX CONTAINER */
        display: flex;             /* flex */
        flex-direction: column;    /* flex-col (Stacks items vertically) */

        /* SPACING */
        gap: 0.5rem;               /* gap-2 (2 * 0.25rem = 0.5rem / 8px) */
      }
    """
  end

  def rule(:auix_icon_size_3) do
    """
      .auix-icon-size-3 {
        width: 0.75rem;          /* size-3 (3 * 0.25rem = 0.75rem) */
        height: 0.75rem;         /* size-3 */
      }
    """
  end

  def rule(:auix_icon_size_4) do
    """
      .auix-icon-size-4 {
        width: 1rem;          /* size-4 (4 * 0.25rem = 1rem) */
        height: 1rem;         /* size-4 */
      }
    """
  end

  def rule(:auix_icon_size_5) do
    """
      .auix-icon-size-5 {
        width: 1.25rem;          /* size-5 (5 * 0.25rem = 1.25rem) */
        height: 1.25rem;         /* size-5 */
      }
    """
  end

  def rule(:auix_icon_size_6) do
    """
      .auix-icon-size-6 {
        width: 1.5rem;          /* size-6 (6 * 0.25rem = 1.5rem) */
        height: 1.5rem;         /* size-6 */
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
    .auix-icon-safe {
      color: var(--auix-color-icon-safe)
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

  def rule(:auix_vertical_align_super) do
    """
    .auix-vertical-align-super {
      /* ALIGNMENT */
      vertical-align: super;   /* align-super */
    }
    """
  end

  def rule(:auix_animate_spin) do
    """
      .auix-animate-spin {
        /* animate-spin */
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
        #{common_container_css()}
      }
    """
  end

  def rule(:auix_embeds_many_container) do
    """
      .auix-embeds-many-container {
        #{common_container_css()}

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
      .auix-embeds-many-footer-actions {
        #{common_actions_css()}
        display: flex;
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
      .auix-embeds-many-new-entry-actions {
        #{common_actions_css()}
      }
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
      .auix-embeds-many-existing-actions {
        #{common_actions_css()}
      }
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
        #{common_container_css()}
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
        display: inline-block;
        padding: 4px 8px;
        background-color: var(--auix-color-bg-default--reverted);
        color: var(--auix-color-text-on-accent);
        border-radius: 12px;
        font-size: 12px;
        font-weight: 600;
        line-height: 1;
        text-align: center;
        white-space: nowrap;
        vertical-align: middle;
      }
    """
  end

  def rule(_), do: ""

  ## PRIVATE
  @spec common_flash_css() :: binary()
  defp common_flash_css do
    """
      /* POSITIONING & SIZE */
      position: fixed;                 /* fixed */
      top: 0.5rem;                     /* top-2 (2 * 0.25rem = 0.5rem) */
      right: 0.5rem;                   /* right-2 */
      margin-right: 0.5rem;            /* mr-2 */
      width: max-content;                    /* w-80 (80 * 0.25rem = 20rem) */
      z-index: 50;                     /* z-50 */

      /* BOX STYLES */
      border-radius: 0.5rem;           /* rounded-lg */
      padding: 0.125rem;                /* p-3 (3 * 0.25rem = 0.75rem) */

    """
  end

  @spec common_text_area_css(binary()) :: binary()
  defp common_text_area_css(suffix \\ "") do
    """
      .auix-textarea#{suffix} {
        /* mt-2 block w-full rounded-lg text-zinc-900 min-h-[6rem] */
        margin-top: 0.5rem;               /* mt-2 */
        display: block;                   /* block */
        width: 100%;                      /* w-full */
        border-radius: 0.5rem;            /* rounded-lg */
        min-height: 6rem;                 /* min-h-[6rem] */
        color: var(--auix-color-text-primary); /* text-zinc-900 */
        padding: 0.25rem;

        /* focus:ring-0 */
        box-shadow: none;
        outline: none;

        /* Default border style (width and type) */
        border-width: 1px;
        border-style: solid;
      }

      /* Common Focus & Small Breakpoint Styles */

      .auix-textarea#{suffix}:focus {
        /* focus:ring-0 */
        box-shadow: none;
        outline: none;
      }

      @media (min-width: 640px) {
        .auix-textarea#{suffix} {
          /* sm:text-sm sm:leading-6 */
          font-size: 0.875rem;            /* sm:text-sm */
          line-height: 1.5rem;            /* sm:leading-6 */
        }
      }
    """
  end

  @spec common_input_css(binary()) :: binary()
  defp common_input_css(suffix \\ "") do
    """
      .auix-input#{suffix} {
        /* mt-2 p-1 block w-full rounded-lg text-zinc-900 */
        margin-top: 0rem;               /* mt-2 (2 * 0.25rem = 0.5rem) */
        padding: 0.25rem;                 /* p-1 (1 * 0.25rem = 0.25rem) */
        display: block;                   /* block */
        width: auto;                      /* w-full */
        border-radius: 0.5rem;            /* rounded-lg */
        color: var(--color-text-primary); /* text-zinc-900 */

        /* border border-zinc-300 */
        border-width: 1px;                /* border */
        border-style: solid;              /* border (default style) */
      }
      /* Focus state */
      .auix-input#{suffix}:focus {
        /* focus:ring-0 focus:border-zinc-400 */
        --auix-ring-color: transparent;     /* focus:ring-0 (Removes the ring color) */
        box-shadow: none;                 /* focus:ring-0 (Removes the ring shadow) */
        outline: none;                    /* focus:ring-0 (Ensures no native outline) */
      }
      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-input#{suffix} {
          /* sm:text-sm sm:leading-6 */
          font-size: 0.875rem;            /* sm:text-sm */
          line-height: 1.5rem;            /* sm:leading-6 (6 * 0.25rem = 1.5rem) */
        }
      }
    """
  end

  @spec common_filter_input_field_css(binary()) :: binary()
  defp common_filter_input_field_css(suffix \\ "") do
    """
      .auix-filter-input-field#{suffix} {
        /* !pb-0 !pt-0 !mt-1 */
        padding-bottom: 0 !important;
        padding-top: 0 !important;
        margin-top: 0.125rem !important; /* 1 * 0.25rem = 0.25rem */
      }
    """
  end

  @spec common_sections_tab_button_css(binary()) :: binary()
  defp common_sections_tab_button_css(suffix) do
    """
    .auix-sections-tab-button#{suffix} {
        padding-left: 1rem;
        padding-right: 1rem;
        padding-top: 0.5rem;
        padding-bottom: 0.5rem;
        font-size: 0.875rem;
        border-bottom-width: 2px;
        border-color: transparent;
        border-top-left-radius: 0.375rem;
        border-top-right-radius: 0.375rem;
        transition-property: all;
        transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
        transition-duration: 200ms;
      }
    """
  end

  @spec common_container_css() :: binary()
  defp common_container_css do
    """
      /* BOX MODEL */
      padding: 1rem;                                     /* p-4 (4 * 0.25rem = 1rem) */
      border-radius: 0.5rem;                             /* rounded-lg (8px) */
      border-width: 1px;                                 /* border */
      border-style: solid;
      /* COLORS */
      border-color: var(--auix-color-border-secondary);
      background-color: var(--auix-color-bg-inner-container);
      box-shadow: var(--auix-shadow-default);            /* shadow (Replaces 0 1px 3px 0 rgb(0 0 0 / 0.1), ...) */
    """
  end

  @spec common_actions_css() :: binary()
  defp common_actions_css do
    """
      margin-top: 0.5rem;  
      margin-bottom: 0.5rem; 
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1.5rem;
    """
  end
end
