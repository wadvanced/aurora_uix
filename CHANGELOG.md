# Changelog for Aurora UIX

## [0.1.5]

**Runtime Component Overrides & Guide Reorganization**

Aurora UIX has grown significantly across recent releases, and this version takes the opportunity to realign the documentation with the current feature set. 
A dedicated **Customization & Extension** section has been introduced, consolidating related guides into a single, navigable reference area.

This release also delivers a runtime mechanism for overriding individual UI components without requiring to fork the library.

Requires:
- Elixir `1.17+`
- Phoenix `1.8+`
- Phoenix LiveView `1.1+`
- Ecto `3.13+`

### Added

- **Runtime component override mechanism**
  - `Aurora.Uix.ComponentsResolver` and `Aurora.Uix.ComponentsResolverHelper` — macro-based system enabling per-function component overrides resolved at call time
  - Each component module (`CoreComponents`, `Components`, `FilteringComponents`, `RoutingComponents`) registers with a unique `Application` env key
  - Hosts configure overrides via `config :aurora_uix, :core_components, MyApp.MyCoreComponents` (and analogous keys for the other component groups)
  - Partial overrides: missing functions fall back to Aurora UIX defaults automatically via `function_exported?/3` — override modules only need to define what they want to replace
  - See `guides/customization/overriding_components.md`

- **New guides supporting existing documentation**
  - `guides/customization/custom_actions.md` — UI action operations guide (extracted from `layouts.md`)
  - `guides/customization/theming.md` — registered theme module creation guide (extracted from `advanced_usage.md`)

- **Central customization hub** — `guides/customization/customization.md` with an at-a-glance decision table linking all seven customization mechanisms

### Changed

- **Guide reorganization moved styling content into a dedicated section**
  - `guides/core/styling.md` → `guides/customization/styling.md`
  - `guides/advanced/writing_a_style_bridge.md` → `guides/customization/writing_a_style_bridge.md`
  - Updated all cross-references across guides, README, CONTRIBUTING, `mix.exs` extras configuration, and docstrings

- **Updated `mix.exs` extras grouping** — added a new `"Customization & Extension"` section group; renamed the former `Core` group to `"Core Concepts"`; expanded the `Introduction` group to include `guides/overview/` entries

- **Simplified `CoreComponentsImporter`** — removed the deprecated `core_components_module` option, now superseded by the new runtime component resolver

### Documentation

- `guides/customization/overriding_components.md` — full reference with per-override-key function tables and configuration examples
- `guides/customization/customization.md` — hub page linking all customization mechanisms
- `guides/customization/custom_actions.md` — comprehensive guide on adding, replacing, inserting, and removing UI action buttons
- `guides/customization/theming.md` — guide for authoring custom registered themes
- Updated internal references across all existing core and advanced guides to point to the new customization paths


## [0.1.4] - 2026-06-07

**Ash Framework improved support** - Changes in this release comes from the experience of adopting aurora_uix on real applications

Requires:
- Elixir `1.17+`
- Phoenix `1.8+`
- Phoenix LiveView `1.1+`
- Ecto `3.13+`

### Added

