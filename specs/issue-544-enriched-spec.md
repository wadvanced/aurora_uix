<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
Every generated UI element takes the framing of the approved mockups — controls, groups, embedded records, sections, buttons, modal, index table, cards, menus and flashes — in every built-in theme; White Charcoal and Vitreous Marble gain success, warning, selection and focus-halo colors, and the new `:blue_graphite` theme ships beside them. The work is theme CSS, small component markup and two value-restricted properties (`resize`, `content`) in the theme CSS sanitizer, rendered by the backend-agnostic renderers, so Ash and Ecto (`ctx`) resources render the same result with no parser change.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md § [0.2.1]`, `guides/customization/styling.md § Variable reference`, `§ Recipe table`, `§ Class reference`, `guides/customization/theming.md § Built-in Themes`, `§ Layer 3: Base Variables` and new `§ Status and selection colors` | none | federico/544-doc-1-ui-refresh | docs: refreshed look and the Blue Graphite theme (#544 · DOC-1) |
| UI-1 | UI | theme · framing size variables, success / warning / selection / focus-halo colors, White Charcoal error colors, flash rules and `:success` / `:warning` flash kinds | DOC-1 | federico/544-ui-1-theme-variables | feat: status, selection and focus-halo theme colors (#544 · UI-1) |
| UI-2 | UI | theme · `:blue_graphite` (`BlueGraphite` module) | UI-1 | federico/544-ui-2-blue-graphite | feat: Blue Graphite theme (#544 · UI-2) |
| UI-3 | UI | theme · inputs, selects, text areas, checkboxes, toggles, labels, field errors; CSS sanitizer `resize` | UI-1 | federico/544-ui-3-form-controls | feat: refreshed form controls (#544 · UI-3) |
| UI-4 | UI | theme · groups, embedded records, sections, form and show containers, headers | UI-3 | federico/544-ui-4-containers | feat: refreshed groups, sections and containers (#544 · UI-4) |
| UI-5 | UI | theme + form renderer · buttons, modal, unsaved-changes confirmation, record pager; CSS sanitizer `content` | UI-4 | federico/544-ui-5-buttons-modal | feat: refreshed buttons and modal (#544 · UI-5) |
| UI-6 | UI | theme · index table, selection, pagination, cards, one-to-many lists, menus | UI-5 | federico/544-ui-6-index | feat: refreshed index table, cards and menus (#544 · UI-6) |
| UI-7 | UI | guide images regenerated | UI-2, UI-6 | federico/544-ui-7-guide-images | docs: regenerate guide images (#544 · UI-7) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md § [0.2.1]` (unreleased; `mix.exs` is at `0.2.1-rc.1`)
- `guides/customization/theming.md § Built-in Themes`, `§ Layer 3: Base Variables`
- `guides/customization/styling.md § Variable reference`, `§ Recipe table`, `§ Escape hatch: semantic class overrides › Class reference`

#### Implementation details

The guide images are binary files; UI-7 regenerates them. Every variable, alias and class name below is introduced by UI-1 to UI-6, and every "Tokens it consumes" cell lists the `var(--…)` names of that class's rule as those sections prescribe it.

##### CHANGELOG.md
1. § `## [0.2.1]` › `### Added` — after the entry `- **Index cards**: a card layout for the index list (Layouts guide, "Index Cards").` insert verbatim:
   ```
   - **Blue Graphite theme**: `:blue_graphite`, a slate theme with a navy primary, in light and dark
     (Theming guide, "Built-in Themes").
   - **Success and warning flashes**: `auix-flash--success` and `auix-flash--warning`, rendered by the
     index, form and show views (Theming guide, "Status and selection colors").
   - **Selection colors**: a selected index row and a selected index card use the theme's selection
     colors (Theming guide, "Status and selection colors").
   ```
2. § `## [0.2.1]` › `### Changed` — after the entry that starts `- **Index card styling (CSS class changes)**:` (two lines, ending `guide, "Class reference").`) insert verbatim:
   ```
   - **Refreshed look (CSS class changes)**: inputs, buttons, groups, embedded records, sections,
     modals, the index table, cards and menus take a new frame in every theme; `auix-button--danger`
     is new (Styling guide, "Class reference").
   - **White Charcoal error colors**: the input error border is rose-500 `#F43F5E` and the inline
     error text rose-700 `#BE123C`.
   - **Theme CSS sanitizer**: theme rules may set `resize` to one of `none`, `block`, `both`,
     `vertical`, `horizontal`, `inline`, and `content` to one plain quoted string such as `""`; any
     other value of either property is dropped.
   ```

##### guides/customization/styling.md
1. § Variable reference — replace the whole section, from the line `## Variable reference` up to the line before `## Recipe table`, with exactly:
`````markdown
## Variable reference

### Sizes & dimensions

| Variable | Default | Affects |
|---|---|---|
| `--auix-box-size-unit` | `1rem` | Select chevron size |
| `--auix-line-height-default` | `1.250rem` | Default line height |
| `--auix-line-height-relaxed` | `1.5rem` | Relaxed/spacious line height |
| `--auix-line-height-title` | `1.75rem` | Header title line height |
| `--auix-border-radius-default` | `0.5rem` | Inputs, selects, text areas, buttons, tabs and menu items |
| `--auix-border-radius-small` | `0.250rem` | Checkboxes, filter inputs and the copy toast |
| `--auix-border-radius-large` | `1rem` | Modals and large containers |
| `--auix-border-radius-round` | `9999px` | Pill / fully-rounded badges |
| `--auix-border-radius-medium` | `0.75rem` | Tables, index cards, menus, groups, embedded records and the form and show containers |
| `--auix-border-radius-nested` | `0.625rem` | Nested groups and sections, flashes, icon-only buttons below the `sm` breakpoint |
| `--auix-border-width-default` | `0.0625rem` | Standard border width |
| `--auix-border-width-thick` | `0.125rem` | Active tab underline |
| `--auix-border-style-default` | `solid` | Border style across all components |
| `--auix-gap-minimal` | `0.125rem` | Tightest flex gap |
| `--auix-gap-default` | `0.250rem` | Standard flex gap |
| `--auix-gap-medium` | `0.500rem` | Medium flex gap |
| `--auix-gap-large` | `0.750rem` | Large flex gap |
| `--auix-gap-label` | `0.375rem` | Label to control, card rows |
| `--auix-gap-xl` | `1rem` | Between fields, inside groups and modals |
| `--auix-gap-container` | `1.25rem` | Inside the form and show containers |
| `--auix-padding-minimal` | `0.3125rem` | Minimal padding (badges, header actions) |
| `--auix-padding-small` | `0.250rem` | Small padding |
| `--auix-padding-default` | `0.625rem` | Standard padding |
| `--auix-padding-medium` | `0.500rem` | Medium padding |
| `--auix-padding-large` | `1.5rem` | Large padding (modal sides and bottom, index page) |
| `--auix-padding-xl` | `2rem` | Extra-large padding (modal boxes) |
| `--auix-padding-control` | `0.75rem` | Inline padding of inputs and selects |
| `--auix-padding-panel` | `1rem` | Groups, embedded records, title bars, nested panels |
| `--auix-padding-container` | `1.25rem` | Form and show containers, section panels, modal top |
| `--auix-margin-default` | `0.250rem` | Standard margin |
| `--auix-margin-medium` | `0.500rem` | Medium margin |
| `--auix-input-height-default` | `1rem` | Filter input height |
| `--auix-button-height-default` | `2em` | Not used by the built-in rules; buttons use `--auix-control-height` |
| `--auix-hidden-element-size` | `1px` | Visually-hidden element dimensions |
| `--auix-touch-target-size` | `2.75rem` | Minimum width and height of the card ⋮ menu toggle, of the card checkbox slot, of the sort menu button and of each menu item; height of inputs, selects, section tabs and icon-only buttons below the `sm` breakpoint |
| `--auix-items-card-label-width` | `8rem` | Width of the label column of a card `label · value` row |
| `--auix-items-card-min-width` | `17.5rem` | Minimum card width in the card grid (`show_on: :all`) |
| `--auix-control-height` | `2.5rem` | Height of inputs, selects, buttons and section tabs |
| `--auix-control-height-compact` | `2.25rem` | Nested section tabs, the modal close button and the record pager |
| `--auix-row-action-size` | `2rem` | Row action icons, pagination links and record pager arrows |
| `--auix-table-header-height` | `2.75rem` | Index table header row |
| `--auix-table-row-height` | `3rem` | Index table body rows |
| `--auix-checkbox-size` | `1.125rem` | Checkbox size |
| `--auix-checkbox-size-mobile` | `1.25rem` | Checkbox size below the `sm` breakpoint |
| `--auix-toggle-width` | `2.75rem` | Toggle switch width |
| `--auix-toggle-height` | `1.5rem` | Toggle switch height |
| `--auix-menu-min-width` | `15rem` | Minimum width of the sort menu |
| `--auix-flash-max-width` | `24rem` | Maximum width of a flash |
| `--auix-focus-outline-width` | `2px` | Focus outline width |
| `--auix-focus-ring-width` | `3px` | Width of the ring around a focused control |
| `--auix-icon-size-base` | `0.25rem` | Base unit for icon size calculations |
| `--auix-icon-size-button` | `var(--auix-icon-size-4)` | Icon size inside buttons |
| `--auix-breakpoint-sm` | `640px` | Small breakpoint |
| `--auix-breakpoint-md` | `768px` | Medium breakpoint |
| `--auix-breakpoint-lg` | `1024px` | Large breakpoint |
| `--auix-breakpoint-xl` | `1280px` | Extra-large breakpoint |
| `--auix-breakpoint-xxl` | `1536px` | Double-XL breakpoint |

### Typography

| Variable | Default | Affects |
|---|---|---|
| `--auix-font-sans` | `ui-sans-serif, system-ui, sans-serif, …` | Sans-serif font stack |
| `--auix-font-mono` | `ui-monospace, SFMono-Regular, Menlo, …` | Monospace font stack |
| `--auix-font-family-default` | `var(--auix-font-sans)` | Default font family for all components |
| `--auix-font-size-title` | `1.25rem` | Modal and show titles (`.auix-header-title`) |
| `--auix-font-size-group-title` | `0.875rem` | Group title bars (`.auix-group-title`) |
| `--auix-font-size-empty-state` | `1.125rem` | Index empty-state message (table and card) |
| `--auix-font-size-label` | `0.8125rem` | Field labels, table headers, card labels and nested tabs |
| `--auix-font-size-input-mobile` | `1rem` | Input, select and textarea text below the `sm` breakpoint |
| `--auix-font-size-page-title` | `1.5rem` | Index page title |
| `--auix-font-size-subtitle` | `1rem` | Subtitles and secondary headings |
| `--auix-font-size-caption` | `0.875rem` | Labels, inputs, table cells |
| `--auix-font-size-small` | `0.750rem` | Badges and helper text |
| `--auix-font-weight-bold` | `600` | Primary bold weight |
| `--auix-font-weight-bold-semi` | `400` | Secondary / semi-bold weight |
| `--auix-font-weight-medium` | `500` | Labels, inactive tabs, pagination links |
| `--auix-font-style-mobile-viewmode` | `italic` | View-mode field value style on mobile |

`--auix-font-size-group-title` and `--auix-font-size-empty-state` carry their own literal
defaults rather than aliasing `--auix-font-size-title`, so resizing the header title leaves
group headings and empty states alone. To make them track the page title instead, alias
them yourself:

```css
:root {
  --auix-font-size-title: 2.5rem;
  --auix-font-size-group-title: var(--auix-font-size-title);
  --auix-font-size-empty-state: var(--auix-font-size-title);
}
```

### Opacity

| Variable | Default | Affects |
|---|---|---|
| `--auix-opacity-20` | `0.20` | Not used by the built-in rules |
| `--auix-opacity-40` | `0.40` | Not used by the built-in rules |
| `--auix-opacity-75` | `0.75` | Loading button and disabled filter input opacity |
| `--auix-opacity-100` | `1` | Full opacity (disabled checkbox text) |

### Shadows & rings

| Variable | Default | Affects |
|---|---|---|
| `--auix-ring-inset` | _(empty)_ | Inset modifier for ring shadows |
| `--auix-ring-offset-shadow` | `0 0 #0000` | Ring offset transparent base |
| `--auix-ring-offset-width` | `0px` | Ring offset width |
| `--auix-ring-color` | `rgba(63, 63, 70, 0.1)` | Default ring color (white_charcoal light) |
| `--auix-ring-default` | `0 0 0 calc(1px + …) var(--auix-ring-color)` | Default focus ring |
| `--auix-ring-info` | `0 0 0 calc(1px + …) var(--auix-color-info-ring)` | Not used by the built-in rules |
| `--auix-ring-secondary` | `0 0 0 calc(1px + …) var(--auix-color-shadow-alpha)` | Secondary ring |
| `--auix-shadow-small` | `0 1px 2px 0 …` | Primary buttons, the index table and index cards |
| `--auix-shadow-default` | `0 1px 3px 0 …, 0 1px 2px -1px …` | Default component shadow |
| `--auix-shadow-md` | `0 4px 6px -1px …, 0 2px 4px -2px …` | Medium shadow (not used by the built-in rules) |
| `--auix-shadow-lg` | `0 10px 15px -3px …, 0 4px 6px -4px …` | Large shadow (modal, flashes, menus, standalone show view) |
| `--auix-shadow-primary` | `var(--auix-shadow-lg)` | Primary shadow alias |
| `--auix-shadow-secondary` | `0 4px 6px -1px var(--auix-color-shadow-alpha), …` | Colored secondary shadow |

### Colors

> Colors are theme-dependent. The defaults shown here are from the **white_charcoal** theme in
> light mode (the library default). Dark-mode variants are applied automatically via
> `--dark--auix-*` intermediate variables when the host sets up a dark-mode selector.

**Backgrounds**

| Variable | Default (light) | Affects |
|---|---|---|
| `--auix-color-bg-default` | `#FFFFFF` | Primary component background |
| `--auix-color-bg-default--reverted` | `#18181B` | Inverted background (button fill) |
| `--auix-color-bg-secondary` | `#D4D4D8` | Secondary / alternating row background |
| `--auix-color-bg-disabled` | `#A1A1AA` | Disabled element background |
| `--auix-color-bg-info` | `#F0FDF4` | Info flash background |
| `--auix-color-bg-light` | `#F4F4F5` | Disabled inputs and buttons; hover of tabs, menu items and row actions |
| `--auix-color-bg-hover` | `#FAFAFA` | Hover state background; read-only inputs and the table header row |
| `--auix-color-bg-hover--reverted` | `#47474a` | Hover on inverted elements |
| `--auix-color-bg-backdrop` | `rgba(250,250,250,0.9)` | Modal / overlay backdrop |
| `--auix-color-bg-inner-container` | `rgba(250,250,250,0.8)` | Embedded container background |
| `--auix-color-bg-danger` | `#FB7185` | Danger/destructive background |
| `--auix-color-bg-danger-hover` | `#E11D48` | Danger hover background |
| `--auix-color-error-bg` | `#FFF1F2` | Error flash / message background |

**Text**

| Variable | Default (light) | Affects |
|---|---|---|
| `--auix-color-text-primary` | `#18181B` | Main body text |
| `--auix-color-text-secondary` | `#52525B` | Secondary / subdued text |
| `--auix-color-text-tertiary` | `#71717A` | Tertiary / muted text |
| `--auix-color-text-inactive` | `#A1A1AA` | Disabled / inactive text |
| `--auix-color-text-label` | `#27272A` | Field labels and headings |
| `--auix-color-text-hover` | `#47474a` | Text on hover states |
| `--auix-color-text-on-accent` | `#FFFFFF` | Text on dark/accent backgrounds |
| `--auix-color-text-on-accent-active` | `rgba(255,255,255,0.8)` | Active state text on accent |
| `--auix-color-error-text` | `#831843` | Error flash text |
| `--auix-color-error-text-default` | `#BE123C` | Inline validation error text |
| `--auix-color-info-text` | `#065F46` | Info flash text |

**Borders & Focus**

| Variable | Default (light) | Affects |
|---|---|---|
| `--auix-color-border-primary` | `#D4D4D8` | Standard borders |
| `--auix-color-border-secondary` | `#E4E4E7` | Secondary borders |
| `--auix-color-border-tertiary` | `#F4F4F5` | Tertiary / hairline borders |
| `--auix-color-border-focus` | `#A1A1AA` | Not used by the built-in aliases; focused controls use `--auix-color-focus-ring` |
| `--auix-color-focus-ring` | `#6366F1` | Focus border of inputs, selects, buttons and tabs (indigo-500) |
| `--auix-color-focus-ring-halo` | `rgba(99, 102, 241, 0.3)` | The 3px ring around a focused control |
| `--auix-color-error-ring` | `#F43F5E` | Error flash border |
| `--auix-color-info-ring` | `#10B981` | Info flash border |
| `--auix-color-error` | `#F43F5E` | Input border on validation error |

**Status & selection**

| Variable | Default (light) | Affects |
|---|---|---|
| `--auix-color-success-bg` | `#ECFDF5` | Success flash background |
| `--auix-color-success-border` | `#6EE7B7` | Success flash border |
| `--auix-color-success-text` | `#065F46` | Success flash text and icon |
| `--auix-color-warning-bg` | `#FFFBEB` | Warning flash background |
| `--auix-color-warning-border` | `#FDE68A` | Warning flash border |
| `--auix-color-warning-text` | `#78350F` | Warning flash text and icon |
| `--auix-color-selection-bg` | `#F3F3F4` | Selected index row and card background |
| `--auix-color-selection-border` | `#18181B` | Selected index card border |

**Icons**

| Variable | Default (light) | Affects |
|---|---|---|
| `--auix-color-icon-default` | `#18181B` | Default icon color |
| `--auix-color-icon-fill` | `#164E63` | Info icon fill |
| `--auix-color-icon-safe` | `#047857` | Safe/confirm action icons |
| `--auix-color-icon-info` | `#1D4ED8` | Informational action icons |
| `--auix-color-icon-danger` | `#BE123C` | Destructive action icons |
| `--auix-color-icon-inactive` | `#D4D4D8` | Inactive / low-relevance icons |

**Shadows (color tokens)**

| Variable | Default (light) | Affects |
|---|---|---|
| `--auix-color-shadow-black-alpha` | `rgba(0,0,0,0.1)` | Default shadow darkness |
| `--auix-color-shadow-black-alpha-small` | `rgba(0,0,0,0.05)` | Small shadow darkness |
| `--auix-color-shadow-alpha` | `rgba(71,71,74,0.1)` | Colored secondary shadow |

**Component aliases** (derived from primitives above)

| Variable | Default | Affects |
|---|---|---|
| `--auix-color-button-bg` | `var(--auix-color-bg-default--reverted)` | Primary button fill |
| `--auix-color-button-text` | `var(--auix-color-text-on-accent)` | Primary button text |
| `--auix-color-button-alt-bg` | `var(--auix-color-bg-default)` | Alternative button fill |
| `--auix-color-button-alt-text` | `var(--auix-color-text-label)` | Alternative button text |
| `--auix-color-button-alt-border` | `var(--auix-color-border-primary)` | Alternative button border |
| `--auix-color-button-iconized-bg-hover` | `var(--auix-color-bg-light)` | Icon-only button hover fill |
| `--auix-color-input-text` | `var(--auix-color-text-primary)` | Input / textarea text |
| `--auix-color-input-border` | `var(--auix-color-border-primary)` | Input border |
| `--auix-color-input-border-focus` | `var(--auix-color-focus-ring)` | Input focus border |
| `--auix-color-input-border-error` | `var(--auix-color-error)` | Input error border |
| `--auix-color-textarea-text` | `var(--auix-color-text-primary)` | Textarea text |
| `--auix-color-textarea-border` | `var(--auix-color-border-primary)` | Textarea border |
| `--auix-color-textarea-border-focus` | `var(--auix-color-focus-ring)` | Textarea focus border |
| `--auix-color-textarea-border-error` | `var(--auix-color-error)` | Textarea error border |
| `--auix-color-select-border` | `var(--auix-color-border-primary)` | Select border |
| `--auix-color-select-border-focus` | `var(--auix-color-focus-ring)` | Select focus border |
| `--auix-color-checkbox-border` | `var(--auix-color-border-primary)` | Checkbox border |
| `--auix-color-checkbox-text` | `var(--auix-color-text-primary)` | Checkbox checkmark color |
| `--auix-color-checkbox-label-text` | `var(--auix-color-text-primary)` | Checkbox label text |
| `--auix-color-label-text` | `var(--auix-color-text-label)` | Generic field label text |
| `--auix-color-horizontal-divider` | `var(--auix-color-border-primary)` | Horizontal rule color |
| `--auix-color-flash-close-text` | `var(--auix-color-text-secondary)` | Flash close-button icon |
| `--auix-color-form-container-bg` | `var(--auix-color-bg-default)` | Form container background |
| `--auix-color-group-container-bg` | `var(--auix-color-bg-default)` | Group container background |
| `--auix-color-group-container-border` | `var(--auix-color-border-secondary)` | Group container border |
| `--auix-color-show-content-bg` | `var(--auix-color-bg-default)` | Show-view content background |
| `--auix-color-header-title-text` | `var(--auix-color-text-label)` | Page/section header title |
| `--auix-color-header-subtitle-text` | `var(--auix-color-text-secondary)` | Page/section header subtitle |
| `--auix-color-sections-tab-active-text` | `var(--auix-color-text-primary)` | Active tab label |
| `--auix-color-sections-tab-active-bg` | `var(--auix-color-bg-default)` | Active tab background |
| `--auix-color-sections-tab-active-border` | `var(--auix-color-border-secondary)` | Active tab border |
| `--auix-color-sections-tab-inactive-bg` | `transparent` | Inactive tab background |
| `--auix-color-sections-content-border` | `var(--auix-color-border-secondary)` | Tab panel border |
| `--auix-color-items-table-header-text` | `var(--auix-color-text-secondary)` | Table column header text |
| `--auix-color-items-table-body-border` | `var(--auix-color-border-secondary)` | Line under the table header row |
| `--auix-color-items-table-body-text` | `var(--auix-color-text-label)` | Table cell text |
| `--auix-color-items-table-row-bg-hover` | `var(--auix-color-bg-hover)` | Table row hover background |
| `--auix-color-items-card-item-content-text` | `var(--auix-color-text-primary)` | Card item text |
| `--auix-color-list-item-title-text` | `var(--auix-color-text-tertiary)` | List item title |
| `--auix-color-list-item-content-text` | `var(--auix-color-text-hover)` | List item body text |
| `--auix-color-list-container-divider` | `var(--auix-color-bg-light)` | List row separator |
| `--auix-color-pagination-current-bg` | `var(--auix-color-bg-default--reverted)` | Current page button fill |
| `--auix-color-pagination-current-text` | `var(--auix-color-text-on-accent)` | Current page button text |
| `--auix-color-pagination-current-border` | `var(--auix-color-pagination-current-bg)` | Current page button border |
| `--auix-color-back-link-text` | `var(--auix-color-text-primary)` | Back-navigation link text |
| `--auix-color-back-link-text-hover` | `var(--auix-color-text-hover)` | Back-navigation link hover text |
| `--auix-color-embeds-bg` | `var(--auix-color-bg-inner-container)` | Embedded relation container background |
| `--auix-color-embeds-border` | `var(--auix-color-border-secondary)` | Embedded relation container border |
| `--auix-color-embeds-many-badge-bg` | `var(--auix-color-bg-default--reverted)` | Embedded many badge fill |
| `--auix-color-embeds-many-badge-text` | `var(--auix-color-text-on-accent)` | Embedded many badge text |
| `--auix-color-one-to-many-text` | `var(--auix-color-text-primary)` | One-to-many relation text |
| `--auix-color-one-to-many-border` | `var(--auix-color-border-primary)` | Not used by the built-in rules |
| `--auix-color-form-field-input-border` | `var(--auix-color-border-primary)` | Form field input border |
| `--auix-color-form-field-input-border-focus` | `var(--auix-color-focus-ring)` | Form field focus border |
| `--auix-color-filter-input-border` | `var(--auix-color-border-primary)` | Filter input border |
| `--auix-color-filter-input-border-focus` | `var(--auix-color-focus-ring)` | Filter input focus border |
| `--auix-color-filter-card-border` | `var(--auix-color-border-primary)` | Filter card border |
| `--auix-color-checkbox-accent` | `var(--auix-color-bg-default--reverted)` | Checked checkbox color |
| `--auix-color-toggle-on` | `var(--auix-color-bg-default--reverted)` | Toggle track, on |
| `--auix-color-toggle-off` | `var(--auix-color-bg-disabled)` | Toggle track, off |
| `--auix-color-toggle-knob` | `var(--auix-color-bg-default)` | Toggle knob |
| `--auix-color-input-bg` | `var(--auix-color-bg-default)` | Input, select and textarea background |
| `--auix-color-input-bg-disabled` | `var(--auix-color-bg-light)` | Disabled control background |
| `--auix-color-input-bg-readonly` | `var(--auix-color-bg-hover)` | Read-only and show-view control background |
| `--auix-color-input-border-disabled` | `var(--auix-color-border-secondary)` | Disabled and read-only control border |
| `--auix-color-input-text-disabled` | `var(--auix-color-text-tertiary)` | Disabled control text |
| `--auix-color-button-disabled-bg` | `var(--auix-color-bg-light)` | Disabled button fill |
| `--auix-color-button-disabled-border` | `var(--auix-color-border-secondary)` | Disabled button border |
| `--auix-color-button-disabled-text` | `var(--auix-color-text-tertiary)` | Disabled button text |
| `--auix-color-button-danger-bg` | `var(--auix-color-icon-danger)` | Destructive button fill |
| `--auix-color-button-danger-bg-hover` | `var(--auix-color-bg-danger-hover)` | Destructive button hover fill |
| `--auix-color-button-danger-text` | `var(--auix-color-text-on-accent)` | Destructive button text |
| `--auix-color-modal-close-border` | `var(--auix-color-border-secondary)` | Modal close button border |
| `--auix-color-modal-close-text` | `var(--auix-color-text-secondary)` | Modal close button icon |
| `--auix-color-sections-tab-inactive-text` | `var(--auix-color-text-secondary)` | Inactive tab label |
| `--auix-color-sections-tab-hover-bg` | `var(--auix-color-bg-light)` | Inactive tab hover background |
| `--auix-color-sections-content-bg` | `var(--auix-color-bg-default)` | Tab panel background |
| `--auix-color-show-content-border` | `var(--auix-color-border-secondary)` | Show-view content and show card border |
| `--auix-color-form-container-border` | `var(--auix-color-border-secondary)` | Form container border |
| `--auix-color-group-title-border` | `var(--auix-color-border-secondary)` | Line under a group title bar |
| `--auix-color-embeds-empty-border` | `var(--auix-color-border-primary)` | Dashed border of an empty embedded or one-to-one record |
| `--auix-color-embeds-empty-text` | `var(--auix-color-text-tertiary)` | "Field is empty" text |
| `--auix-color-items-table-bg` | `var(--auix-color-bg-default)` | Index table card background |
| `--auix-color-items-table-border` | `var(--auix-color-border-secondary)` | Index table card border |
| `--auix-color-items-table-header-bg` | `var(--auix-color-bg-hover)` | Table header row background |
| `--auix-color-items-table-header-sorted-text` | `var(--auix-color-text-primary)` | Sorted column header text |
| `--auix-color-items-table-row-border` | `var(--auix-color-border-tertiary)` | Line between table rows |
| `--auix-color-items-table-row-bg-selected` | `var(--auix-color-selection-bg)` | Selected row background |
| `--auix-color-row-action-text` | `var(--auix-color-text-secondary)` | Row action icon |
| `--auix-color-row-action-bg-hover` | `var(--auix-color-bg-light)` | Row action hover background |
| `--auix-color-items-card-bg` | `var(--auix-color-bg-default)` | Index card background |
| `--auix-color-items-card-border` | `var(--auix-color-border-secondary)` | Index card border |
| `--auix-color-items-card-bg-selected` | `var(--auix-color-selection-bg)` | Selected card background |
| `--auix-color-items-card-border-selected` | `var(--auix-color-selection-border)` | Selected card border |
| `--auix-color-items-card-label-text` | `var(--auix-color-text-secondary)` | Card row label |
| `--auix-color-menu-bg` | `var(--auix-color-bg-default)` | Card and sort menu background |
| `--auix-color-menu-border` | `var(--auix-color-border-secondary)` | Card and sort menu border |
| `--auix-color-menu-divider` | `var(--auix-color-border-secondary)` | Divider between menu groups |
| `--auix-color-menu-item-bg-hover` | `var(--auix-color-bg-light)` | Menu item hover background, open card menu toggle |
| `--auix-color-sort-toggle-active-text` | `var(--auix-color-bg-default--reverted)` | Sort menu button while a sort is on |
| `--auix-color-sort-toggle-active-bg` | `var(--auix-color-selection-bg)` | Sort menu button fill while a sort is on |
| `--auix-color-sort-toggle-active-border` | `var(--auix-color-selection-border)` | Sort menu button border while a sort is on |
| `--auix-color-pagination-link-text` | `var(--auix-color-text-label)` | Page link text |
| `--auix-color-pagination-link-bg-hover` | `var(--auix-color-bg-light)` | Page link hover background |

