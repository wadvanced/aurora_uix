defmodule Aurora.Uix.Templates.Basic.Themes.BaseVariables do
  @moduledoc """
  The root variables for the Basic template. 
  Colors variables should be already set by calling module. No colors variables should be defined here.
  """
  use Aurora.Uix.Templates.Theme

  alias Aurora.Uix.Templates.Basic.Themes.Base

  @impl true
  @spec rule(atom()) :: binary()
  def rule(:root) do
    """

    :root, :host {

      /* ---------- SIZES and DIMENSIONS ----------- */

      --auix-box-size-unit: 1rem;

      --auix-line-height-default: 1.250rem;

      --auix-border-radius-default: 0.5rem;
      --auix-border-radius-small: 0.250rem;
      --auix-border-radius-large: 1rem;
      --auix-border-radius-round: 9999px;
      --auix-border-width-default: 0.0625rem;
      --auix-border-width-thick: 0.125rem;
      --auix-border-style-default: solid;

      --auix-gap-minimal: 0.125rem;
      --auix-gap-default: 0.250rem;
      --auix-gap-medium: 0.500rem;
      --auix-gap-large: 0.750rem;

      --auix-padding-default: 0.625rem;
      --auix-padding-minimal: 0.3125rem;
      --auix-padding-small: 0.250rem;
      --auix-padding-medium: 0.500rem;
      --auix-padding-large: 1.5rem;
      --auix-padding-xl: 2rem;

      --auix-margin-default: 0.250rem;
      --auix-margin-medium: 0.500rem;

      --auix-input-height-default: 1rem;
      --auix-button-height-default: 2em;
      
      --auix-icon-size-base: 0.25rem;
      --auix-icon-size-3: calc(var(--auix-icon-size-base) * 3);
      --auix-icon-size-4: calc(var(--auix-icon-size-base) * 4);
      --auix-icon-size-5: calc(var(--auix-icon-size-base) * 5);
      --auix-icon-size-6: calc(var(--auix-icon-size-base) * 6);

      --auix-icon-size-button: var(--auix-icon-size-4);

      /* Font */
      --auix-font-sans: ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
      --auix-font-mono: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;
      --auix-font-family-default: var(--auix-font-sans);
      --auix-font-size-title: 1.125rem;
      --auix-font-size-subtitle: 1rem;
      --auix-font-size-caption: 0.875rem;
      --auix-font-size-small: 0.750rem;
      --auix-font-weight-bold: 600;
      --auix-font-weight-bold-semi: 400;
      --auix-font-style-mobile-viewmode: italic;


      /* OPACITIES
      --auix-opacity-20: 0.20 /* Opacity 20% */
      --auix-opacity-40: 0.40 /* Opacity 40% */
      --auix-opacity-75: 0.75 /* Opacity 75% */
      --auix-opacity-100: 1 /* Opacity 100% */

      /* SHADOWS & RINGS */

      /* Generic Shadow/Ring Variables */
      --auix-ring-inset: ;
      --auix-ring-offset-shadow: 0 0 #0000;
      --auix-ring-offset-width: 0px;
      --auix-ring-info:
        var(--auix-ring-inset)
        0 0 0
        calc(1px + var(--auix-ring-offset-width))
        var(--auix-color-info-ring);


      /* Equivalent to Tailwind's 'shadow' (Default/Smallest) */
      --auix-shadow-default:
        0 1px 3px 0 var(--auix-color-shadow-black-alpha),
        0 1px 2px -1px var(--auix-color-shadow-black-alpha);

      /* Equivalent to Tailwind's 'shadow-sm' (Single-layer small shadow) */
      --auix-shadow-small: 0 1px 2px 0 var(--auix-color-shadow-black-alpha-small);

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
