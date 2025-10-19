defmodule Aurora.Uix.Templates.Basic.Themes.Light do
  @moduledoc """
  The light theme for the Basic template.

  This theme defines the CSS variables for the light theme and delegates the rest of the rules to the `Base` theme.
  """
  use Aurora.Uix.Templates.Theme

  alias Aurora.Uix.Templates.Basic.Themes.Base

  @impl true
  @spec rule(atom()) :: binary()
  def rule(:root) do
    """
    /* */
    :root {
      /* Backgrounds */
      --auix-color-bg-disabled: #A1A1AA; /* zinc-400 for disabled backgrounds */
      --auix-color-bg-light: #F4F4F5; /* zinc-100 for light backgrounds/borders */
      --auix-color-bg-hover: #FAFAFA; /* zinc-50 */
      --auix-color-bg-white: #FFFFFF; /* For pure white backgrounds (e.g., unchecked inputs) */
      --auix-color-bg-backdrop: rgba(250, 250, 250, 0.9); /* zinc-50 with 90% opacity */

      /* Text */
      --auix-color-text-primary: #18181B; /* zinc-900 */
      --auix-color-text-secondary: #52525B;  /* zinc-600 for secondary text */
      --auix-color-text-label: #27272A;      /* zinc-800 for label text */
      --auix-color-text-hover: #47474a;   /* zinc-700 */
      --auix-color-text-on-accent: #FFFFFF; /* white text on dark/accent background */
      --auix-color-text-on-accent-active: rgba(255, 255, 255, 0.8); /* active text opacity */

      /* Status Colors */
      --auix-color-error: #FB7185; /* rose-400 for input error borders */
      --auix-color-info-bg: #F0FDF4;        /* emerald-50 (Info Background) */
      --auix-color-info-text: #065F46;      /* emerald-800 (Info Text) */
      --auix-color-info-ring: #10B981;      /* emerald-500 (Info Ring) */
      --auix-color-icon-fill: #164E63;      /* cyan-900 (Icon Fill) */
      --auix-color-error-bg: #FFF1F2;       /* rose-50 (Error Background) */
      --auix-color-error-text: #831843;     /* rose-900 (Error Text/Fill) */
      --auix-color-error-ring: #F43F5E;     /* rose-500 (Error Ring) */

      /* Borders */
      --auix-color-border-default: #D4D4D8; /* zinc-300 */
      --auix-color-border-focus: #A1A1AA;   /* zinc-400 for input focus border */

      /* Focus States (Focus Ring / Border) */
      --auix-color-focus-ring: #6366F1; /* indigo-500 */

      /* SHADOWS & RINGS */
      /* Zinc 700 is #47474a. Opacity 10% is 0.1 */
      --auix-color-zinc-700-10: rgba(71, 71, 74, 0.1);

      /* shadow-md (0 4px 6px -1px, 0 2px 4px -2px with 10% black opacity) */
      --auix-shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);

      /* shadow-lg (Example based on Tailwind default values) */
      --auix-shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);

      /* shadow-zinc-700/10 */
      --auix-shadow-zinc-700-10: 0 4px 6px -1px var(--auix-color-zinc-700-10), 0 2px 4px -2px var(--auix-color-zinc-700-10);

      /* ring-zinc-700/10 (1px ring is achieved via box-shadow) */
      --auix-ring-zinc-700-10: var(--auix-ring-inset) 0 0 0 calc(1px + var(--auix-ring-offset-width)) var(--auix-color-zinc-700-10);

      /* Generic Shadow/Ring Variables */
      --auix-primary-shadow: var(--auix-shadow-lg); /* Use shadow-lg as the primary shadow */
      --auix-ring-inset: ;
      --auix-ring-offset-shadow: 0 0 #0000;
      --auix-ring-offset-width: 0px;

    }
    """
  end

  @impl true
  @spec rule(atom()) :: binary()
  def rule(rule), do: Base.rule(rule)
end