`````
2. § Recipe table — replace these three rows, each verbatim:
   - `| Larger touch targets | `--auix-button-height-default`, `--auix-input-height-default`, `--auix-padding-default` |` → `| Larger touch targets | `--auix-control-height`, `--auix-touch-target-size` |`
   - `| Custom focus ring | `--auix-color-focus-ring`, `--auix-color-form-field-input-border-focus` |` → `| Custom focus ring | `--auix-color-focus-ring`, `--auix-color-focus-ring-halo` |`
   - `| Card-style groups (pre-0.1.6 look) | `--auix-color-group-container-bg`, `--auix-color-group-container-border` |` → `| Flat groups (0.2.0 look) | `--auix-color-group-container-bg`, `--auix-color-group-container-border` and `--auix-color-group-title-border` set to `transparent` |`
3. § Escape hatch: semantic class overrides › Class reference — replace the table (from its header row `| Class | Used by | Tokens it consumes |` through its last row, the `.auix-index-sort-action--always` row) with exactly:
`````markdown
| Class | Used by | Tokens it consumes |
|---|---|---|
| `.auix-button-default` | Structural base auto-applied to every `<.button>` (layout, border, padding, typography — no color) | `--auix-gap-medium`, `--auix-control-height`, `--auix-padding-panel`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-default`, `--auix-font-size-caption`, `--auix-font-weight-bold`, `--auix-color-focus-ring`, `--auix-focus-ring-width`, `--auix-color-focus-ring-halo`, `--auix-touch-target-size`, `--auix-border-radius-nested` |
| `.auix-button` | Primary color variant (default for `<.button>` when no variant is passed) | `--auix-color-button-bg`, `--auix-color-button-text`, `--auix-shadow-small`, `--auix-color-bg-hover--reverted`, `--auix-color-text-on-accent-active`, `--auix-color-button-disabled-bg`, `--auix-color-button-disabled-border`, `--auix-color-button-disabled-text`, `--auix-opacity-75`, `--auix-border-radius-round` |
| `.auix-button--alt` | Secondary / alternative button (caller-supplied via `class=`; sits on top of the auto-applied `.auix-button-default` — never combine with `.auix-button`) | `--auix-color-button-alt-bg`, `--auix-color-button-alt-text`, `--auix-color-button-alt-border`, `--auix-color-bg-hover`, `--auix-color-button-disabled-bg`, `--auix-color-button-disabled-border`, `--auix-color-button-disabled-text` |
| `.auix-index-all-action-button` | Select-all / deselect-all index-bar variant — color only; replaces, not supplements, `.auix-button` | `--auix-color-button-alt-bg`, `--auix-color-button-alt-text`, `--auix-color-button-alt-border`, `--auix-color-bg-hover`, `--auix-color-button-disabled-bg`, `--auix-color-button-disabled-border`, `--auix-color-button-disabled-text` |
| `.auix-button--iconized` | Icon-only button (no border); a 32px minimum target | `--auix-row-action-size`, `--auix-border-radius-default`, `--auix-color-button-iconized-bg-hover` |
| `.auix-button-badge` | Embedded-relation count badge | `--auix-font-size-small`, `--auix-border-radius-round`, `--auix-padding-minimal` |
| `.auix-input` | Text / number / date inputs; disabled and read-only states (a show-view input is read-only) | `--auix-control-height`, `--auix-padding-control`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-default`, `--auix-font-size-caption`, `--auix-color-input-text`, `--auix-color-input-bg`, `--auix-focus-ring-width`, `--auix-color-focus-ring-halo`, `--auix-color-input-bg-disabled`, `--auix-color-input-border-disabled`, `--auix-color-input-text-disabled`, `--auix-color-input-bg-readonly`, `--auix-touch-target-size`, `--auix-font-size-input-mobile` |
| `.auix-input--errors` | Input in validation-error state | `--auix-color-input-border-error` |
| `.auix-textarea` | Multi-line textarea; disabled and read-only states | `--auix-padding-default`, `--auix-padding-control`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-default`, `--auix-font-size-caption`, `--auix-line-height-default`, `--auix-color-textarea-text`, `--auix-color-input-bg`, `--auix-focus-ring-width`, `--auix-color-focus-ring-halo`, `--auix-color-input-bg-disabled`, `--auix-color-input-border-disabled`, `--auix-color-input-text-disabled`, `--auix-color-input-bg-readonly`, `--auix-font-size-input-mobile`, `--auix-line-height-relaxed` |
| `.auix-textarea--errors` | Textarea in validation-error state | `--auix-color-textarea-border-error` |
| `.auix-select` | Dropdown select; disabled, read-only and multiple states | `--auix-control-height`, `--auix-padding-control`, `--auix-border-radius-default`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-select-border`, `--auix-box-size-unit`, `--auix-color-input-bg`, `--auix-font-size-caption`, `--auix-color-input-text`, `--auix-color-input-bg-disabled`, `--auix-color-input-border-disabled`, `--auix-color-input-text-disabled`, `--auix-color-input-bg-readonly`, `--auix-padding-medium`, `--auix-color-select-border-focus`, `--auix-focus-ring-width`, `--auix-color-focus-ring-halo`, `--auix-touch-target-size`, `--auix-font-size-input-mobile` |
| `.auix-select-label` | Label paired with a select | Structural only |
| `.auix-checkbox` | Checkbox input; checked in the primary color | `--auix-checkbox-size`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-small`, `--auix-color-checkbox-border`, `--auix-color-bg-default`, `--auix-color-checkbox-text`, `--auix-color-checkbox-accent`, `--auix-focus-ring-width`, `--auix-color-focus-ring-halo`, `--auix-color-bg-light`, `--auix-color-text-secondary`, `--auix-opacity-100`, `--auix-checkbox-size-mobile` |
| `.auix-checkbox-label` | Label paired with a checkbox | `--auix-gap-medium`, `--auix-font-size-caption`, `--auix-color-checkbox-label-text`, `--auix-touch-target-size` |
| `.auix-fieldset` | Form fieldset wrapper: label above its control | `--auix-gap-label`, `--auix-font-size-caption` |
| `.auix-modal` | Modal root (hidden by default) | Structural only |
| `.auix-modal-box` | Modal positioning container; floats with a margin below the `sm` breakpoint | `--auix-padding-xl`, `--auix-margin-medium` |
| `.auix-modal-focus-wrap` | Modal visible panel | `--auix-border-radius-large`, `--auix-color-bg-default`, `--auix-padding-container`, `--auix-padding-large`, `--auix-shadow-lg`, `--auix-shadow-secondary`, `--auix-ring-offset-shadow`, `--auix-ring-secondary`, `--auix-border-width-default`, `--auix-padding-medium` |
| `.auix-modal-close-button` | Modal close (×) button | `--auix-control-height-compact`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-modal-close-border`, `--auix-border-radius-default`, `--auix-color-bg-default`, `--auix-color-modal-close-text`, `--auix-color-bg-light`, `--auix-color-text-primary`, `--auix-color-focus-ring`, `--auix-focus-ring-width`, `--auix-color-focus-ring-halo`, `--auix-touch-target-size` |
| `.auix-discard-confirm` | Discard-changes dialog body inside the form modal | `--auix-gap-xl`, `--auix-control-height-compact`, `--auix-gap-medium` |
| `.auix-discard-confirm-message` | Discard-changes dialog message | `--auix-font-size-caption`, `--auix-line-height-default`, `--auix-color-text-primary` |
| `.auix-discard-confirm-actions` | Discard-changes dialog button row | `--auix-gap-large` |
| `.auix-flash` | Flash notification container | `--auix-margin-medium`, `--auix-gap-default`, `--auix-flash-max-width`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-nested`, `--auix-padding-control`, `--auix-shadow-lg`, `--auix-font-size-caption`, `--auix-line-height-default` |
| `.auix-flash--info` | Info-variant flash | `--auix-color-bg-info`, `--auix-color-info-ring`, `--auix-color-info-text`, `--auix-color-icon-fill` |
| `.auix-flash--error` | Error-variant flash | `--auix-color-error-bg`, `--auix-color-error-ring`, `--auix-color-error-text` |
| `.auix-flash-title` | Flash notification title row | `--auix-gap-medium`, `--auix-font-size-caption`, `--auix-font-weight-bold` |
| `.auix-flash-message` | Flash notification body text | `--auix-font-size-caption`, `--auix-line-height-default` |
| `.auix-simple-form-content` | Form fields wrapper | `--auix-gap-xl` |
| `.auix-simple-form-actions` | Form submit/cancel button row | `--auix-gap-default` |
| `.auix-actions` | Generic action bar | `--auix-gap-default` |
| `.auix-horizontal-divider` | Horizontal rule separator | `--auix-border-width-default`, `--auix-color-horizontal-divider`, `--auix-margin-default` |
| `.auix-sections-tab-button` | Section/tab navigation button: a folder tab | `--auix-control-height`, `--auix-padding-panel`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-default`, `--auix-font-size-caption`, `--auix-color-focus-ring`, `--auix-focus-ring-width`, `--auix-color-focus-ring-halo`, `--auix-touch-target-size` |
| `.auix-items-table-header-sort` | Sortable index column header button (label + direction arrow) | `--auix-gap-label` |
| `.auix-index-sort-action` | Card-view sort control in the index header actions: the field select and direction switch from the `sm` breakpoint up, the sort menu below it; hidden from the `md` breakpoint up, where the column headers sort | Structural only |
| `.auix-index-sort-select` | Field select plus direction switch button of the card-view sort control; shown from the `sm` breakpoint up | `--auix-gap-minimal`, `--auix-font-size-caption`, `--auix-font-weight-bold` |
| `.auix-index-sort-select-direction` | Direction switch button of the card-view sort control, stretched to the select height | Structural only |
| `.auix-index-sort-menu` | Icon button and menu of the card-view sort control; shown below the `sm` breakpoint | Structural only |
| `.auix-index-sort-menu-toggle` | Icon button that opens and closes the sort menu; its `aria-expanded` drives the open state | `--auix-touch-target-size` |
| `.auix-index-sort-menu-toggle--active` | Sort menu button while a field sort is on | `--auix-color-sort-toggle-active-text`, `--auix-color-sort-toggle-active-bg`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-sort-toggle-active-border` |
| `.auix-index-sort-menu-list` | Sort menu, opening below its button; hidden until `.auix-index-sort-menu-toggle` has `aria-expanded="true"` | `--auix-menu-min-width`, `--auix-gap-label`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-menu-border`, `--auix-border-radius-medium`, `--auix-color-menu-bg`, `--auix-shadow-lg` |
| `.auix-index-sort-menu-group` | One group of the sort menu: the fields, then the directions below a divider | `--auix-gap-minimal`, `--auix-gap-default`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-menu-divider` |
| `.auix-index-sort-menu-item` | One option of the sort menu; a check marks the active field and the active direction, which are bold | `--auix-padding-default`, `--auix-touch-target-size`, `--auix-border-radius-default`, `--auix-font-size-caption`, `--auix-font-weight-bold-semi`, `--auix-font-weight-bold`, `--auix-color-menu-item-bg-hover`, `--auix-color-text-inactive` |
| `.auix-index-sort-menu-check--off` | Check of an inactive sort menu option, kept invisible so the labels line up | Structural only |
| `.auix-action-icon` | Icon of a default action button (`<.action_content>`); hidden from the `sm` breakpoint up, shown below it | Structural only |
| `.auix-action-label` | Label of a default action button (`<.action_content>`); hidden below the `sm` breakpoint | Structural only |
| `.auix-action-icon-image` | An action icon given as an image URL (`<.action_icon>`) | Structural only |
| `.auix-action-icon-text` | An action icon given as a character (`<.action_icon>`) | Structural only |
| `.auix-items-card-list` | List of index cards | `--auix-gap-large` |
| `.auix-items-card-item-content` | One index card; the show action is stretched over it; a checked card takes the selection colors | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-items-card-border`, `--auix-border-radius-medium`, `--auix-color-items-card-bg`, `--auix-color-items-card-item-content-text`, `--auix-shadow-small`, `--auix-color-items-card-border-selected`, `--auix-color-items-card-bg-selected` |
| `.auix-items-card-show` | Tap target of a card: the show action, stretched over the card and transparent; the action is matched as `.auix-index-row-action`, else as any child element | Structural only |
| `.auix-items-card-item-group` | Card header: checkbox, heading and ⋮ menu | `--auix-gap-minimal`, `--auix-padding-panel` |
| `.auix-items-card-select` | Checkbox slot of the card header; a 44px target centering the checkbox | `--auix-touch-target-size` |
| `.auix-items-card-heading` | Title and subtitle column of the card header | Structural only |
| `.auix-items-card-title` | Card title | `--auix-font-size-subtitle`, `--auix-font-weight-bold`, `--auix-line-height-relaxed` |
| `.auix-items-card-subtitle` | Card subtitle | `--auix-font-size-label`, `--auix-color-text-secondary` |
| `.auix-items-card-item` | Card body | `--auix-gap-label`, `--auix-gap-default`, `--auix-padding-panel`, `--auix-gap-large` |
| `.auix-items-card-item-fieldset` | One `label · value` row of a card | `--auix-items-card-label-width`, `--auix-padding-control` |
| `.auix-items-card-menu` | ⋮ menu at the end of the card header: its toggle and its list; hidden when no menu item renders | `--auix-touch-target-size`, `--auix-color-menu-item-bg-hover` |
| `.auix-items-card-menu-toggle` | ⋮ button that opens and closes the card menu; its `aria-expanded` drives the open state | `--auix-touch-target-size` |
| `.auix-items-card-menu-list` | Row-action menu of the card header, opening below the toggle; hidden until `.auix-items-card-menu-toggle` has `aria-expanded="true"` | `--auix-gap-minimal`, `--auix-gap-label`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-menu-border`, `--auix-border-radius-medium`, `--auix-color-menu-bg`, `--auix-shadow-lg` |
| `.auix-items-card-menu-group` | One group of the card menu: the row actions, then the destructive ones below a divider; hidden when none of its items renders | `--auix-gap-minimal`, `--auix-gap-default`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-menu-divider` |
| `.auix-items-card-menu-group--destructive` | Destructive group of the card menu, in the danger color | `--auix-color-icon-danger` |
| `.auix-items-card-menu-item` | One row action in the card menu; hidden when it renders nothing. Its action gets the touch target as `.auix-index-row-action`, else as an `a` element, else as a `button` element | `--auix-touch-target-size`, `--auix-border-radius-default`, `--auix-color-menu-item-bg-hover` |
| `.auix-index-row-action` | Every default row action link (index and one-to-many): a touch target in the card menu, and the card's tap target as the show action | `--auix-touch-target-size` |
| `.auix-items-cards` | Card container shown at every breakpoint (`show_on: :all`); lays the cards out as a grid | `--auix-items-card-min-width`, `--auix-gap-large` |
| `.auix-index-sort-action--always` | Keeps the card-view sort control visible from the `md` breakpoint up (`show_on: :all`) | Structural only |
| `.auix-button--danger` | Destructive button (caller-supplied via `class=`, on top of the auto-applied `.auix-button-default`): the "Discard changes" button of the unsaved-changes confirmation | `--auix-color-button-danger-bg`, `--auix-color-button-danger-text`, `--auix-color-button-danger-bg-hover`, `--auix-color-button-disabled-bg`, `--auix-color-button-disabled-border`, `--auix-color-button-disabled-text` |
| `.auix-flash--success` | Success-variant flash | `--auix-color-success-bg`, `--auix-color-success-border`, `--auix-color-success-text` |
| `.auix-flash--warning` | Warning-variant flash | `--auix-color-warning-bg`, `--auix-color-warning-border`, `--auix-color-warning-text` |
| `.auix-flash-close-button` | Flash close button | `--auix-color-flash-close-text` |
| `.auix-label` | Field label above its control | `--auix-font-size-label`, `--auix-font-weight-medium`, `--auix-color-label-text`, `--auix-font-size-caption` |
| `.auix-error-message` | Field error: icon and message under the control | `--auix-gap-label`, `--auix-font-size-small`, `--auix-color-error-text-default` |
| `.auix-form-field-container` | Wrapper of one form or show field; stretches its input, select or textarea to the full width | Structural only |
| `.auix-toggle-switch` | Toggle switch (on `.auix-checkbox`), on in the primary color | `--auix-toggle-width`, `--auix-toggle-height`, `--auix-border-radius-round`, `--auix-color-toggle-off`, `--auix-color-toggle-knob`, `--auix-color-toggle-on`, `--auix-opacity-100` |
| `.auix-group-container` | Group frame; a nested group uses a smaller radius | `--auix-gap-xl`, `--auix-padding-panel`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-medium`, `--auix-color-group-container-border`, `--auix-color-group-container-bg`, `--auix-border-radius-nested` |
| `.auix-group-title` | Title bar of a group | `--auix-padding-panel`, `--auix-padding-default`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-group-title-border`, `--auix-font-weight-bold`, `--auix-font-size-group-title`, `--auix-line-height-default` |
| `.auix-embeds-one-container` | Embedded record: tinted frame whose header title is the title bar | `--auix-gap-xl`, `--auix-padding-panel`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-medium`, `--auix-color-embeds-border`, `--auix-color-embeds-bg`, `--auix-padding-default`, `--auix-font-size-caption`, `--auix-line-height-default` |
| `.auix-embeds-one-empty-msg` | "Field is empty" dashed box of an empty embedded record | `--auix-padding-default`, `--auix-padding-control`, `--auix-border-width-default`, `--auix-color-embeds-empty-border`, `--auix-border-radius-default`, `--auix-color-bg-default`, `--auix-font-size-caption`, `--auix-font-style-mobile-viewmode`, `--auix-line-height-default`, `--auix-color-embeds-empty-text` |
| `.auix-one-to-one-container` | One-to-one record: same frame as `.auix-embeds-one-container` | `--auix-gap-xl`, `--auix-padding-panel`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-medium`, `--auix-color-embeds-border`, `--auix-color-embeds-bg`, `--auix-padding-default`, `--auix-font-size-caption`, `--auix-line-height-default` |
| `.auix-one-to-one-empty-msg` | "Field is empty" dashed box of an empty one-to-one record | `--auix-padding-default`, `--auix-padding-control`, `--auix-border-width-default`, `--auix-color-embeds-empty-border`, `--auix-border-radius-default`, `--auix-color-bg-default`, `--auix-font-size-caption`, `--auix-font-style-mobile-viewmode`, `--auix-line-height-default`, `--auix-color-embeds-empty-text` |
| `.auix-embeds-many-container` | Embedded list frame | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-default`, `--auix-color-embeds-border`, `--auix-color-embeds-bg` |
| `.auix-embeds-many-details` | Collapsible body of the embedded list | Structural only |
| `.auix-embeds-many-summary` | Title row of the embedded list | `--auix-padding-default`, `--auix-padding-control`, `--auix-font-size-caption`, `--auix-font-weight-medium`, `--auix-line-height-default` |
| `.auix-embeds-many-content` | Entries and actions of the embedded list | `--auix-gap-large`, `--auix-padding-control`, `--auix-font-size-caption` |
| `.auix-embeds-many-entry-contents` | One embedded entry | `--auix-gap-default`, `--auix-padding-default`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-default`, `--auix-color-embeds-border`, `--auix-color-embeds-bg` |
| `.auix-sections-tab-container` | Row of section tabs, attached to the panel and scrolling horizontally when it overflows | `--auix-gap-minimal`, `--auix-margin-medium`, `--auix-border-width-default`, `--auix-focus-ring-width`, `--auix-padding-control`, `--auix-padding-medium` |
| `.auix-sections-tab-button--active` | Active section tab, joined to the panel | `--auix-font-weight-bold`, `--auix-color-sections-tab-active-text`, `--auix-color-sections-tab-active-bg`, `--auix-color-sections-tab-active-border` |
| `.auix-sections-tab-button--inactive` | Inactive section tab | `--auix-font-weight-medium`, `--auix-color-sections-tab-inactive-text`, `--auix-color-sections-tab-inactive-bg`, `--auix-color-sections-tab-active-text`, `--auix-color-sections-tab-hover-bg` |
| `.auix-sections-content` | Bordered panel under the section tabs; nested sections use smaller tabs and padding | `--auix-padding-container`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-sections-content-border`, `--auix-border-radius-medium`, `--auix-color-sections-content-bg`, `--auix-control-height-compact`, `--auix-font-size-label`, `--auix-padding-panel`, `--auix-border-radius-nested` |
| `.auix-form-container` | Bordered container of the form fields; frameless below the `sm` breakpoint | `--auix-gap-container`, `--auix-padding-container`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-form-container-border`, `--auix-border-radius-medium`, `--auix-color-form-container-bg`, `--auix-gap-xl` |
| `.auix-show-content` | Bordered container of the show-view fields; frameless below the `sm` breakpoint | `--auix-gap-container`, `--auix-padding-container`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-show-content-border`, `--auix-border-radius-medium`, `--auix-color-show-content-bg`, `--auix-gap-xl` |
| `.auix-show-container` | Show view; framed as a card from the `md` breakpoint up, unframed inside a modal | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-show-content-border`, `--auix-border-radius-large`, `--auix-color-show-content-bg`, `--auix-shadow-lg` |
| `.auix-header-title-container` | Title and subtitle column of a header | `--auix-gap-default` |
| `.auix-header-title` | Header title; the index page title is larger | `--auix-font-size-title`, `--auix-font-weight-bold`, `--auix-line-height-title`, `--auix-color-header-title-text`, `--auix-font-size-page-title`, `--auix-font-size-subtitle`, `--auix-line-height-relaxed` |
| `.auix-header-subtitle` | Header subtitle | `--auix-font-size-caption`, `--auix-line-height-default`, `--auix-color-header-subtitle-text` |
| `.auix-inline-container` | `inline` layout: fields in a row from the `md` breakpoint up | `--auix-gap-xl` |
| `.auix-stacked-container` | `stacked` layout: fields in a column | `--auix-gap-xl` |
| `.auix-show-field` | Label and value of a predefined show renderer | `--auix-gap-label` |
| `.auix-modal-box-content` | Column of the modal content | `--auix-gap-xl` |
| `.auix-modal-close-button-container` | Top-right position of the modal close button | `--auix-padding-panel`, `--auix-margin-medium` |
| `.auix-record-navigator-bar` | Centered record pager (previous, position, next) | `--auix-gap-default`, `--auix-control-height-compact`, `--auix-font-size-caption`, `--auix-font-weight-medium`, `--auix-color-text-label`, `--auix-row-action-size`, `--auix-border-radius-default`, `--auix-color-bg-light`, `--auix-touch-target-size` |
| `.auix-index-container` | Index page column | `--auix-gap-xl`, `--auix-padding-default`, `--auix-padding-xl`, `--auix-padding-large` |
| `.auix-index-actions` | Select and header action row of the index | `--auix-gap-large` |
| `.auix-index-header-actions` | Header actions of the index (filters, sort, new) | `--auix-gap-medium` |
| `.auix-items-table-container` | Card around the index table; from the `md` breakpoint up its pagination bar is its footer | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-items-table-border`, `--auix-border-radius-medium`, `--auix-color-items-table-bg`, `--auix-shadow-small` |
| `.auix-items-table` | Index table | Structural only |
| `.auix-items-table-header` | Tinted header of the index table; marks the sorted column | `--auix-font-size-label`, `--auix-color-items-table-header-text`, `--auix-color-items-table-header-bg`, `--auix-color-items-table-body-border`, `--auix-color-items-table-header-sorted-text`, `--auix-color-text-inactive` |
| `.auix-items-table-header-cell` | Column header cell | `--auix-table-header-height`, `--auix-padding-control`, `--auix-font-weight-bold` |
| `.auix-items-table-header-cell--first` | First column header cell | `--auix-padding-panel` |
| `.auix-items-table-body` | Body of the index table | `--auix-font-size-caption`, `--auix-color-items-table-body-text`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-items-table-row-border` |
| `.auix-items-table-row` | Table row; a row with a checked selection box takes the selection background | `--auix-color-items-table-row-bg-hover`, `--auix-color-items-table-row-bg-selected` |
| `.auix-items-table-cell` | Table cell | `--auix-table-row-height`, `--auix-padding-control`, `--auix-padding-panel` |
| `.auix-items-table-action-cell` | Row actions cell: 32px icon targets | `--auix-table-row-height`, `--auix-padding-control`, `--auix-gap-minimal`, `--auix-row-action-size`, `--auix-color-row-action-text`, `--auix-color-row-action-bg-hover`, `--auix-color-text-primary` |
| `.auix-items-card-item-label` | Label of a card `label · value` row | `--auix-font-size-label`, `--auix-font-weight-medium`, `--auix-color-items-card-label-text` |
| `.auix-items-card-item-value` | Value of a card `label · value` row | `--auix-font-size-caption`, `--auix-line-height-default`, `--auix-color-text-primary` |
| `.auix-pagination-container` | Pagination bar; the table card footer from the `md` breakpoint up | `--auix-gap-xl`, `--auix-padding-control`, `--auix-padding-panel`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-items-table-border`, `--auix-color-items-table-row-border`, `--auix-border-radius-medium`, `--auix-color-items-table-bg` |
| `.auix-pagination-bar` | Centered page links | `--auix-gap-default`, `--auix-row-action-size`, `--auix-padding-medium`, `--auix-border-radius-round`, `--auix-font-size-caption`, `--auix-font-weight-medium`, `--auix-color-pagination-link-text`, `--auix-color-pagination-link-bg-hover` |
| `.auix-pagination-bar-link` | Link to a page | Structural only |
| `.auix-pagination-bar-current-page-number` | Pill of the current page | `--auix-row-action-size`, `--auix-padding-medium`, `--auix-border-width-default`, `--auix-color-pagination-current-border`, `--auix-border-radius-round`, `--auix-font-size-caption`, `--auix-font-weight-bold`, `--auix-color-pagination-current-text`, `--auix-color-pagination-current-bg` |
| `.auix-one-to-many-field` | One-to-many field: header and list | `--auix-gap-medium` |
| `.auix-one-to-many-header` | Label and add action of a one-to-many field | `--auix-gap-medium` |
| `.auix-one-to-many-container` | List of a one-to-many field, with no outer box; its table is denser | `--auix-color-one-to-many-text`, `--auix-padding-default`, `--auix-padding-panel`, `--auix-font-size-small`, `--auix-gap-label`, `--auix-font-size-caption` |
`````

