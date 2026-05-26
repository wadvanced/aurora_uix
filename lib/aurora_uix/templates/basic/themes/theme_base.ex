defmodule Aurora.Uix.Templates.Basic.Themes.ThemeBase do
  @moduledoc """
  Component-specific color aliases shared across themes.

  Each alias defaults to a generic semantic var so the cascade still flows
  from generic palette → component. Override any alias in a theme's
  `:root_colors` block (or in user CSS) to change one component without
  touching its siblings.

  This module sits between the theme palette files and `BaseVariables` in the
  delegation chain:

  ```
  WhiteCharcoal / VitreousMarble  (own :root_colors)
          ↓ fallthrough
  ThemeBase                       (:root_color_aliases)
          ↓ fallthrough
  BaseVariables                   (:root sizes/shadows)
          ↓ fallthrough
  Base                            (all .auix-* component rules)
  ```
  """
  use Aurora.Uix.Templates.Theme

  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  @impl true
  @spec rule(atom()) :: binary()
  def rule(:root_color_aliases) do
    """
    :root, :host {
      /* header */
      --auix-color-header-title-text: var(--auix-color-text-label);
      --auix-color-header-subtitle-text: var(--auix-color-text-secondary);

      /* labels & inputs */
      --auix-color-label-text: var(--auix-color-text-label);
      --auix-color-input-text: var(--auix-color-text-primary);
      --auix-color-input-border: var(--auix-color-border-primary);
      --auix-color-input-border-focus: var(--auix-color-border-focus);
      --auix-color-input-border-error: var(--auix-color-error);
      --auix-color-textarea-text: var(--auix-color-text-primary);
      --auix-color-textarea-border: var(--auix-color-border-primary);
      --auix-color-textarea-border-focus: var(--auix-color-border-focus);
      --auix-color-textarea-border-error: var(--auix-color-error);
      --auix-color-select-border: var(--auix-color-border-primary);
      --auix-color-select-border-focus: var(--auix-color-border-focus);
      --auix-color-checkbox-text: var(--auix-color-text-primary);
      --auix-color-checkbox-border: var(--auix-color-border-primary);
      --auix-color-checkbox-label-text: var(--auix-color-text-secondary);

      /* buttons */
      --auix-color-button-bg: var(--auix-color-bg-default--reverted);
      --auix-color-button-text: var(--auix-color-text-on-accent);
      --auix-color-button-alt-text: var(--auix-color-text-tertiary);
      --auix-color-button-alt-border: var(--auix-color-text-label);
      --auix-color-button-alt-bg: var(--auix-color-bg-light);
      --auix-color-button-iconized-bg-hover: var(--auix-color-bg-hover);

      /* tables */
      --auix-color-items-table-header-text: var(--auix-color-text-tertiary);
      --auix-color-items-table-body-border: var(--auix-color-border-secondary);
      --auix-color-items-table-body-text: var(--auix-color-text-hover);
      --auix-color-items-table-row-bg-hover: var(--auix-color-bg-hover);

      /* list */
      --auix-color-list-item-title-text: var(--auix-color-text-tertiary);
      --auix-color-list-item-content-text: var(--auix-color-text-hover);
      --auix-color-list-container-divider: var(--auix-color-bg-light);

      /* back link */
      --auix-color-back-link-text: var(--auix-color-text-primary);
      --auix-color-back-link-text-hover: var(--auix-color-text-hover);

      /* sections / tabs */
      --auix-color-sections-tab-active-text: var(--auix-color-text-label);
      --auix-color-sections-tab-active-bg: var(--auix-color-bg-light);
      --auix-color-sections-tab-active-border: var(--auix-color-bg-light);
      --auix-color-sections-tab-inactive-bg: var(--auix-color-bg-hover);
      --auix-color-sections-content-border: var(--auix-color-bg-light);

      /* containers */
      --auix-color-show-content-bg: var(--auix-color-bg-default);
      --auix-color-form-container-bg: var(--auix-color-bg-default);
      --auix-color-group-container-border: var(--auix-color-border-primary);
      --auix-color-group-container-bg: var(--auix-color-bg-light);
      --auix-color-one-to-many-text: var(--auix-color-text-primary);
      --auix-color-one-to-many-border: var(--auix-color-border-primary);
      --auix-color-form-field-input-border: var(--auix-color-border-primary);
      --auix-color-form-field-input-border-focus: var(--auix-color-focus-ring);
      --auix-color-filter-input-border: var(--auix-color-border-primary);
      --auix-color-filter-input-border-focus: var(--auix-color-focus-ring);
      --auix-color-filter-card-border: var(--auix-color-border-primary);

      /* embeds */
      --auix-color-embeds-bg: var(--auix-color-bg-inner-container);
      --auix-color-embeds-border: var(--auix-color-border-secondary);
      --auix-color-embeds-many-badge-bg: var(--auix-color-bg-default--reverted);
      --auix-color-embeds-many-badge-text: var(--auix-color-text-on-accent);
      --auix-color-items-card-item-content-text: var(--auix-color-text-primary);

      /* pagination */
      --auix-color-pagination-current-bg: var(--auix-color-bg-default--reverted);
      --auix-color-pagination-current-text: var(--auix-color-text-on-accent);
      --auix-color-pagination-current-border: var(--auix-color-border-focus);

      /* flash */
      --auix-color-flash-close-text: var(--auix-color-text-secondary);

      /* divider */
      --auix-color-horizontal-divider: var(--auix-color-border-primary);
    }
    """
  end

  def rule(rule), do: BaseVariables.rule(rule)
end
