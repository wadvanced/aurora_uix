defmodule Aurora.Uix.Templates.Basic.Themes.Base do
  @moduledoc """
  The base theme for the Basic template.

  This theme defines a set of CSS rules for the base theme.
  """
  use Aurora.Uix.Templates.Theme

  @impl true
  @spec rule(atom()) :: binary()
  def rule(:auix_modal) do
    """
      .auix-modal {
        /* relative z-50 hidden */
        position: relative; /* relative */
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
        position: relative;            /* relative */
        display: none;                 /* hidden */

        /* BOX STYLES */
        border-radius: 1rem;           /* rounded-2xl (16px) */
        background-color: var(--auix-color-bg-white); /* bg-white */
        padding: 3.5rem;               /* p-14 (14 * 0.25rem = 3.5rem) */

        /* SHADOW */
        box-shadow: var(--auix-shadow-lg), var(--auix-shadow-zinc-700-10); /* shadow-lg & shadow-zinc-700/10 */

        /* RING */
        --auix-calc-ring-offset-shadow: 0 0 #0000;
        --auix-calc-ring-shadow: var(--auix-ring-zinc-700-10); /* ring-zinc-700/10 (opacity 10) */
        box-shadow: var(--auix-calc-ring-offset-shadow), var(--auix-calc-ring-shadow), var(--auix-calc-shadow);
        border-width: 1px;             /* ring-1 (The ring effect is achieved via box-shadow in Tailwind) */

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

  def rule(:auix_flash__info) do
    """
      .auix-flash--info {
        #{common_flash_css()}
        background-color: var(--auix-color-info-bg); /* bg-emerald-50 */

        /* TEXT & ICON */
        color: var(--auix-color-info-text);   /* text-emerald-800 */
        fill: var(--auix-color-icon-fill);    /* fill-cyan-900 (For internal SVG/Icon) */

        /* RING */
        --auix-calc-ring-color: var(--auix-color-info-ring); /* ring-emerald-500 (sets ring color) */
        --auix-calc-ring-offset-shadow: 0 0 #0000;
        --auix-calc-ring-shadow: var(--auix-ring-inset) 0 0 0 calc(1px + var(--auix-ring-offset-width)) var(--auix-calc-ring-color);
        box-shadow: var(--auix-calc-ring-offset-shadow), var(--auix-calc-ring-shadow), var(--auix-primary-shadow);
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
        box-shadow: var(--auix-ring-offset-shadow), var(--auix-calc-ring-shadow), var(--auix-shadow-md);
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
      }
    """
  end

  def rule(:auix_flash_message) do
    """
      .auix-flash-message {
        /* mt-2 text-sm leading-5 */
        margin-top: 0.5rem;   /* mt-2 (2 * 0.25rem = 0.5rem) */
        font-size: 0.875rem;  /* text-sm */
        line-height: 1.25rem; /* leading-5 (5 * 0.25rem = 1.25rem) */
      }
    """
  end

  def rule(:auix_flash_close_button) do
    """
      .auix-flash-close-button {
        position: absolute;       /* absolute */
        inset-inline-end: 0.25rem;  /* right-1 */
        inset-block-start: 0.25rem;             /* top-1 (1 * 0.25rem = 0.25rem) */
        padding: 0.5rem;         /* p-2 (2 * 0.25rem = 0.5rem) */
      }
    """
  end

  def rule(:auix_simple_form_content) do
    """
      .auix-simple-form-content {
        /* mt-10 space-y-8 bg-white */
        margin-top: 2.0rem;             /* mt-10 (10 * 0.25rem = 2.5rem) */
        background-color: var(--auix-color-bg-white); /* bg-white */
      }
    """
  end

  def rule(:auix_simple_form_actions) do
    """
      .auix-simple-form-actions {
        /* mt-2 flex items-center justify-between gap-6 */
        margin-top: 0.5rem;          /* mt-2 (2 * 0.25rem = 0.5rem) */
        display: flex;               /* flex */
        align-items: center;         /* items-center */
        justify-content: space-between; /* justify-between */
        gap: 1.5rem;                 /* gap-6 (6 * 0.25rem = 1.5rem) */
      }
    """
  end

  def rule(:auix_button) do
    """
      .auix-button {
        border-radius: 0.5rem;
        background-color: var(--auix-color-text-primary);
        padding: 0.5rem 0.75rem;
        font-size: 0.875rem;
        font-weight: 600;
        line-height: 1.5rem;
        color: var(--auix-color-text-on-accent);
      }

      .auix-button:hover {
        background-color: var(--auix-color-text-hover);
      }

      .auix-button:active {
        color: var(--auix-color-text-on-accent-active);
      }

      .auix-button[phx-submit-loading] {
        opacity: 0.75;
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
      }
    """
  end

  def rule(:auix_checkbox) do
    """
    .auix-checkbox {
        appearance: none;
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
        background-color: var(--auix-color-bg-white);
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
        background-color: var(--auix-color-bg-white);
        box-shadow: 0 1px 2px 0 rgb(0 0 0 / 0.05);
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
        line-height: 1.5rem;             /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--auix-color-text-label); /* text-zinc-800 */
      }
    """
  end

  def rule(:auix_error_message) do
    """
      .auix-error-message {
        /* mt-3 flex gap-3 text-sm leading-6 text-rose-600 */
        margin-top: 0.25rem;                       /* mt-3 (3 * 0.25rem = 0.75rem) */
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
        all: unset;
      }
    """
  end

  def rule(:auix_header__top_actions) do
    """
      .auix-header--top-actions {
        /* flex items-center justify-between gap-6 */
        display: flex;                 /* flex */
        align-items: center;           /* items-center */
        justify-content: space-between;  /* justify-between */
        gap: 1.5rem;                   /* gap-6 (6 * 0.25rem = 1.5rem) */
      }
    """
  end

  def rule(:auix_header_title) do
    """
      .auix-header-title {
        /* text-lg font-semibold leading-8 text-zinc-800 */
        font-size: 1.125rem;                      /* text-lg */
        font-weight: 600;                         /* font-semibold */
        line-height: 2rem;                        /* leading-8 (8 * 0.25rem = 2rem) */
        color: var(--auix-color-text-label);      /* text-zinc-800 */
      }
    """
  end

  def rule(:auix_header_subtitle) do
    """
      .auix-header-subtitle {
        /* mt-2 text-sm leading-6 text-zinc-600 */
        margin-top: 0.1rem;
        margin-bottom: 1.5rem;
        font-size: 1rem;
        line-height: 1.5rem;                       /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--auix-color-text-secondary);   /* text-zinc-600 */
      }
    """
  end

  def rule(:auix_header__bottom_actions) do
    """
      .auix-header--bottom-actions {
        /* flex-none */
        flex-shrink: 0;   /* flex-none */
        flex-grow: 0;     /* flex-none */
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
        /* overflow-hidden */
        overflow: hidden;
      }
    """
  end

  def rule(:auix_items_desktop) do
    """
      .auix-items-desktop {
        /* md:block */
        display: none;
      }

      /* Medium breakpoint (md) and up */
      @media (min-width: 768px) {
        .auix-items-desktop {
          /* md:block */
          display: block;
        }
      }
    """
  end

  def rule(:auix_items_mobile) do
    """
      .auix-items-mobile {
        /* mt-0 */
        margin-top: 0;
      }

      /* Medium breakpoint (md) and up */
      @media (min-width: 768px) {
        .auix-items-mobile {
          /* md:hidden */
          display: none;
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
        /* w-[40rem] mt-0 */
        width: 40rem;         /* w-[40rem] (Explicitly set width) */
        margin-top: 0;        /* mt-0 */
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-items-table {
          /* sm:w-full */
          width: 100%;        /* sm:w-full */
        }
      }
    """
  end

  def rule(:auix_items_table_header) do
    """
      .auix-items-table-header {
        /* text-sm text-left leading-6 text-zinc-500 */
        font-size: 0.875rem;                       /* text-sm */
        text-align: left;                          /* text-left */
        line-height: 1.5rem;                       /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--auix-color-text-tertiary);    /* text-zinc-500 */
      }
    """
  end

  def rule(:auix_items_table_header_filter_cell) do
    """
      .auix-items-table-header-filter-cell {
        /* p-0 pb-4 pr-6 font-normal h-full align-bottom */
        padding: 0;           /* p-0 */
        padding-bottom: 1rem; /* pb-4 (4 * 0.25rem = 1rem) */
        padding-right: 1.5rem;/* pr-6 (6 * 0.25rem = 1.5rem) */
        font-weight: 400;     /* font-normal */
        height: 100%;         /* h-full */
        vertical-align: bottom; /* align-bottom */
      }
    """
  end

  def rule(:auix_items_table_header_cell) do
    """
      .auix-items-table-header-cell {
        /* p-0 pb-4 pr-6 font-normal h-full align-bottom */
        padding: 0;           /* p-0 */
        padding-bottom: 1rem; /* pb-4 (4 * 0.25rem = 1rem) */
        padding-right: 1.5rem;/* pr-6 (6 * 0.25rem = 1.5rem) */
        font-weight: 400;     /* font-normal */
        height: 100%;         /* h-full */
        vertical-align: bottom; /* align-bottom */
      }
    """
  end

  def rule(:auix_items_table_header_cell_content) do
    """
      .auix-items-table-header-cell-content {
        /* font-bold inline-flex */
        font-weight: 700;    /* font-bold */
        display: inline-flex; /* inline-flex */
      }
    """
  end

  def rule(:auix_items_table_body) do
    """
      .auix-items-table-body {
        /* relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700 */
        position: relative;                             /* relative */

        /* Divider Rules (divide-y and divide-zinc-100 are translated into border-bottom on children) */
        /* Since we cannot apply divide-y directly to the parent, we apply border-top to the body
          and assume the row children handle the rest of the dividers. */
        border-top-width: 1px;                          /* border-t */
        border-top-color: var(--auix-color-border-secondary); /* border-zinc-200 */

        font-size: 0.875rem;                            /* text-sm */
        line-height: 1.5rem;                            /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--auix-color-text-hover);            /* text-zinc-700 */
      }

      /* * NOTE ON DIVIDERS:
      * Tailwind's `divide-y` actually applies a border to children.
      * To fully replicate `divide-y divide-zinc-100`, you would need an additional rule
      * targeting immediate children (table rows):
      */
      .auix-items-table-body > tr:not(:last-child) {
        border-bottom-width: 1px;
        border-bottom-color: var(--auix-color-border-tertiary); /* Equivalent to divide-zinc-100 */
      }
    """
  end

  def rule(:auix_items_table_row__hover) do
    """
      .auix-items-table-row:hover {
        /* hover:bg-zinc-50 */
        background-color: var(--auix-color-bg-hover); /* Zinc 50 */
      }
    """
  end

  def rule(:auix_items_table_cell) do
    """
      #{common_items_table_cell()}
    """
  end

  def rule(:auix_items_table_cell_clickable) do
    """
      #{common_items_table_cell("-clickable")}

      .auix-items-table-cell-clickable:hover {
        /* hover:cursor-pointer */
        cursor: pointer;    /* hover:cursor-pointer */
      }
    """
  end

  def rule(:auix_items_table_cell_content) do
    """
      .auix-items-table-cell-content {
        /* block py-4 pr-6 */
        display: block;       /* block */
        padding-top: 1rem;    /* py-4 (4 * 0.25rem = 1rem) */
        padding-bottom: 1rem; /* py-4 */
        padding-right: 1.5rem;/* pr-6 (6 * 0.25rem = 1.5rem) */
      }
    """
  end

  def rule(:auix_items_table_cell_focus_ring) do
    """
      .auix-items-table-cell-focus-ring {
        /* absolute -inset-y-px right-0 -left-4 */
        position: absolute;                   /* absolute */
        top: -1px;                            /* -inset-y-px */
        bottom: -1px;                         /* -inset-y-px */
        right: 0;                             /* right-0 */
        left: -1rem;                          /* -left-4 (4 * 0.25rem = 1rem) */
      }

      .auix-items-table-row:hover .auix-items-table-cell-focus-ring {
        /* group-hover:bg-zinc-50 */
        background-color: var(--auix-color-background-hover); /* Zinc 50 */
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-items-table-cell-focus-ring {
          /* sm:rounded-l-xl */
          border-top-left-radius: 0.75rem;    /* rounded-l-xl (12 * 0.0625rem = 0.75rem) */
          border-bottom-left-radius: 0.75rem;
        }
      }
    """
  end

  def rule(:auix_items_table_cell_text) do
    """
      .auix-items-table-cell-text {
        /* relative */
        position: relative; /* relative */
      }
    """
  end

  def rule(:auix_items_table_cell_text__first) do
    """
      .auix-items-table-cell-text--first {
        /* relative font-semibold text-zinc-900 */
        position: relative;                             /* relative */
        font-weight: 600;                               /* font-semibold */
        color: var(--auix-color-text-primary);          /* text-zinc-900 */
      }
    """
  end

  def rule(:auix_items_table_action_cell) do
    """
      .auix-items-table-action-cell {
        /* relative w-14 p-0 */
        position: relative; /* relative */
        width: 3.5rem;      /* w-14 (14 * 0.25rem = 3.5rem) */
        padding: 0;         /* p-0 */
      }
    """
  end

  def rule(:auix_items_table_action_cell_content) do
    """
      .auix-items-table-action-cell-content {
        /* relative whitespace-nowrap py-4 text-right text-sm font-medium */
        position: relative;          /* relative */
        white-space: nowrap;         /* whitespace-nowrap */
        padding-top: 1rem;           /* py-4 (4 * 0.25rem = 1rem) */
        padding-bottom: 1rem;        /* py-4 */
        text-align: right;           /* text-right */
        font-size: 0.875rem;         /* text-sm */
        font-weight: 500;            /* font-medium */
      }
    """
  end

  def rule(:auix_items_table_action_cell_focus_ring) do
    """
      .auix-items-table-action-cell-focus-ring {
        /* absolute -inset-y-px -right-4 left-0 */
        position: absolute;                   /* absolute */
        top: -1px;                            /* -inset-y-px */
        bottom: -1px;                         /* -inset-y-px */
        right: -1rem;                         /* -right-4 (4 * 0.25rem = 1rem) */
        left: 0;                              /* left-0 */
      }

      /* Group-hover interaction */
      .auix-items-table-row:hover .auix-items-table-action-cell-focus-ring {
        /* group-hover:bg-zinc-50 */
        background-color: var(--auix-color-background-hover); /* Zinc 50 */
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .auix-items-table-action-cell-focus-ring {
          /* sm:rounded-r-xl */
          border-top-right-radius: 0.75rem;    /* rounded-r-xl (12 * 0.0625rem = 0.75rem) */
          border-bottom-right-radius: 0.75rem;
        }
      }
    """
  end

  def rule(:auix_items_table_action_button) do
    """
      .auix-items-table-action-button {
        /* relative ml-4 font-semibold leading-6 text-zinc-900 */
        position: relative;                             /* relative */
        margin-left: 1rem;                              /* ml-4 (4 * 0.25rem = 1rem) */
        font-weight: 600;                               /* font-semibold */
        line-height: 1.5rem;                            /* leading-6 (6 * 0.25rem = 1.5rem) */
        color: var(--auix-color-text-primary);          /* text-zinc-900 */
      }

      .auix-items-table-action-button:hover {
        /* hover:text-zinc-700 */
        color: var(--auix-color-text-hover);            /* hover:text-zinc-700 */
      }
    """
  end

  @spec rule(atom()) :: binary()
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
      width: 20rem;                    /* w-80 (80 * 0.25rem = 20rem) */
      z-index: 50;                     /* z-50 */

      /* BOX STYLES */
      border-radius: 0.5rem;           /* rounded-lg */
      padding: 0.75rem;                /* p-3 (3 * 0.25rem = 0.75rem) */

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
        margin-top: 0.5rem;               /* mt-2 (2 * 0.25rem = 0.5rem) */
        padding: 0.25rem;                 /* p-1 (1 * 0.25rem = 0.25rem) */
        display: block;                   /* block */
        width: 100%;                      /* w-full */
        border-radius: 0.5rem;            /* rounded-lg */
        color: var(--color-text-primary); /* text-zinc-900 */

        /* border border-zinc-300 */
        border-width: 1px;                /* border */
        border-style: solid;              /* border (default style) */
      }
      /* Focus state */
      .auix-input#{suffix}:focus {
        /* focus:ring-0 focus:border-zinc-400 */
        --tw-ring-color: transparent;     /* focus:ring-0 (Removes the ring color) */
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
    """
  end

  @spec common_items_table_cell(binary()) :: binary()
  defp common_items_table_cell(suffix \\ "") do
    """
      .auix-items-table-cell#{suffix} {
        /* relative p-0 */
        position: relative; /* relative */
        padding: 0;         /* p-0 */
      }
    """
  end
end