##### guides/customization/theming.md
1. § Built-in Themes — replace
   ```
   Aurora UIX ships with two registered themes:

   - `:white_charcoal` — the library default (light-first, neutral grays)
   - `:vitreous_marble` — Slate/Cyan/Ruby palette
   ```
   with
   ```
   Aurora UIX ships with three registered themes:

   - `:white_charcoal` — the library default (light-first, neutral grays)
   - `:vitreous_marble` — Slate/Cyan/Ruby palette
   - `:blue_graphite` — slate text and borders with a navy primary, light and dark
   ```
2. § Layer 3: Base Variables — in the `BaseVariables` code sample, replace `    --auix-font-size-title: 1.125rem;` with `    --auix-font-size-title: 1.25rem;` (UI-1 changes the default).
3. Insert a new section directly before the line `## Built-in Themes`, verbatim:
`````markdown
## Status and selection colors

Every built-in theme defines these colors in `:root_colors`, each with a light value and a
`--dark--` value. A custom theme defines them too: a color it leaves out is undefined, and the
element that reads it loses that color.

| Variable | Used by |
|---|---|
| `--auix-color-success-bg` | Success flash background (`.auix-flash--success`) |
| `--auix-color-success-border` | Success flash border |
| `--auix-color-success-text` | Success flash text and icon |
| `--auix-color-warning-bg` | Warning flash background (`.auix-flash--warning`) |
| `--auix-color-warning-border` | Warning flash border |
| `--auix-color-warning-text` | Warning flash text and icon |
| `--auix-color-selection-bg` | Background of a selected index row and of a selected index card |
| `--auix-color-selection-border` | Border of a selected index card |
| `--auix-color-focus-ring-halo` | The 3px ring around a focused input, select, button or tab |

The index, form and show views render a flash of kind `:success` or `:warning`; the library's own
messages stay `:info` and `:error`. A host handler puts one like any other flash:

```elixir
{:noreply, put_flash(socket, :success, "Saved")}
```

`````

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-544-enriched-spec.md`)
- [x] AC-3: `guides/customization/styling.md § Variable reference` documents every new size, typography, status and alias variable (mechanical — no red test; verified by `` for v in --auix-control-height --auix-font-size-label --auix-color-focus-ring-halo --auix-color-selection-bg --auix-color-button-danger-bg --auix-color-menu-bg; do grep -qF -- "| \`$v\` |" guides/customization/styling.md || echo "missing $v"; done `` printing nothing)
- [x] AC-4: `guides/customization/styling.md § Class reference` lists `.auix-button--danger`, `.auix-flash--success`, `.auix-flash--warning` and every class UI-1 to UI-6 restyle (mechanical — no red test; verified by `` for c in .auix-button--danger .auix-flash--success .auix-flash--warning .auix-items-table-container .auix-group-container .auix-sections-content; do grep -qF -- "| \`$c\` |" guides/customization/styling.md || echo "missing $c"; done `` printing nothing)
- [x] AC-5: `guides/customization/styling.md § Recipe table` has no `--auix-button-height-default` and a "Flat groups (0.2.0 look)" row (mechanical — no red test; verified by `grep -n 'Flat groups (0.2.0 look)' guides/customization/styling.md` matching and `grep -n 'Larger touch targets.*button-height-default' guides/customization/styling.md` matching nothing)
- [x] AC-6: `guides/customization/theming.md § Built-in Themes` lists `:blue_graphite`, `§ Status and selection colors` precedes it and `§ Layer 3: Base Variables` shows `--auix-font-size-title: 1.25rem;` (mechanical — no red test; verified by `grep -n -e '^## Status and selection colors' -e '^## Built-in Themes' -e 'blue_graphite' -e 'font-size-title: 1.25rem' guides/customization/theming.md` showing the status heading before the Built-in Themes heading)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · theme variables and flash messages
Depends on: DOC-1

#### Documentation references
- `guides/customization/theming.md § Status and selection colors` (added by DOC-1)
- `guides/customization/styling.md § Variable reference`, `§ Class reference`

#### Implementation details

Layout types: `:index`, `:form`, `:show` (the three renderers that render flashes). Backend-agnostic: no file under `lib/aurora_uix/integration/` changes; flash rendering has no backend branch, so the LiveView test runs on the Ecto inventory guide only.

1. `lib/aurora_uix/templates/basic/themes/base_variables.ex`, `rule(:root, ...)`:
   1. Replace `    --auix-line-height-relaxed: 1.5rem;` with:
      ```
          --auix-line-height-relaxed: 1.5rem;
          --auix-line-height-title: 1.75rem;
      ```
   2. Replace `    --auix-border-radius-round: 9999px;` with:
      ```
          --auix-border-radius-round: 9999px;
          --auix-border-radius-medium: 0.75rem;
          --auix-border-radius-nested: 0.625rem;
      ```
   3. Replace `    --auix-items-card-label-width: 7.25rem;` with `    --auix-items-card-label-width: 8rem;`.
   4. Replace `    --auix-items-card-min-width: 17.5rem;` with:
      ```
          --auix-items-card-min-width: 17.5rem;

          --auix-control-height: 2.5rem;
          --auix-control-height-compact: 2.25rem;
          --auix-padding-control: 0.75rem;
          --auix-padding-panel: 1rem;
          --auix-padding-container: 1.25rem;
          --auix-gap-label: 0.375rem;
          --auix-gap-xl: 1rem;
          --auix-gap-container: 1.25rem;
          --auix-focus-ring-width: 3px;
          --auix-row-action-size: 2rem;
          --auix-table-header-height: 2.75rem;
          --auix-table-row-height: 3rem;
          --auix-checkbox-size: 1.125rem;
          --auix-checkbox-size-mobile: 1.25rem;
          --auix-toggle-width: 2.75rem;
          --auix-toggle-height: 1.5rem;
          --auix-menu-min-width: 15rem;
          --auix-flash-max-width: 24rem;
      ```
   5. Replace `    --auix-font-size-title: 1.125rem;` with `    --auix-font-size-title: 1.25rem;`.
   6. Replace `    --auix-font-size-group-title: 1.125rem;` with `    --auix-font-size-group-title: 0.875rem;`.
   7. Replace `    --auix-font-size-empty-state: 1.125rem;` with:
      ```
          --auix-font-size-empty-state: 1.125rem;
          --auix-font-size-label: 0.8125rem;
          --auix-font-size-input-mobile: 1rem;
          --auix-font-size-page-title: 1.5rem;
      ```
   8. Replace `    --auix-font-weight-bold-semi: 400;` with:
      ```
          --auix-font-weight-bold-semi: 400;
          --auix-font-weight-medium: 500;
      ```
   New-name evidence: `rg -n -e 'line-height-title' -e 'border-radius-medium' -e 'border-radius-nested' -e 'control-height' -e 'padding-control' -e 'padding-panel' -e 'padding-container' -e 'gap-label' -e 'gap-xl' -e 'gap-container' -e 'focus-ring-width' -e 'row-action-size' -e 'table-header-height' -e 'table-row-height' -e 'checkbox-size' -e 'toggle-width' -e 'toggle-height' -e 'menu-min-width' -e 'flash-max-width' -e 'font-size-label' -e 'font-size-input-mobile' -e 'font-size-page-title' -e 'font-weight-medium' lib test` returns nothing.

2. `lib/aurora_uix/templates/basic/themes/white_charcoal.ex`, `rule(:root_colors, ...)`:
   1. Replace `    --auix-color-error-text-default: #E11D48; /* rose-600 for inline error text */` with `    --auix-color-error-text-default: #BE123C; /* rose-700 for inline error text */`.
   2. Replace `    --auix-color-error: #FB7185;          /* rose-400 for input error borders */` with `    --auix-color-error: #F43F5E;          /* rose-500 for input error borders */`.
   3. Replace `    --auix-color-focus-ring: #6366F1; /* indigo-500 */` with:
      ```
          --auix-color-focus-ring: #6366F1; /* indigo-500 */
          --auix-color-focus-ring-halo: rgba(99, 102, 241, 0.3); /* indigo-500 at 30% */

          /* Success, warning and selection */
          --auix-color-success-bg: #ECFDF5;       /* emerald-50 */
          --auix-color-success-border: #6EE7B7;   /* emerald-300 */
          --auix-color-success-text: #065F46;     /* emerald-800 */
          --auix-color-warning-bg: #FFFBEB;       /* amber-50 */
          --auix-color-warning-border: #FDE68A;   /* amber-200 */
          --auix-color-warning-text: #78350F;     /* amber-900 */
          --auix-color-selection-bg: #F3F3F4;     /* zinc-900 at 5% on white */
          --auix-color-selection-border: #18181B; /* zinc-900 */
      ```
   4. Replace `    --dark--auix-color-focus-ring: #818CF8; /* indigo-400 */` with:
      ```
          --dark--auix-color-focus-ring: #818CF8; /* indigo-400 */
          --dark--auix-color-focus-ring-halo: rgba(129, 140, 248, 0.3); /* indigo-400 at 30% */
          --dark--auix-color-success-bg: #022C22;       /* emerald-950 */
          --dark--auix-color-success-border: #065F46;   /* emerald-800 */
          --dark--auix-color-success-text: #6EE7B7;     /* emerald-300 */
          --dark--auix-color-warning-bg: #451A03;       /* amber-950 */
          --dark--auix-color-warning-border: #92400E;   /* amber-800 */
          --dark--auix-color-warning-text: #FCD34D;     /* amber-300 */
          --dark--auix-color-selection-bg: #2A2A2D;     /* zinc-50 at 8% on zinc-900 */
          --dark--auix-color-selection-border: #FAFAFA; /* zinc-50 */
      ```
   5. The line `--auix-color-focus-ring: var(--dark--auix-color-focus-ring);` occurs twice: once inside `@media (prefers-color-scheme: dark)` (6-space indent) and once inside `:root[data-theme="dark"]...` (4-space indent). After each occurrence, insert these nine lines at that occurrence's indent:
      ```
      --auix-color-focus-ring-halo: var(--dark--auix-color-focus-ring-halo);
      --auix-color-success-bg: var(--dark--auix-color-success-bg);
      --auix-color-success-border: var(--dark--auix-color-success-border);
      --auix-color-success-text: var(--dark--auix-color-success-text);
      --auix-color-warning-bg: var(--dark--auix-color-warning-bg);
      --auix-color-warning-border: var(--dark--auix-color-warning-border);
      --auix-color-warning-text: var(--dark--auix-color-warning-text);
      --auix-color-selection-bg: var(--dark--auix-color-selection-bg);
      --auix-color-selection-border: var(--dark--auix-color-selection-border);
      ```
   The dark values of `--dark--auix-color-error` (`#F43F5E`) and `--dark--auix-color-error-text-default` (`#FB7185`) stay as they are.

3. `lib/aurora_uix/templates/basic/themes/vitreous_marble.ex`, `rule(:root_colors, ...)`:
   1. Replace `    --auix-color-focus-ring: #06B6D4; /* Cyan-500 */` with:
      ```
          --auix-color-focus-ring: #06B6D4; /* Cyan-500 */
          --auix-color-focus-ring-halo: rgba(6, 182, 212, 0.3); /* Cyan-500 at 30% */

          /* Success, warning and selection */
          --auix-color-success-bg: #ECFDF5;       /* Emerald-50 */
          --auix-color-success-border: #A7F3D0;   /* Emerald-200 */
          --auix-color-success-text: #065F46;     /* Emerald-800 */
          --auix-color-warning-bg: #FFFBEB;       /* Amber-50 */
          --auix-color-warning-border: #FDE68A;   /* Amber-200 */
          --auix-color-warning-text: #78350F;     /* Amber-900 */
          --auix-color-selection-bg: #ECFEFF;     /* Cyan-50 */
          --auix-color-selection-border: #06B6D4; /* Cyan-500 */
      ```
   2. Replace `    --dark--auix-color-focus-ring: #22D3EE; /* Cyan-400 (Glowing Glass) */` with:
      ```
          --dark--auix-color-focus-ring: #22D3EE; /* Cyan-400 (Glowing Glass) */
          --dark--auix-color-focus-ring-halo: rgba(34, 211, 238, 0.3); /* Cyan-400 at 30% */
          --dark--auix-color-success-bg: #022C22;       /* Emerald-950 */
          --dark--auix-color-success-border: #065F46;   /* Emerald-800 */
          --dark--auix-color-success-text: #6EE7B7;     /* Emerald-300 */
          --dark--auix-color-warning-bg: #451A03;       /* Amber-950 */
          --dark--auix-color-warning-border: #92400E;   /* Amber-800 */
          --dark--auix-color-warning-text: #FCD34D;     /* Amber-300 */
          --dark--auix-color-selection-bg: #083344;     /* Cyan-950 */
          --dark--auix-color-selection-border: #22D3EE; /* Cyan-400 */
      ```
   3. After both occurrences of `--auix-color-focus-ring: var(--dark--auix-color-focus-ring);` (the `@media (prefers-color-scheme: dark)` block and the `:root[data-theme="dark"]...` block), insert the nine lines of step 2.5 at that occurrence's indent.

4. `lib/aurora_uix/templates/basic/themes/base.ex` — flash rules. Replace the whole heredoc of each rule named below with the CSS given; add the two new rules directly after `rule(:auix_flash__error, ...)`.
   1. `rule(:_auix_flash, ...)`:
      ```css
      .auix-flash {
        position: fixed;
        top: var(--auix-margin-medium);
        right: var(--auix-margin-medium);
        z-index: 50;

        display: flex;
        flex-direction: column;
        gap: var(--auix-gap-default);
        max-width: min(var(--auix-flash-max-width), calc(100vw - 1rem));

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-nested);
        padding: var(--auix-padding-control) 0.875rem;
        box-shadow: var(--auix-shadow-lg);

        font-size: var(--auix-font-size-caption);
        line-height: var(--auix-line-height-default);
      }
      ```
   2. `rule(:auix_flash__info, ...)`:
      ```
      /* auix-flash--info */

      #{import_rule(:_auix_flash, :auix_flash__info)}

      .auix-flash--info {
        background-color: var(--auix-color-bg-info);
        border-color: var(--auix-color-info-ring);
        color: var(--auix-color-info-text);
        fill: var(--auix-color-icon-fill);
      }
      ```
   3. `rule(:auix_flash__error, ...)`:
      ```
      #{import_rule(:_auix_flash, :auix_flash__error)}

      .auix-flash--error {
        background-color: var(--auix-color-error-bg);
        border-color: var(--auix-color-error-ring);
        color: var(--auix-color-error-text);
        fill: var(--auix-color-error-text);
      }
      ```
   4. New `rule(:auix_flash__success, ...)`:
      ```
      #{import_rule(:_auix_flash, :auix_flash__success)}

      .auix-flash--success {
        background-color: var(--auix-color-success-bg);
        border-color: var(--auix-color-success-border);
        color: var(--auix-color-success-text);
        fill: var(--auix-color-success-text);
      }
      ```
   5. New `rule(:auix_flash__warning, ...)`:
      ```
      #{import_rule(:_auix_flash, :auix_flash__warning)}

      .auix-flash--warning {
        background-color: var(--auix-color-warning-bg);
        border-color: var(--auix-color-warning-border);
        color: var(--auix-color-warning-text);
        fill: var(--auix-color-warning-text);
      }
      ```
   6. `rule(:auix_flash_title, ...)`:
      ```css
      .auix-flash-title {
        display: flex;
        flex-direction: row;
        justify-content: space-between;
        align-items: center;
        gap: var(--auix-gap-medium);

        font-size: var(--auix-font-size-caption);
        font-weight: var(--auix-font-weight-bold);
      }

      .auix-flash-title > div {
        display: flex;
        flex-direction: row;
        align-items: center;
        gap: var(--auix-gap-medium);
      }
      ```
   7. `rule(:auix_flash_message, ...)`:
      ```css
      .auix-flash-message {
        font-size: var(--auix-font-size-caption);
        line-height: var(--auix-line-height-default);
      }
      ```
   8. `rule(:auix_flash_close_button, ...)`:
      ```css
      .auix-flash-close-button {
        display: inline-flex;
        align-items: center;
        padding: 0;
        background: transparent;
        border: none;
        color: var(--auix-color-flash-close-text);
        cursor: pointer;
      }
      ```
   `import_rule/2` renames `_auix_flash` to the target through `ThemeHelper.rename_rule/3` (`auix_flash__success` → `.auix-flash--success`); new-name evidence: `rg -n 'flash__success|flash__warning|flash--success|flash--warning' lib test` returns nothing.

5. `lib/aurora_uix/templates/basic/components/core_components.ex`, `flash/1`:
   1. Replace `  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")` with `  attr(:kind, :atom, values: [:info, :success, :warning, :error], doc: "used for styling and flash lookup")`.
   2. After the line `          <.icon :if={@kind == :info} name="hero-information-circle-mini" class="auix-icon-size-4" />` insert:
      ```
                <.icon :if={@kind == :success} name="hero-check-circle-mini" class="auix-icon-size-4" />
                <.icon :if={@kind == :warning} name="hero-exclamation-triangle-mini" class="auix-icon-size-4" />
      ```
   `flash_group/1` is not changed.

