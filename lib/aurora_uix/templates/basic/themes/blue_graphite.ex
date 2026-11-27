defmodule Aurora.Uix.Templates.Basic.Themes.BlueGraphite do
  @moduledoc """
  The Blue Graphite theme for the Basic template.

  ## Key Features
  - Slate text and borders, a blue primary, graphite table headers, a dimmed modal backdrop and
    light / dark values for every color variable.
  - Registered as `:blue_graphite`; select it with `config :aurora_uix, theme_name: :blue_graphite`.

  ## Key Constraints
  - Defines colors only; every other rule comes from `ThemeBase` through `include`.
  """
  use Aurora.Uix.Templates.Theme, theme_name: :blue_graphite

  alias Aurora.Uix.Templates.Basic.Themes.ThemeBase

  rule(:root_colors, """
  :root[data-theme-name="#{@theme_name}"], :host[data-theme-name="#{@theme_name}"] {
  /* Theme Name: Blue Graphite */
  /* Base Palette: Gray (Slate), Blue (Primary), Graphite (Table header), Red (Danger) */

    /* Backgrounds */
    --auix-color-bg-default: #FFFFFF;
    --auix-color-bg-default--reverted: #1D4ED8;
    --auix-color-bg-secondary: #D0D5DD;
    --auix-color-bg-disabled: #98A2B3;
    --auix-color-bg-info: #EFF4FF;
    --auix-color-bg-light: #F2F4F7;
    --auix-color-bg-hover: #F9FAFB;
    --auix-color-bg-hover--reverted: #1E40AF;
    --auix-color-bg-backdrop: rgba(31, 41, 55, 0.6);
    --auix-color-bg-inner-container: rgba(249, 250, 251, 0.8);
    --auix-color-bg-danger: #B42318;
    --auix-color-bg-danger-hover: #912018;

    /* Text */
    --auix-color-text-primary: #101828;
    --auix-color-text-secondary: #475467;
    --auix-color-text-tertiary: #667085;
    --auix-color-text-inactive: #98A2B3;
    --auix-color-text-label: #344054;
    --auix-color-text-hover: #344054;
    --auix-color-text-on-accent: #FFFFFF;
    --auix-color-text-on-accent-active: rgba(255, 255, 255, 0.8);

    /* Status Colors */
    --auix-color-error-text-default: #B42318;
    --auix-color-error: #D92D20;
    --auix-color-info-text: #00359E;
    --auix-color-info-ring: #B2CCFF;
    --auix-color-error-bg: #FEF3F2;
    --auix-color-error-text: #912018;
    --auix-color-error-ring: #FDA29B;
    --auix-color-icon-fill: #00359E;
    --auix-color-icon-default: #101828;
    --auix-color-icon-safe: #085D3A;
    --auix-color-icon-info: #1D4ED8;
    --auix-color-icon-danger: #B42318;
    --auix-color-icon-inactive: #D0D5DD;

    /* Borders */
    --auix-color-border-primary: #C4CAD4;
    --auix-color-border-secondary: #E4E7EC;
    --auix-color-border-tertiary: #F2F4F7;
    --auix-color-border-focus: #2563EB;

    /* Focus States */
    --auix-color-focus-ring: #2563EB;
    --auix-color-focus-ring-halo: rgba(37, 99, 235, 0.28);

    /* Success, warning and selection */
    --auix-color-success-bg: #ECFDF3;
    --auix-color-success-border: #ABEFC6;
    --auix-color-success-text: #085D3A;
    --auix-color-warning-bg: #FFFAEB;
    --auix-color-warning-border: #FEDF89;
    --auix-color-warning-text: #7A2E0E;
    --auix-color-selection-bg: #EFF6FF;
    --auix-color-selection-border: #1D4ED8;

    /* Rings and shadows */
    --auix-ring-color: rgba(16, 24, 40, 0.1);
    --auix-color-shadow-alpha: rgba(16, 24, 40, 0.1);
    --auix-color-shadow-black-alpha: rgba(16, 24, 40, 0.1);
    --auix-color-shadow-black-alpha-small: rgba(16, 24, 40, 0.05);
    /* Component colors */
    --auix-color-items-table-header-bg: #374151;
    --auix-color-items-table-header-text: #E5E7EB;
    --auix-color-items-table-header-sorted-text: #FFFFFF;
    --auix-color-sections-tab-active-text: #1D4ED8;


    /* Dark theme variant - intermediate variables used in the dark mode selectors */
    --dark--auix-color-bg-default: #111723;
    --dark--auix-color-bg-default--reverted: #84ADFF;
    --dark--auix-color-bg-secondary: #3A4558;
    --dark--auix-color-bg-disabled: #5B6678;
    --dark--auix-color-bg-info: #111C3A;
    --dark--auix-color-bg-light: #1D2535;
    --dark--auix-color-bg-hover: #161C29;
    --dark--auix-color-bg-hover--reverted: #B2CCFF;
    --dark--auix-color-bg-backdrop: #05070B;
    --dark--auix-color-bg-inner-container: rgba(17, 23, 35, 0.8);
    --dark--auix-color-bg-danger: #F97066;
    --dark--auix-color-bg-danger-hover: #FDA29B;
    --dark--auix-color-text-primary: #F2F4F7;
    --dark--auix-color-text-secondary: #98A2B3;
    --dark--auix-color-text-tertiary: #8591A3;
    --dark--auix-color-text-inactive: #5B6678;
    --dark--auix-color-text-label: #D0D5DD;
    --dark--auix-color-text-hover: #D0D5DD;
    --dark--auix-color-text-on-accent: #0C111D;
    --dark--auix-color-text-on-accent-active: rgba(12, 17, 29, 0.8);
    --dark--auix-color-error-text-default: #F97066;
    --dark--auix-color-error: #F04438;
    --dark--auix-color-info-text: #B2CCFF;
    --dark--auix-color-info-ring: #23408E;
    --dark--auix-color-error-bg: #2A1313;
    --dark--auix-color-error-text: #FDA29B;
    --dark--auix-color-error-ring: #7A271A;
    --dark--auix-color-icon-fill: #B2CCFF;
    --dark--auix-color-icon-default: #F2F4F7;
    --dark--auix-color-icon-safe: #75E0A7;
    --dark--auix-color-icon-info: #B2CCFF;
    --dark--auix-color-icon-danger: #F97066;
    --dark--auix-color-icon-inactive: #5B6678;
    --dark--auix-color-border-primary: #3A4558;
    --dark--auix-color-border-secondary: #262F3F;
    --dark--auix-color-border-tertiary: #1D2535;
    --dark--auix-color-border-focus: #84ADFF;
    --dark--auix-color-focus-ring: #84ADFF;
    --dark--auix-color-focus-ring-halo: rgba(132, 173, 255, 0.3);
    --dark--auix-color-success-bg: #0B261A;
    --dark--auix-color-success-border: #17573A;
    --dark--auix-color-success-text: #75E0A7;
    --dark--auix-color-warning-bg: #2B1D08;
    --dark--auix-color-warning-border: #6B4A0F;
    --dark--auix-color-warning-text: #FEC84B;
    --dark--auix-color-selection-bg: #17264A;
    --dark--auix-color-selection-border: #84ADFF;
    --dark--auix-ring-color: rgba(230, 233, 239, 0.1);
    --dark--auix-color-shadow-alpha: rgba(0, 0, 0, 0.3);
    --dark--auix-color-shadow-black-alpha: rgba(0, 0, 0, 0.3);
    --dark--auix-color-shadow-black-alpha-small: rgba(0, 0, 0, 0.15);
  }

  /* Dark theme - Apply dark variant via media query */
  @media (prefers-color-scheme: dark) {
    :root[data-theme-name="#{@theme_name}"]:not([data-theme="light"]), :host[data-theme-name="#{@theme_name}"]:not([data-theme="light"]) {
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
      --auix-color-focus-ring-halo: var(--dark--auix-color-focus-ring-halo);
      --auix-color-success-bg: var(--dark--auix-color-success-bg);
      --auix-color-success-border: var(--dark--auix-color-success-border);
      --auix-color-success-text: var(--dark--auix-color-success-text);
      --auix-color-warning-bg: var(--dark--auix-color-warning-bg);
      --auix-color-warning-border: var(--dark--auix-color-warning-border);
      --auix-color-warning-text: var(--dark--auix-color-warning-text);
      --auix-color-selection-bg: var(--dark--auix-color-selection-bg);
      --auix-color-selection-border: var(--dark--auix-color-selection-border);
      --auix-ring-color: var(--dark--auix-ring-color);
      --auix-color-shadow-alpha: var(--dark--auix-color-shadow-alpha);
      --auix-color-shadow-black-alpha: var(--dark--auix-color-shadow-black-alpha);
      --auix-color-shadow-black-alpha-small: var(--dark--auix-color-shadow-black-alpha-small);
      --auix-color-items-table-header-bg: #2B3648;
      --auix-color-sections-tab-active-text: #84ADFF;
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
    --auix-color-focus-ring-halo: var(--dark--auix-color-focus-ring-halo);
    --auix-color-success-bg: var(--dark--auix-color-success-bg);
    --auix-color-success-border: var(--dark--auix-color-success-border);
    --auix-color-success-text: var(--dark--auix-color-success-text);
    --auix-color-warning-bg: var(--dark--auix-color-warning-bg);
    --auix-color-warning-border: var(--dark--auix-color-warning-border);
    --auix-color-warning-text: var(--dark--auix-color-warning-text);
    --auix-color-selection-bg: var(--dark--auix-color-selection-bg);
    --auix-color-selection-border: var(--dark--auix-color-selection-border);
    --auix-ring-color: var(--dark--auix-ring-color);
    --auix-color-shadow-alpha: var(--dark--auix-color-shadow-alpha);
    --auix-color-shadow-black-alpha: var(--dark--auix-color-shadow-black-alpha);
    --auix-color-shadow-black-alpha-small: var(--dark--auix-color-shadow-black-alpha-small);
    --auix-color-items-table-header-bg: #2B3648;
    --auix-color-sections-tab-active-text: #84ADFF;
  }
  """)

  include(ThemeBase)
end
