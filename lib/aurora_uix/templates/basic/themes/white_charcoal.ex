defmodule Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal do
  @moduledoc """
  The Snow Coat theme for the Basic template. This is the default template

  This theme defines the CSS variables with light and dark mode for a mostly white / black theme 
  and delegates the rest of the rules to the `BaseVariables` module.
  """
  use Aurora.Uix.Templates.Theme, theme_name: :white_charcoal

  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  @impl true
  @spec rule(atom()) :: binary()
  def rule(:root_colors) do
    """
    :root[data-theme-name="#{@theme_name}"], :host[data-theme-name="#{@theme_name}"] {
    /* Theme Name: White Charcoal */
    /* Base Palette: Zinc (Cool Grey), Emerald (Glass), Rose (Danger) */
    /* https://tailscan.com/colors */

      /* -------- COLORS, BORDERS, TRANSITIONS ------*/
      /* Backgrounds */
      --auix-color-bg-default: #FFFFFF; /* For pure white backgrounds (e.g., unchecked inputs) */
      --auix-color-bg-default--reverted: #18181B; /* zinc-900 */
      --auix-color-bg-secondary: #D4D4D8; /* zinc-300, use in odd/even elements */ 
      --auix-color-bg-disabled: #A1A1AA; /* zinc-400 for disabled backgrounds */
      --auix-color-bg-info: #F0FDF4;  /* emerald-50 (Info Background) */
      --auix-color-bg-light: #F4F4F5; /* zinc-100 for light backgrounds/borders */
      --auix-color-bg-hover: #FAFAFA; /* zinc-50 */
      --auix-color-bg-hover--reverted: #47474a;   /* zinc-700 */
      --auix-color-bg-backdrop: rgba(250, 250, 250, 0.9); /* zinc-50 with 90% opacity */
      --auix-color-bg-inner-container: rgba(250, 250, 250, 0.8); /* zinc-50 with 80% opacity */
      --auix-color-bg-danger: #FB7185;     /* rose-400 */
      --auix-color-bg-danger-hover: #E11D48; /* rose-600 */
      
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
      --auix-color-error-bg: #FFF1F2;       /* rose-50 (Error Background) */
      --auix-color-error-text: #831843;     /* rose-900 (Error Text/Fill) */
      --auix-color-error-ring: #F43F5E;     /* rose-500 (Error Ring) */
      --auix-color-icon-fill: #164E63;      /* cyan-900 (Icon Fill) */
      --auix-color-icon-default: #18181B;   /* zinc-900 */
      --auix-color-icon-safe: #047857;      /* emerald-700 for safe actions (like save) */
      --auix-color-icon-info: #1D4ED8;      /* blue-700 for informative actions (like show) */
      --auix-color-icon-danger: #BE123C;    /* rose-700 for dangerous actions (like delete) */
      --auix-color-icon-inactive: #D4D4D8;  /* zinc-300 for inactive or low relevance actions */

      /* Borders */
      --auix-color-border-primary: #D4D4D8; /* zinc-300 */
      --auix-color-border-secondary: #E4E4E7; /* zinc-200 */
      --auix-color-border-tertiary: #F4F4F5; /* zinc-100 */
      --auix-color-border-focus: #A1A1AA;   /* zinc-400 for input focus border */

      /* Focus States (Focus Ring / Border) */
      --auix-color-focus-ring: #6366F1; /* indigo-500 */

      --auix-ring-color: rgba(63, 63, 70, 0.1);
      
      /* Zinc 700 is #47474a. Opacity 10% is 0.1 */
      --auix-color-shadow-alpha: rgba(71, 71, 74, 0.1);
      --auix-color-shadow-black-alpha: rgba(0, 0, 0, 0.1);
      --auix-color-shadow-black-alpha-small: rgba(0, 0, 0, 0.05);

      /* Dark theme variant - Intermediate variables used in dark mode selectors */
      /* These are applied via @media or data-theme selectors below */
      --dark--auix-color-bg-default: #18181B; /* zinc-900 */
      --dark--auix-color-bg-default--reverted: #FFFFFF; /* white */
      --dark--auix-color-bg-secondary: #3F3F46; /* zinc-700, use in odd/even elements */
      --dark--auix-color-bg-disabled: #52525B; /* zinc-600 for disabled backgrounds */
      --dark--auix-color-bg-info: #051F16;  /* emerald-950 (Info Background) */
      --dark--auix-color-bg-light: #27272A; /* zinc-800 for light backgrounds/borders */
      --dark--auix-color-bg-hover: #27272A; /* zinc-800 */
      --dark--auix-color-bg-hover--reverted: #E4E4E7; /* zinc-200 */
      --dark--auix-color-bg-backdrop: rgba(24, 24, 27, 0.9); /* zinc-900 with 90% opacity */
      --dark--auix-color-bg-inner-container: rgba(24, 24, 27, 0.8); /* zinc-900 with 80% opacity */
      --dark--auix-color-bg-danger: #BE123C; /* rose-700 */
      --dark--auix-color-bg-danger-hover: #FB7185; /* rose-400 */
      
      --dark--auix-color-text-primary: #FAFAFA; /* zinc-50 */
      --dark--auix-color-text-secondary: #A1A1AA; /* zinc-400 for secondary text */
      --dark--auix-color-text-tertiary: #71717A; /* zinc-500 for tertiary/muted text */
      --dark--auix-color-text-inactive: #52525B; /* zinc-600 for inactive text */
      --dark--auix-color-text-label: #E4E4E7; /* zinc-200 for label text */
      --dark--auix-color-text-hover: #D4D4D8; /* zinc-300 */
      --dark--auix-color-text-on-accent: #18181B; /* dark text on light/accent background */
      --dark--auix-color-text-on-accent-active: rgba(24, 24, 27, 0.8); /* active text opacity */

      --dark--auix-color-error-text-default: #FB7185; /* rose-400 for inline error text */
      --dark--auix-color-error: #F43F5E; /* rose-500 for input error borders */
      --dark--auix-color-info-text: #10B981; /* emerald-500 (Info Text) */
      --dark--auix-color-info-ring: #06B6D4; /* cyan-500 (Info Ring) */
      --dark--auix-color-error-bg: #3F000A; /* rose-950 (Error Background) */
      --dark--auix-color-error-text: #FCA5A5; /* rose-300 (Error Text/Fill) */
      --dark--auix-color-error-ring: #FB7185; /* rose-400 (Error Ring) */
      --dark--auix-color-icon-fill: #06B6D4; /* cyan-500 (Icon Fill) */
      --dark--auix-color-icon-default: #FAFAFA; /* zinc-50 */
      --dark--auix-color-icon-safe: #10B981; /* emerald-500 for safe actions (like save) */
      --dark--auix-color-icon-info: #60A5FA; /* blue-400 for informative actions (like show) */
      --dark--auix-color-icon-danger: #FB7185; /* rose-400 for dangerous actions (like delete) */
      --dark--auix-color-icon-inactive: #52525B; /* zinc-600 for inactive or low relevance actions */

      --dark--auix-color-border-primary: #3F3F46; /* zinc-700 */
      --dark--auix-color-border-secondary: #27272A; /* zinc-800 */
      --dark--auix-color-border-tertiary: #18181B; /* zinc-900 */
      --dark--auix-color-border-focus: #52525B; /* zinc-600 for input focus border */

      --dark--auix-color-focus-ring: #818CF8; /* indigo-400 */
      --dark--auix-ring-color: rgba(212, 212, 212, 0.1);

      --dark--auix-color-shadow-alpha: rgba(0, 0, 0, 0.3);
      --dark--auix-color-shadow-black-alpha: rgba(0, 0, 0, 0.3);
      --dark--auix-color-shadow-black-alpha-small: rgba(0, 0, 0, 0.15);
    }

    /* Dark theme - Apply dark variant via media query */
    @media (prefers-color-scheme: dark) {
      :root[data-theme-name="#{@theme_name}"], :host[data-theme-name="#{@theme_name}"] {
        --auix-color-bg-default: var(--dark--auix-color-bg-default);
        --auix-color-bg-default--reverted: var(--dark--auix-color-bg-default--reverted);
        --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
        --auix-color-bg-disabled: var(--dark--auix-color-bg-disabled);
        --auix-color-bg-info: var(--dark--auix-color-bg-info);
        --auix-color-bg-light: var(--dark--auix-color-bg-light);
        --auix-color-bg-hover: var(--dark--auix-color-bg-hover);
        --auix-color-bg-hover--reverted: var(--dark--auix-color-bg-hover--reverted);
        --auix-color-bg-backdrop: var(--dark--auix-color-bg-backdrop);
        --auix-color-bg-inner-container: var(--dark--auix-color-bg-inner-container);
        --auix-color-bg-danger: var(--dark--auix-color-bg-danger);
        --auix-color-bg-danger-hover: var(--dark--auix-color-bg-danger-hover);
        
        --auix-color-text-primary: var(--dark--auix-color-text-primary);
        --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
        --auix-color-text-tertiary: var(--dark--auix-color-text-tertiary);
        --auix-color-text-inactive: var(--dark--auix-color-text-inactive);
        --auix-color-text-label: var(--dark--auix-color-text-label);
        --auix-color-text-hover: var(--dark--auix-color-text-hover);
        --auix-color-text-on-accent: var(--dark--auix-color-text-on-accent);
        --auix-color-text-on-accent-active: var(--dark--auix-color-text-on-accent-active);

        --auix-color-error-text-default: var(--dark--auix-color-error-text-default);
        --auix-color-error: var(--dark--auix-color-error);
        --auix-color-info-text: var(--dark--auix-color-info-text);
        --auix-color-info-ring: var(--dark--auix-color-info-ring);
        --auix-color-error-bg: var(--dark--auix-color-error-bg);
        --auix-color-error-text: var(--dark--auix-color-error-text);
        --auix-color-error-ring: var(--dark--auix-color-error-ring);
        --auix-color-icon-fill: var(--dark--auix-color-icon-fill);
        --auix-color-icon-default: var(--dark--auix-color-icon-default);
        --auix-color-icon-safe: var(--dark--auix-color-icon-safe);
        --auix-color-icon-info: var(--dark--auix-color-icon-info);
        --auix-color-icon-danger: var(--dark--auix-color-icon-danger);
        --auix-color-icon-inactive: var(--dark--auix-color-icon-inactive);

        --auix-color-border-primary: var(--dark--auix-color-border-primary);
        --auix-color-border-secondary: var(--dark--auix-color-border-secondary);
        --auix-color-border-tertiary: var(--dark--auix-color-border-tertiary);
        --auix-color-border-focus: var(--dark--auix-color-border-focus);

        --auix-color-focus-ring: var(--dark--auix-color-focus-ring);
        --auix-ring-color: var(--dark--auix-ring-color);

        --auix-color-shadow-alpha: var(--dark--auix-color-shadow-alpha);
        --auix-color-shadow-black-alpha: var(--dark--auix-color-shadow-black-alpha);
        --auix-color-shadow-black-alpha-small: var(--dark--auix-color-shadow-black-alpha-small);
      }
    }

    /* Data-theme attribute - Highest priority */
    :root[data-theme="dark"][data-theme-name="#{@theme_name}"], :host[data-theme="dark"][data-theme-name="#{@theme_name}"] {
      --auix-color-bg-default: var(--dark--auix-color-bg-default);
      --auix-color-bg-default--reverted: var(--dark--auix-color-bg-default--reverted);
      --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
      --auix-color-bg-disabled: var(--dark--auix-color-bg-disabled);
      --auix-color-bg-info: var(--dark--auix-color-bg-info);
      --auix-color-bg-light: var(--dark--auix-color-bg-light);
      --auix-color-bg-hover: var(--dark--auix-color-bg-hover);
      --auix-color-bg-hover--reverted: var(--dark--auix-color-bg-hover--reverted);
      --auix-color-bg-backdrop: var(--dark--auix-color-bg-backdrop);
      --auix-color-bg-inner-container: var(--dark--auix-color-bg-inner-container);
      --auix-color-bg-danger: var(--dark--auix-color-bg-danger);
      --auix-color-bg-danger-hover: var(--dark--auix-color-bg-danger-hover);
      
      --auix-color-text-primary: var(--dark--auix-color-text-primary);
      --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
      --auix-color-text-tertiary: var(--dark--auix-color-text-tertiary);
      --auix-color-text-inactive: var(--dark--auix-color-text-inactive);
      --auix-color-text-label: var(--dark--auix-color-text-label);
      --auix-color-text-hover: var(--dark--auix-color-text-hover);
      --auix-color-text-on-accent: var(--dark--auix-color-text-on-accent);
      --auix-color-text-on-accent-active: var(--dark--auix-color-text-on-accent-active);

      --auix-color-error-text-default: var(--dark--auix-color-error-text-default);
      --auix-color-error: var(--dark--auix-color-error);
      --auix-color-info-text: var(--dark--auix-color-info-text);
      --auix-color-info-ring: var(--dark--auix-color-info-ring);
      --auix-color-error-bg: var(--dark--auix-color-error-bg);
      --auix-color-error-text: var(--dark--auix-color-error-text);
      --auix-color-error-ring: var(--dark--auix-color-error-ring);
      --auix-color-icon-fill: var(--dark--auix-color-icon-fill);
      --auix-color-icon-default: var(--dark--auix-color-icon-default);
      --auix-color-icon-safe: var(--dark--auix-color-icon-safe);
      --auix-color-icon-info: var(--dark--auix-color-icon-info);
      --auix-color-icon-danger: var(--dark--auix-color-icon-danger);
      --auix-color-icon-inactive: var(--dark--auix-color-icon-inactive);

      --auix-color-border-primary: var(--dark--auix-color-border-primary);
      --auix-color-border-secondary: var(--dark--auix-color-border-secondary);
      --auix-color-border-tertiary: var(--dark--auix-color-border-tertiary);
      --auix-color-border-focus: var(--dark--auix-color-border-focus);

      --auix-color-focus-ring: var(--dark--auix-color-focus-ring);
      --auix-ring-color: var(--dark--auix-ring-color);

      --auix-color-shadow-alpha: var(--dark--auix-color-shadow-alpha);
      --auix-color-shadow-black-alpha: var(--dark--auix-color-shadow-black-alpha);
      --auix-color-shadow-black-alpha-small: var(--dark--auix-color-shadow-black-alpha-small);
    }
    """
  end

  @impl true
  @spec rule(atom()) :: binary()
  def rule(rule), do: BaseVariables.rule(rule)
end