6. Render the two new kinds after the existing `:info` flash in each view renderer. Each new line follows its sibling `:info` line verbatim except for `kind` and `title`:
   1. `lib/aurora_uix/templates/basic/renderers/index_renderer.ex`, `render/1`: after `      <.flash kind={:info} flash={@flash} title={dt("Info")} />` insert
      ```
            <.flash kind={:success} flash={@flash} title={dt("Success")} />
            <.flash kind={:warning} flash={@flash} title={dt("Warning")} />
      ```
   2. `lib/aurora_uix/templates/basic/renderers/form_renderer.ex`, `render/1`: after `      <.flash kind={:info} flash={@flash} title={dt("Info")} />` insert the same two lines.
   3. `lib/aurora_uix/templates/basic/renderers/show_component_renderer.ex`, `render/1`: after `        <.flash kind={:info} flash={@flash} title={dt("Info!")} />` insert
      ```
              <.flash kind={:success} flash={@flash} title={dt("Success!")} />
              <.flash kind={:warning} flash={@flash} title={dt("Warning!")} />
      ```
   The flash `id` defaults to `"flash-#{kind}"`, so the new elements are `#flash-success` and `#flash-warning`. No library handler puts either kind; a host handler does.

7. Tests:
   1. `test/cases/templates/theme_helper_test.exs`, test `"group-title and empty-state sizes do not resolve through the page title"`: replace `assert css =~ "--auix-font-size-group-title: 1.125rem;"` with `assert css =~ "--auix-font-size-group-title: 0.875rem;"`.
   2. `test/support/app_web/routes.ex`: after the `RoutesHelper.register_crud(FormDiscardGuardTest.Product, "form-discard-guard-products")` entry, add
      ```
              RoutesHelper.register_crud(
                FlashKindsTest.Product,
                "flash-kinds-products"
              )
      ```
   3. New file `test/cases_live/flash_kinds_test.exs` (no file matches `rg -l 'FlashKinds' test`). Module `Aurora.UixWeb.Test.FlashKindsTest` with `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`, `auix_resource_metadata(:product, context: Inventory, schema: Product)` and
      ```
      auix_create_ui do
        index_columns(:product, [:reference, :name], handler_module: Aurora.UixWeb.FlashKindsHandlerHook)
      end
      ```
      A second top-level module `Aurora.UixWeb.FlashKindsHandlerHook` in the same file, shaped like `Aurora.UixWeb.IndexHandlerHook` in `test/cases_live/handler_hooks_index_test.exs`: `use Aurora.Uix.Templates.Basic.Handlers.IndexImpl`, with
      ```
      @impl IndexImpl
      def auix_handle_event("flash_kinds", _params, socket) do
        {:noreply, socket |> put_flash(:success, "Saved") |> put_flash(:warning, "Check")}
      end

      def auix_handle_event(event, params, socket), do: super(event, params, socket)
      ```

##### Acceptance criteria
- [x] AC-1: Given the White Charcoal and Vitreous Marble themes, then each `:root_colors` rule declares `--auix-color-focus-ring-halo`, `--auix-color-success-bg`, `--auix-color-success-border`, `--auix-color-success-text`, `--auix-color-warning-bg`, `--auix-color-warning-border`, `--auix-color-warning-text`, `--auix-color-selection-bg` and `--auix-color-selection-border`, each with a `--dark--` value and a dark switch line in both dark blocks.
- [x] AC-2: Given White Charcoal, then `--auix-color-error` is `#F43F5E` and `--auix-color-error-text-default` is `#BE123C` in light mode.
- [x] AC-3: Given the `:product` index at `/flash-kinds-products`, when the host handler puts a `:success` and a `:warning` flash, then `#flash-success.auix-flash--success` shows "Saved" with a `hero-check-circle-mini` icon and `#flash-warning.auix-flash--warning` shows "Check" with a `hero-exclamation-triangle-mini` icon.
- [x] AC-4: Given the same index with no flash put, then neither `#flash-success` nor `#flash-warning` renders.
- [x] AC-5: The flash rules `.auix-flash--info`, `.auix-flash--success`, `.auix-flash--warning` and `.auix-flash--error` take their background, border and text colors from their theme variables.
- [x] AC-6: The variables stylesheet declares every framing size of step 1.
- [x] AC-7: Info, success, warning and error flashes look like the "Flash messages" board of the White Charcoal mockup (visual — no red test; verified by the guide images reviewed in UI-7).

##### Test ports
- Route `"/flash-kinds-products"` registered in `routes.ex` via `register_crud/2` · layout type `:index` · observable: `has_element?/2` on `#flash-success.auix-flash--success`, `#flash-warning.auix-flash--warning`.
- Theme rules: `WhiteCharcoal.rule(:root_colors)`, `VitreousMarble.rule(:root_colors)`, `Base.rule/1` (pure, no DB) — the CSS is not observable through LiveViewTest, so these assertions follow the existing `test/cases/templates/theme_rules_test.exs`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/templates/theme_rules_test.exs`, new `describe "theme properties"` | aliases `WhiteCharcoal`, `VitreousMarble` (add `alias Aurora.Uix.Templates.Basic.Themes.VitreousMarble`) | `test/cases/templates/theme_rules_test.exs` | `"both themes declare the status, selection and focus-halo colors, light and dark"` | for each theme and each of the nine names (`auix-color-focus-ring-halo`, `auix-color-success-bg`, …): `css =~ ~r/^\s*--#{name}: (#\|rgba\()/m`, `css =~ ~r/--dark--#{name}: (#\|rgba\()/`, and `length(String.split(css, "--#{name}: var(--dark--#{name});")) == 3` |
| AC-2 | same describe | `WhiteCharcoal.rule(:root_colors)` | `test/cases/templates/theme_rules_test.exs` | `"White Charcoal uses rose-500 error borders and rose-700 error text"` | `css =~ "--auix-color-error: #F43F5E;"` and `css =~ "--auix-color-error-text-default: #BE123C;"` |
| AC-3 | new file | `live(conn, "/flash-kinds-products")`, `render_click(view, "flash_kinds", %{})` | `test/cases_live/flash_kinds_test.exs` | `"success and warning flashes render with their class and icon"` | `has_element?(view, "#flash-success.auix-flash--success", "Saved")`, `has_element?(view, "#flash-success .hero-check-circle-mini")`, `has_element?(view, "#flash-warning.auix-flash--warning", "Check")`, `has_element?(view, "#flash-warning .hero-exclamation-triangle-mini")` |
| AC-4 | same file | `live(conn, "/flash-kinds-products")` only | `test/cases_live/flash_kinds_test.exs` | `"no success or warning flash renders without a message"` | `refute has_element?(view, "#flash-success")`, `refute has_element?(view, "#flash-warning")` |
| AC-5 | add to `theme_rules_test.exs`, describe `"theme properties"` | `Base.rule/1` | `test/cases/templates/theme_rules_test.exs` | `"each flash variant reads its own colors"` | for `{rule, bg, border}` in `[{:auix_flash__info, "bg-info", "info-ring"}, {:auix_flash__success, "success-bg", "success-border"}, {:auix_flash__warning, "warning-bg", "warning-border"}, {:auix_flash__error, "error-bg", "error-ring"}]`: `Base.rule(rule) =~ "background-color: var(--auix-color-#{bg})"` and `=~ "border-color: var(--auix-color-#{border})"` |
| AC-6 | add to `test/cases/templates/theme_helper_test.exs`, describe `"split stylesheet generation"` | `ThemeHelper.generate_variables_stylesheet()` | `test/cases/templates/theme_helper_test.exs` | `"declares the framing sizes"` | for each name in `~w(line-height-title border-radius-medium border-radius-nested control-height control-height-compact padding-control padding-panel padding-container gap-label gap-xl gap-container focus-ring-width row-action-size table-header-height table-row-height checkbox-size checkbox-size-mobile toggle-width toggle-height menu-min-width flash-max-width font-size-label font-size-input-mobile font-size-page-title font-weight-medium)`: `css =~ ~r/--auix-#{name}:\s*[^;]+;/` |

In the tables, `\|` stands for `|`.

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Themes.BaseVariables`, `WhiteCharcoal`, `VitreousMarble`, `Base` — modified (rules only).
2. `CoreComponents.flash/1` — attr `:kind` gains `:success` and `:warning`; markup unchanged apart from the two icons. `IndexRenderer.render/1`, `FormRenderer.render/1`, `ShowComponentRenderer.render/1` — two `<.flash>` lines each.
3. Theme: `.auix-flash` (`rule(:_auix_flash)`), `.auix-flash--info`, `.auix-flash--error`, new `.auix-flash--success` (`rule(:auix_flash__success)`), new `.auix-flash--warning` (`rule(:auix_flash__warning)`), `.auix-flash-title`, `.auix-flash-message`, `.auix-flash-close-button`. Regenerate with `mix auix.gen.stylesheet`; `mix auix.gen.tailwind_classes` (first stage of `mix consistency`) adds `hero-check-circle-mini` and `hero-exclamation-triangle-mini` to `priv/static/classes.js` — commit the regenerated file.
4. `dt/1` strings: `"Success"`, `"Warning"`, `"Success!"`, `"Warning!"`.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI · Blue Graphite theme
Depends on: UI-1

#### Documentation references
- `guides/customization/theming.md § Built-in Themes`, `§ Status and selection colors`

#### Implementation details

Layout types: none directly — the theme recolors every layout type through the CSS variables. Backend-agnostic. Registration is automatic: `ThemeHelper.find_registered_themes/0` registers every loaded module that implements the `Aurora.Uix.Templates.Theme` behaviour under its `theme_name/0`, so no registry entry is written.

1. New file `lib/aurora_uix/templates/basic/themes/blue_graphite.ex` (`rg -l 'BlueGraphite|blue_graphite' lib test` returns nothing), with exactly this content. Variable names, order and the two dark blocks mirror `white_charcoal.ex` after UI-1; values come from the issue's Blue Graphite tables.
   ```elixir
   defmodule Aurora.Uix.Templates.Basic.Themes.BlueGraphite do
     @moduledoc """
     The Blue Graphite theme for the Basic template.
   
     ## Key Features
     - Slate text and borders, a navy primary and light / dark values for every color variable.
     - Registered as `:blue_graphite`; select it with `config :aurora_uix, theme_name: :blue_graphite`.
   
     ## Key Constraints
     - Defines colors only; every other rule comes from `ThemeBase` through `include`.
     """
     use Aurora.Uix.Templates.Theme, theme_name: :blue_graphite
   
     alias Aurora.Uix.Templates.Basic.Themes.ThemeBase
   
     rule(:root_colors, """
     :root[data-theme-name="#{@theme_name}"], :host[data-theme-name="#{@theme_name}"] {
     /* Theme Name: Blue Graphite */
     /* Base Palette: Gray (Slate), Navy (Primary), Red (Danger) */
   
       /* Backgrounds */
       --auix-color-bg-default: #FFFFFF;
       --auix-color-bg-default--reverted: #0F172A;
       --auix-color-bg-secondary: #D0D5DD;
       --auix-color-bg-disabled: #98A2B3;
       --auix-color-bg-info: #EFF4FF;
       --auix-color-bg-light: #F2F4F7;
       --auix-color-bg-hover: #F9FAFB;
       --auix-color-bg-hover--reverted: #1E293B;
       --auix-color-bg-backdrop: #DDE1E8;
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
       --auix-color-icon-info: #2F56D6;
       --auix-color-icon-danger: #B42318;
       --auix-color-icon-inactive: #D0D5DD;
   
       /* Borders */
       --auix-color-border-primary: #C4CAD4;
       --auix-color-border-secondary: #E4E7EC;
       --auix-color-border-tertiary: #F2F4F7;
       --auix-color-border-focus: #0F172A;
   
       /* Focus States */
       --auix-color-focus-ring: #0F172A;
       --auix-color-focus-ring-halo: rgba(15, 23, 42, 0.22);
   
       /* Success, warning and selection */
       --auix-color-success-bg: #ECFDF3;
       --auix-color-success-border: #ABEFC6;
       --auix-color-success-text: #085D3A;
       --auix-color-warning-bg: #FFFAEB;
       --auix-color-warning-border: #FEDF89;
       --auix-color-warning-text: #7A2E0E;
       --auix-color-selection-bg: #F1F1F2;
       --auix-color-selection-border: #0F172A;
   
       /* Rings and shadows */
       --auix-ring-color: rgba(16, 24, 40, 0.1);
       --auix-color-shadow-alpha: rgba(16, 24, 40, 0.1);
       --auix-color-shadow-black-alpha: rgba(16, 24, 40, 0.1);
       --auix-color-shadow-black-alpha-small: rgba(16, 24, 40, 0.05);
   
       /* Dark theme variant - intermediate variables used in the dark mode selectors */
       --dark--auix-color-bg-default: #111723;
       --dark--auix-color-bg-default--reverted: #E6E9EF;
       --dark--auix-color-bg-secondary: #3A4558;
       --dark--auix-color-bg-disabled: #5B6678;
       --dark--auix-color-bg-info: #111C3A;
       --dark--auix-color-bg-light: #1D2535;
       --dark--auix-color-bg-hover: #161C29;
       --dark--auix-color-bg-hover--reverted: #D0D5DD;
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
       --dark--auix-color-border-focus: #E6E9EF;
       --dark--auix-color-focus-ring: #E6E9EF;
       --dark--auix-color-focus-ring-halo: rgba(230, 233, 239, 0.28);
       --dark--auix-color-success-bg: #0B261A;
       --dark--auix-color-success-border: #17573A;
       --dark--auix-color-success-text: #75E0A7;
       --dark--auix-color-warning-bg: #2B1D08;
       --dark--auix-color-warning-border: #6B4A0F;
       --dark--auix-color-warning-text: #FEC84B;
       --dark--auix-color-selection-bg: #1E2636;
       --dark--auix-color-selection-border: #E6E9EF;
       --dark--auix-ring-color: rgba(230, 233, 239, 0.1);
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
     }
     """)
   
     include(ThemeBase)
   end
   ```
2. `mix.exs`, `docs` groups, `"Basic Template - Themes"`: replace
   ```
               Aurora.Uix.Templates.Basic.Themes.BaseVariables,
               Aurora.Uix.Templates.Basic.Themes.VitreousMarble,
   ```
   with
   ```
               Aurora.Uix.Templates.Basic.Themes.BaseVariables,
               Aurora.Uix.Templates.Basic.Themes.BlueGraphite,
               Aurora.Uix.Templates.Basic.Themes.VitreousMarble,
   ```
3. `config/test.exs` keeps `theme_name: :vitreous_marble`; `Aurora.Uix.Templates.Basic.default_theme_name/0` keeps returning `:white_charcoal`.
4. Run `mix auix.gen.stylesheet`: `ThemeHelper.generate_variables_stylesheet/0` emits the `:root_colors` of every registered theme, so `assets/css/auix-variables.css` gains the `[data-theme-name="blue_graphite"]` blocks.

##### Acceptance criteria
- [x] AC-1: `ThemeHelper.registered_themes()` maps `:blue_graphite` to `Aurora.Uix.Templates.Basic.Themes.BlueGraphite`, so `config :aurora_uix, theme_name: :blue_graphite` selects it.
- [x] AC-2: Every `--auix-color-*` and `--auix-ring-*` variable White Charcoal declares, Blue Graphite declares too, with a `--dark--` value and a switch line in both dark blocks.
- [x] AC-3: Blue Graphite light uses `#0F172A` with white text for the primary and dark uses `#E6E9EF` with `#0C111D` text.
- [x] AC-4: White Charcoal remains the default theme: `Aurora.Uix.Templates.Basic.default_theme_name()` is `:white_charcoal`.
- [x] AC-5: The variables stylesheet carries a `[data-theme-name="blue_graphite"]` block.
- [x] AC-7: Blue Graphite's variables never leak into another theme: every `:root` / `:host` selector of its `:root_colors` is scoped by `[data-theme-name="blue_graphite"]`, so a host on White Charcoal keeps White Charcoal's values.
- [x] AC-6: Blue Graphite matches the Light and Dark pages of its mockup (visual — no red test; verified by switching `config/test.exs` to `theme_name: :blue_graphite`, running `mix auix.gen.stylesheet` and the demo server `iex -S mix run test/start_test_server.exs`, then reverting the config).

##### Test ports
- Theme rules (pure, no DB): `BlueGraphite.rule(:root_colors)`, `WhiteCharcoal.rule(:root_colors)`, `ThemeHelper.registered_themes/0`, `ThemeHelper.generate_variables_stylesheet/0` — the issue names the theme rules test as the coverage.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/templates/theme_rules_test.exs`, new `describe "Blue Graphite"` | `alias Aurora.Uix.Templates.Basic.Themes.BlueGraphite`, `alias Aurora.Uix.Templates.ThemeHelper` | `test/cases/templates/theme_rules_test.exs` | `"is registered as :blue_graphite"` | `ThemeHelper.registered_themes()[:blue_graphite] == BlueGraphite` and `BlueGraphite.theme_name() == :blue_graphite` |
| AC-2 | same describe | `names = ~r/^\s*--((?:auix-color\|auix-ring)-[a-z0-9-]+):/m \|> Regex.scan(WhiteCharcoal.rule(:root_colors), capture: :all_but_first) \|> List.flatten() \|> Enum.uniq()` | `test/cases/templates/theme_rules_test.exs` | `"declares every White Charcoal color, light and dark"` | for each name: `css =~ ~r/^\s*--#{name}: (#\|rgba\()/m`, `css =~ "--dark--#{name}: "`, `length(String.split(css, "--#{name}: var(--dark--#{name});")) == 3`, where `css = BlueGraphite.rule(:root_colors)` |
| AC-3 | same describe | `BlueGraphite.rule(:root_colors)` | `test/cases/templates/theme_rules_test.exs` | `"uses a navy primary, light and dark"` | `=~ "--auix-color-bg-default--reverted: #0F172A;"`, `=~ "--auix-color-text-on-accent: #FFFFFF;"`, `=~ "--dark--auix-color-bg-default--reverted: #E6E9EF;"`, `=~ "--dark--auix-color-text-on-accent: #0C111D;"` |
| AC-4 | same describe | — | `test/cases/templates/theme_rules_test.exs` | `"leaves White Charcoal as the default theme"` | `Aurora.Uix.Templates.Basic.default_theme_name() == :white_charcoal` |
| AC-5 | same describe | `ThemeHelper.generate_variables_stylesheet()` | `test/cases/templates/theme_rules_test.exs` | `"reaches the variables stylesheet"` | `=~ ~s([data-theme-name="blue_graphite"])` |
| AC-7 | same describe | `BlueGraphite.rule(:root_colors)` | `test/cases/templates/theme_rules_test.exs` | `"scopes every selector to its theme name"` | `~r/(?::root\|:host)[^,{]*/ \|> Regex.scan(css) \|> List.flatten()` is not empty and every match contains `[data-theme-name="blue_graphite"]` |

In the tables, `\|` stands for `|`.

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Themes.BlueGraphite` at `lib/aurora_uix/templates/basic/themes/blue_graphite.ex` — new; `include(ThemeBase)`.
2. Components: none.
3. Theme: `rule(:root_colors)` of the new module; no `auix-*` class rule. Regenerate with `mix auix.gen.stylesheet`.
4. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-2:end -->
<!-- section:UI-3:start -->
### UI-3 — UI · form controls
Depends on: UI-1

#### Documentation references
- `guides/customization/styling.md § Class reference` (rows `.auix-input` … `.auix-fieldset`), `§ Variable reference › Colors › Component aliases`

#### Implementation details

Layout types: `:form` and `:show` (every `<.input>` they render); `:index` filter inputs keep their `.auix-filter-*` rules. Theme CSS plus one sanitizer change — no markup changes, no backend code.

Every text input reaches the browser with `class="auix-input"` (`auix-input--errors` when the field has errors): `CoreComponents.input/1` writes its own `class` before `{@rest}`, so the `class="auix-form-field-input"` `DefaultRenderer.render/1` passes arrives as a second, ignored `class` attribute. This section styles `.auix-input`, `.auix-input--errors`, `.auix-textarea`, `.auix-textarea--errors`, `.auix-select` and `.auix-checkbox`; `rule(:auix_form_field_input)` stays as it is. The show view renders its inputs with `disabled={true}` (`DefaultRenderer.default_render_input/1`, `:show` clause), so the read-only look is keyed on `.auix-show-content … :disabled` as well as on `[readonly]`.

Mobile is `max-width: #{breakpoint(:sm)}`, the breakpoint the existing `.auix-input` and `.auix-textarea` mobile rules use.

The stylesheet emits every rule through `CssSanitizer.sanitize_css/1` (`lib/aurora_uix/templates/theme_helper.ex`, `style/2`). No entry of its `@allowed_properties` matches `resize`, so `do_sanitize_declarations/1` drops the `resize: vertical;` and `resize: none;` declarations of step 2.1 today. Step 5 admits `resize` with a fixed value set.

1. `lib/aurora_uix/templates/basic/themes/theme_base.ex`, `rule(:root_color_aliases, ...)`:
   1. Replace `    --auix-color-input-border-focus: var(--auix-color-border-focus);` with `    --auix-color-input-border-focus: var(--auix-color-focus-ring);`.
   2. Replace `    --auix-color-textarea-border-focus: var(--auix-color-border-focus);` with `    --auix-color-textarea-border-focus: var(--auix-color-focus-ring);`.
   3. Replace `    --auix-color-select-border-focus: var(--auix-color-border-focus);` with `    --auix-color-select-border-focus: var(--auix-color-focus-ring);`.
   4. Replace `    --auix-color-checkbox-label-text: var(--auix-color-text-secondary);` with:
      ```
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
      ```
   New-name evidence: `rg -n -e 'checkbox-accent' -e 'toggle-on' -e 'toggle-off' -e 'toggle-knob' -e 'input-bg' -e 'input-border-disabled' -e 'input-text-disabled' lib test` returns nothing.

