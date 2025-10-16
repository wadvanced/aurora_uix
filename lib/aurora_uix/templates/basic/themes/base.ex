defmodule Aurora.Uix.Templates.Basic.Themes.Base do
  @moduledoc """
  The base theme for the Basic template.

  This theme defines a set of CSS rules for the base theme.
  """
  use Aurora.Uix.Templates.Theme

  @impl true
  @spec rule(:core_modal) :: binary()
  def rule(:core_modal) do
    """
      .core-modal {
        /* relative z-50 hidden */
        position: relative; /* relative */
        z-index: 50;        /* z-50 */
        display: none;
      }
    """
  end

  @impl true
  @spec rule(:core_modal_background) :: binary()
  def rule(:core_modal_background) do
    """
      .core-modal-background {
        background-color: var(--color-bg-backdrop);

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

  @impl true
  @spec rule(:core_modal_container) :: binary()
  def rule(:core_modal_container) do
    """
      .core-modal-container {
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

  @impl true
  @spec rule(:core_modal_content) :: binary()
  def rule(:core_modal_content) do
    """
    .core-modal-content {
      /* flex min-h-full items-center justify-center */
      display: flex;
      min-height: 100%;
      align-items: center;
      justify-content: center;
    }
    """
  end

  @impl true
  @spec rule(:core_modal_box) :: binary()
  def rule(:core_modal_box) do
    """
      .core-modal-box {
        /* max-w-max max-w-3xl p-4 sm:p-6 lg:py-8 mx-auto */
        max-width: max-content;         /* max-w-max (Overridden by max-w-3xl) */
        padding: 1rem;                  /* p-4 (4 * 0.25rem = 1rem) */
        margin-left: auto;              /* mx-auto */
        margin-right: auto;             /* mx-auto */
      }

      /* Small breakpoint (sm) and up */
      @media (min-width: 640px) {
        .core-modal-box {
          padding: 1.5rem;              /* sm:p-6 (6 * 0.25rem = 1.5rem) */
        }
      }

      /* Large breakpoint (lg) and up */
      @media (min-width: 1024px) {
        .core-modal-box {
          padding-top: 2rem;            /* lg:py-8 (8 * 0.25rem = 2rem) */
          padding-bottom: 2rem;         /* lg:py-8 */
        }
      }
    """
  end

  @impl true
  @spec rule(:core_modal_focus_wrap) :: binary()
  def rule(:core_modal_focus_wrap) do
    """
      .core-modal-focus-wrap {
        /* shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition */

        /* POSITIONING & VISIBILITY */
        position: relative;            /* relative */
        display: none;                 /* hidden */

        /* BOX STYLES */
        border-radius: 1rem;           /* rounded-2xl (16px) */
        background-color: var(--color-bg-white); /* bg-white */
        padding: 3.5rem;               /* p-14 (14 * 0.25rem = 3.5rem) */

        /* SHADOW */
        box-shadow: var(--shadow-lg), var(--shadow-zinc-700-10); /* shadow-lg & shadow-zinc-700/10 */

        /* RING */
        --tw-ring-offset-shadow: 0 0 #0000;
        --tw-ring-shadow: var(--ring-zinc-700-10); /* ring-zinc-700/10 (opacity 10) */
        box-shadow: var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow);
        border-width: 1px;             /* ring-1 (The ring effect is achieved via box-shadow in Tailwind) */

        /* TRANSITION */
        transition-property: color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter; /* transition (all properties) */
        transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
        transition-duration: 150ms;
      }
    """
  end

  @impl true
  @spec rule(:core_modal_close_button_container) :: binary()
  def rule(:core_modal_close_button_container) do
    """
      .core-modal-close-button-container {
        /* absolute top-6 right-5 */
        position: absolute;
        top: 1.5rem;   /* top-6 (6 * 0.25rem = 1.5rem) */
        right: 1.25rem; /* right-5 (5 * 0.25rem = 1.25rem) */
      }
    """
  end

  @impl true
  @spec rule(:core_modal_close_button) :: binary()
  def rule(:core_modal_close_button) do
    """
      .core-modal-close-button {
        /* -m-3 flex-none p-3 opacity-20 hover:opacity-40 */
        margin: -0.75rem;          /* -m-3 (-3 * 0.25rem = -0.75rem) */
        flex-shrink: 0;            /* flex-none (shorthand for flex-shrink: 0 and flex-grow: 0) */
        flex-grow: 0;              /* flex-none */
        padding: 0.75rem;          /* p-3 (3 * 0.25rem = 0.75rem) */
        opacity: 0.2;              /* opacity-20 */
      }

      /* Hover state */
      .core-modal-close-button:hover {
        opacity: 0.4;              /* hover:opacity-40 */
      }
    """
  end

  @impl true
  @spec rule(:button) :: binary()
  def rule(:button) do
    """
      .button {
        border-radius: 0.5rem;
        background-color: var(--color-text-primary);
        padding: 0.5rem 0.75rem;
        font-size: 0.875rem;
        font-weight: 600;
        line-height: 1.5rem;
        color: var(--color-text-on-accent);
      }

      .button:hover {
        background-color: var(--color-text-hover);
      }

      .button:active {
        color: var(--color-text-on-accent-active);
      }

      .button[phx-submit-loading] {
        opacity: 0.75;
      }
    """
  end

  @impl true
  @spec rule(:checkbox) :: binary()
  def rule(:checkbox) do
    """
    .checkbox {
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
        border-color: var(--color-border-default);
        background-color: var(--color-bg-white);
        color: var(--color-text-primary);


        --tw-ring-color: transparent;
        box-shadow: none;
        outline: none;
        background-image: none;
      }

      .checkbox:disabled {
        background-color: var(--color-bg-light);
        color: var(--color-text-secondary);

        opacity: 1;
        cursor: not-allowed;
      }
    """
  end

  @impl true
  @spec rule(:checkbox_label) :: binary()
  def rule(:checkbox_label) do
    """
      .checkbox-label {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        line-height: 1.5rem;
        color: var(--color-text-secondary);
      }
    """
  end

  @impl true
  @spec rule(atom()) :: binary()
  def rule(_), do: ""
end