- **File-upload support via `data.upload` field config** [#251](https://github.com/wadvanced/aurora_uix/issues/251)
  - A resource field can now carry a LiveView upload by setting `data: %{upload: %{allow: [...], consume: &fun/1}}`.
  - The library registers uploads via `allow_upload/3`, renders `live_file_input` with entry progress and cancel buttons, and invokes the `:consume` callback on save.
  - Purely additive — fields without `data.upload` are unaffected.
  - **Download support**: add a `:download` producer callback (arity 1–3) to show a Download button on show and edit views. The callback receives the stored field value and returns `{:ok, %{name: filename, content: binary}}`, `:no_download`, or `{:error, reason}`. An optional `:downloadable?` gate callback (same arities) controls whether the button renders at all.
  - See `guides/core/resource_metadata.md` for the `data.upload` configuration reference.

- **Actor threading for policy-protected Ash resources** [#253](https://github.com/wadvanced/aurora_uix/issues/253)
  - `auix_resource_metadata` accepts `ash_actor_assign: :current_user` (or any other socket-assigns key). The named actor is forwarded as `actor:` to every generated Ash call: `Ash.read/2`, `Ash.get/3`, `Ash.create/3`, `Ash.update/3`, `Ash.destroy/2`, `Ash.load/3`, and `AshPhoenix.Form.for_update/3`.
  - Backward-compatible: omitting `ash_actor_assign` keeps the previous behaviour. A `nil` actor (assign missing or unset) is also a no-op — no `actor:` is added.
  - `authorize?:` is **never** set explicitly; the host domain's `authorize` config (`:by_default` / `:when_requested` / `:always`) continues to decide whether policies run.
  - Forbidden reads on policy-protected resources now render an empty index (instead of crashing) — `Ash.Error.Forbidden` is translated to an empty list for `list/2`, `list_function_paginated/2`, and `to_page/4`. Writes still propagate the error so the form handler can flash it.
  - Adds a new `socket_opts/2` callback to the `Aurora.Uix.Integration.Crud` behaviour; the Ash backend resolves the actor from `socket.assigns`, the Ctx backend ignores it. `Connector` stays neutral — the new `actor_assign` field lives on the Ash `CrudSpec`.
  - See `guides/core/ash_integration.md#authorization--policies`.

- **Styling guide and customization scaffold** — new [Styling](./guides/core/styling.md) guide; `mix auix.gen.stylesheet --custom` seeds an opt-in `auix-custom.css` stub for token-level overrides (add `--force` to refresh an existing stub).

- **Non-Tailwind baseline stylesheet (opt-in)** — `mix auix.gen.stylesheet --baseline` scaffolds `assets/css/auix-baseline.css`, a tag-selector reset (`html`, `body`, `a`) for hosts without a CSS preflight. Host-owned once created; refresh with `--baseline --force`. Tailwind hosts skip the flag and the file. See [Hosts without Tailwind](./guides/core/styling.md#hosts-without-tailwind).

- **New `mix auix.gen.tailwind_classes` task** — scans Aurora UIX source files for Heroicon class names and writes a minimal JS safelist to `priv/static/classes.js`. Host Tailwind configs can reference this file with `@source "../deps/aurora_uix/priv/static/classes.js"` instead of scanning the entire dependency tree.

- **New introspection functions on UI modules**
  - `auix_layout_trees/0` — returns the layout trees as defined (excluding auto-generated defaults).
  - `auix_configurations/0` — returns the full configuration map from which all UI is generated; useful for debugging and tooling.

- **Complete Gettext backend with automatic POT generation**
  - `Aurora.Uix.GettextBackend` now implements all three `Gettext.Backend` callbacks:
    `handle_missing_translation/5`, `handle_missing_plural_translation/7`, and
    `handle_missing_bindings/2`.
  - Missing singular and plural translations are appended as stubs to the matching `.pot`
    file when `gettext_pot_path` is configured, keeping translation templates in sync with
    the UI without manual editing.
  - New `gettext_show_warnings?` config key (default `false`) opts in to `Logger.warning`
    emission for missing translations during development. Configure in `config/dev.exs`.
  - New `gettext_domain` config key (compile-time) isolates Aurora UIX strings in their own
    Gettext domain, preventing `mix gettext.merge` from intermixing them with host strings.
  - See the new [Internationalization guide](./guides/core/internationalization.md).

### Changed

- **Stylesheet split for host-theme inheritance** [#259](https://github.com/wadvanced/aurora_uix/issues/259)
  - `mix auix.gen.stylesheet` now writes three files instead of one:
    - `auix-variables.css` — all `:root` / `--auix-*` custom-property declarations (sizes, colors, shadows, palette variants).
    - `auix-rules.css` — all `.auix-*` component rules that consume those variables.
    - `auix-stylesheet.css` — back-compat shim that re-imports the two files above. Existing hosts importing only this file continue to work unchanged.
  - On first run the task also copies `assets/css/auix-bridge-daisyui.css` into the host project — a small CSS file that maps daisyUI v5 tokens (`--color-primary`, `--color-base-100`, `--radius-field`, …) onto `--auix-*` variables so Aurora UIX components follow the host theme automatically. The file is treated as user-editable and is not overwritten on subsequent runs; pass `--force` to refresh it from the library version.
  - Hosts using Tailwind v4 + daisyUI import the files in this order in `app.css`:
    ```css
    @import "auix-variables.css";
    @import "auix-bridge-daisyui.css";
    :root { /* optional per-host overrides */ }
    @import "auix-rules.css";
    ```
  - Added `guides/advanced/writing_a_style_bridge.md` — a guide for authoring a custom bridge for any design system other than daisyUI.
  - `ThemeHelper` gained two new public functions: `generate_variables_stylesheet/0` and `generate_rules_stylesheet/0`.

- **Updated Dependencies**
  - `ash`: `3.16.0` → `3.27.8`
  - `ash_phoenix`: `2.3.19` → `2.3.23` 
  - `ash_postgres`: `2.6.31` → `2.9.1`
  - `bandit`: `1.10.2` → `1.12.0`
  - `credo`: `1.7.16` → `1.7.19`
  - `doctor`: `0.22.0` → `0.23.0`
  - `ecto_sql`: `3.13.4` → `3.14.0`
  - `ex_doc`: `0.40.1` → `0.40.3`
  - `image`: `0.63.0` → `0.68.0`
  - `phoenix`: `1.8.3` → `1.8.7`
  - `phoenix_live_view`: `1.1.22` → `1.1.31`
  - `postgrex`: `0.22.0` → `0.22.2`


### Fixes

- **`auix_resource/1` returned a map instead of a struct** — calling `auix_resource(:name)` on a metadata module previously returned a single-key map wrapping the resource. It now returns the `Aurora.Uix.Resource` struct directly.

### CSS class changes

- **`.auix-button` no longer carries structural rules** (`display`, `border-*`, `padding`, `font-*`).
  Structure has moved to `.auix-button-default`, which is now auto-applied by the `<.button>`
  component. Hosts that selected `.auix-button` to override padding or borders should switch
  their selector to `.auix-button-default`.
- **`.auix-button-default` is now a public/semi-public class.** Hosts that previously applied
  `.auix-button` directly (without going through `<.button>`) will now receive only the color
  rules. Add `.auix-button-default` explicitly to restore the structural styles.
- **`.auix-index-all-action-button` lost its structural declarations** (previously duplicated
  from `.auix-button`). Visible behaviour is identical when the button is rendered through
  `<.button>` as intended, because `.auix-button-default` is auto-applied.


## [0.1.3] - 2026-02-15

**Ash Framework Integration & Improvements** - This release adds full support for Ash Framework as a backend alternative to Phoenix Contexts, along with custom action support and various improvements.

Requires:
- Elixir `1.17+`
- Phoenix `1.8+`
- Phoenix LiveView `1.1+`
- Ecto `3.13+`


### Added

- **Ash Framework Integration** [#208](https://github.com/wadvanced/aurora_uix/pull/208)
  - Full support for Ash Framework as a backend alternative to Phoenix Contexts
  - Automatic field parsing, pagination, and embeds support
  - Support for custom Ash actions (read, create, update, destroy)
  - See `guides/core/ash_integration.md` for details

- **Custom Action Support** [#214](https://github.com/wadvanced/aurora_uix/pull/214)
  - Support for custom backend actions via resource metadata options
  - Custom Ash actions: `:ash_read_action`, `:ash_create_action`, `:ash_update_action`, etc.
  - Custom Context functions: `:ctx_list_function`, `:ctx_create_function`, etc.
  - See resource metadata guide for configuration options

- **Integration Architecture**
  - New connector behaviour for backend abstraction
  - Unified CRUD and field parser interfaces
  - Automatic backend type detection (`:ctx` or `:ash`)


### Changed

- **Refactored Integration Layer**
  - Improved separation of concerns between parsers and CRUD operations
  - Enhanced support for custom functions in Context-based backends
  
- **Enhanced Parser Module**
  - Extended to support both Context and Ash backends
  - Improved error handling and validation

- **Unified Handler Callback Pattern**
  - All handler implementations now follow a consistent `auix_*` callback pattern
  - Added `auix_mount/3`, `auix_handle_params/3`, `auix_handle_event/3`, `auix_handle_info/2`, `auix_handle_async/3` to IndexImpl
  - Added `auix_update/2` to FormImpl and ShowComponentImpl
  - All callbacks properly marked as `@callback` and `defoverridable`
  - Phoenix callbacks remain overridable for advanced use cases
  - See `guides/core/liveview.md` for comprehensive callback documentation
  
- **Updated Dependencies**
  - `ash`: `3.12.0` → `3.16.0`
  - `ash_postgres`: `2.6.27` → `2.6.31`
  - `bandit`: `1.10.1` → `1.10.2`
  - `credo`: `1.7.15` → `1.7.16`
  - `ex_doc`: `0.39.3` → `0.40.1`
  - `lazy_html`: `0.1.8` → `0.1.10`
  - `phoenix_live_view`: `1.1.19` → `1.1.22`


### Fixed

- Record navigator incorrectly rendered in new entry forms [#213](https://github.com/wadvanced/aurora_uix/pull/223)
- Failure to detect `embeds_one` or `embeds_many` in some cases
- Error resolving default function in `:ctx` type backends
- Missing HTML type assignment for certain field types


### Documentation

- Added comprehensive Ash Framework integration guide (`guides/core/ash_integration.md`)
- Updated resource metadata guide with backend-specific examples
- Updated LiveView integration guide with unified callback pattern documentation (`guides/core/liveview.md`)
  - Callback reference tables for IndexImpl, FormImpl, and ShowComponentImpl
  - Distinction between Aurora UIX callbacks and Phoenix callbacks
  - Examples and guidance for customization
- Corrected QueryBuilder documentation in layouts guide (`guides/core/layouts.md`)


### Build

- Excluded guide modules from Hex package distribution
- Updated test environment for Ash resources
- Added Ash dependencies for development and testing


## [0.1.2] - 2026-01-14

**Record Navigation** - Now users can navigate back and forth while editing or viewing records.

Requires:
- Elixir `1.17+`
- Phoenix `1.7+`
- Phoenix LiveView `1.0+`
- Ecto `3.2+`


### Added

- Record navigation feature for show and edit views that added
  navigation controls to move among records without returning to index
- Option to disable record navigation when needed


### Changed

- Updated dependencies to latest versions


### Fixed

- Navigation issues by implementing fallback URI handling
- Section switching when in show record mode


## [0.1.1] - 2025-01-07

**Show Component Refactor** - In this release, the show live view is no longer generated. Instead, a show component 
(LiveComponent) is now used within the Index LiveView. This is a preparatory step towards implementing record 
navigation in show and edit modals.

Requires:
- Elixir `1.17+`
- Phoenix `1.7+`
- Phoenix LiveView `1.0+`
- Ecto `3.2+`


### Changed

- **Routing architecture**: Show and show_edit actions now route to `.Index` module instead of `.Show` module
  - `GET /path/:id/show` → `.Index` module with `:show` action (was `GET /path/:id` to `.Show` module)
  - `GET /path/:id/show-edit` → `.Index` module with `:show_edit` action (was `GET /path/:id/show/edit` to `.Show` module with `:edit` action)
- **Show implementation**: Replaced show LiveView module with ShowComponent (LiveComponent)
- **Handler behavior**: Show handler now uses `ShowComponentImpl` instead of `ShowImpl`


### Added

- `Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl` - New handler behavior for show LiveComponent
- `ShowComponent` generator for creating show LiveComponents
- Documentation updates reflecting new routing architecture


### Removed

- `ShowGenerator` - No longer generates standalone show LiveView modules
- `Aurora.Uix.Templates.Basic.Handlers.ShowImpl` - Replaced by `ShowComponentImpl`


### Breaking Changes

**If you are using Aurora UIX 0.1.0, review these potential breaking changes:**

1. **Manual Route Definitions**
   
   If you manually defined routes instead of using `auix_live_resources`, update them:
   
   ```elixir
   # OLD (0.1.0) - will break
   live "/:id", MyApp.Product.Show, :show
   live "/:id/show/edit", MyApp.Product.Show, :edit
   
   # NEW (0.1.1) - correct
   live "/:id/show", MyApp.Product.Index, :show
   live "/:id/show-edit", MyApp.Product.Index, :show_edit
   ```
   
   **Note**: If you used `auix_live_resources`, no changes needed - it generates correct routes automatically.

2. **Custom Show Handler Hooks**
   
   If you implemented a custom show handler using the old behavior:
   
   ```elixir
   # OLD (0.1.0) - will break
   defmodule MyApp.ProductShowHandler do
     use Aurora.Uix.Templates.Basic.Handlers.ShowImpl
     # ...custom implementation
   end
   ```
   
   Update to the new behavior:
   
   ```elixir
   # NEW (0.1.1) - correct
   defmodule MyApp.ProductShowHandler do
     use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
     # ...custom implementation
   end
   ```
   
   **Migration steps**:
   - Change `ShowImpl` to `ShowComponentImpl`
   - Update `@impl Phoenix.LiveView` to `@impl Phoenix.LiveComponent` where applicable
   - Replace `mount/3` with `update/2` if you override lifecycle callbacks
   - Handler hooks specified in layout DSL via `show_handler_module` option will continue to work

**Most users will not be affected** as these scenarios only apply if you:
- Manually defined routes (instead of using `auix_live_resources`)
- Created custom show handler implementations



## [0.1.0] - 2024-12-11

**Initial Release** - Aurora UIX 0.1.0 is the first stable release, providing a complete low-code CRUD UI generation framework for Elixir's Phoenix LiveView.

Requires:
- Elixir `1.17+`
- Phoenix `1.7+`
- Phoenix LiveView `1.0+`
- Ecto `3.2+`

### Added

#### Core Features
- **Resource Metadata System** (`auix_resource_metadata/3`)
  - Declarative resource and field configuration
  - Field-level customization: labels, placeholders, validation rules
  - Association support: `belongs_to`, `has_many`, `embeds_one`, `embeds_many`
  - Field attributes: type, precision, scale, required, readonly, hidden, disabled
  - Per-field HTML type overrides and custom rendering options

- **Layout System**
  - Layout macros: `edit_layout/3`, `show_layout/3`, `index_columns/3`
  - Layout containers: `inline/2`, `stacked/2`, `group/3`, `sections/3`, `section/3`
  - Support for complex, nested layouts
  - Flexible field organization and UI composition

- **Compile-Time Code Generation**
  - `use Aurora.Uix` macro for automatic LiveView module generation
  - Generates index, show, and edit views
  - Template generation from layout definitions
  - Zero-runtime-overhead through compile-time processing

- **View Features**
  - **Index Views**: Pagination, sorting, filtering, selection, bulk actions
  - **Show Views**: Display with read-only fields, navigation
  - **Edit Views**: Form handling, validation, error display, real-time updates

- **Association Handling**
  - One-to-many inline tables with edit/delete/add actions
  - Embeds-many collections with dynamic entry management
  - Many-to-one select fields with related data loading

- **Action System**
  - Customizable actions for index, show, form, and association layouts
  - Action groups: header, footer, row, selected, filters
  - Support for add, insert, replace, remove action operations
  - Extensible action component system

#### UI & Theming
- **Built-in Templates**
  - Basic template with Phoenix components
  - Responsive, mobile-first design
  - Light and dark theme variants

- **Core Components**
  - Form inputs with validation feedback
  - Tables with responsive behavior
  - Modals for confirmations
  - Buttons with various styles
  - Navigation components
  - Icon support via Heroicons

#### Developer Experience
- **Internationalization (i18n)**
  - Configurable Gettext backend
  - Automatic translation of UI strings
  - Support for multiple languages

- **Extensibility**
  - Custom template support via `Aurora.Uix.Template` behaviour
  - Customizable core components
  - Field renderer overrides
  - Layout container customization
  - Theme customization

- **Documentation**
  - Comprehensive guides: Overview, Getting Started, Core Concepts
  - Advanced usage documentation
  - Troubleshooting guide
  - Real-world examples

#### Infrastructure
- **Development Tools**
  - Stylesheet generator task (`mix auix.gen.stylesheet`)
  - Icon asset generator task (`mix auix.gen.icons`)
  - Development server with hot reload

- **Testing**
  - UICase test helper
  - WebCase test helper
  - Fixtures and test utilities

#### API Highlights
- **Metadata Module Functions**
  - `auix_resources/0` - Retrieve all configured resources
  - `auix_resource/1` - Get specific resource metadata
  - Metadata export for separation of concerns

- **Template API**
  - Template behavior with required callbacks
  - Module name generation helpers
  - Field omission support

- **Action API**
  - `Aurora.Uix.Action` - Action creation and management
  - `Aurora.Uix.Templates.Basic.Actions` - Action manipulation helpers
  - Helper functions: `add_auix_action`, `insert_auix_action`, `replace_auix_action`, `remove_auix_action`

### Known Limitations

- Templates currently support compile-time generation only (no dynamic template creation at runtime)
- Limited to Ecto-based schemas (other data sources require custom integration)
- CSS themes are basic and designed for light customization
- Some advanced Phoenix features (plugs, channels) require manual setup

### Fixed

- N/A (initial release)

### Security

- Form validations run both client-side and server-side
- CSRF protection via Phoenix's standard mechanisms
- No sensitive data logged or exposed in templates

---

## Future Roadmap

**Future releases may include:**
- Additional rendering components and theme options
- Simplified template creation with better hooks for customization
- Enhanced theme adoption and customization
- Query builder integration for advanced filtering
- Performance optimizations for large datasets
- GraphQL integration support
