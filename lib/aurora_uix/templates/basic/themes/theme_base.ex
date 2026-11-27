defmodule Aurora.Uix.Templates.Basic.Themes.ThemeBase do
  @moduledoc """
  Component-specific color aliases shared across themes.

  Each alias defaults to a generic semantic var so the cascade still flows
  from generic palette → component. Override any alias in a theme's
  `:root_colors` block (or in user CSS) to change one component without
  touching its siblings.

  The built-in themes `include` this module, which includes the next one in turn:

  ```
  WhiteCharcoal / VitreousMarble / BlueGraphite  (own :root_colors)
          ↓ include
  ThemeBase                                      (:root_color_aliases)
          ↓ include
  BaseVariables                                  (:root sizes/shadows)
          ↓ include
  Base                                           (all .auix-* component rules)
  ```
  """
  use Aurora.Uix.Templates.Theme

  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  rule(:root_color_aliases, """
  :root, :host {
    /* header */
    --auix-color-header-title-text: var(--auix-color-text-label);
    --auix-color-header-subtitle-text: var(--auix-color-text-secondary);

    /* labels & inputs */
    --auix-color-label-text: var(--auix-color-text-label);
    --auix-color-input-text: var(--auix-color-text-primary);
    --auix-color-input-border: var(--auix-color-border-primary);
    --auix-color-input-border-focus: var(--auix-color-focus-ring);
    --auix-color-input-border-error: var(--auix-color-error);
    --auix-color-textarea-text: var(--auix-color-text-primary);
    --auix-color-textarea-border: var(--auix-color-border-primary);
    --auix-color-textarea-border-focus: var(--auix-color-focus-ring);
    --auix-color-textarea-border-error: var(--auix-color-error);
    --auix-color-select-border: var(--auix-color-border-primary);
    --auix-color-select-border-focus: var(--auix-color-focus-ring);
    --auix-color-checkbox-text: var(--auix-color-text-primary);
    --auix-color-checkbox-border: var(--auix-color-border-primary);
    --auix-color-checkbox-label-text: var(--auix-color-text-primary);
    --auix-color-checkbox-accent: var(--auix-color-bg-default--reverted);
    --auix-color-toggle-on: var(--auix-color-bg-default--reverted);
    --auix-color-toggle-off: var(--auix-color-bg-disabled);
    --auix-color-toggle-knob: var(--auix-color-bg-default);
    --auix-color-input-bg: var(--auix-color-bg-default);
    --auix-color-input-bg-disabled: var(--auix-color-bg-light);
    --auix-color-input-bg-readonly: var(--auix-color-bg-hover);
    --auix-color-input-border-disabled: var(--auix-color-border-secondary);
    --auix-color-input-text-disabled: var(--auix-color-text-tertiary);

    /* buttons */
    --auix-color-button-bg: var(--auix-color-bg-default--reverted);
    --auix-color-button-text: var(--auix-color-text-on-accent);
    --auix-color-button-alt-text: var(--auix-color-text-label);
    --auix-color-button-alt-border: var(--auix-color-border-primary);
    --auix-color-button-alt-bg: var(--auix-color-bg-default);
    --auix-color-button-iconized-bg-hover: var(--auix-color-bg-light);
    --auix-color-button-disabled-bg: var(--auix-color-bg-light);
    --auix-color-button-disabled-border: var(--auix-color-border-secondary);
    --auix-color-button-disabled-text: var(--auix-color-text-tertiary);
    --auix-color-button-danger-bg: var(--auix-color-icon-danger);
    --auix-color-button-danger-bg-hover: var(--auix-color-bg-danger-hover);
    --auix-color-button-danger-text: var(--auix-color-text-on-accent);

    /* modal */
    --auix-color-modal-close-border: var(--auix-color-border-secondary);
    --auix-color-modal-close-text: var(--auix-color-text-secondary);

    /* tables */
    --auix-color-items-table-header-text: var(--auix-color-text-secondary);
    --auix-color-items-table-header-sorted-text: var(--auix-color-text-primary);
    --auix-color-items-table-header-bg: var(--auix-color-bg-hover);
    --auix-color-items-table-body-border: var(--auix-color-border-secondary);
    --auix-color-items-table-body-text: var(--auix-color-text-label);
    --auix-color-items-table-row-bg-hover: var(--auix-color-bg-hover);
    --auix-color-items-table-row-bg-selected: var(--auix-color-selection-bg);
    --auix-color-items-table-row-border: var(--auix-color-border-tertiary);
    --auix-color-items-table-bg: var(--auix-color-bg-default);
    --auix-color-items-table-border: var(--auix-color-border-secondary);
    --auix-color-row-action-text: var(--auix-color-text-secondary);
    --auix-color-row-action-bg-hover: var(--auix-color-bg-light);

    /* cards and menus */
    --auix-color-items-card-bg: var(--auix-color-bg-default);
    --auix-color-items-card-border: var(--auix-color-border-secondary);
    --auix-color-items-card-bg-selected: var(--auix-color-selection-bg);
    --auix-color-items-card-border-selected: var(--auix-color-selection-border);
    --auix-color-items-card-label-text: var(--auix-color-text-secondary);
    --auix-color-menu-bg: var(--auix-color-bg-default);
    --auix-color-menu-border: var(--auix-color-border-secondary);
    --auix-color-menu-divider: var(--auix-color-border-secondary);
    --auix-color-menu-item-bg-hover: var(--auix-color-bg-light);
    --auix-color-sort-toggle-active-text: var(--auix-color-bg-default--reverted);
    --auix-color-sort-toggle-active-bg: var(--auix-color-selection-bg);
    --auix-color-sort-toggle-active-border: var(--auix-color-selection-border);

    /* list */
    --auix-color-list-item-title-text: var(--auix-color-text-tertiary);
    --auix-color-list-item-content-text: var(--auix-color-text-hover);
    --auix-color-list-container-divider: var(--auix-color-bg-light);

    /* back link */
    --auix-color-back-link-text: var(--auix-color-text-primary);
    --auix-color-back-link-text-hover: var(--auix-color-text-hover);

    /* sections / tabs */
    --auix-color-sections-tab-active-text: var(--auix-color-text-primary);
    --auix-color-sections-tab-active-bg: var(--auix-color-bg-default);
    --auix-color-sections-tab-active-border: var(--auix-color-border-secondary);
    --auix-color-sections-tab-inactive-text: var(--auix-color-text-secondary);
    --auix-color-sections-tab-inactive-bg: transparent;
    --auix-color-sections-tab-hover-bg: var(--auix-color-bg-light);
    --auix-color-sections-content-border: var(--auix-color-border-secondary);
    --auix-color-sections-content-bg: var(--auix-color-bg-default);

    /* containers */
    --auix-color-show-content-bg: var(--auix-color-bg-default);
    --auix-color-show-content-border: var(--auix-color-border-secondary);
    --auix-color-form-container-bg: var(--auix-color-bg-default);
    --auix-color-form-container-border: var(--auix-color-border-secondary);
    --auix-color-group-container-border: var(--auix-color-border-secondary);
    --auix-color-group-container-bg: var(--auix-color-bg-default);
    --auix-color-group-title-border: var(--auix-color-border-secondary);
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
    --auix-color-embeds-empty-border: var(--auix-color-border-primary);
    --auix-color-embeds-empty-text: var(--auix-color-text-tertiary);
    --auix-color-embeds-many-badge-bg: var(--auix-color-bg-default--reverted);
    --auix-color-embeds-many-badge-text: var(--auix-color-text-on-accent);
    --auix-color-items-card-item-content-text: var(--auix-color-text-primary);

    /* pagination */
    --auix-color-pagination-current-bg: var(--auix-color-bg-default--reverted);
    --auix-color-pagination-current-text: var(--auix-color-text-on-accent);
    --auix-color-pagination-current-border: var(--auix-color-pagination-current-bg);
    --auix-color-pagination-link-text: var(--auix-color-text-label);
    --auix-color-pagination-link-bg-hover: var(--auix-color-bg-light);

    /* flash */
    --auix-color-flash-close-text: var(--auix-color-text-secondary);

    /* divider */
    --auix-color-horizontal-divider: var(--auix-color-border-primary);
  }
  """)

  include(BaseVariables)
end
