# Styling Aurora UIX in a Host Application

Aurora UIX renders all of its generated components against a set of `--auix-*` CSS custom
properties. This guide shows how to align those properties with your host application's design
system — either by remapping them through a style bridge file or by overriding individual tokens
directly — without touching any library source.

The stylesheet is pure CSS by design: custom properties and `.auix-*` rules in native cascade
layers, with nothing that needs Tailwind or another framework to process it. That leaves the host
free to choose how the files reach the page: imported into a Tailwind v4 `app.css`, bundled by
esbuild or another tool, or served as plain stylesheets.

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

> #### Re-run the generator after every upgrade {: .warning}
>
> `auix-variables.css` and `auix-rules.css` are build artifacts pinned to the Aurora UIX
> version that generated them — they are **not** read from the library at runtime. Run
> `mix auix.gen.stylesheet` again after every `aurora_uix` upgrade. Skipping it leaves any
> `.auix-*` rule or `--auix-*` variable added by the new version absent from your CSS, which
> shows up as a component silently losing styling the theme does define (a list rendering
> without its bullets, a label without its color) rather than as a build error.

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
[Writing a Style Bridge](writing_a_style_bridge.md) for authoring guidance.

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
@import "./auix-variables.css";
@import "./auix-bridge-daisyui.css";  /* or your custom bridge */
@import "./auix-custom.css";          /* host customizations (opt-in via --custom) */
@import "./auix-rules.css";
```

`auix-stylesheet.css` imports only `auix-variables.css` and `auix-rules.css`. With a bridge or
`auix-custom.css`, list the files as above, or import the shim and then the files it leaves out:

```css
@import "./auix-stylesheet.css";
@import "./auix-bridge-daisyui.css";  /* or your custom bridge */
@import "./auix-custom.css";
```

Both forms give the same result. `auix-variables.css` declares the layer order
(`auix.variables`, `auix.bridge`, `auix.rules`) before any rule, so a bridge or custom override
wins over the defaults wherever it is imported, and the rules read the `--auix-*` variables when
the page renders, not when they are imported.

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

Overrides normally live inside `@layer auix.bridge` to win over `auix.variables` but lose to
`auix.rules` (which provides the final component rules):

```css
@layer auix.bridge {
  :root, :host {
    --auix-border-radius-default: 0.75rem;
    --auix-color-focus-ring: #7C3AED; /* violet-600 */
  }
}
```

Alternatively, the same `:root, :host` block may be placed *outside* all layers. Unlayered
CSS wins over every layer — including `auix.rules` — so this is the more forceful variant:
use it when an override must also beat component rules, or when a bundler or minifier
mishandles layered custom properties. Two things to keep in mind either way: Lightning CSS
(the minifier behind Tailwind v4's `--minify`) merges `:root, :host` rules that share a
layer (the bridge and `auix-custom.css` both sit in `auix.bridge`) and keeps only the
**last** declaration of each custom property, so the import order shown above is
load-bearing in release builds; and unlayered overrides apply unconditionally, so theme
switching in lower layers can no longer affect the overridden tokens.

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
@import "./auix-baseline.css"; /* non-Tailwind hosts only */
@import "./auix-variables.css";
@import "./auix-bridge-daisyui.css";  /* or your custom bridge */
@import "./auix-custom.css";          /* host customizations (opt-in via --custom) */
@import "./auix-rules.css";
```

The reset uses the same `--auix-*` variables a bridge maps, so a style bridge still controls
colours and typography — the baseline and style bridge complement each other. The reset sits in
`@layer auix.baseline`, the lowest layer in the cascade, so both the style bridge and any
rules-level overrides win over it.

> **Tailwind hosts:** do not pass `--baseline` and do not import this file. Tailwind's
> preflight already normalises the same selectors, and double-resetting can produce
> subtle border and spacing regressions.

## Tailwind v3 hosts

The import examples in this guide are written for Tailwind v4. Tailwind v3 processes `@layer`
itself and accepts only `base`, `components` and `utilities`, so importing the Aurora UIX files
into a v3 `app.css` fails on `@layer auix.variables`. The files need no Tailwind processing, so the
workaround is to keep them out of Tailwind's input and bundle them separately with esbuild, which
keeps native cascade layers as they are.

Create `assets/css/auix.css` with the imports from [Import order](#import-order):

```css
@import "./auix-variables.css";
@import "./my-bridge.css";            /* optional: your bridge (see daisyUI below) */
@import "./auix-custom.css";          /* host customizations (opt-in via --custom) */
@import "./auix-rules.css";
```

Add an esbuild profile for it in `config/config.exs`:

```elixir
config :esbuild,
  auix: [
    args: ~w(css/auix.css --bundle --outdir=../priv/static/assets/css),
    cd: Path.expand("../assets", __DIR__)
  ]
```

Run `esbuild auix` next to the existing profiles in the `assets.build` and `assets.deploy`
aliases (add `--minify` for deploy) and, in development, add
`auix: {Esbuild, :install_and_run, [:auix, ~w(--watch)]}` to the endpoint's `watchers`. Then load
the bundle in the root layout, next to the `app.css` link:

```heex
<link phx-track-static rel="stylesheet" href={~p"/assets/css/auix.css"} />
```

Two more differences from v4:

- **Icons:** v3 has no `@source`. Add `"../deps/aurora_uix/priv/static/classes.js"` to `content`
  in `tailwind.config.js`, so the Heroicons plugin generates the `hero-*` classes Aurora UIX uses.
- **daisyUI:** `auix-bridge-daisyui.css` maps daisyUI 5 tokens (`--color-primary`, …). daisyUI 4,
  which pairs with Tailwind v3, uses other variable names, so leave the bridge out or write your
  own (see [Writing a Style Bridge](writing_a_style_bridge.md)).

Tailwind v3 ships a preflight, so skip `auix-baseline.css` as for v4.

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

## Recipe table

Common visual adjustments and the minimal set of variables to override:

| Goal | Override |
|---|---|
| Denser forms | `--auix-padding-minimal`, `--auix-padding-default`, `--auix-gap-default` |
| Rounder corners | `--auix-border-radius-default`, `--auix-border-radius-small`, `--auix-border-radius-large` |
| Larger touch targets | `--auix-control-height`, `--auix-touch-target-size` |
| Custom focus ring | `--auix-color-focus-ring`, `--auix-color-focus-ring-halo` |
| Error palette | `--auix-color-error`, `--auix-color-error-bg`, `--auix-color-error-text`, `--auix-color-error-ring` |
| Monospace inputs | `--auix-font-family-default` set to `var(--auix-font-mono)` |
| Brand primary color | `--auix-color-button-bg`, `--auix-color-button-text`, `--auix-color-bg-default--reverted` |
| Dark backgrounds | `--auix-color-bg-default`, `--auix-color-bg-light`, `--auix-color-bg-hover` |
| Tighter list rows | `--auix-gap-minimal`, `--auix-padding-minimal`, `--auix-margin-default` |
| Larger page title only | `--auix-font-size-title` (group headings and empty states stay put) |
| Flat groups (0.2.0 look) | `--auix-color-group-container-bg`, `--auix-color-group-container-border` and `--auix-color-group-title-border` set to `transparent` |
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

## Related guides

- [Customizing & Extending Aurora UIX](customization.md) — the central customization hub
- [Writing a Style Bridge](writing_a_style_bridge.md) — map host design-system tokens onto `--auix-*` variables
- [Creating Custom Registered Themes](theming.md) — author a registered theme module instead of overriding tokens
- [Overriding Components](overriding_components.md) — replace component implementations at runtime
