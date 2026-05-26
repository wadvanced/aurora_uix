# Styling Aurora UIX in a Host Application

Aurora UIX renders all of its generated components against a set of `--auix-*` CSS custom
properties. This guide shows how to align those properties with your host application's design
system — either by remapping them through a style bridge file or by overriding individual tokens
directly — without touching any library source.

## The five files and their cascade layers

Running `mix auix.gen.stylesheet` writes the following files and declares the layer order
`auix.baseline → auix.variables → auix.bridge → auix.rules`:

| File | `@layer` | Owner | Purpose |
|---|---|---|---|
| `auix-baseline.css` | `auix.baseline` | Host | Tag-selector reset (`html`, `body`, `a`) using `--auix-*` variables. **Opt-in for non-Tailwind hosts only** — generate with `mix auix.gen.stylesheet --baseline`. Tailwind hosts already ship a preflight and must NOT import this file. |
| `auix-variables.css` | `auix.variables` | Library | `:root` / `:host` declarations for every `--auix-*` custom property |
| `auix-bridge-*.css` (e.g. `auix-bridge-daisyui.css`) | `auix.bridge` | Host | Maps host design-system tokens onto `--auix-*` variables |
| `auix-custom.css` | `auix.bridge` | Host | Token-level overrides that sit in the same layer as the bridge (opt-in; see below) |
| `auix-rules.css` | `auix.rules` | Library | `.auix-*` component rules that consume the custom properties |

The library regenerates `auix-variables.css` and `auix-rules.css` on every
`mix auix.gen.stylesheet` run. The bridge, custom, and baseline files are host-owned:
the task copies or creates them on first run (each behind its own opt-in flag where
applicable) and skips them on subsequent runs unless `--force` is passed.

## Choosing an integration path

**Variables + rules only.** Import `auix-variables.css` and `auix-rules.css` directly (or the
`auix-stylesheet.css` shim). The components render using Aurora UIX's built-in defaults with no
host-theme integration. This is the fastest path to a working UI.

