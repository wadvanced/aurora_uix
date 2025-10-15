defmodule Aurora.Uix.Templates.Basic.Themes.Light do
  use Aurora.Uix.Templates.Theme

  alias Aurora.Uix.Templates.Basic.Themes.Base

  @impl true
  def rule(:root) do
    """
    /* */
    :root {
      /* Backgrounds */
      --color-bg-disabled: #A1A1AA; /* zinc-400 for disabled backgrounds */
      --color-bg-light: #F4F4F5; /* zinc-100 for light backgrounds/borders */
      --color-bg-hover: #FAFAFA; /* zinc-50 */
      --color-bg-white: #FFFFFF; /* For pure white backgrounds (e.g., unchecked inputs) */
      --color-bg-backdrop: rgba(250, 250, 250, 0.9); /* zinc-50 with 90% opacity */

      /* Text */
      --color-text-primary: #18181B; /* zinc-900 */
      --color-text-secondary: #52525B;  /* zinc-600 for secondary text */
      --color-text-hover: #47474a;   /* zinc-700 */
      --color-text-on-accent: #FFFFFF; /* white text on dark/accent background */
      --color-text-on-accent-active: rgba(255, 255, 255, 0.8); /* active text opacity */

      /* Status Colors */
      --color-error: #FB7185; /* New: rose-400 for input error borders */

      /* Borders */
      --color-border-default: #D4D4D8; /* zinc-300 */
      --color-border-focus: #A1A1AA;   /* zinc-400 for input focus border */

      /* Focus States (Focus Ring / Border) */
      --color-focus-ring: #6366F1; /* indigo-500 */

      /* SHADOWS & RINGS */
      /* Zinc 700 is #47474a. Opacity 10% is 0.1 */
      --color-zinc-700-10: rgba(71, 71, 74, 0.1);

      /* shadow-lg (Example based on Tailwind default values) */
      --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);

      /* shadow-zinc-700/10 */
      --shadow-zinc-700-10: 0 4px 6px -1px var(--color-zinc-700-10), 0 2px 4px -2px var(--color-zinc-700-10);

      /* ring-zinc-700/10 (1px ring is achieved via box-shadow) */
      --ring-zinc-700-10: var(--tw-ring-inset) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--color-zinc-700-10);

      /* Generic Shadow/Ring Variables (Needed for Tailwind's box-shadow implementation) */
      --tw-shadow: var(--shadow-lg); /* Use shadow-lg as the primary shadow */
      --tw-ring-inset: ;
      --tw-ring-offset-width: 0px;
    }
    """
  end

  def rule(rule), do: Base.rule(rule)
end
