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
    :root, :host {


      /* Backgrounds */
      --auix-color-bg-default: #FFFFFF; /* For pure white backgrounds (e.g., unchecked inputs) */
      --auix-color-bg-disabled: #A1A1AA; /* zinc-400 for disabled backgrounds */
      --auix-color-bg-info: #F0FDF4;  /* emerald-50 (Info Background) */
      --auix-color-bg-light: #F4F4F5; /* zinc-100 for light backgrounds/borders */
      --auix-color-bg-hover: #FAFAFA; /* zinc-50 */
      --auix-color-bg-backdrop: rgba(250, 250, 250, 0.9); /* zinc-50 with 90% opacity */

      /* Font */
      --auix-font-sans: ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
      --auix-font-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;
      --auix-default-font-family: var(--auix-font-sans);

      /* Text */
      --auix-color-text-primary: #18181B; /* zinc-900 */
      --auix-color-text-secondary: #52525B;  /* zinc-600 for secondary text */
      --auix-color-text-tertiary: #71717A;   /* zinc-500 for tertiary/muted text */
      --auix-color-text-inactive: #A1A1AA;   /* zinc-400 for inactive text */
      --auix-color-text-label: #27272A;      /* zinc-800 for label text */
      --auix-color-text-hover: #47474a;   /* zinc-700 */
      --auix-color-text-on-accent: #FFFFFF; /* white text on dark/accent background */
      --auix-color-text-on-accent-active: rgba(255, 255, 255, 0.8); /* active text opacity */

      /* Status Colors */
      --auix-color-error-text-default: #E11D48; /* rose-600 for inline error text */
      --auix-color-error: #FB7185;          /* rose-400 for input error borders */
      --auix-color-info-text: #065F46;      /* emerald-800 (Info Text) */
      --auix-color-info-ring: #10B981;      /* emerald-500 (Info Ring) */
      --auix-color-icon-fill: #164E63;      /* cyan-900 (Icon Fill) */
      --auix-color-error-bg: #FFF1F2;       /* rose-50 (Error Background) */
      --auix-color-error-text: #831843;     /* rose-900 (Error Text/Fill) */
      --auix-color-error-ring: #F43F5E;     /* rose-500 (Error Ring) */

      /* Borders */
      --auix-color-border-default: #D4D4D8; /* zinc-300 */
      --auix-color-border-secondary: #E4E4E7; /* zinc-200 */
      --auix-color-border-tertiary: #F4F4F5; /* zinc-100 */
      --auix-color-border-focus: #A1A1AA;   /* zinc-400 for input focus border */

      /* Focus States (Focus Ring / Border) */
      --auix-color-focus-ring: #6366F1; /* indigo-500 */

      /* SHADOWS & RINGS */

      /* Generic Shadow/Ring Variables */
      --auix-ring-inset: ;
      --auix-ring-offset-shadow: 0 0 #0000;
      --auix-ring-offset-width: 0px;
      --auix-ring-color: rgba(63, 63, 70, 0.1);
      --auix-ring-info:
        var(--auix-ring-inset)
        0 0 0
        calc(1px + var(--auix-ring-offset-width))
        var(--auix-color-info-ring);

      /* Zinc 700 is #47474a. Opacity 10% is 0.1 */
      --auix-color-shadow-alpha: rgba(71, 71, 74, 0.1);
      --auix-color-shadow-black-alpha: rgba(0, 0, 0, 0.1);
      --auix-color-shadow-black-alpha-sm: rgba(0, 0, 0, 0.05);

      /* Equivalent to Tailwind's 'shadow' (Default/Smallest) */
      --auix-shadow-default:
        0 1px 3px 0 var(--auix-color-shadow-black-alpha),
        0 1px 2px -1px var(--auix-color-shadow-black-alpha);

      /* Equivalent to Tailwind's 'shadow-sm' (Single-layer small shadow) */
      --auix-shadow-sm: 0 1px 2px 0 var(--auix-color-shadow-black-alpha-sm);

      /* Equivalent to Tailwind's 'shadow-md' (Medium size) */
      --auix-shadow-md:
        0 4px 6px -1px var(--auix-color-shadow-black-alpha),
        0 2px 4px -2px var(--auix-color-shadow-black-alpha);

      /* Equivalent to Tailwind's 'shadow-lg' (Large size) */
      --auix-shadow-lg:
        0 10px 15px -3px var(--auix-color-shadow-black-alpha),
        0 4px 6px -4px var(--auix-color-shadow-black-alpha);

      --auix-shadow-primary: var(--auix-shadow-lg); /* Use shadow-lg as the primary shadow */

      /* Secondary/Colored shadow (Uses -md offsets but with a custom Zinc color) */
      --auix-shadow-secondary:
        0 4px 6px -1px var(--auix-color-shadow-alpha),
        0 2px 4px -2px var(--auix-color-shadow-alpha);

      /* ring-zinc-700/10 (1px ring is achieved via box-shadow) */
      --auix-ring-default:
        var(--auix-ring-inset)
        0 0 0
        calc(1px + var(--auix-ring-offset-width))
        var(--auix-ring-color);
      --auix-ring-secondary: var(--auix-ring-inset) 0 0 0 calc(1px + var(--auix-ring-offset-width)) var(--auix-color-shadow-alpha);
    }
    """
  end

  @impl true
  @spec rule(atom()) :: binary()
  def rule(rule), do: Base.rule(rule)
end