**Non-Tailwind hosts: add `auix-baseline.css`.** Plain CSS apps, vanilla Phoenix apps, and
Web Component hosts have no preflight to normalise `html`, `body`, and `a`. Generate the
opt-in baseline stylesheet with `mix auix.gen.stylesheet --baseline`, then import it
**before** `auix-variables.css`. Tailwind v4 hosts already ship a preflight and must skip
this file — see [Hosts without Tailwind](#hosts-without-tailwind) below.

**Bridge.** Add the daisyUI bridge (`auix-bridge-daisyui.css`) or write your own. The bridge
maps your framework's semantic tokens onto `--auix-*` variables so every component follows
theme changes (dark mode, brand tokens, etc.) automatically. See
[Writing a Style Bridge](../advanced/writing_a_style_bridge.md) for authoring guidance.

**Recommended: style bridge + `auix-custom.css`.** For hosts that already use a style bridge but need a
few additional per-project tweaks, an `auix-custom.css` file provides a safe override layer
that sits at the same cascade level as the style bridge. Token overrides written here take effect
without modifying either library file. Run `mix auix.gen.stylesheet --custom` to scaffold the
stub on first use.

**Escape hatch: semantic class overrides.** When a desired visual change cannot be expressed
with a token override (e.g. restructuring flex layout), you can override `.auix-*` class rules
directly. This is intentionally last-resort; see [Escape hatch: semantic class overrides](#escape-hatch-semantic-class-overrides).

## Recommended path: variable overrides

### Import order

```css
@import "auix-variables.css";
@import "auix-bridge-daisyui.css";  /* or your custom bridge */
@import "auix-custom.css";          /* host customizations (opt-in via --custom) */
@import "auix-rules.css";
```

### Scaffolding `auix-custom.css`

Run the following to create the stub on first use:

```sh
mix auix.gen.stylesheet --custom
```

The file is treated as host-owned and will not be overwritten on subsequent runs. Pass
`--force` together with `--custom` to regenerate it from the current theme defaults:

```sh
mix auix.gen.stylesheet --custom --force
```

Without `--custom`, the task never creates this file, so hosts that do not need it stay clean.

### Wrapping pattern

All overrides must live inside `@layer auix.bridge` to win over `auix.variables` but lose to
`auix.rules` (which provides the final component rules):

```css
@layer auix.bridge {
  :root, :host {
    --auix-border-radius-default: 0.75rem;
    --auix-color-focus-ring: #7C3AED; /* violet-600 */
  }
}
```

### Worked example: rounder corners + custom focus color

```css
/* assets/css/auix-custom.css */
@layer auix.bridge {
  :root, :host {
    /* Round all component borders */
    --auix-border-radius-default: 0.75rem;
    --auix-border-radius-small:   0.375rem;
    --auix-border-radius-large:   1.25rem;

    /* Use a violet focus ring instead of the default indigo */
    --auix-color-focus-ring: #7C3AED;
  }
}
```

Both changes take effect for every generated form, table, and modal without modifying any
library file.

## Hosts without Tailwind

Tailwind v4 ships a preflight that resets `html`, `body`, `a`, and form elements. Plain
CSS apps, vanilla Phoenix apps, and Web Component hosts have no such reset — without
one, links render with browser-default purple+underline, `body` gets its default margin,
and `html` loses the `--auix-*` font stack.

### Scaffolding `auix-baseline.css`

`auix-baseline.css` is opt-in. Run:

```sh
mix auix.gen.stylesheet --baseline
```

The file is host-owned. Subsequent runs without `--force` leave it untouched. Pass
`--force` together with `--baseline` to regenerate it from the current theme defaults:

```sh
mix auix.gen.stylesheet --baseline --force
```

### Import order

Add one extra import **before** `auix-variables.css`:

```css
@import "auix-baseline.css"; /* non-Tailwind hosts only */
@import "auix-variables.css";
@import "auix-bridge-daisyui.css";  /* or your custom bridge */
@import "auix-custom.css";          /* host customizations (opt-in via --custom) */
@import "auix-rules.css";
```

The reset uses the same `--auix-*` variables a bridge maps, so a style bridge still controls
colours and typography — the baseline and style bridge complement each other. The reset sits in
`@layer auix.baseline`, the lowest layer in the cascade, so both the style bridge and any
rules-level overrides win over it.

> **Tailwind hosts:** do not pass `--baseline` and do not import this file. Tailwind's
> preflight already normalises the same selectors, and double-resetting can produce
> subtle border and spacing regressions.

## Variable reference

### Sizes & dimensions

| Variable | Default | Affects |
|---|---|---|
| `--auix-box-size-unit` | `1rem` | Checkbox / icon base square size |
| `--auix-line-height-default` | `1.250rem` | Default line height |
| `--auix-line-height-relaxed` | `1.5rem` | Relaxed/spacious line height |
| `--auix-border-radius-default` | `0.5rem` | Most component corners |
| `--auix-border-radius-small` | `0.250rem` | Inputs, buttons, small badges |
| `--auix-border-radius-large` | `1rem` | Modals and large containers |
| `--auix-border-radius-round` | `9999px` | Pill / fully-rounded badges |
| `--auix-border-width-default` | `0.0625rem` | Standard border width |
| `--auix-border-width-thick` | `0.125rem` | Active tab underline |
| `--auix-border-style-default` | `solid` | Border style across all components |
| `--auix-gap-minimal` | `0.125rem` | Tightest flex gap |
| `--auix-gap-default` | `0.250rem` | Standard flex gap |
| `--auix-gap-medium` | `0.500rem` | Medium flex gap |
| `--auix-gap-large` | `0.750rem` | Large flex gap |
| `--auix-padding-minimal` | `0.3125rem` | Minimal padding (inputs, buttons) |
| `--auix-padding-small` | `0.250rem` | Small padding |
| `--auix-padding-default` | `0.625rem` | Standard padding |
| `--auix-padding-medium` | `0.500rem` | Medium padding |
| `--auix-padding-large` | `1.5rem` | Large padding (cards) |
| `--auix-padding-xl` | `2rem` | Extra-large padding (modal boxes) |
| `--auix-margin-default` | `0.250rem` | Standard margin |
| `--auix-margin-medium` | `0.500rem` | Medium margin |
| `--auix-input-height-default` | `1rem` | Minimum input field height |
| `--auix-button-height-default` | `2em` | Minimum button height |
| `--auix-hidden-element-size` | `1px` | Visually-hidden element dimensions |
| `--auix-focus-outline-width` | `2px` | Focus outline width |
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
| `--auix-font-size-title` | `1.125rem` | Section and page titles |
| `--auix-font-size-subtitle` | `1rem` | Subtitles and secondary headings |
| `--auix-font-size-caption` | `0.875rem` | Labels, inputs, table cells |
| `--auix-font-size-small` | `0.750rem` | Badges and helper text |
| `--auix-font-weight-bold` | `600` | Primary bold weight |
| `--auix-font-weight-bold-semi` | `400` | Secondary / semi-bold weight |
| `--auix-font-style-mobile-viewmode` | `italic` | View-mode field value style on mobile |

### Opacity

| Variable | Default | Affects |
|---|---|---|
| `--auix-opacity-20` | `0.20` | Close-button default opacity |
| `--auix-opacity-40` | `0.40` | Close-button hover opacity |
| `--auix-opacity-75` | `0.75` | Loading / disabled button opacity |
| `--auix-opacity-100` | `1` | Full opacity (disabled checkbox text) |

### Shadows & rings

| Variable | Default | Affects |
|---|---|---|
| `--auix-ring-inset` | _(empty)_ | Inset modifier for ring shadows |
| `--auix-ring-offset-shadow` | `0 0 #0000` | Ring offset transparent base |
| `--auix-ring-offset-width` | `0px` | Ring offset width |
| `--auix-ring-color` | `rgba(63, 63, 70, 0.1)` | Default ring color (white_charcoal light) |
| `--auix-ring-default` | `0 0 0 calc(1px + …) var(--auix-ring-color)` | Default focus ring |
| `--auix-ring-info` | `0 0 0 calc(1px + …) var(--auix-color-info-ring)` | Info flash ring |
| `--auix-ring-secondary` | `0 0 0 calc(1px + …) var(--auix-color-shadow-alpha)` | Secondary ring |
| `--auix-shadow-small` | `0 1px 2px 0 …` | Subtle card / input shadow |
| `--auix-shadow-default` | `0 1px 3px 0 …, 0 1px 2px -1px …` | Default component shadow |
| `--auix-shadow-md` | `0 4px 6px -1px …, 0 2px 4px -2px …` | Medium shadow (error flash) |
| `--auix-shadow-lg` | `0 10px 15px -3px …, 0 4px 6px -4px …` | Large shadow (modal, info flash) |
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
| `--auix-color-bg-light` | `#F4F4F5` | Light tinted background (groups, tabs) |
| `--auix-color-bg-hover` | `#FAFAFA` | Hover state background |
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
| `--auix-color-error-text-default` | `#E11D48` | Inline validation error text |
| `--auix-color-info-text` | `#065F46` | Info flash text |

**Borders & Focus**

| Variable | Default (light) | Affects |
|---|---|---|
| `--auix-color-border-primary` | `#D4D4D8` | Standard borders |
| `--auix-color-border-secondary` | `#E4E4E7` | Secondary borders |
| `--auix-color-border-tertiary` | `#F4F4F5` | Tertiary / hairline borders |
| `--auix-color-border-focus` | `#A1A1AA` | Input focus border color |
| `--auix-color-focus-ring` | `#6366F1` | Focus ring color (indigo-500) |
| `--auix-color-error-ring` | `#F43F5E` | Error focus ring |
| `--auix-color-info-ring` | `#10B981` | Info focus ring |
| `--auix-color-error` | `#FB7185` | Input border on validation error |

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
| `--auix-color-button-alt-bg` | `var(--auix-color-bg-light)` | Alternative button fill |
| `--auix-color-button-alt-text` | `var(--auix-color-text-tertiary)` | Alternative button text |
| `--auix-color-button-alt-border` | `var(--auix-color-text-label)` | Alternative button border |
| `--auix-color-button-iconized-bg-hover` | `var(--auix-color-bg-hover)` | Icon-only button hover fill |
| `--auix-color-input-text` | `var(--auix-color-text-primary)` | Input / textarea text |
| `--auix-color-input-border` | `var(--auix-color-border-primary)` | Input border |
| `--auix-color-input-border-focus` | `var(--auix-color-border-focus)` | Input focus border |
| `--auix-color-input-border-error` | `var(--auix-color-error)` | Input error border |
| `--auix-color-textarea-text` | `var(--auix-color-text-primary)` | Textarea text |
| `--auix-color-textarea-border` | `var(--auix-color-border-primary)` | Textarea border |
| `--auix-color-textarea-border-focus` | `var(--auix-color-border-focus)` | Textarea focus border |
| `--auix-color-textarea-border-error` | `var(--auix-color-error)` | Textarea error border |
| `--auix-color-select-border` | `var(--auix-color-border-primary)` | Select border |
| `--auix-color-select-border-focus` | `var(--auix-color-border-focus)` | Select focus border |
| `--auix-color-checkbox-border` | `var(--auix-color-border-primary)` | Checkbox border |
| `--auix-color-checkbox-text` | `var(--auix-color-text-primary)` | Checkbox checkmark color |
| `--auix-color-checkbox-label-text` | `var(--auix-color-text-secondary)` | Checkbox label text |
| `--auix-color-label-text` | `var(--auix-color-text-label)` | Generic field label text |
| `--auix-color-horizontal-divider` | `var(--auix-color-border-primary)` | Horizontal rule color |
| `--auix-color-flash-close-text` | `var(--auix-color-text-secondary)` | Flash close-button icon |
| `--auix-color-form-container-bg` | `var(--auix-color-bg-default)` | Form container background |
| `--auix-color-group-container-bg` | `var(--auix-color-bg-light)` | Group/card container background |
| `--auix-color-group-container-border` | `var(--auix-color-border-primary)` | Group/card container border |
| `--auix-color-show-content-bg` | `var(--auix-color-bg-default)` | Show-view content background |
| `--auix-color-header-title-text` | `var(--auix-color-text-label)` | Page/section header title |
| `--auix-color-header-subtitle-text` | `var(--auix-color-text-secondary)` | Page/section header subtitle |
| `--auix-color-sections-tab-active-text` | `var(--auix-color-text-label)` | Active tab label |
| `--auix-color-sections-tab-active-bg` | `var(--auix-color-bg-light)` | Active tab background |
| `--auix-color-sections-tab-active-border` | `var(--auix-color-bg-light)` | Active tab underline |
| `--auix-color-sections-tab-inactive-bg` | `var(--auix-color-bg-hover)` | Inactive tab background |
| `--auix-color-sections-content-border` | `var(--auix-color-bg-light)` | Tab panel border |
| `--auix-color-items-table-header-text` | `var(--auix-color-text-tertiary)` | Table column header text |
| `--auix-color-items-table-body-border` | `var(--auix-color-border-secondary)` | Table row separator |
| `--auix-color-items-table-body-text` | `var(--auix-color-text-hover)` | Table cell text |
| `--auix-color-items-table-row-bg-hover` | `var(--auix-color-bg-hover)` | Table row hover background |
| `--auix-color-items-card-item-content-text` | `var(--auix-color-text-primary)` | Card item text |
| `--auix-color-list-item-title-text` | `var(--auix-color-text-tertiary)` | List item title |
| `--auix-color-list-item-content-text` | `var(--auix-color-text-hover)` | List item body text |
| `--auix-color-list-container-divider` | `var(--auix-color-bg-light)` | List row separator |
| `--auix-color-pagination-current-bg` | `var(--auix-color-bg-default--reverted)` | Current page button fill |
| `--auix-color-pagination-current-text` | `var(--auix-color-text-on-accent)` | Current page button text |
| `--auix-color-pagination-current-border` | `var(--auix-color-border-focus)` | Current page button border |
| `--auix-color-back-link-text` | `var(--auix-color-text-primary)` | Back-navigation link text |
| `--auix-color-back-link-text-hover` | `var(--auix-color-text-hover)` | Back-navigation link hover text |
| `--auix-color-embeds-bg` | `var(--auix-color-bg-inner-container)` | Embedded relation container background |
| `--auix-color-embeds-border` | `var(--auix-color-border-secondary)` | Embedded relation container border |
| `--auix-color-embeds-many-badge-bg` | `var(--auix-color-bg-default--reverted)` | Embedded many badge fill |
| `--auix-color-embeds-many-badge-text` | `var(--auix-color-text-on-accent)` | Embedded many badge text |
| `--auix-color-one-to-many-text` | `var(--auix-color-text-primary)` | One-to-many relation text |
| `--auix-color-one-to-many-border` | `var(--auix-color-border-primary)` | One-to-many relation border |
| `--auix-color-form-field-input-border` | `var(--auix-color-border-primary)` | Form field input border |
| `--auix-color-form-field-input-border-focus` | `var(--auix-color-focus-ring)` | Form field focus border |
| `--auix-color-filter-input-border` | `var(--auix-color-border-primary)` | Filter input border |
| `--auix-color-filter-input-border-focus` | `var(--auix-color-focus-ring)` | Filter input focus border |
| `--auix-color-filter-card-border` | `var(--auix-color-border-primary)` | Filter card border |

## Recipe table

Common visual adjustments and the minimal set of variables to override:

| Goal | Override |
|---|---|
| Denser forms | `--auix-padding-minimal`, `--auix-padding-default`, `--auix-gap-default` |
| Rounder corners | `--auix-border-radius-default`, `--auix-border-radius-small`, `--auix-border-radius-large` |
| Larger touch targets | `--auix-button-height-default`, `--auix-input-height-default`, `--auix-padding-default` |
| Custom focus ring | `--auix-color-focus-ring`, `--auix-color-form-field-input-border-focus` |
| Error palette | `--auix-color-error`, `--auix-color-error-bg`, `--auix-color-error-text`, `--auix-color-error-ring` |
| Monospace inputs | `--auix-font-family-default` set to `var(--auix-font-mono)` |
| Brand primary color | `--auix-color-button-bg`, `--auix-color-button-text`, `--auix-color-bg-default--reverted` |
| Dark backgrounds | `--auix-color-bg-default`, `--auix-color-bg-light`, `--auix-color-bg-hover` |
| Tighter list rows | `--auix-gap-minimal`, `--auix-padding-minimal`, `--auix-margin-default` |
| Bolder labels | `--auix-font-weight-bold`, `--auix-color-text-label` |

## Rule: one color class per element

An element may carry multiple CSS classes, but at most one of them may set `color`,
`background-color`, or `border-color`. The classes ending in a BEM modifier (`--alt`,
`--errors`, `--iconized`) and the named full-variant classes (`.auix-index-all-action-button`)
are the color-bearing classes. Structural bases like `.auix-button-default` and size utilities
like `.auix-icon-size-5` are color-neutral and safe to combine freely with a color class.

When adding a brand variant, mirror the same pattern — declare a single class that sets
color rules only (no `padding`, `border-width`, `font-*`, etc.) and let the component's
structural base handle the rest:

```css
/* ✅ Color-only variant — safe to layer on top of .auix-button-default */
.my-host-app .auix-button--promo {
  background-color: var(--my-brand-promo);
  color: var(--my-brand-promo-text);
}
```

## Escape hatch: semantic class overrides

When a variable override cannot express the desired structural change — for example, switching
a component's flex direction or inserting an additional layout layer — you can override the
`.auix-*` class rules directly.

> **Warning:** The class names listed below are a semi-public API.
> They may be renamed, split, or removed in any release without
> prior deprecation. Changes will be called out in `CHANGELOG.md`
> under a dedicated **CSS class changes** subsection. If you
> override these classes, you are accepting that responsibility.
> Prefer variable overrides whenever they can express the change.

### Class reference

| Class | Used by | Tokens it consumes |
|---|---|---|
| `.auix-button-default` | Structural base auto-applied to every `<.button>` (layout, border, padding, typography — no color) | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-small`, `--auix-padding-minimal`, `--auix-font-size-caption`, `--auix-font-weight-bold` |
| `.auix-button` | Primary color variant (default for `<.button>` when no variant is passed) | `--auix-color-button-bg`, `--auix-color-button-text`, `--auix-color-bg-hover--reverted`, `--auix-color-text-on-accent-active`, `--auix-opacity-75` |
| `.auix-button--alt` | Secondary / alternative button (caller-supplied via `class=`; sits on top of the auto-applied `.auix-button-default` — never combine with `.auix-button`) | `--auix-color-button-alt-bg`, `--auix-color-button-alt-text`, `--auix-color-button-alt-border`, `--auix-color-bg-hover`, `--auix-color-text-inactive` |
| `.auix-index-all-action-button` | Select-all / deselect-all index-bar variant — color only; replaces, not supplements, `.auix-button` | `--auix-color-button-bg`, `--auix-color-button-text` |
| `.auix-button--iconized` | Icon-only button (no border) | `--auix-color-bg-secondary` (hover) |
| `.auix-button-badge` | Embedded-relation count badge | `--auix-font-size-small`, `--auix-border-radius-round`, `--auix-padding-minimal` |
| `.auix-input` | Text / number / date inputs | `--auix-padding-minimal`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-small`, `--auix-color-input-text`, `--auix-font-size-caption` |
| `.auix-input--errors` | Input in validation-error state | `--auix-color-input-border-error` |
| `.auix-textarea` | Multi-line textarea | `--auix-padding-minimal`, `--auix-border-width-default`, `--auix-border-style-default`, `--auix-border-radius-small`, `--auix-color-textarea-text`, `--auix-font-size-caption` |
| `.auix-textarea--errors` | Textarea in validation-error state | `--auix-color-textarea-border-error` |
| `.auix-select` | Dropdown select | `--auix-border-radius-small`, `--auix-border-width-default`, `--auix-color-select-border`, `--auix-color-bg-default`, `--auix-shadow-small`, `--auix-padding-minimal`, `--auix-padding-medium`, `--auix-box-size-unit` |
| `.auix-select-label` | Label paired with a select | Structural only |
| `.auix-checkbox` | Checkbox input | `--auix-box-size-unit`, `--auix-margin-default`, `--auix-border-width-default`, `--auix-border-radius-small`, `--auix-color-checkbox-border`, `--auix-color-bg-default`, `--auix-color-checkbox-text`, `--auix-opacity-100` |
| `.auix-checkbox-label` | Label paired with a checkbox | `--auix-font-size-caption`, `--auix-color-checkbox-label-text` |
| `.auix-fieldset` | Form fieldset wrapper | `--auix-gap-default`, `--auix-font-size-caption` |
| `.auix-modal` | Modal root (hidden by default) | Structural only |
| `.auix-modal-box` | Modal positioning container | Structural only |
| `.auix-modal-focus-wrap` | Modal visible panel | `--auix-border-radius-large`, `--auix-color-bg-default`, `--auix-padding-xl`, `--auix-shadow-lg`, `--auix-shadow-secondary`, `--auix-ring-offset-shadow`, `--auix-ring-secondary`, `--auix-border-width-default` |
| `.auix-modal-close-button` | Modal close (×) button | `--auix-border-width-default`, `--auix-border-radius-small`, `--auix-opacity-20`, `--auix-opacity-40` |
| `.auix-flash` | Flash notification container | `--auix-margin-default`, `--auix-gap-minimal`, `--auix-border-radius-default`, `--auix-padding-default` |
| `.auix-flash--info` | Info-variant flash | `--auix-color-bg-info`, `--auix-color-info-text`, `--auix-color-icon-fill`, `--auix-ring-info`, `--auix-shadow-primary` |
| `.auix-flash--error` | Error-variant flash | `--auix-color-error-bg`, `--auix-color-error-text`, `--auix-color-error-ring`, `--auix-shadow-md` |
| `.auix-flash-title` | Flash notification title row | `--auix-font-size-caption`, `--auix-font-weight-bold` |
| `.auix-flash-message` | Flash notification body text | `--auix-font-size-caption` |
| `.auix-simple-form-content` | Form fields wrapper | `--auix-gap-default` |
| `.auix-simple-form-actions` | Form submit/cancel button row | `--auix-gap-default` |
| `.auix-actions` | Generic action bar | `--auix-gap-default` |
| `.auix-horizontal-divider` | Horizontal rule separator | `--auix-border-width-default`, `--auix-color-horizontal-divider`, `--auix-margin-default` |
| `.auix-sections-tab-button` | Section/tab navigation button | `--auix-padding-minimal`, `--auix-padding-default`, `--auix-font-size-caption`, `--auix-border-width-thick`, `--auix-border-radius-default` |

### Scoping example

Scope overrides to a specific host section to avoid leaking into unrelated components:

```css
/* Overrides the primary color variant only; sibling variants (.auix-button--alt,
   .auix-index-all-action-button) are unaffected and need their own override if
   matching brand color is desired there. */
.my-host-app .auix-button {
  background-color: var(--my-brand);
}
```

## Verifying your overrides

- **Inspect computed values.** Open DevTools → Elements → Computed and search for
  `--auix-` to see the resolved values in context.
- **Confirm layer precedence.** In Chrome DevTools Styles pane, each rule shows its
  `@layer`. Check that your override is in `auix.bridge` and is not crossed out by a
  higher-specificity rule in `auix.rules`.
- **Visual smoke-test.** Navigate to a generated index, form, or show page in the dev
  server and verify the change is visible across components.
- For non-Tailwind hosts: confirm `auix-baseline.css` is imported by checking
  for `@layer auix.baseline` rules in the DevTools Styles pane on `<html>` or
  `<body>`. If absent, link styling will fall back to browser defaults; if you
  never generated the file, re-run `mix auix.gen.stylesheet --baseline`.