2. `lib/aurora_uix/templates/basic/themes/base.ex` — replace the whole heredoc of each rule below with the CSS given. `#{breakpoint(:sm)}` and `#{import_rule(...)}` are interpolations inside the Elixir heredoc, as in the current rules.
   1. `rule(:_auix_textarea, ...)`:
      ```css
      .auix-textarea {
        box-sizing: border-box;
        display: block;
        min-height: 5.25rem;
        margin: 0;
        padding: var(--auix-padding-default) var(--auix-padding-control);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-default);

        font-family: inherit;
        font-size: var(--auix-font-size-caption);
        line-height: var(--auix-line-height-default);
        resize: vertical;

        color: var(--auix-color-textarea-text);
        background-color: var(--auix-color-input-bg);
        caret-color: var(--auix-color-textarea-text);
      }

      .auix-textarea:focus {
        outline: none;
        box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
      }

      .auix-textarea:disabled {
        background-color: var(--auix-color-input-bg-disabled);
        border-color: var(--auix-color-input-border-disabled);
        color: var(--auix-color-input-text-disabled);
        cursor: not-allowed;
      }

      .auix-textarea[readonly],
      .auix-show-content .auix-textarea:disabled {
        background-color: var(--auix-color-input-bg-readonly);
        border-color: var(--auix-color-input-border-disabled);
        color: var(--auix-color-textarea-text);
        resize: none;
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-textarea {
          font-size: var(--auix-font-size-input-mobile);
          line-height: var(--auix-line-height-relaxed);
        }
      }
      ```
   2. `rule(:_auix_input, ...)`:
      ```css
      .auix-input {
        box-sizing: border-box;
        height: var(--auix-control-height);
        margin: 0;
        padding: 0 var(--auix-padding-control);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-default);

        font-size: var(--auix-font-size-caption);
        color: var(--auix-color-input-text);
        background-color: var(--auix-color-input-bg);
        caret-color: var(--auix-color-input-text);
      }

      .auix-input:focus {
        outline: none;
        box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
      }

      .auix-input:disabled {
        background-color: var(--auix-color-input-bg-disabled);
        border-color: var(--auix-color-input-border-disabled);
        color: var(--auix-color-input-text-disabled);
        cursor: not-allowed;
      }

      .auix-input[readonly],
      .auix-show-content .auix-input:disabled {
        background-color: var(--auix-color-input-bg-readonly);
        border-color: var(--auix-color-input-border-disabled);
        color: var(--auix-color-input-text);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-input {
          height: var(--auix-touch-target-size);
          font-size: var(--auix-font-size-input-mobile);
        }
      }
      ```
      `rule(:auix_input)`, `rule(:auix_input__errors)`, `rule(:auix_textarea)` and `rule(:auix_textarea__errors)` keep their current CSS: each imports the base rule renamed and adds its `border-color` and `:focus` border. The `:disabled` and read-only `border-color` declarations above carry two classes of specificity and win over those single-class `border-color` declarations.
   3. `rule(:auix_select, ...)`:
      ```css
      .auix-select {
        box-sizing: border-box;
        height: var(--auix-control-height);
        margin: 0;
        padding: 0 var(--auix-padding-control);

        border-radius: var(--auix-border-radius-default);
        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-color: var(--auix-color-select-border);

        appearance: none;
        -webkit-appearance: none;
        -moz-appearance: none;
        background-position: right var(--auix-padding-control) center;
        background-repeat: no-repeat;
        background-size: var(--auix-box-size-unit) var(--auix-box-size-unit);
        background-color: var(--auix-color-input-bg);

        font-size: var(--auix-font-size-caption);
        color: var(--auix-color-input-text);
      }
      .auix-select:not(:disabled) {
        background-image: url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M6 9L12 15L18 9' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
        padding-right: 2.25rem;
      }
      .auix-select:disabled {
        background-image: none;
        background-color: var(--auix-color-input-bg-disabled);
        border-color: var(--auix-color-input-border-disabled);
        color: var(--auix-color-input-text-disabled);
        cursor: not-allowed;
      }
      .auix-show-content .auix-select:disabled {
        background-color: var(--auix-color-input-bg-readonly);
        color: var(--auix-color-input-text);
      }
      .auix-select[multiple] {
        height: auto;
        padding: var(--auix-padding-medium) var(--auix-padding-control);
        background-image: none;
      }

      .auix-select:focus {
        border-color: var(--auix-color-select-border-focus);
        outline: none;
        box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-select {
          height: var(--auix-touch-target-size);
          font-size: var(--auix-font-size-input-mobile);
        }
        .auix-select[multiple] {
          height: auto;
        }
      }
      ```
      The `background-image` URL is the current one, copied unchanged.
   4. `rule(:auix_fieldset, ...)`:
      ```css
      .auix-fieldset {
        display: flex;
        flex-direction: column;
        gap: var(--auix-gap-label);

        min-width: 0;
        margin: 0;
        padding: 0;
        border-width: 0;
        font-size: var(--auix-font-size-caption);
      }
      ```
   5. `rule(:auix_checkbox, ...)`:
      ```css
      .auix-checkbox {
        display: inline-block;
        vertical-align: middle;
        flex-shrink: 0;

        width: var(--auix-checkbox-size);
        height: var(--auix-checkbox-size);
        margin: 0;
        padding: 0;

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-small);
        border-color: var(--auix-color-checkbox-border);
        background-color: var(--auix-color-bg-default);
        color: var(--auix-color-checkbox-text);
        accent-color: var(--auix-color-checkbox-accent);

        box-shadow: none;
        outline: none;
        background-image: none;
      }

      .auix-checkbox:focus-visible {
        box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
      }

      .auix-checkbox:disabled {
        background-color: var(--auix-color-bg-light);
        color: var(--auix-color-text-secondary);

        opacity: var(--auix-opacity-100);
        cursor: not-allowed;
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-checkbox {
          width: var(--auix-checkbox-size-mobile);
          height: var(--auix-checkbox-size-mobile);
        }
      }
      ```
   6. `rule(:auix_checkbox_label, ...)` (the current `gap: var(auix-gap-default)` lacks the `--` prefix and never applied):
      ```css
      .auix-checkbox-label {
        display: flex;
        align-items: center;
        gap: var(--auix-gap-medium);
        font-size: var(--auix-font-size-caption);
        color: var(--auix-color-checkbox-label-text);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-checkbox-label {
          min-height: var(--auix-touch-target-size);
        }
      }
      ```
   7. `rule(:auix_label, ...)`:
      ```css
      .auix-label {
        font-size: var(--auix-font-size-label);
        font-weight: var(--auix-font-weight-medium);
        color: var(--auix-color-label-text);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-label {
          font-size: var(--auix-font-size-caption);
        }
      }
      ```
   8. `rule(:auix_error_message, ...)`:
      ```css
      .auix-error-message {
        display: flex;
        flex-direction: row;
        justify-content: flex-start;
        align-items: center;
        gap: var(--auix-gap-label);

        margin: 0;
        font-size: var(--auix-font-size-small);
        line-height: 1rem;
        color: var(--auix-color-error-text-default);
      }

      .auix-error-message .auix-icon-size-5 {
        flex-shrink: 0;
        width: 0.875rem;
        height: 0.875rem;
      }
      ```
      `CoreComponents.error/1` keeps rendering `<.icon name="hero-exclamation-circle-mini" class="auix-icon-size-5" />`; the two-class selector sizes it to 14px.
   9. `rule(:auix_form_field_container, ...)`:
      ```css
      .auix-form-field-container {
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        width: stretch;
      }
      .auix-form-field-container > * {
        flex: 1;
      }
      .auix-form-field-container .auix-input,
      .auix-form-field-container .auix-input--errors,
      .auix-form-field-container .auix-textarea,
      .auix-form-field-container .auix-textarea--errors,
      .auix-form-field-container .auix-select {
        width: 100%;
      }
      ```
   10. `rule(:auix_toggle_pill, ...)`:
       ```css
       .auix-checkbox.auix-toggle-switch {
         appearance: none;
         -webkit-appearance: none;
         align-self: flex-start;
         width: var(--auix-toggle-width);
         height: var(--auix-toggle-height);
         margin: 0;
         border: none;
         border-radius: var(--auix-border-radius-round);
         background-color: var(--auix-color-toggle-off);
         background-image: radial-gradient(circle 0.625rem at 0.75rem 0.75rem, var(--auix-color-toggle-knob) 100%, transparent 0);
         background-repeat: no-repeat;
         box-shadow: none;
         cursor: pointer;
         transition: background-color 0.2s ease, background-position 0.2s ease;
       }
       .auix-checkbox.auix-toggle-switch:checked {
         background-color: var(--auix-color-toggle-on);
         background-position: 1.25rem 0;
       }
       .auix-checkbox.auix-toggle-switch:disabled {
         opacity: var(--auix-opacity-100);
         cursor: default;
       }
       ```

3. New file `test/cases/templates/theme_framing_test.exs` (`rg -l 'ThemeFramingTest' test` returns nothing): module `Aurora.Uix.Templates.ThemeFramingTest`, `use ExUnit.Case, async: true`, `alias Aurora.Uix.Templates.Basic.Themes.Base`, `alias Aurora.Uix.Templates.Basic.Themes.ThemeBase`. UI-4, UI-5 and UI-6 add their own `describe` blocks to it.

4. New file `test/cases_live/form_controls_test.exs` (`rg -l 'FormControlsTest' test` returns nothing): module `Aurora.UixWeb.Test.FormControlsTest` with `use Aurora.UixWeb.Test.UICase, :phoenix_case`, `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`, `auix_resource_metadata(:product, context: Inventory, schema: Product)` and
   ```
   auix_create_ui do
     edit_layout :product do
       stacked([:reference, :name, :description, :quantity_initial])
     end

     show_layout :product do
       stacked([:reference, :name, :description])
     end
   end
   ```
   Data: `delete_all_inventory_data()` then `create_sample_products(1, :test)`. Route: in `test/support/app_web/routes.ex`, after the `FlashKindsTest.Product` entry UI-1 adds, add
   ```
           RoutesHelper.register_crud(
             FormControlsTest.Product,
             "form-controls-products"
           )
   ```

5. `lib/aurora_uix/templates/css_sanitizer.ex`:
   1. `@allowed_properties` — replace
      ```
                              # --- Browser behavior ---
                              "appearance",
      ```
      with
      ```
                              # --- Browser behavior ---
                              "^resize$",
                              "appearance",
      ```
      `allowed?/2` compiles each entry as an unanchored regex; the `^…$` anchors keep the entry to the exact property `resize`.
   2. `do_sanitize_declarations/1` — replace
      `      if Enum.any?(@allowed_properties, &allowed?(&1, property)) do`
      with
      ```
            if Enum.any?(@allowed_properties, &allowed?(&1, property)) and
                 allowed_value?(property, String.trim(property_value)) do
      ```
   3. After `allowed?/2`, at the end of the module, add the new private function (`rg -n 'allowed_value' lib` returns nothing):
      ```elixir
        # Properties whose values are restricted to a fixed grammar; every other allowed property
        # takes any value.
        @spec allowed_value?(binary(), binary()) :: boolean()
        defp allowed_value?("resize", value),
          do: value in ~w(none block both vertical horizontal inline)

        defp allowed_value?(_property, _value), do: true
      ```
      The match is exact and case-sensitive: `auto`, `inherit`, `Vertical` and `vertical !important` drop the declaration.
   4. `@moduledoc`, `Constraints:` list — after the line `  - Custom properties must follow --auix-[a-z-]+ naming convention` add the line `  - resize accepts only the values none, block, both, vertical, horizontal and inline; any other value drops the declaration`.

6. New file `test/cases/templates/css_sanitizer_test.exs` (`rg -l 'CssSanitizerTest' test` returns nothing): module `Aurora.Uix.Templates.CssSanitizerTest`, `use ExUnit.Case, async: true`, `alias Aurora.Uix.Templates.Basic.Themes.Base`, `alias Aurora.Uix.Templates.CssSanitizer`. UI-5 adds its own `describe` block to it.

##### Acceptance criteria
- [x] AC-1: An input, a select and a text area are 40px tall (`--auix-control-height`) with an 8px radius on desktop, and 44px tall (`--auix-touch-target-size`) with a 16px font below the `sm` breakpoint; a multiple select keeps its natural height.
- [x] AC-2: Each focused input, select and text area shows the focus border plus a 3px ring in `--auix-color-focus-ring-halo`.
- [x] AC-3: A disabled form input uses the disabled fill, border and text; an input in the show view, which is disabled, uses the read-only tinted fill and the primary text color instead.
- [x] AC-4: A field error shows the message left-aligned under the field, in the error text color, with a 14px icon.
- [x] AC-5: A checkbox is 18px on desktop and 20px on mobile, and its checked state uses `--auix-color-checkbox-accent` (the primary color); a toggle is 44×24px, off in `--auix-color-toggle-off` and on in `--auix-color-toggle-on`.
- [x] AC-6: Given the `:product` edit form at `/form-controls-products/:id/edit`, the text inputs render inside `.auix-form-field-container` with `class="auix-input"`, and given the show modal at `/form-controls-products/:id/show`, they render inside `.auix-show-content` as disabled `.auix-input` elements — the markup the read-only selector of step 2.2 matches.
- [x] AC-7: Given a submitted edit form whose `name` is blank, the error message renders as `.auix-error-message` under the field.
- [x] AC-8: The controls match the "Field inputs" and "Text area, select and choices" boards of the mockups in every state (visual — no red test; verified by the guide images reviewed in UI-7).
- [x] AC-9: The sanitized text area rule keeps `resize: vertical;` and the read-only text area's `resize: none;`.
- [x] AC-10: The sanitizer keeps a `resize` declaration whose value is one of `none`, `block`, `both`, `vertical`, `horizontal`, `inline`, and drops a `resize` declaration with any other value (`auto`, `inherit`, `Vertical`, `vertical !important`, `url(x)`) while keeping the rule's other declarations.

