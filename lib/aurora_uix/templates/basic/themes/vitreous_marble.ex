defmodule Aurora.Uix.Templates.Basic.Themes.VitreousMarble do
  @moduledoc """
  The sky theme for the basic template.

  This theme defines the CSS variables with light / dark mode for blueish / purpleish theme 
  and delegates the rest of the rules to the `BaseVariables` theme.
  """
  use Aurora.Uix.Templates.Theme, theme_name: :vitreous_marble

  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  @impl true
  @spec rule(atom()) :: binary()
  def rule(:root_colors) do
    """
    :root[data-theme-name="#{@theme_name}"], :host[data-theme-name="#{@theme_name}"] {
    /* Theme Name: Vitreous Marble */
    /* Base Palette: Slate (Cool Grey), Cyan (Glass), Ruby (Danger) */
    /* https://tailscan.com/colors */

      /* -------- COLORS, BORDERS, TRANSITIONS ------*/
      /* Backgrounds */
      --auix-color-bg-default: #FFFFFF; /* Pure White Marble */
      --auix-color-bg-default--reverted: #0F172A; /* Slate-900 */
      --auix-color-bg-secondary: #CBD5E1; /* Slate-300 - Cold stone secondary */ 
      --auix-color-bg-disabled: #94A3B8; /* Slate-400 */
      --auix-color-bg-info: #ECFEFF;  /* Cyan-50 (Glassy Info Background) */
      --auix-color-bg-light: #F1F5F9; /* Slate-100 */
      --auix-color-bg-hover: #F8FAFC; /* Slate-50 */
      --auix-color-bg-hover--reverted: #334155;   /* Slate-700 */
      --auix-color-bg-backdrop: rgba(248, 250, 252, 0.9); /* Slate-50 with 90% opacity */
      --auix-color-bg-inner-container: rgba(248, 250, 252, 0.8); /* Slate-50 with 80% opacity */
      --auix-color-bg-danger: #F87171;     /* Red-400 */
      --auix-color-bg-danger-hover: #DC2626; /* Red-600 */
      
      /* Text */
      --auix-color-text-primary: #0F172A; /* Slate-900 (Deep Blue-Black) */
      --auix-color-text-secondary: #475569;  /* Slate-600 */
      --auix-color-text-tertiary: #64748B;   /* Slate-500 */
      --auix-color-text-inactive: #94A3B8;   /* Slate-400 */
      --auix-color-text-label: #1E293B;      /* Slate-800 */
      --auix-color-text-hover: #334155;   /* Slate-700 */
      --auix-color-text-on-accent: #FFFFFF; 
      --auix-color-text-on-accent-active: rgba(255, 255, 255, 0.8);

      /* Status Colors - The "Glass Swirls" */
      --auix-color-error-text-default: #DC2626; /* Red-600 */
      --auix-color-error: #F87171;           /* Red-400 */
      --auix-color-info-text: #0F766E;       /* Teal-700 */
      --auix-color-info-ring: #14B8A6;       /* Teal-500 */
      --auix-color-error-bg: #FEF2F2;        /* Red-50 */
      --auix-color-error-text: #7F1D1D;      /* Red-900 */
      --auix-color-error-ring: #EF4444;      /* Red-500 */
      --auix-color-icon-fill: #155E75;       /* Cyan-900 */
      --auix-color-icon-default: #0F172A;    /* Slate-900 */
      --auix-color-icon-safe: #059669;       /* Emerald-600 */
      --auix-color-icon-info: #0891B2;       /* Cyan-600 */
      --auix-color-icon-danger: #B91C1C;     /* Red-700 */
      --auix-color-icon-inactive: #CBD5E1;   /* Slate-300 */

      /* Borders */
      --auix-color-border-primary: #CBD5E1; /* Slate-300 */
      --auix-color-border-secondary: #E2E8F0; /* Slate-200 */
      --auix-color-border-tertiary: #F1F5F9; /* Slate-100 */
      --auix-color-border-focus: #94A3B8;   /* Slate-400 */

      /* Focus States (Focus Ring / Border) - The "Cat's Eye" effect */
      --auix-color-focus-ring: #06B6D4; /* Cyan-500 */

      --auix-ring-color: rgba(51, 65, 85, 0.1);
      
      --auix-color-shadow-alpha: rgba(51, 65, 85, 0.1);
      --auix-color-shadow-black-alpha: rgba(0, 0, 0, 0.1);
      --auix-color-shadow-black-alpha-small: rgba(0, 0, 0, 0.05);

      /* Dark theme variant - Obsidian/Space Marble */
      --dark--auix-color-bg-default: #020617; /* Slate-950 (Deep Obsidian) */
      --dark--auix-color-bg-default--reverted: #FFFFFF; 
      --dark--auix-color-bg-secondary: #334155; /* Slate-700 */
      --dark--auix-color-bg-disabled: #475569; /* Slate-600 */
      --dark--auix-color-bg-info: #042F2E;  /* Teal-950 */
      --dark--auix-color-bg-light: #1E293B; /* Slate-800 */
      --dark--auix-color-bg-hover: #1E293B; /* Slate-800 */
      --dark--auix-color-bg-hover--reverted: #E2E8F0; /* Slate-200 */
      --dark--auix-color-bg-backdrop: rgba(2, 6, 23, 0.9); /* Slate-950 opacity */
      --dark--auix-color-bg-inner-container: rgba(2, 6, 23, 0.8); 
      --dark--auix-color-bg-danger: #BE123C; /* Rose-700 */
      --dark--auix-color-bg-danger-hover: #FB7185; /* Rose-400 */
      
      --dark--auix-color-text-primary: #F8FAFC; /* Slate-50 */
      --dark--auix-color-text-secondary: #94A3B8; /* Slate-400 */
      --dark--auix-color-text-tertiary: #64748B; /* Slate-500 */
      --dark--auix-color-text-inactive: #475569; /* Slate-600 */
      --dark--auix-color-text-label: #E2E8F0; /* Slate-200 */
      --dark--auix-color-text-hover: #CBD5E1; /* Slate-300 */
      --dark--auix-color-text-on-accent: #020617; 
      --dark--auix-color-text-on-accent-active: rgba(2, 6, 23, 0.8);

      --dark--auix-color-error-text-default: #F87171; /* Red-400 */
      --dark--auix-color-error: #EF4444; /* Red-500 */
      --dark--auix-color-info-text: #14B8A6; /* Teal-500 */
      --dark--auix-color-info-ring: #22D3EE; /* Cyan-400 */
      --dark--auix-color-error-bg: #450A0A; /* Red-950 */
      --dark--auix-color-error-text: #FCA5A5; /* Red-300 */
      --dark--auix-color-error-ring: #F87171; /* Red-400 */
      --dark--auix-color-icon-fill: #22D3EE; /* Cyan-400 */
      --dark--auix-color-icon-default: #F8FAFC; /* Slate-50 */
      --dark--auix-color-icon-safe: #10B981; /* Emerald-500 */
      --dark--auix-color-icon-info: #38BDF8; /* Sky-400 */
      --dark--auix-color-icon-danger: #F87171; /* Red-400 */
      --dark--auix-color-icon-inactive: #475569; /* Slate-600 */

      --dark--auix-color-border-primary: #334155; /* Slate-700 */
      --dark--auix-color-border-secondary: #1E293B; /* Slate-800 */
      --dark--auix-color-border-tertiary: #0F172A; /* Slate-900 */
      --dark--auix-color-border-focus: #475569; /* Slate-600 */

      --dark--auix-color-focus-ring: #22D3EE; /* Cyan-400 (Glowing Glass) */
      --dark--auix-ring-color: rgba(203, 213, 225, 0.1);

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

  def rule(rule), do: BaseVariables.rule(rule)
end