##### Test ports
- Route `"/form-controls-products"` registered in `routes.ex` via `register_crud/2` · layout types `:form`, `:show` · observable: `has_element?/2` on `.auix-form-field-container input.auix-input[name='product[name]']`, `.auix-show-content input.auix-input[disabled]`, `.auix-error-message`.
- Theme rules (pure, no DB): `Base.rule/1`, `ThemeBase.rule(:root_color_aliases)`.
- Sanitizer (pure, no DB): `CssSanitizer.sanitize_css/1`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (step 3), `describe "form controls"` | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"inputs, selects and text areas share the control frame"` | `Base.rule(:_auix_input) =~ "height: var(--auix-control-height)"`, `=~ "border-radius: var(--auix-border-radius-default)"`, `=~ ~r/@media \(max-width: 640px\) \{\s*\.auix-input \{\s*height: var\(--auix-touch-target-size\);/`; `Base.rule(:auix_select) =~ "height: var(--auix-control-height)"` and `=~ ~r/\.auix-select\[multiple\] \{\s*height: auto;/`; `Base.rule(:_auix_textarea) =~ "resize: vertical"` |
| AC-2 | same describe | `Base.rule/1`, `ThemeBase.rule(:root_color_aliases)` | `test/cases/templates/theme_framing_test.exs` | `"a focused control shows the 3px halo"` | each of `:_auix_input`, `:_auix_textarea`, `:auix_select` `=~ "box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo)"`; aliases `=~ "--auix-color-input-border-focus: var(--auix-color-focus-ring);"` |
| AC-3 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"disabled and read-only controls differ"` | `Base.rule(:_auix_input) =~ ~r/\.auix-input:disabled \{\s*background-color: var\(--auix-color-input-bg-disabled\);/` and `=~ ~r/\.auix-input\[readonly\],\s*\.auix-show-content \.auix-input:disabled \{\s*background-color: var\(--auix-color-input-bg-readonly\);/` |
| AC-4 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"the error message sits left with a small icon"` | `Base.rule(:auix_error_message) =~ "justify-content: flex-start"` and `=~ ".auix-error-message .auix-icon-size-5"` |
| AC-5 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"checkboxes and toggles use the primary color"` | `Base.rule(:auix_checkbox) =~ "accent-color: var(--auix-color-checkbox-accent)"`, `=~ "width: var(--auix-checkbox-size-mobile)"`; `Base.rule(:auix_toggle_pill) =~ "background-color: var(--auix-color-toggle-on)"` and `refute =~ "#16a34a"` |
| AC-6 | new file (step 4) | `create_sample_products(1, :test)`, `live(conn, "/form-controls-products/#{id}/edit")` and `live(conn, "/form-controls-products/#{id}/show")` | `test/cases_live/form_controls_test.exs` | `"form inputs and show inputs carry the classes the theme targets"` | `has_element?(view, ".auix-form-field-container input.auix-input[name='product[name]']")`; on the show view `has_element?(view, ".auix-show-content input.auix-input[disabled]")` |
| AC-7 | same file | edit view, `view \|> form("#auix-product-form", product: %{name: ""}) \|> render_submit()` | `test/cases_live/form_controls_test.exs` | `"a blank required field shows the error message"` | `has_element?(view, "#auix-product-form .auix-error-message")` |
| AC-9 | new file (step 6), `describe "resize"` | `Base.rule/1`, `CssSanitizer.sanitize_css/1` | `test/cases/templates/css_sanitizer_test.exs` | `"the text area rule keeps its resize declarations"` | `css = CssSanitizer.sanitize_css(Base.rule(:_auix_textarea))`; `css =~ "resize: vertical;"` and `css =~ "resize: none;"` |
| AC-10 | same describe | `CssSanitizer.sanitize_css/1` | `test/cases/templates/css_sanitizer_test.exs` | `"resize keeps the six keywords and drops any other value"` | for each `v` of `~w(none block both vertical horizontal inline)`, `CssSanitizer.sanitize_css(".a { resize: #{v}; }") == ".a { resize: #{v}; }"`; for each `v` of `["auto", "inherit", "Vertical", "vertical !important", "url(x)"]`, `CssSanitizer.sanitize_css(".a { color: red; resize: #{v}; }") == ".a { color: red; }"` |

In the tables, `\|` stands for `|`.

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Themes.ThemeBase`, `Base` — modified (rules only). `Aurora.Uix.Templates.CssSanitizer` — modified: `@allowed_properties`, `do_sanitize_declarations/1`, `@moduledoc`, new private `allowed_value?/2`.
2. Components: none changed; `CoreComponents.input/1`, `label/1` and `error/1` render the classes styled here.
3. Theme: `.auix-textarea` (`rule(:_auix_textarea)`), `.auix-input` (`rule(:_auix_input)`), `.auix-select` (`rule(:auix_select)`), `.auix-fieldset` (`rule(:auix_fieldset)`), `.auix-checkbox` (`rule(:auix_checkbox)`), `.auix-checkbox-label` (`rule(:auix_checkbox_label)`), `.auix-label` (`rule(:auix_label)`), `.auix-error-message` (`rule(:auix_error_message)`), `.auix-form-field-container` (`rule(:auix_form_field_container)`), `.auix-toggle-switch` (`rule(:auix_toggle_pill)`). Regenerate with `mix auix.gen.stylesheet`.
4. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->
<!-- section:UI-4:start -->
### UI-4 — UI · groups, embedded records, sections and containers
Depends on: UI-3

#### Documentation references
- `guides/customization/styling.md § Class reference`, `§ Recipe table`, `§ Variable reference › Colors › Component aliases`
- `guides/core/layouts.md` (groups, sections and inline / stacked layouts render through these classes; no text changes)

#### Implementation details

Layout types: `:form` and `:show`; `:index` only where a card body holds a group. CSS only — every frame is drawn on the markup the renderers emit today:

| Element | Markup (unchanged) | Title bar |
|---|---|---|
| Group | `Renderer.render/1` group clause: `div.auix-group-container > h3.auix-group-title` | `.auix-group-title`, pulled to the frame edges with negative margins |
| Embedded record | `EmbedsOneRenderer.render/1`: `div.auix-embeds-one-container > header.auix-header` | `.auix-header-title` inside that header |
| One-to-one record | `OneToOne.render/1`: `div.auix-one-to-one-container > header.auix-header` | same as the embedded record |
| Empty record | `span.auix-embeds-one-empty-msg` / `span.auix-one-to-one-empty-msg` inside the header's `p.auix-header-subtitle` | dashed box below the title bar |
| Section tabs | `SectionsRenderer.render/1`: `div.auix-sections-tab-container > button.auix-sections-tab-button--active / --inactive`, then `div.auix-sections-content` | — |

A nested group is `.auix-group-container .auix-group-container`; a nested section is a `.auix-sections-tab-button--*` element and an `.auix-sections-content` inside an `.auix-sections-content`.

1. `lib/aurora_uix/templates/basic/themes/theme_base.ex`, `rule(:root_color_aliases, ...)`:
   1. Replace the lines from `    /* sections / tabs */` through `    --auix-color-group-container-bg: transparent;` (this drops the "Flat by default" comment) with:
      ```
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
      ```
   2. Replace `    --auix-color-embeds-border: var(--auix-color-border-secondary);` with:
      ```
          --auix-color-embeds-border: var(--auix-color-border-secondary);
          --auix-color-embeds-empty-border: var(--auix-color-border-primary);
          --auix-color-embeds-empty-text: var(--auix-color-text-tertiary);
      ```
   New-name evidence: `rg -n -e 'sections-tab-inactive-text' -e 'sections-tab-hover-bg' -e 'sections-content-bg' -e 'show-content-border' -e 'form-container-border' -e 'group-title-border' -e 'embeds-empty' lib test` returns nothing.

2. `lib/aurora_uix/templates/basic/themes/base.ex` — replace the whole heredoc of each rule below with the CSS given.
   1. `rule(:_auix_sections_tab_button, ...)`:
      ```css
      .auix-sections-tab-button {
        flex-shrink: 0;
        height: var(--auix-control-height);
        padding: 0 var(--auix-padding-panel);
        border: var(--auix-border-width-default) var(--auix-border-style-default) transparent;
        border-radius: var(--auix-border-radius-default) var(--auix-border-radius-default) 0 0;
        font-size: var(--auix-font-size-caption);
        white-space: nowrap;
        cursor: pointer;
      }

      .auix-sections-tab-button:focus-visible {
        outline: none;
        border-color: var(--auix-color-focus-ring);
        box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-sections-tab-button {
          height: var(--auix-touch-target-size);
          padding: 0 0.875rem;
        }
      }
      ```
   2. `rule(:auix_sections_tab_container, ...)`:
      ```css
      .auix-sections-tab-container {
        position: relative;
        z-index: 1;
        display: flex;
        flex-direction: row;
        gap: var(--auix-gap-minimal);
        margin-top: var(--auix-margin-medium);
        margin-bottom: calc(-1 * var(--auix-border-width-default));
        padding: var(--auix-focus-ring-width) var(--auix-padding-control) 0;
        overflow-x: auto;
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-sections-tab-container {
          padding: var(--auix-focus-ring-width) var(--auix-padding-medium) 0;
        }
      }
      ```
   3. `rule(:auix_sections_tab_button__active, ...)`:
      ```
      /* auix-sections-tab-button--active */
      #{import_rule(:_auix_sections_tab_button, :auix_sections_tab_button__active)}

      .auix-sections-tab-button--active {
        font-weight: var(--auix-font-weight-bold);
        color: var(--auix-color-sections-tab-active-text);
        background-color: var(--auix-color-sections-tab-active-bg);
        border-color: var(--auix-color-sections-tab-active-border);
        border-bottom-color: var(--auix-color-sections-tab-active-bg);
      }
      ```
   4. `rule(:auix_sections_tab_button__inactive, ...)`:
      ```
      /* auix-sections-tab-button--inactive */
      #{import_rule(:_auix_sections_tab_button, :auix_sections_tab_button__inactive)}

      .auix-sections-tab-button--inactive {
        font-weight: var(--auix-font-weight-medium);
        color: var(--auix-color-sections-tab-inactive-text);
        background-color: var(--auix-color-sections-tab-inactive-bg);
      }

      .auix-sections-tab-button--inactive:hover {
        color: var(--auix-color-sections-tab-active-text);
        background-color: var(--auix-color-sections-tab-hover-bg);
      }
      ```
   5. `rule(:auix_sections_content, ...)`:
      ```css
      .auix-sections-content {
        padding: var(--auix-padding-container);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-color: var(--auix-color-sections-content-border);
        border-radius: var(--auix-border-radius-medium);
        background-color: var(--auix-color-sections-content-bg);
      }

      .auix-sections-content .auix-sections-tab-button--active,
      .auix-sections-content .auix-sections-tab-button--inactive {
        height: var(--auix-control-height-compact);
        padding: 0 0.875rem;
        font-size: var(--auix-font-size-label);
      }

      .auix-sections-content .auix-sections-content {
        padding: var(--auix-padding-panel);
        border-radius: var(--auix-border-radius-nested);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-sections-content {
          padding: var(--auix-padding-panel);
        }
      }
      ```
   6. `rule(:auix_group_container, ...)`:
      ```css
      .auix-group-container {
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        width: stretch;

        gap: var(--auix-gap-xl);
        padding: var(--auix-padding-panel);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-medium);
        border-color: var(--auix-color-group-container-border);

        background-color: var(--auix-color-group-container-bg);
      }

      .auix-group-container > * {
        flex: 1;
      }

      .auix-group-container .auix-group-container {
        border-radius: var(--auix-border-radius-nested);
      }
      ```
   7. `rule(:auix_group_title, ...)`:
      ```css
      .auix-group-container > .auix-group-title {
        flex: none;
      }

      .auix-group-title {
        margin: calc(-1 * var(--auix-padding-panel)) calc(-1 * var(--auix-padding-panel)) 0;
        padding: var(--auix-padding-default) var(--auix-padding-panel);
        border-bottom: var(--auix-border-width-default) var(--auix-border-style-default) var(--auix-color-group-title-border);
        font-weight: var(--auix-font-weight-bold);
        font-size: var(--auix-font-size-group-title);
        line-height: var(--auix-line-height-default);
      }
      ```
   8. `rule(:auix_embeds_one_container, ...)`:
      ```css
      .auix-embeds-one-container {
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        width: stretch;

        gap: var(--auix-gap-xl);
        padding: var(--auix-padding-panel);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-medium);
        border-color: var(--auix-color-embeds-border);
        background-color: var(--auix-color-embeds-bg);
      }
      .auix-embeds-one-container > * {
        flex: 1;
      }
      .auix-embeds-one-container > .auix-header {
        flex: none;
        margin: calc(-1 * var(--auix-padding-panel)) calc(-1 * var(--auix-padding-panel)) 0;
      }
      .auix-embeds-one-container > .auix-header .auix-header-title {
        padding: var(--auix-padding-default) var(--auix-padding-panel);
        border-bottom: var(--auix-border-width-default) var(--auix-border-style-default) var(--auix-color-embeds-border);
        font-size: var(--auix-font-size-caption);
        line-height: var(--auix-line-height-default);
      }
      .auix-embeds-one-container > .auix-header .auix-header-subtitle {
        margin: var(--auix-padding-panel) var(--auix-padding-panel) 0;
      }
      ```
   9. `rule(:auix_embeds_one_empty_msg, ...)`:
      ```css
      .auix-embeds-one-empty-msg {
        display: block;
        padding: var(--auix-padding-default) var(--auix-padding-control);
        border: var(--auix-border-width-default) dashed var(--auix-color-embeds-empty-border);
        border-radius: var(--auix-border-radius-default);
        background-color: var(--auix-color-bg-default);
        font-size: var(--auix-font-size-caption);
        font-style: var(--auix-font-style-mobile-viewmode);
        line-height: var(--auix-line-height-default);
        color: var(--auix-color-embeds-empty-text);
      }
      ```
   10. `rule(:auix_one_to_one_container, ...)`:
       ```
       /* auix-one-to-one-container */

       #{import_rule(:auix_embeds_one_container, :auix_one_to_one_container)}
       ```
   11. `rule(:auix_one_to_one_empty_msg, ...)`:
       ```
       /* auix-one-to-one-empty-msg */

       #{import_rule(:auix_embeds_one_empty_msg, :auix_one_to_one_empty_msg)}
       ```
       `ThemeHelper.rename_rule/3` turns `.auix-embeds-one-container` into `.auix-one-to-one-container` and `.auix-embeds-one-empty-msg` into `.auix-one-to-one-empty-msg`; the `.auix-header` selectors are copied unchanged.
   12. `rule(:auix_embeds_many_container, ...)` — delete its line `    box-shadow: var(--auix-shadow-default);`; nothing else changes.
   13. `rule(:auix_embeds_many_details, ...)`:
       ```css
       .auix-embeds-many-details {
         display: flex;
         flex-direction: column;
         gap: 0;

         padding: 0;
       }
       ```
   14. `rule(:auix_embeds_many_summary, ...)`:
       ```css
       .auix-embeds-many-summary {
         padding: var(--auix-padding-default) var(--auix-padding-control);
         font-size: var(--auix-font-size-caption);
         font-weight: var(--auix-font-weight-medium);
         line-height: var(--auix-line-height-default);
       }

       .auix-embeds-many-summary:hover {
         cursor: pointer;
       }
       ```
   15. `rule(:auix_embeds_many_content, ...)`:
       ```css
       .auix-embeds-many-content {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-large);
         padding: 0 var(--auix-padding-control) var(--auix-padding-control);
       }

       .auix-embeds-many-content > .auix-header .auix-header-title {
         font-size: var(--auix-font-size-caption);
       }
       ```
   16. `rule(:auix_embeds_many_entry_contents, ...)` — delete its line `    box-shadow: var(--auix-shadow-default);`; nothing else changes.
   17. `rule(:auix_form_container, ...)`:
       ```css
       .auix-form-container {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-container);

         padding: var(--auix-padding-container);
         border-width: var(--auix-border-width-default);
         border-style: var(--auix-border-style-default);
         border-color: var(--auix-color-form-container-border);
         border-radius: var(--auix-border-radius-medium);

         background-color: var(--auix-color-form-container-bg);
       }

       @media (max-width: #{breakpoint(:sm)}) {
         .auix-form-container {
           gap: var(--auix-gap-xl);
           padding: 0;
           border-width: 0;
         }
       }
       ```
   18. `rule(:auix_show_content, ...)`:
       ```
       /* auix-show-content */

       #{import_rule(:auix_index_container, :auix_show_content)}

       .auix-show-content {
         gap: var(--auix-gap-container);
         padding: var(--auix-padding-container);
         border-width: var(--auix-border-width-default);
         border-style: var(--auix-border-style-default);
         border-color: var(--auix-color-show-content-border);
         border-radius: var(--auix-border-radius-medium);
         box-shadow: none;
         background-color: var(--auix-color-show-content-bg);
       }

       @media (max-width: #{breakpoint(:sm)}) {
         .auix-show-content {
           gap: var(--auix-gap-xl);
           padding: 0;
           border-width: 0;
         }
       }
       ```
   19. `rule(:auix_show_container, ...)`:
       ```
       /* auix-show-container */

       #{import_rule(:auix_index_container, :auix_show_container)}

       @media (min-width: #{breakpoint(:md)}) {
         .auix-show-container {
           border-width: var(--auix-border-width-default);
           border-style: var(--auix-border-style-default);
           border-color: var(--auix-color-show-content-border);
           border-radius: var(--auix-border-radius-large);
           background-color: var(--auix-color-show-content-bg);
           box-shadow: var(--auix-shadow-lg);
         }
       }

       .auix-modal-focus-wrap .auix-show-container {
         padding: 0;
         border-width: 0;
         box-shadow: none;
       }
       ```
   20. `rule(:auix_simple_form_content, ...)`:
       ```css
       .auix-simple-form-content {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-xl);
         background-color: transparent;
       }
       ```
   21. `rule(:auix_header_title_container, ...)`:
       ```css
       .auix-header-title-container {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-default);
       }
       ```
   22. `rule(:auix_header_title, ...)`:
       ```css
       .auix-header-title {
         margin: 0;
         font-size: var(--auix-font-size-title);
         font-weight: var(--auix-font-weight-bold);
         line-height: var(--auix-line-height-title);
         color: var(--auix-color-header-title-text);
       }

       .auix-index-container > .auix-header .auix-header-title,
       .auix-index-container > .auix-header--top-actions .auix-header-title {
         font-size: var(--auix-font-size-page-title);
         line-height: 2rem;
       }

       @media (max-width: #{breakpoint(:sm)}) {
         .auix-header-title {
           font-size: var(--auix-font-size-subtitle);
           line-height: var(--auix-line-height-relaxed);
         }

         .auix-index-container > .auix-header .auix-header-title,
         .auix-index-container > .auix-header--top-actions .auix-header-title {
           font-size: var(--auix-font-size-title);
           line-height: var(--auix-line-height-title);
         }
       }
       ```
       The two `.auix-embeds-*` title selectors of steps 2.8 and 2.15 carry more classes, so the embedded and one-to-one title bars keep `--auix-font-size-caption` at every breakpoint.
   23. `rule(:auix_header_subtitle, ...)`:
       ```css
       .auix-header-subtitle {
         margin-top: 0;
         margin-bottom: 0;
         font-size: var(--auix-font-size-caption);
         line-height: var(--auix-line-height-default);
         color: var(--auix-color-header-subtitle-text);
       }
       ```
   24. `rule(:auix_inline_container, ...)`:
       ```css
       .auix-inline-container {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-xl);
       }

       @media (min-width: #{breakpoint(:md)}) {
         .auix-inline-container {
           flex-direction: row;
         }
       }
       ```
   25. `rule(:auix_stacked_container, ...)` (its current media query targets `.auix-inline-container` by mistake):
       ```css
       .auix-stacked-container {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-xl);
       }
       ```
   26. `rule(:auix_show_field, ...)`:
       ```css
       .auix-show-field {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-label);
       }
       ```

3. Tests: add `describe "containers"` to `test/cases/templates/theme_framing_test.exs` (created by UI-3); the LiveView rows amend two existing layout tests on their existing routes.

##### Acceptance criteria
- [x] AC-1: A group is a framed container (`--auix-color-group-container-border`, 12px radius, 16px padding) whose title is a title bar with a bottom border; a nested group uses the same frame with a 10px radius.
- [x] AC-2: An embedded record and a one-to-one record are tinted frames whose header title is the title bar.
- [x] AC-3: An empty embedded record and an empty one-to-one record each show "Field is empty" as a dashed box below the title bar.
- [x] AC-4: Section tabs are 40px folder tabs (44px below `sm`) attached to a bordered panel; the active tab's bottom border takes the panel background, so the tab joins the panel; tabs stay on one horizontal row and scroll horizontally when they overflow.
- [x] AC-5: A nested section uses 36px tabs with 13px text and a panel with 16px padding and a 10px radius.
- [x] AC-6: The form fields sit in a bordered container with the save button below it; below `sm` the container drops its border and padding. The show view's content follows the same frame, and inside a modal the show container adds no frame of its own.
- [x] AC-7: Given `/group-ui-layout-products/new`, a group renders as `div.auix-group-container > h3.auix-group-title`, the markup the title bar rule targets; given `/association/one_to_one/layout/products/:id/show` with no related record, `.auix-one-to-one-empty-msg` renders inside `.auix-one-to-one-container > .auix-header`.
- [x] AC-8: Groups, nested groups, embedded records and sections match the mockups' "Groups, nested groups and embedded records" and "Section tabs, with nested sections" boards on desktop and the mobile Form board (visual — no red test; verified by the guide images reviewed in UI-7).

##### Test ports
- Theme rules (pure, no DB): `Base.rule/1`, `ThemeBase.rule(:root_color_aliases)`.
- Existing routes `"/group-ui-layout-products"` and `"/association/one_to_one/layout/products"` · layout types `:form`, `:show` · observable: `has_element?/2` on the selectors in the Red tests table.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/templates/theme_framing_test.exs`, new `describe "containers"` | `Base.rule/1`, `ThemeBase.rule(:root_color_aliases)` | `test/cases/templates/theme_framing_test.exs` | `"a group is a framed container with a title bar"` | `Base.rule(:auix_group_container) =~ "border-radius: var(--auix-border-radius-medium)"`, `=~ ".auix-group-container .auix-group-container"`; `Base.rule(:auix_group_title) =~ "border-bottom: "`; aliases `=~ "--auix-color-group-container-border: var(--auix-color-border-secondary);"` |
| AC-2 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"embedded and one-to-one records share the title-bar frame"` | `Base.rule(:auix_embeds_one_container) =~ ".auix-embeds-one-container > .auix-header .auix-header-title"`; `Base.rule(:auix_one_to_one_container) =~ ".auix-one-to-one-container > .auix-header .auix-header-title"` |
| AC-3 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"an empty record shows a dashed box"` | `Base.rule(:auix_embeds_one_empty_msg) =~ "dashed"`; `Base.rule(:auix_one_to_one_empty_msg) =~ ".auix-one-to-one-empty-msg"` and `=~ "dashed"` |
| AC-4 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"section tabs join their panel"` | `Base.rule(:auix_sections_tab_button__active) =~ "border-bottom-color: var(--auix-color-sections-tab-active-bg)"`; `Base.rule(:auix_sections_tab_container) =~ "overflow-x: auto"` and `refute =~ "flex-direction: column"` |
| AC-5 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"nested sections use smaller tabs"` | `Base.rule(:auix_sections_content) =~ ~r/\.auix-sections-content \.auix-sections-tab-button--active,\s*\.auix-sections-content \.auix-sections-tab-button--inactive \{\s*height: var\(--auix-control-height-compact\);/` |
| AC-6 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"form and show content sit in a bordered container"` | `Base.rule(:auix_form_container) =~ "border-color: var(--auix-color-form-container-border)"` and `=~ ~r/@media \(max-width: 640px\) \{\s*\.auix-form-container \{[^}]*padding: 0;/`; `Base.rule(:auix_show_container) =~ ".auix-modal-focus-wrap .auix-show-container"` |
| AC-7 | amend `test/cases_live/group_ui_layout_test.exs` "Test groups" | its `live(conn, "/group-ui-layout-products/new")` | `test/cases_live/group_ui_layout_test.exs` | `"Test groups"` | add `assert has_element?(view, ~s(div[id^="auix-group-quantities-"] > h3.auix-group-title:first-child))` |
| AC-7 | amend `test/cases_live/association_one2one_ui_layout_test.exs` "renders the empty message when there is no child" | its `live(conn, "/association/one_to_one/layout/products/#{product.id}/show")` | `test/cases_live/association_one2one_ui_layout_test.exs` | `"renders the empty message when there is no child"` | replace its selector with `"#auix-one-to-one-product_barcode-show > .auix-header .auix-one-to-one-empty-msg"` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Themes.ThemeBase`, `Base` — modified (rules only).
2. Components: none changed.
3. Theme: `.auix-sections-tab-button` (`rule(:_auix_sections_tab_button)`), `.auix-sections-tab-container`, `.auix-sections-tab-button--active`, `.auix-sections-tab-button--inactive`, `.auix-sections-content`, `.auix-group-container`, `.auix-group-title`, `.auix-embeds-one-container`, `.auix-embeds-one-empty-msg`, `.auix-one-to-one-container`, `.auix-one-to-one-empty-msg`, `.auix-embeds-many-container`, `.auix-embeds-many-details`, `.auix-embeds-many-summary`, `.auix-embeds-many-content`, `.auix-embeds-many-entry-contents`, `.auix-form-container`, `.auix-show-content`, `.auix-show-container`, `.auix-simple-form-content`, `.auix-header-title-container`, `.auix-header-title`, `.auix-header-subtitle`, `.auix-inline-container`, `.auix-stacked-container`, `.auix-show-field` — each in its same-named `rule/1` clause. Regenerate with `mix auix.gen.stylesheet`.
4. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-4:end -->
<!-- section:UI-5:start -->
### UI-5 — UI · buttons, modal, unsaved-changes confirmation and record pager
Depends on: UI-4

#### Documentation references
- `guides/customization/styling.md § Class reference` (rows `.auix-button-default` … `.auix-button-badge`, `.auix-modal-focus-wrap`, `.auix-modal-close-button`, `.auix-discard-confirm*`), `§ Variable reference › Opacity`

#### Implementation details

Layout types: `:index`, `:form`, `:show` (buttons and the modal appear in all three). One markup change: the "Discard changes" button of `FormRenderer.render/1` gains the new `auix-button--danger` variant. Everything else is theme CSS, plus `content` in the CSS sanitizer. Backend-agnostic.

`<.button>` always renders `class={["auix-button-default", @class]}` (`CoreComponents.button/1`), so `.auix-button-default` carries the shared frame and the variant class carries only color, per `guides/customization/styling.md § Rule: one color class per element`. `.auix-button`, `.auix-button--alt`, `.auix-button-badge` and the new `.auix-button--danger` also import `_auix_button_default` renamed. LiveView adds the class `phx-submit-loading` to every button of a submitting form and disables it (`deps/phoenix_live_view/assets/js/phoenix_live_view/view.ts`, `disableForm/3` → `putRef(els, phxEvent, "submit", opts)`, which adds `phx-${eventType}-loading` to each element); the current `.auix-button[phx-submit-loading]` attribute selector never matches.

`CssSanitizer.sanitize_css/1`, which the stylesheet emits every rule through, drops every `content` declaration today: no entry of `@allowed_properties` matches `content`. Without `content: "";` the `.auix-button.phx-submit-loading::before` box of step 2.2 is never generated and the spinner never shows. Step 5 admits `content` with a plain-string value check, as a clause of the `allowed_value?/2` function UI-3 adds.

1. `lib/aurora_uix/templates/basic/themes/theme_base.ex`, `rule(:root_color_aliases, ...)` — replace the lines from `    /* buttons */` through `    --auix-color-button-iconized-bg-hover: var(--auix-color-bg-hover);` with:
   ```
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
   ```
   The danger fill is `--auix-color-icon-danger` because that variable holds the mockup's destructive red in every theme (White Charcoal `#BE123C`, Blue Graphite `#B42318` / `#F97066`), and the text is `--auix-color-text-on-accent`, which Blue Graphite dark sets to the issue's destructive button text `#0C111D`. New-name evidence: `rg -n -e 'button-disabled' -e 'button-danger' -e 'modal-close-border' -e 'modal-close-text' -e 'button--danger' lib test` returns nothing.

2. `lib/aurora_uix/templates/basic/themes/base.ex` — replace the whole heredoc of each rule below with the CSS given; add `rule(:auix_button__danger, ...)` directly after `rule(:auix_button__alt, ...)`.
   1. `rule(:_auix_button_default, ...)`:
      ```css
      .auix-button-default {
        box-sizing: border-box;
        display: inline-flex;
        flex-direction: row;
        align-items: center;
        justify-content: center;
        gap: var(--auix-gap-medium);

        height: var(--auix-control-height);
        padding: 0 var(--auix-padding-panel);

        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-radius: var(--auix-border-radius-default);

        font-size: var(--auix-font-size-caption);
        font-weight: var(--auix-font-weight-bold);
        white-space: nowrap;
      }

      .auix-button-default:focus-visible {
        outline: none;
        border-color: var(--auix-color-focus-ring);
        box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-button-default:has(> .auix-action-icon) {
          width: var(--auix-touch-target-size);
          height: var(--auix-touch-target-size);
          padding: 0;
          border-radius: var(--auix-border-radius-nested);
        }
      }
      ```
      Below `sm`, `CoreComponents.action_content/1` hides `.auix-action-label` and shows `.auix-action-icon`, so the `:has(> .auix-action-icon)` selector reaches exactly the buttons that become icon-only.
   2. `rule(:auix_button, ...)`:
      ```
      /* auix-button */
      #{import_rule(:_auix_button_default, :auix_button)}

      .auix-button {
        background-color: var(--auix-color-button-bg);
        border-color: var(--auix-color-button-bg);
        color: var(--auix-color-button-text);
        box-shadow: var(--auix-shadow-small);
        cursor: pointer;
      }

      .auix-button:hover {
        background-color: var(--auix-color-bg-hover--reverted);
        border-color: var(--auix-color-bg-hover--reverted);
      }

      .auix-button:active {
        color: var(--auix-color-text-on-accent-active);
      }

      .auix-button:disabled {
        background-color: var(--auix-color-button-disabled-bg);
        border-color: var(--auix-color-button-disabled-border);
        color: var(--auix-color-button-disabled-text);
        box-shadow: none;
        cursor: not-allowed;
      }

      .auix-button.phx-submit-loading {
        background-color: var(--auix-color-button-bg);
        border-color: var(--auix-color-button-bg);
        color: var(--auix-color-button-text);
        opacity: var(--auix-opacity-75);
        cursor: progress;
      }

      .auix-button.phx-submit-loading::before {
        content: "";
        width: 1rem;
        height: 1rem;
        border: 2px solid currentColor;
        border-right-color: transparent;
        border-radius: var(--auix-border-radius-round);
        animation: spin 1s linear infinite;
      }
      ```
      `@keyframes spin` is defined by `rule(:auix_animate_spin)`, which ships in every stylesheet.
   3. `rule(:auix_button__alt, ...)`:
      ```
      /* auix-button--alt */
      #{import_rule(:_auix_button_default, :auix_button__alt)}

      .auix-button--alt {
        background-color: var(--auix-color-button-alt-bg);
        color: var(--auix-color-button-alt-text);
        border-color: var(--auix-color-button-alt-border);
        cursor: pointer;
      }

      .auix-button--alt:hover {
        background-color: var(--auix-color-bg-hover);
      }

      .auix-button--alt:disabled {
        background-color: var(--auix-color-button-disabled-bg);
        border-color: var(--auix-color-button-disabled-border);
        color: var(--auix-color-button-disabled-text);
        cursor: not-allowed;
      }
      ```
   4. New `rule(:auix_button__danger, ...)`:
      ```
      /* auix-button--danger */
      #{import_rule(:_auix_button_default, :auix_button__danger)}

      .auix-button--danger {
        background-color: var(--auix-color-button-danger-bg);
        border-color: var(--auix-color-button-danger-bg);
        color: var(--auix-color-button-danger-text);
        cursor: pointer;
      }

      .auix-button--danger:hover {
        background-color: var(--auix-color-button-danger-bg-hover);
        border-color: var(--auix-color-button-danger-bg-hover);
      }

      .auix-button--danger:disabled {
        background-color: var(--auix-color-button-disabled-bg);
        border-color: var(--auix-color-button-disabled-border);
        color: var(--auix-color-button-disabled-text);
        cursor: not-allowed;
      }
      ```
   5. `rule(:auix_button_badge, ...)`:
      ```
      /* auix-button-badge */
      #{import_rule(:_auix_button_default, :auix_button_badge)}

      .auix-button-badge {
        height: auto;
        gap: 0;
        font-size: var(--auix-font-size-small);
        border-radius: var(--auix-border-radius-round);
        padding-top: 0;
        padding-bottom: 0;
        padding-left: var(--auix-padding-minimal);
        padding-right: var(--auix-padding-minimal);
      }
      ```
   6. `rule(:auix_button__iconized, ...)`:
      ```css
      .auix-button--iconized {
        height: auto;
        min-width: var(--auix-row-action-size);
        min-height: var(--auix-row-action-size);
        background-color: transparent;
        border: none;
        border-radius: var(--auix-border-radius-default);
        box-shadow: none;
        padding: 0;
        margin: 0;
      }
      .auix-button--iconized:hover {
        background-color: var(--auix-color-button-iconized-bg-hover);
        cursor: pointer;
      }
      ```
   7. `rule(:auix_index_all_action_button, ...)`:
      ```
      /* auix-index-all-action-button */

      .auix-index-all-action-button {
        background-color: var(--auix-color-button-alt-bg);
        color: var(--auix-color-button-alt-text);
        border-color: var(--auix-color-button-alt-border);
        cursor: pointer;
      }

      .auix-index-all-action-button:hover {
        background-color: var(--auix-color-bg-hover);
      }

      .auix-index-all-action-button:disabled {
        background-color: var(--auix-color-button-disabled-bg);
        border-color: var(--auix-color-button-disabled-border);
        color: var(--auix-color-button-disabled-text);
        cursor: not-allowed;
      }
      ```
   8. `rule(:auix_modal_box, ...)`:
      ```css
      .auix-modal-box {
        position: absolute;
        top: var(--auix-padding-xl);
        margin-left: auto;
        margin-right: auto;
        padding-bottom: var(--auix-padding-xl);
      }

      @media (max-width: #{breakpoint(:sm)}) {
        .auix-modal-box {
          top: var(--auix-margin-medium);
          left: var(--auix-margin-medium);
          right: var(--auix-margin-medium);
          padding-bottom: var(--auix-margin-medium);
        }
      }
      ```
   9. `rule(:auix_modal_box_content, ...)`:
      ```css
      .auix-modal-box-content {
        display: flex;
        flex-direction: column;
        gap: var(--auix-gap-xl);
      }
      ```
   10. `rule(:auix_modal_focus_wrap, ...)`:
       ```css
       .auix-modal-focus-wrap {
         position: relative;

         border-radius: var(--auix-border-radius-large);
         background-color: var(--auix-color-bg-default);
         padding: var(--auix-padding-container) var(--auix-padding-large) var(--auix-padding-large);

         --auix-calc-shadow: var(--auix-shadow-lg), var(--auix-shadow-secondary);

         box-shadow:
           var(--auix-ring-offset-shadow),
           var(--auix-ring-secondary),
           var(--auix-calc-shadow);

         border-width: var(--auix-border-width-default);

         transition-property: color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter;
         transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
         transition-duration: 150ms;
       }

       @media (max-width: #{breakpoint(:sm)}) {
         .auix-modal-focus-wrap {
           padding: var(--auix-padding-medium) 0.875rem var(--auix-padding-container);
         }
       }
       ```
   11. `rule(:auix_modal_close_button_container, ...)`:
       ```css
       .auix-modal-close-button-container {
         position: absolute;
         top: var(--auix-padding-panel);
         right: var(--auix-padding-panel);
         z-index: 1;
         display: flex;
         flex-direction: row;
         justify-content: flex-end;
       }

       @media (max-width: #{breakpoint(:sm)}) {
         .auix-modal-close-button-container {
           top: var(--auix-margin-medium);
           right: var(--auix-margin-medium);
         }
       }
       ```
   12. `rule(:auix_modal_close_button, ...)`:
       ```css
       .auix-modal-close-button {
         display: inline-flex;
         align-items: center;
         justify-content: center;
         width: var(--auix-control-height-compact);
         height: var(--auix-control-height-compact);
         padding: 0;
         border-width: var(--auix-border-width-default);
         border-style: var(--auix-border-style-default);
         border-color: var(--auix-color-modal-close-border);
         border-radius: var(--auix-border-radius-default);
         background-color: var(--auix-color-bg-default);
         color: var(--auix-color-modal-close-text);
         cursor: pointer;
       }

       .auix-modal-close-button:hover {
         background-color: var(--auix-color-bg-light);
         color: var(--auix-color-text-primary);
       }

       .auix-modal-close-button:focus-visible {
         outline: none;
         border-color: var(--auix-color-focus-ring);
         box-shadow: 0 0 0 var(--auix-focus-ring-width) var(--auix-color-focus-ring-halo);
       }

       @media (max-width: #{breakpoint(:sm)}) {
         .auix-modal-close-button {
           width: var(--auix-touch-target-size);
           height: var(--auix-touch-target-size);
         }
       }
       ```
   13. `rule(:auix_discard_confirm, ...)`:
       ```css
       .auix-discard-confirm {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-xl);
         padding-right: calc(var(--auix-control-height-compact) + var(--auix-gap-medium));
       }
       ```
   14. `rule(:auix_discard_confirm_message, ...)`:
       ```css
       .auix-discard-confirm-message {
         font-size: var(--auix-font-size-caption);
         line-height: var(--auix-line-height-default);
         color: var(--auix-color-text-primary);
       }
       ```
   15. `rule(:auix_discard_confirm_actions, ...)`:
       ```css
       .auix-discard-confirm-actions {
         display: flex;
         flex-wrap: wrap;
         justify-content: flex-end;
         gap: var(--auix-gap-large);
       }
       ```
   16. `rule(:auix_record_navigator_bar, ...)`:
       ```css
       .auix-record-navigator-bar {
         width: 100%;
         display: flex;
         flex-direction: row;
         justify-content: center;
         align-items: center;
         gap: var(--auix-gap-default);
         height: var(--auix-control-height-compact);

         font-size: var(--auix-font-size-caption);
         font-weight: var(--auix-font-weight-medium);
         font-variant-numeric: tabular-nums;
         color: var(--auix-color-text-label);
       }

       .auix-record-navigator-bar > a {
         display: inline-flex;
         align-items: center;
         justify-content: center;
         width: var(--auix-row-action-size);
         height: var(--auix-row-action-size);
         border-radius: var(--auix-border-radius-default);
       }

       .auix-record-navigator-bar > a:hover {
         background-color: var(--auix-color-bg-light);
       }

       .auix-record-navigator-bar > .auix-icon-inactive {
         margin: 0 var(--auix-gap-default);
       }

       .auix-record-navigator-bar > span:not([class]) {
         min-width: 4rem;
         text-align: center;
       }

       @media (max-width: #{breakpoint(:sm)}) {
         .auix-record-navigator-bar {
           height: var(--auix-touch-target-size);
           font-size: 0.9375rem;
         }
       }
       ```
       `Components.record_navigator_bar/1` renders `<.link>` (an `a`) around each enabled arrow, a bare `<.icon class="auix-icon-inactive">` for a disabled arrow, and a class-less `span` for the counter.

3. `lib/aurora_uix/templates/basic/renderers/form_renderer.ex`, `render/1`: replace
   `            <.button type="button" name="auix-discard-changes" phx-click="auix_discard_changes" phx-target={@myself}>{dt("Discard changes")}</.button>`
   with
   `            <.button type="button" class="auix-button--danger" name="auix-discard-changes" phx-click="auix_discard_changes" phx-target={@myself}>{dt("Discard changes")}</.button>`.
   The `name` attribute every test drives stays: `rg -n "auix-discard-changes" test` lists `test/cases_live/form_discard_guard_test.exs` and `test/cases_live/ash_form_discard_guard_test.exs`, which select `button[name='auix-discard-changes']` and keep working unchanged.

4. `lib/aurora_uix/templates/basic/components/core_components.ex`, `button/1`: replace
   `    doc: "color/variant class; one of auix-button, auix-button--alt, auix-index-all-action-button"`
   with
   `    doc: "color/variant class; one of auix-button, auix-button--alt, auix-button--danger, auix-index-all-action-button"`.

5. `lib/aurora_uix/templates/css_sanitizer.ex`:
   1. `@allowed_properties` — replace
      `                        "content-visibility",`
      with
      ```
                              "content-visibility",
                              "^content$",
      ```
      The anchors keep `justify-content`, `align-content` and `content-visibility` on their own entries, with no value check.
   2. `allowed_value?/2` (added by UI-3) — insert directly before the line `  defp allowed_value?(_property, _value), do: true`:
      ```elixir
        defp allowed_value?("content", value),
          do: Regex.match?(~r/\A(?:"[^"'\\()\n]*"|'[^"'\\()\n]*')\z/, value)
      ```
      followed by one blank line. Accepted grammar, one string literal: `"` body `"`; `'` body `'`. The body holds none of `"`, `'`, `\`, `(`, `)`, a line break. Kept: `""`, `''`, `"*"`, `'a b'`. Dropped: every function (`url(a.png)`, `attr(title)`, `counter(item)`, `image-set("a.png" 1x)`), every keyword (`none`), a backslash escape (`"\201C"`), two strings (`"a" "b"`), a string holding a parenthesis (`"x(y)"`), a string holding the other quote (`"a'b"`).
   3. `@moduledoc`, `Constraints:` list — after the `resize` line UI-3 adds, add the line `  - content accepts only one quoted string whose body holds none of: quote, backslash, parenthesis, line break; any other value drops the declaration`.

##### Acceptance criteria
- [x] AC-1: Every `<.button>` is 40px tall with an 8px radius and 14px semibold text; a keyboard-focused button shows the focus border and the 3px halo.
- [x] AC-2: A primary button uses the primary fill; a secondary button (`auix-button--alt`, `auix-index-all-action-button`) is a white button with the primary border color; a disabled button of any variant uses the disabled fill, border and text; a submitting primary button dims and shows a spinner.
- [x] AC-3: Below `sm`, a button whose label is hidden (an action button) is a 44px square.
- [x] AC-4: The modal panel has a 16px radius, the close button sits at its top right, and below `sm` the modal floats with an 8px margin.
- [x] AC-5: Given a changed edit form at `/form-discard-guard-products/:id/edit`, when the user asks to close it, the "Discard changes" button of the confirmation renders as `button.auix-button--danger[name='auix-discard-changes']`.
- [x] AC-6: Given a clean edit form, closing it opens no confirmation, so no `.auix-button--danger` renders.
- [x] AC-7: The record pager is centered; each enabled arrow is a 32px target with a hover background, and a disabled arrow keeps its place.
- [x] AC-8: Buttons, the modal and the confirmation match the "Buttons" and "Unsaved-changes confirmation" boards and the desktop and mobile Form boards (visual — no red test; verified by the guide images reviewed in UI-7).
- [x] AC-9: The sanitized `auix-button` rule keeps the spinner box `.auix-button.phx-submit-loading::before` with its `content: "";`.
- [x] AC-10: The sanitizer keeps a `content` declaration whose value is one plain quoted string (`""`, `''`, `"*"`, `'a b'`), and drops a `content` declaration whose value is a function, a keyword, a backslash escape, two strings, a string holding a parenthesis, a string holding the other quote (`url(a.png)`, `attr(title)`, `counter(item)`, `image-set("a.png" 1x)`, `none`, `"\201C"`, `"a" "b"`, `"x(y)"`, `"a'b"`) while keeping the rule's other declarations; `justify-content`, `align-content` and `content-visibility` keep their values.

##### Test ports
- Route `"/form-discard-guard-products"` (already registered via `register_crud/2`) · layout type `:form` · observable: `has_element?/2` on `#auix-product-discard-confirm-modal button.auix-button--danger[name='auix-discard-changes']`.
- Theme rules (pure, no DB): `Base.rule/1`, `ThemeBase.rule(:root_color_aliases)`.
- Sanitizer (pure, no DB): `CssSanitizer.sanitize_css/1`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/templates/theme_framing_test.exs`, new `describe "buttons and modal"` | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"buttons share the 40px frame and the focus halo"` | `Base.rule(:_auix_button_default) =~ "height: var(--auix-control-height)"`, `=~ ".auix-button-default:focus-visible"` |
| AC-2 | same describe | `Base.rule/1`, `ThemeBase.rule(:root_color_aliases)` | `test/cases/templates/theme_framing_test.exs` | `"every variant has a disabled state and the primary a loading state"` | each of `:auix_button`, `:auix_button__alt`, `:auix_button__danger`, `:auix_index_all_action_button` `=~ "background-color: var(--auix-color-button-disabled-bg)"`; `Base.rule(:auix_button) =~ ".auix-button.phx-submit-loading::before"` and `refute =~ "[phx-submit-loading]"`; aliases `=~ "--auix-color-button-alt-bg: var(--auix-color-bg-default);"` |
| AC-3 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"action buttons become 44px squares on mobile"` | `Base.rule(:_auix_button_default) =~ ~r/@media \(max-width: 640px\) \{\s*\.auix-button-default:has\(> \.auix-action-icon\) \{\s*width: var\(--auix-touch-target-size\);/` |
| AC-4 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"the modal floats with its close button at the top right"` | `Base.rule(:auix_modal_close_button_container) =~ "position: absolute"`; `Base.rule(:auix_modal_box) =~ ~r/@media \(max-width: 640px\) \{\s*\.auix-modal-box \{\s*top: var\(--auix-margin-medium\);/`; `Base.rule(:auix_modal_close_button) =~ "border-color: var(--auix-color-modal-close-border)"` and `refute =~ "opacity"` |
| AC-5 | amend `test/cases_live/form_discard_guard_test.exs` "a changed form opens the discard dialog" | its `open_changed_edit(conn)` and `request_close(view)` | `test/cases_live/form_discard_guard_test.exs` | `"a changed form opens the discard dialog"` | replace its last selector with `"#auix-product-discard-confirm-modal button.auix-button--danger[name='auix-discard-changes']"` |
| AC-6 | amend `test/cases_live/form_discard_guard_test.exs` "a clean form closes without a prompt" | its existing setup | `test/cases_live/form_discard_guard_test.exs` | `"a clean form closes without a prompt"` | add `refute has_element?(view, "button.auix-button--danger")` |
| AC-7 | same describe of `theme_framing_test.exs` | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"the record pager centers 32px arrows"` | `Base.rule(:auix_record_navigator_bar) =~ ~r/\.auix-record-navigator-bar > a \{[^}]*width: var\(--auix-row-action-size\);/` and `=~ ".auix-record-navigator-bar > .auix-icon-inactive"` |
| AC-9 | add to `test/cases/templates/css_sanitizer_test.exs` (UI-3 step 6), new `describe "content"` | `Base.rule/1`, `CssSanitizer.sanitize_css/1` | `test/cases/templates/css_sanitizer_test.exs` | `"the loading button keeps its spinner box"` | `CssSanitizer.sanitize_css(Base.rule(:auix_button)) =~ ~s(.auix-button.phx-submit-loading::before { content: "";)` |
| AC-10 | same describe | `CssSanitizer.sanitize_css/1` | `test/cases/templates/css_sanitizer_test.exs` | `"content keeps one plain string and drops any other value"` | for each `v` of `[~s(""), ~s(''), ~s("*"), ~s('a b')]`, `CssSanitizer.sanitize_css(".a { content: #{v}; }") == ".a { content: #{v}; }"`; for each `v` of `["url(a.png)", "attr(title)", "counter(item)", ~s[image-set("a.png" 1x)], "none", ~S("\201C"), ~s("a" "b"), ~s["x(y)"], ~s["a'b"]]`, `CssSanitizer.sanitize_css(".a { color: red; content: #{v}; }") == ".a { color: red; }"`; `CssSanitizer.sanitize_css(".a { justify-content: center; align-content: start; content-visibility: auto; }") == ".a { justify-content: center; align-content: start; content-visibility: auto; }"` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Themes.ThemeBase`, `Base` — modified (rules only). `FormRenderer.render/1` — one `class` attribute. `CoreComponents.button/1` — the `:class` attr doc. `Aurora.Uix.Templates.CssSanitizer` — modified: `@allowed_properties`, one `allowed_value?/2` clause, `@moduledoc`.
2. Components: `<.button>` gains the documented variant `auix-button--danger`; attrs unchanged.
3. Theme: `.auix-button-default` (`rule(:_auix_button_default)`), `.auix-button`, `.auix-button--alt`, new `.auix-button--danger` (`rule(:auix_button__danger)`), `.auix-button-badge`, `.auix-button--iconized`, `.auix-index-all-action-button`, `.auix-modal-box`, `.auix-modal-box-content`, `.auix-modal-focus-wrap`, `.auix-modal-close-button-container`, `.auix-modal-close-button`, `.auix-discard-confirm`, `.auix-discard-confirm-message`, `.auix-discard-confirm-actions`, `.auix-record-navigator-bar` — each in its same-named `rule/1` clause. Regenerate with `mix auix.gen.stylesheet`.
4. `dt/1` strings: none new (`"Discard changes"` exists).

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-5:end -->
<!-- section:UI-6:start -->
### UI-6 — UI · index table, pagination, cards and menus
Depends on: UI-5

#### Documentation references
- `guides/customization/styling.md § Class reference` (rows `.auix-items-table-header-sort` … `.auix-index-sort-action--always`), `§ Variable reference › Colors › Component aliases`
- `guides/core/layouts.md` (index cards; no text changes)

#### Implementation details

Layout types: `:index` (the index list and the one-to-many lists, which render through the same `Components.auix_items/1`). CSS only — no markup changes, no backend code.

The selection, the pagination footer and the sorted column are drawn from markup that exists today:

| Look | Selector | Markup it relies on |
|---|---|---|
| Selected row | `.auix-items-table-row:has(> .auix-items-table-cell:first-child .auix-checkbox:checked)` | `Components.auix_items_table/1` row `tr.auix-items-table-row > td.auix-items-table-cell`; the first column is the `:selected_check__` field, rendered by `DefaultRenderer.index_value/1` as `<.input type="checkbox">` (`input.auix-checkbox`) |
| Selected card | `.auix-items-card-item-content:has(> .auix-items-card-item-group > .auix-items-card-select .auix-checkbox:checked)` | `Components.auix_items_card/1`: the first column renders inside `div.auix-items-card-select` |
| Pagination in the card footer | `.auix-index-container:has(> [name="auix-index-footer-actions"] > .auix-pagination-container)` and `.auix-index-container:has(> form .auix-items-desktop)` | `IndexRenderer.index_list/1` renders `div.auix-index-actions`, the `form` and `div[name="auix-index-footer-actions"]` as direct children of `.auix-index-container`; `Index.pagination_action/1` renders `div.auix-pagination-container` |
| Sorted column | `th[aria-sort="ascending"]`, `th[aria-sort="descending"]`, `th[aria-sort="none"]` | `Components.auix_items_table/1` sets `aria-sort` on every sortable header cell |

Rows are streamed, so a server-side class on the selected row would not re-render when the selection changes; `:has()` follows the live checkbox state. `:has()` is already used by `rule(:auix_items_card_menu)`.

The existing assertions of `test/cases/templates/theme_rules_test.exs` on these rules stay true, apart from the two this section amends (step 3): the menu lists keep `top: 100%` and contain none of `left`, `right`, `bottom`; the open-menu blocks keep only `display: flex;`; the `:not(:has(...)) { display: none; }` blocks, the destructive-group selector and the `> .auix-index-row-action` / `> a` / `> button` item selectors are kept verbatim; `rule(:auix_items_card_item_value)` contains no `font-style`.

1. `lib/aurora_uix/templates/basic/themes/theme_base.ex`, `rule(:root_color_aliases, ...)`:
   1. Replace the lines from `    /* tables */` through `    --auix-color-items-table-row-bg-hover: var(--auix-color-bg-hover);` with:
      ```
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
      ```
   2. Replace `    --auix-color-pagination-current-border: var(--auix-color-border-focus);` with:
      ```
          --auix-color-pagination-current-border: var(--auix-color-pagination-current-bg);
          --auix-color-pagination-link-text: var(--auix-color-text-label);
          --auix-color-pagination-link-bg-hover: var(--auix-color-bg-light);
      ```
   New-name evidence: `rg -n -e 'header-sorted-text' -e 'items-table-header-bg' -e 'row-bg-selected' -e 'items-table-row-border' -e 'items-table-bg' -e 'items-table-border' -e 'row-action-text' -e 'row-action-bg-hover' -e 'items-card-bg' -e 'items-card-border' -e 'items-card-label-text' -e 'color-menu-' -e 'sort-toggle-active' -e 'pagination-link-' lib test` returns nothing.

2. `lib/aurora_uix/templates/basic/themes/base.ex` — replace the whole heredoc of each rule below with the CSS given.
   1. `rule(:auix_index_container, ...)` — keep its CSS and change only `gap: var(--auix-gap-medium);` to `gap: var(--auix-gap-xl);`.
   2. `rule(:auix_index_actions, ...)`:
      ```css
      .auix-index-actions {
        display: flex;
        flex-direction: row;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        gap: var(--auix-gap-large);
      }
      ```
   3. `rule(:auix_index_header_actions, ...)`:
      ```css
      .auix-index-header-actions {
        display: flex;
        flex-direction: row;
        align-items: center;
        gap: var(--auix-gap-medium);
      }
      ```
   4. `rule(:auix_items_table_container, ...)`:
      ```css
      .auix-items-table-container {
        overflow-x: auto;
        border-width: var(--auix-border-width-default);
        border-style: var(--auix-border-style-default);
        border-color: var(--auix-color-items-table-border);
        border-radius: var(--auix-border-radius-medium);
        background-color: var(--auix-color-items-table-bg);
        box-shadow: var(--auix-shadow-small);
      }

      @media (min-width: #{breakpoint(:md)}) {
        .auix-index-container:has(> [name="auix-index-footer-actions"] > .auix-pagination-container) > form .auix-items-desktop > .auix-items-table-container {
          border-bottom-left-radius: 0;
          border-bottom-right-radius: 0;
        }
      }
      ```
   5. `rule(:auix_items_table, ...)`:
      ```css
      .auix-items-table {
        width: 40rem;
        margin-top: 0;
        border-collapse: collapse;
      }

      @media (min-width: #{breakpoint(:sm)}) {
        .auix-items-table {
          width: 100%;
        }
      }
      ```
   6. `rule(:auix_items_table_header, ...)`:
      ```css
      .auix-items-table-header {
        font-size: var(--auix-font-size-label);
        color: var(--auix-color-items-table-header-text);
        background-color: var(--auix-color-items-table-header-bg);
      }

      .auix-items-table-header .auix-horizontal-divider {
        margin: 0;
        padding: 0;
        border-top-color: var(--auix-color-items-table-body-border);
      }

      .auix-items-table-header th[aria-sort="ascending"],
      .auix-items-table-header th[aria-sort="descending"] {
        color: var(--auix-color-items-table-header-sorted-text);
      }

      .auix-items-table-header th[aria-sort="none"] .auix-items-table-header-sort .auix-icon-size-4 {
        color: var(--auix-color-text-inactive);
      }
      ```
      The divider is the `td.auix-horizontal-divider` row `auix_items_table/1` renders under the header row; it becomes the header's bottom line.
   7. `rule(:auix_items_table_header_cell, ...)`:
      ```css
      .auix-items-table-header-cell {
        height: var(--auix-table-header-height);
        padding-left: var(--auix-padding-control);
        padding-right: var(--auix-padding-control);
        font-weight: var(--auix-font-weight-bold);
        white-space: nowrap;
        vertical-align: middle;
      }
      ```
   8. `rule(:auix_items_table_header_cell__first, ...)`:
      ```
      /* auix-items-table-header-cell--first */

      #{import_rule(:auix_items_table_header_cell, :auix_items_table_header_cell__first)}

      .auix-items-table-header-cell--first {
        padding-left: var(--auix-padding-panel);
      }
      ```
   9. `rule(:auix_items_table_header_sort, ...)`:
      ```css
      .auix-items-table-header-sort {
        display: inline-flex;
        align-items: center;
        gap: var(--auix-gap-label);
        padding: 0;
        border: 0;
        background: transparent;
        color: inherit;
        font: inherit;
        cursor: pointer;
      }
      ```
   10. `rule(:auix_items_table_body, ...)`:
       ```css
       .auix-items-table-body {
         position: relative;
         font-size: var(--auix-font-size-caption);
         color: var(--auix-color-items-table-body-text);
       }

       .auix-items-table-body > tr:not(:last-child) {
         border-bottom-width: var(--auix-border-width-default);
         border-bottom-style: var(--auix-border-style-default);
         border-bottom-color: var(--auix-color-items-table-row-border);
       }
       ```
   11. `rule(:auix_items_table_row, ...)`:
       ```css
       .auix-items-table-row:hover {
         background-color: var(--auix-color-items-table-row-bg-hover);
       }

       .auix-items-table-row:has(> .auix-items-table-cell:first-child .auix-checkbox:checked) {
         background-color: var(--auix-color-items-table-row-bg-selected);
       }
       ```
   12. `rule(:auix_items_table_cell, ...)`:
       ```css
       .auix-items-table-cell {
         height: var(--auix-table-row-height);
         padding-right: var(--auix-padding-control);
         padding-left: var(--auix-padding-control);
         vertical-align: middle;
       }

       .auix-items-table-cell:first-child {
         padding-left: var(--auix-padding-panel);
       }
       ```
   13. `rule(:auix_items_table_action_cell, ...)`:
       ```css
       .auix-items-table-action-cell {
         height: var(--auix-table-row-height);
         padding: 0 var(--auix-padding-control);
         text-align: right;
         vertical-align: middle;
         white-space: nowrap;
       }

       .auix-items-table-action-cell > div {
         display: inline-flex;
         vertical-align: middle;
       }

       .auix-items-table-action-cell > div + div {
         margin-left: var(--auix-gap-minimal);
       }

       .auix-items-table-action-cell .auix-index-row-action {
         display: inline-flex;
         align-items: center;
         justify-content: center;
         width: var(--auix-row-action-size);
         height: var(--auix-row-action-size);
         border-radius: 0.375rem;
         color: var(--auix-color-row-action-text);
       }

       .auix-items-table-action-cell .auix-index-row-action:hover {
         background-color: var(--auix-color-row-action-bg-hover);
         color: var(--auix-color-text-primary);
       }
       ```
       The delete action's icon carries `auix-icon-danger` (`Index.remove_row_action/1`), which sets its own color, so it stays in the danger color.
   14. `rule(:auix_items_card_item_content, ...)`:
       ```css
       .auix-items-card-item-content {
         display: flex;
         flex-direction: column;
         position: relative;
         border-width: var(--auix-border-width-default);
         border-style: var(--auix-border-style-default);
         border-color: var(--auix-color-items-card-border);
         border-radius: var(--auix-border-radius-medium);
         background-color: var(--auix-color-items-card-bg);
         color: var(--auix-color-items-card-item-content-text);
         box-shadow: var(--auix-shadow-small);
       }

       .auix-items-card-item-content:has(> .auix-items-card-item-group > .auix-items-card-select .auix-checkbox:checked) {
         border-color: var(--auix-color-items-card-border-selected);
         background-color: var(--auix-color-items-card-bg-selected);
       }
       ```
   15. `rule(:auix_items_card_item_group, ...)`:
       ```css
       .auix-items-card-item-group {
         display: flex;
         flex-direction: row;
         align-items: center;
         gap: 0;
         padding: var(--auix-gap-minimal) var(--auix-gap-minimal) 0;
       }

       .auix-items-card-item-group > .auix-items-card-heading:first-child {
         padding-left: calc(var(--auix-padding-panel) - var(--auix-gap-minimal));
       }
       ```
   16. `rule(:auix_items_card_select, ...)`:
       ```css
       .auix-items-card-select {
         position: relative;
         display: flex;
         align-items: center;
         justify-content: center;
         flex-shrink: 0;
         width: var(--auix-touch-target-size);
         height: var(--auix-touch-target-size);
       }

       .auix-items-card-select .auix-fieldset {
         padding: 0;
         gap: 0;
       }

       .auix-items-card-select .auix-checkbox {
         margin: 0;
       }
       ```
   17. `rule(:auix_items_card_heading, ...)`:
       ```css
       .auix-items-card-heading {
         display: flex;
         flex-direction: column;
         flex: 1;
         gap: 0;
         min-width: 0;
       }
       ```
   18. `rule(:auix_items_card_subtitle, ...)`:
       ```css
       .auix-items-card-subtitle {
         font-size: var(--auix-font-size-label);
         line-height: 1.125rem;
         color: var(--auix-color-text-secondary);
       }
       ```
   19. `rule(:auix_items_card_item, ...)`:
       ```css
       .auix-items-card-item {
         display: flex;
         flex-direction: column;
         flex: 1;
         gap: var(--auix-gap-label);
         padding: var(--auix-gap-default) var(--auix-padding-panel) 0.875rem;
       }

       .auix-items-card-item .auix-inline-container {
         flex-direction: row;
         flex-wrap: wrap;
         column-gap: var(--auix-gap-large);
       }
       ```
   20. `rule(:auix_items_card_item_fieldset, ...)`:
       ```css
       .auix-items-card-item-fieldset {
         display: grid;
         grid-template-columns: var(--auix-items-card-label-width) minmax(0, 1fr);
         column-gap: var(--auix-padding-control);
         align-items: baseline;
       }
       ```
   21. `rule(:auix_items_card_item_label, ...)`:
       ```css
       .auix-items-card-item-label {
         font-size: var(--auix-font-size-label);
         font-weight: var(--auix-font-weight-medium);
         color: var(--auix-color-items-card-label-text);
       }
       ```
   22. `rule(:auix_items_card_item_value, ...)`:
       ```css
       .auix-items-card-item-value {
         min-width: 0;
         font-size: var(--auix-font-size-caption);
         line-height: var(--auix-line-height-default);
         color: var(--auix-color-text-primary);
         overflow-wrap: anywhere;
       }
       ```
   23. `rule(:auix_items_card_menu, ...)`:
       ```css
       .auix-items-card-menu {
         position: relative;
         display: inline-flex;
         flex-shrink: 0;
       }

       .auix-items-card-menu > .auix-items-card-menu-toggle {
         min-width: var(--auix-touch-target-size);
         min-height: var(--auix-touch-target-size);
         justify-content: center;
       }

       .auix-items-card-menu > .auix-items-card-menu-toggle[aria-expanded="true"] {
         background-color: var(--auix-color-menu-item-bg-hover);
       }

       .auix-items-card-menu:not(:has(.auix-items-card-menu-item > *)) {
         display: none;
       }
       ```
   24. `rule(:auix_items_card_menu_list, ...)`:
       ```css
       .auix-items-card-menu-list {
         display: none;
         position: absolute;
         inset-inline-end: 0;
         top: 100%;
         z-index: 10;
         flex-direction: column;
         gap: var(--auix-gap-minimal);
         padding: var(--auix-gap-label);
         border-width: var(--auix-border-width-default);
         border-style: var(--auix-border-style-default);
         border-color: var(--auix-color-menu-border);
         border-radius: var(--auix-border-radius-medium);
         background-color: var(--auix-color-menu-bg);
         box-shadow: var(--auix-shadow-lg);
       }

       .auix-items-card-menu-toggle[aria-expanded="true"] ~ .auix-items-card-menu-list {
         display: flex;
       }
       ```
   25. `rule(:auix_items_card_menu_group, ...)`:
       ```css
       .auix-items-card-menu-group {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-minimal);
       }

       .auix-items-card-menu-group:not(:has(.auix-items-card-menu-item > *)) {
         display: none;
       }

       .auix-items-card-menu-group:has(.auix-items-card-menu-item > *) + .auix-items-card-menu-group--destructive {
         margin-top: var(--auix-gap-default);
         padding-top: var(--auix-gap-default);
         border-top-width: var(--auix-border-width-default);
         border-top-style: var(--auix-border-style-default);
         border-top-color: var(--auix-color-menu-divider);
       }
       ```
   26. `rule(:auix_items_card_menu_item, ...)`:
       ```css
       .auix-items-card-menu-item,
       .auix-items-card-menu-item > .auix-index-row-action,
       .auix-items-card-menu-item > a,
       .auix-items-card-menu-item > button {
         display: inline-flex;
         align-items: center;
         justify-content: center;
         min-width: var(--auix-touch-target-size);
         min-height: var(--auix-touch-target-size);
         border-radius: var(--auix-border-radius-default);
       }

       .auix-items-card-menu-item > .auix-index-row-action:hover,
       .auix-items-card-menu-item > a:hover,
       .auix-items-card-menu-item > button:hover {
         background-color: var(--auix-color-menu-item-bg-hover);
       }

       .auix-items-card-menu-item:not(:has(> *)) {
         display: none;
       }
       ```
   27. `rule(:auix_index_sort_menu_toggle__active, ...)`:
       ```css
       .auix-index-sort-menu > .auix-index-sort-menu-toggle--active {
         color: var(--auix-color-sort-toggle-active-text);
         background-color: var(--auix-color-sort-toggle-active-bg);
         border: var(--auix-border-width-default) var(--auix-border-style-default) var(--auix-color-sort-toggle-active-border);
       }
       ```
   28. `rule(:auix_index_sort_menu_list, ...)`:
       ```css
       .auix-index-sort-menu-list {
         display: none;
         position: absolute;
         inset-inline-end: 0;
         top: 100%;
         z-index: 10;
         flex-direction: column;
         min-width: var(--auix-menu-min-width);
         padding: var(--auix-gap-label);
         border-width: var(--auix-border-width-default);
         border-style: var(--auix-border-style-default);
         border-color: var(--auix-color-menu-border);
         border-radius: var(--auix-border-radius-medium);
         background-color: var(--auix-color-menu-bg);
         box-shadow: var(--auix-shadow-lg);
       }

       .auix-index-sort-menu-toggle[aria-expanded="true"] ~ .auix-index-sort-menu-list {
         display: flex;
       }
       ```
   29. `rule(:auix_index_sort_menu_group, ...)`:
       ```css
       .auix-index-sort-menu-group {
         display: flex;
         flex-direction: column;
         gap: var(--auix-gap-minimal);
       }

       .auix-index-sort-menu-group + .auix-index-sort-menu-group {
         margin-top: var(--auix-gap-default);
         padding-top: var(--auix-gap-default);
         border-top-width: var(--auix-border-width-default);
         border-top-style: var(--auix-border-style-default);
         border-top-color: var(--auix-color-menu-divider);
       }
       ```
   30. `rule(:auix_index_sort_menu_item, ...)`:
       ```css
       .auix-index-sort-menu-item {
         display: flex;
         flex-direction: row;
         align-items: center;
         justify-content: flex-start;
         gap: var(--auix-padding-default);
         height: auto;
         min-height: var(--auix-touch-target-size);
         padding-inline: var(--auix-padding-default);
         border: none;
         border-radius: var(--auix-border-radius-default);
         background-color: transparent;
         color: inherit;
         font-size: var(--auix-font-size-caption);
         font-weight: var(--auix-font-weight-bold-semi);
         white-space: nowrap;
         cursor: pointer;
       }

       .auix-index-sort-menu-item:not(:has(.auix-index-sort-menu-check--off)) {
         font-weight: var(--auix-font-weight-bold);
       }

       .auix-index-sort-menu-item:hover {
         background-color: var(--auix-color-menu-item-bg-hover);
       }

       .auix-index-sort-menu-item:disabled {
         background-color: transparent;
         color: var(--auix-color-text-inactive);
         cursor: default;
       }
       ```
       Each sort menu option is a `<.button>` that also carries `.auix-button-default` (UI-5); `rule(:auix_index_sort_menu_item)` comes later in the stylesheet, so its `height`, `justify-content`, `font-weight` and `border` win at equal specificity.
   31. `rule(:auix_pagination_bar, ...)`:
       ```css
       .auix-pagination-bar {
         display: flex;
         flex-direction: row;
         flex-wrap: wrap;
         align-items: center;
         justify-content: center;
         gap: var(--auix-gap-default);
         overflow-x: clip;
       }

       .auix-pagination-bar > a,
       .auix-pagination-bar-link {
         display: inline-flex;
         align-items: center;
         justify-content: center;
         box-sizing: border-box;
         min-width: var(--auix-row-action-size);
         min-height: var(--auix-row-action-size);
         padding: 0 var(--auix-padding-medium);
         border-radius: var(--auix-border-radius-round);
         font-size: var(--auix-font-size-caption);
         font-weight: var(--auix-font-weight-medium);
         color: var(--auix-color-pagination-link-text);
         cursor: pointer;
       }

       .auix-pagination-bar > a:hover,
       .auix-pagination-bar-link:hover {
         background-color: var(--auix-color-pagination-link-bg-hover);
       }
       ```
       `Components.pages_selection/1` renders the previous and next arrows as class-less `a` children of `.auix-pagination-bar` and every page link as `a.auix-pagination-bar-link`.
   32. `rule(:auix_pagination_bar_link, ...)`:
       ```css
       .auix-pagination-bar-link {
         flex-direction: column;
         gap: 0;
       }
       ```
   33. `rule(:auix_pagination_bar_current_page_number, ...)`:
       ```css
       .auix-pagination-bar-current-page-number {
         display: inline-flex;
         align-items: center;
         justify-content: center;
         box-sizing: border-box;
         min-width: var(--auix-row-action-size);
         height: var(--auix-row-action-size);
         padding: 0 var(--auix-padding-medium);
         border: var(--auix-border-width-default) solid var(--auix-color-pagination-current-border);
         border-radius: var(--auix-border-radius-round);
         font-size: var(--auix-font-size-caption);
         font-weight: var(--auix-font-weight-bold);
         color: var(--auix-color-pagination-current-text);
         background-color: var(--auix-color-pagination-current-bg);
       }
       ```
   34. `rule(:auix_pagination_container, ...)`:
       ```css
       .auix-pagination-container {
         margin-top: 0;
       }

       @media (min-width: #{breakpoint(:md)}) {
         .auix-index-container:has(> form .auix-items-desktop) > [name="auix-index-footer-actions"] > .auix-pagination-container {
           margin-top: calc(-1 * var(--auix-gap-xl));
           padding: var(--auix-padding-control) var(--auix-padding-panel);
           border-width: var(--auix-border-width-default);
           border-style: var(--auix-border-style-default);
           border-color: var(--auix-color-items-table-border);
           border-top-color: var(--auix-color-items-table-row-border);
           border-radius: 0 0 var(--auix-border-radius-medium) var(--auix-border-radius-medium);
           background-color: var(--auix-color-items-table-bg);
         }

         .auix-index-container:has(> form .auix-items-desktop) > [name="auix-index-footer-actions"] > .auix-pagination-container > .auix-horizontal-divider {
           display: none;
         }
       }
       ```
       The `-1 * --auix-gap-xl` margin cancels the `.auix-index-container` gap of step 2.1, so the footer touches the table card. Below `md` the table is hidden (`rule(:auix_items_desktop)`) and every pagination breakpoint bar is hidden too (`rule(:auix_pagination_breakpoint_md)`), so the footer frame applies only where both show.
   35. `rule(:auix_one_to_many_field, ...)`:
       ```css
       .auix-one-to-many-field {
         display: flex;
         flex-direction: column;
         width: stretch;
         gap: var(--auix-gap-medium);
       }
       ```
   36. `rule(:auix_one_to_many_header, ...)`:
       ```css
       .auix-one-to-many-header {
         display: flex;
         align-items: center;
         gap: var(--auix-gap-medium);
       }
       ```
   37. `rule(:auix_one_to_many_container, ...)`:
       ```css
       .auix-one-to-many-container {
         width: auto;
         color: var(--auix-color-one-to-many-text);
       }

       .auix-one-to-many-container .auix-items-table-header-cell,
       .auix-one-to-many-container .auix-items-table-header-cell--first {
         height: auto;
         padding: var(--auix-padding-default) var(--auix-padding-panel);
         font-size: var(--auix-font-size-small);
       }

       .auix-one-to-many-container .auix-items-table-cell,
       .auix-one-to-many-container .auix-items-table-action-cell {
         height: auto;
         padding: var(--auix-gap-label) var(--auix-padding-panel);
       }

       @media (min-width: #{breakpoint(:sm)}) {
         .auix-one-to-many-container {
           font-size: var(--auix-font-size-caption);
         }
       }
       ```
       The container no longer draws a border: on desktop the table card of step 2.4 frames the list, and below `md` each card keeps its own frame with no outer box. `--auix-color-one-to-many-border` stays declared in `ThemeBase` and is no longer read by a built-in rule.

3. `test/cases/templates/theme_rules_test.exs` amendments:
   1. Test `"align the checkbox with the title"`: replace `assert select =~ "height: var(--auix-line-height-relaxed)"` with `assert select =~ "height: var(--auix-touch-target-size)"`; the other three assertions stay.
   2. Test `"the sort menu opens below its button and marks the active sort"`: replace `assert active =~ "color: var(--auix-color-icon-info)"` with `assert active =~ "color: var(--auix-color-sort-toggle-active-text)"`.

##### Acceptance criteria
- [ ] AC-1: The index table sits in a bordered card with a 12px radius, a tinted 44px header row and 48px body rows; the sorted column header uses the primary text color and an unsorted sort arrow the inactive color.
- [ ] AC-2: A row whose selection checkbox is checked uses `--auix-color-items-table-row-bg-selected`; a card whose checkbox is checked uses the selection border and background.
- [ ] AC-3: Row action icons are 32px targets with a hover background; the delete action stays in the danger color.
- [ ] AC-4: From `md` up, when the index shows a table and a pagination bar, the bar is the table card's footer, centered, with a pill on the current page; with no pagination bar the table card keeps all four rounded corners.
- [ ] AC-5: An index card and a one-to-many card have the new frame (12px radius, 44px checkbox and ⋮ targets); the one-to-many list has no outer bordered box.
- [ ] AC-6: The card ⋮ menu and the sort menu are 12px-radius surfaces with 44px items, a divider before the destructive items and between the sort fields and directions, and the active sort field and direction marked with a check in bold.
- [ ] AC-7: Given the `:product` index at `/selected-products` with 35 products, when the user checks all, every body row renders `tr.auix-items-table-row > td.auix-items-table-cell:first-child input.auix-checkbox[checked]` and every card renders `.auix-items-card-item-content > .auix-items-card-item-group > .auix-items-card-select input.auix-checkbox[checked]` — the markup the selection selectors of step 2.11 and 2.14 match; before checking, no row carries a checked box.
- [ ] AC-8: Given `/pages-bar-products` with 1000 products, `.auix-index-container > [name='auix-index-footer-actions'] > .auix-pagination-container` and `.auix-index-container > form .auix-items-desktop > .auix-items-table-container` both render — the markup the footer selectors of steps 2.4 and 2.34 match; with 30 products no `.auix-pagination-container` renders and the table card keeps its own corners.
- [ ] AC-9: The index table, cards and menus match the desktop Index, mobile Index cards, "Card with its ⋮ menu open" and "Card sort menu" boards (visual — no red test; verified by the guide images reviewed in UI-7).

##### Test ports
- Routes `"/selected-products"` and `"/pages-bar-products"` (already registered via `register_crud/2`) · layout type `:index` · observable: `has_element?/2` on the selectors of AC-7 and AC-8.
- Theme rules (pure, no DB): `Base.rule/1`, `ThemeBase.rule(:root_color_aliases)`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/templates/theme_framing_test.exs`, new `describe "index"` | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"the table sits in a card with a tinted header and marks the sorted column"` | `Base.rule(:auix_items_table_container) =~ "border-radius: var(--auix-border-radius-medium)"`; `Base.rule(:auix_items_table_header) =~ "background-color: var(--auix-color-items-table-header-bg)"` and `=~ ~s(th[aria-sort="ascending"])`; `Base.rule(:auix_items_table_cell) =~ "height: var(--auix-table-row-height)"` |
| AC-2 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"a selected row and a selected card use the selection colors"` | `Base.rule(:auix_items_table_row) =~ ".auix-items-table-row:has(> .auix-items-table-cell:first-child .auix-checkbox:checked)"`; `Base.rule(:auix_items_card_item_content) =~ "border-color: var(--auix-color-items-card-border-selected)"` |
| AC-3 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"row actions are 32px targets"` | `Base.rule(:auix_items_table_action_cell) =~ ~r/\.auix-items-table-action-cell \.auix-index-row-action \{[^}]*width: var\(--auix-row-action-size\);/` and `refute =~ "display: flex"` |
| AC-4 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"pagination becomes the table card footer"` | `Base.rule(:auix_pagination_container) =~ ~s(.auix-index-container:has(> form .auix-items-desktop) > [name="auix-index-footer-actions"] > .auix-pagination-container)`; `Base.rule(:auix_pagination_bar_current_page_number) =~ "border-radius: var(--auix-border-radius-round)"` |
| AC-5 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"cards get the new frame and one-to-many lists no outer box"` | `Base.rule(:auix_items_card_item_content) =~ "border-radius: var(--auix-border-radius-medium)"`; `refute Base.rule(:auix_one_to_many_container) =~ "border-width"` |
| AC-6 | same describe | `Base.rule/1` | `test/cases/templates/theme_framing_test.exs` | `"menus are 12px surfaces with dividers"` | each of `:auix_items_card_menu_list`, `:auix_index_sort_menu_list` `=~ "border-radius: var(--auix-border-radius-medium)"`; `Base.rule(:auix_index_sort_menu_group) =~ "border-top-color: var(--auix-color-menu-divider)"`; `Base.rule(:auix_index_sort_menu_item) =~ ":not(:has(.auix-index-sort-menu-check--off))"` |
| AC-7 | amend `test/cases_live/selected_test.exs` "Test select / deselect all" | its `create_sample_products(35, :test)` and `live(conn, "/selected-products")` | `test/cases_live/selected_test.exs` | `"Test select / deselect all"` | before the check-all click: `refute has_element?(view, "tr.auix-items-table-row > td.auix-items-table-cell:first-child input.auix-checkbox[checked]")`; after it: `assert has_element?(view, "tr.auix-items-table-row > td.auix-items-table-cell:first-child input.auix-checkbox[checked]")` and `assert has_element?(view, "#auix-table-selected-products-index-mobile .auix-items-card-item-content > .auix-items-card-item-group > .auix-items-card-select input.auix-checkbox[checked]")` |
| AC-8 | amend `test/cases_live/pages_bar_test.exs` "Test UI page bar needed" and "Test UI page bar not needed" | their `create_sample_products(1000, :test)` / `(30, :test)` and `live(conn, "/pages-bar-products")` | `test/cases_live/pages_bar_test.exs` | `"Test UI page bar needed"`, `"Test UI page bar not needed"` | needed: `assert has_element?(view, ".auix-index-container > [name='auix-index-footer-actions'] > .auix-pagination-container")` and `assert has_element?(view, ".auix-index-container > form .auix-items-desktop > .auix-items-table-container")`; not needed: `refute has_element?(view, ".auix-pagination-container")` and `assert has_element?(view, ".auix-items-table-container")` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Themes.ThemeBase`, `Base` — modified (rules only).
2. Components: none changed.
3. Theme: `.auix-index-container`, `.auix-index-actions`, `.auix-index-header-actions`, `.auix-items-table-container`, `.auix-items-table`, `.auix-items-table-header`, `.auix-items-table-header-cell`, `.auix-items-table-header-cell--first`, `.auix-items-table-header-sort`, `.auix-items-table-body`, `.auix-items-table-row`, `.auix-items-table-cell`, `.auix-items-table-action-cell`, `.auix-items-card-item-content`, `.auix-items-card-item-group`, `.auix-items-card-select`, `.auix-items-card-heading`, `.auix-items-card-subtitle`, `.auix-items-card-item`, `.auix-items-card-item-fieldset`, `.auix-items-card-item-label`, `.auix-items-card-item-value`, `.auix-items-card-menu`, `.auix-items-card-menu-list`, `.auix-items-card-menu-group`, `.auix-items-card-menu-item`, `.auix-index-sort-menu-toggle--active`, `.auix-index-sort-menu-list`, `.auix-index-sort-menu-group`, `.auix-index-sort-menu-item`, `.auix-pagination-bar`, `.auix-pagination-bar-link`, `.auix-pagination-bar-current-page-number`, `.auix-pagination-container`, `.auix-one-to-many-field`, `.auix-one-to-many-header`, `.auix-one-to-many-container` — each in its same-named `rule/1` clause. Regenerate with `mix auix.gen.stylesheet`.
4. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-6:end -->
<!-- section:UI-7:start -->
### UI-7 — UI · regenerated guide images
Depends on: UI-2, UI-6

#### Documentation references
- `guides/overview/overview.md`, `guides/core/layouts.md`, `guides/core/ash_integration.md` (they embed the images; no text changes)
- `.claude/skills/prepare-release/SKILL.md § 4. Build assets`, `§ 5. Screenshots` (the capture procedure this section follows)

#### Implementation details

Layout types: `:index`, `:form`, `:show`, as the capture tests drive them. No library code changes; the section commits regenerated PNGs only. The capture tests run on Wallaby (`test/guides/capture_*.exs`) because a PNG of the rendered page cannot be produced by LiveViewTest. They render with the test config's theme, `config/test.exs` `theme_name: :vitreous_marble`.

1. `mix assets.build` — must exit `0`. It regenerates the icons, `assets/css/auix-*.css` and the bundles the capture server serves.
2. `mix test test/guides/capture_*.exs` — overwrites the PNGs under `guides/overview/images`, `guides/core/images/layouts` and `guides/core/images/ash` (desktop 1024×768, mobile 412×915) through `ImageHelper.capture/5`.
3. `git status --short` lists only `.png` files under those three directories.
4. Open every changed PNG of the index, show and edit views and check: inputs, tabs, groups, the table card with its header row and pagination footer, the cards and the modal show the UI-3 to UI-6 frame; the data is the sample data; no error flash, no half-loaded state, no clipped crop, no empty crop.
5. A bad capture is fixed in the UI section's CSS on a follow-up commit of this branch, after which steps 1–4 run again. PNGs are never edited by hand.
6. Commit the PNGs alone as `docs: regenerate guide images`.

##### Acceptance criteria
- [ ] AC-1: After steps 1–2, `git status --short` lists only PNG files under `guides/overview/images`, `guides/core/images/layouts` and `guides/core/images/ash` (mechanical — no red test; verified by `git status --short`).
- [ ] AC-2: Every regenerated index, show and edit image shows the new frame of UI-3 to UI-6 at desktop and mobile width with no clipping (manual — no red test; verified by reading each changed PNG per step 4).
- [ ] AC-3: A failing capture, and a capture showing an error flash, block the section: the PNG is not committed until a re-run is clean (manual — no red test; verified by step 4 on the re-run).

##### Test ports
- None: the capture tests are the procedure, not the proof.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|

Every AC above carries its own verification; no red test applies.

##### Modules & components
1. None.
2. Components: none.
3. Theme: none; `mix assets.build` regenerates the stylesheet.
4. `dt/1` strings: none.

##### Green tests
1. `mix test test/guides/capture_*.exs` passes (code-issue runs this)
2. `mix test` — full suite green (review-issue runs this)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-7:end -->

---

### Out of Scope
- Parser, schema and CRUD layers: the issue changes how the generated markup is styled, so there is no Schema section and no Parser section; Ash and Ecto (`ctx`) resources render through the same renderers and theme.
- A page-background variable: the mockups' page canvas (Blue Graphite `#F5F6F8` / `#0A0E15`) is the host page's background, not a theme property.
- The library's own flash messages keep their kinds (`:info`, `:error`); `flash_group/1` is unchanged.
- Fonts: the mockups render in Inter; `--auix-font-family-default` stays `var(--auix-font-sans)`.
- The second `class` attribute `DefaultRenderer.render/1` passes to `<.input>` (`auix-form-field-input`) and `rule(:auix_form_field_input)` stay as they are.
- Card ⋮ menu items keep their icon-only content; the menu gains no labels.
- Filter inputs (`.auix-filter-*`), the confirm-button modal (`.auix-confirm-button--*`), upload fields and the predefined renderers other than the toggle keep their current rules.
- The daisyUI bridge (`priv/static/css/auix-bridge-daisyui.css`) maps none of the new variables.
- Variables the new rules stop reading (`--auix-opacity-20`, `--auix-opacity-40`, `--auix-ring-info`, `--auix-shadow-md`, `--auix-button-height-default`, `--auix-color-border-focus`, `--auix-color-one-to-many-border`) stay declared.
<!-- enriched-spec:end -->
