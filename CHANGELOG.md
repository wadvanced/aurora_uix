# Changelog for Aurora UIX

## [0.1.6]

**Multi-Value Selects & Read-Only Array Fields**

This release closes a gap in array attribute handling: multi-value enums (atom or `Ecto.Enum`
arrays with a fixed option set) are now recognized as multi-selects on both backends, and scalar
arrays that carry no option set render as a read-only list instead of leaking a raw `{:array, _}`
type into the UI. Ash enum modules and `NewType`-wrapped `one_of` constraints are now also detected
as selects.

Requires:
- Elixir `1.17+`
- Phoenix `1.8+`
- Phoenix LiveView `1.1+`
- Ecto `3.13+`

### Fixes

- **Ash aggregates of kind `:first`, `:list` and `:custom` had no type, and `sum`/`max`/`min` were always `:float`**
  - The Ash parser re-derived Ash's own kind → type mapping and covered only six of the nine kinds.
    The other three fell through to the catch-all, which logged a parse error and returned the
    `Ash.Resource.Aggregate` struct's `:type` — always `nil`. The field ended up with `type: nil`
    and `html_type: nil`, could not be rendered or placed in `index_columns`, and logged on every
    compile of the host application even when no layout referenced it.
  - `sum`, `max` and `min` were pinned to `:float`, although Ash types them as the aggregated
    attribute's own type: a `sum` over a `:decimal` money column parsed as `:float`, and a `max`
    over a `:date` lost its type. They were only accidentally right when the aggregated attribute
    was already a float.
  - The mapping now delegates to `Ash.Resource.Info.aggregate_type/2` and so covers all nine kinds.
    A `:list` aggregate carries its item's type and renders read-only, like any other scalar array.
  - Two failures on the same path are fixed with it: a `custom` aggregate that declares its type by
    short name (`custom :joined, :rel, :string`) crashed the parser with
    `ArgumentError: expected an Elixir module, got: :string`, because `:string` is also an Erlang
    module and has no Elixir module path to take apart; and an aggregate over a `use Ash.Type.Enum`
    attribute yielded the enum module itself as its type instead of the scalar the enum stores.
  - Aggregates are an Ash-only concept, so the Ecto/`aurora_ctx` parser is unaffected.

- **Aggregate, calculation and association columns rendered an empty cell in the index**
  - Generated fields and associations referenced by a layout are collected into the resource's
    preload, and the `:show`, `:edit` and `:new` reads apply it — the index list query never did.
    `prepare_query_options/2` rebuilt the query from `order_by` and `where` alone and discarded
    everything else, including the `:preload` that `@allowed_query_options` had listed as allowed
    since it was introduced.
  - A `count :posts_count` aggregate therefore rendered its value on `:show` but a blank cell in an
    index listing the same field.
  - Both backends already accepted `:preload` on their list functions, so the option is simply no
    longer dropped. Resources with nothing to preload issue the same query as before.

- **The multi-select toggle-all checkbox stayed clickable on a disabled or read-only field**
  - `auix_toggle_all` didn't forward the field's `disabled`/`readonly` state to its checkbox, so a
    field the host had disabled could still have every option checked or cleared in one click through
    the select-all control, bypassing the per-option checkboxes' own disabled state.

- **Every `--auix-opacity-*` variable was undeclared, so nothing dimmed**
  - The four declarations were missing their terminating semicolons, which merged the whole run into
    a single custom property: `--auix-opacity-20` absorbed the rest as its value and `-40`, `-75`
    and `-100` were never declared at all. Each `var(--auix-opacity-*)` reference was therefore
    invalid at computed-value time and, because `opacity` is not inherited, fell back to the initial
    value `1`.
  - Visible effect of the fix: the modal close button renders at 20% (40% on hover) instead of fully
    opaque, and loading / disabled states dim again. 12 rules across `themes/base.ex` and
    `themes/baseline.ex` were affected.

- **Multi-word checkbox-group and selected-list labels broke mid-word**
  - Option labels are flex items, whose default `min-width: auto` lets them shrink past their
    natural text width down to the longest unbreakable word. Once several checkbox-group fields
    shared one `inline([...])` row, labels such as `Employer Manager` split across two lines.
  - Both the interactive option label and the read-only selected-list item are pinned to a single
    line, and their containers scroll horizontally so a long label overflows into a scroll region
    rather than breaking the row.

- **Title/subtitle layout options no longer run through dynamic-template rendering**
  - `edit_title`, `edit_subtitle`, `new_title`, `new_subtitle`, index `page_title`, and show
    `page_title`/`page_subtitle` defaults are plain interpolated strings, but
    `LayoutOptions.get_option/3` special-cased every binary title/subtitle option through
    `LayoutOptions.render_binary/2` (dynamic template evaluation) regardless. That special-case,
    and the `@title_options` list backing it, are removed — these options are returned as-is, same
    as any other string option.
  - The index subtitle `<:subtitle>` slot is now only rendered `:if` `page_subtitle` is set, instead
    of always being present with an empty-string default that rendered a blank line.
  - The `:edit_subtitle` and `:new_subtitle` form defaults previously embedded `<strong>…</strong>`
    markup around the resource name, relying on the removed `render_binary/2` raw-HTML wrapping to
    render it unescaped. Since these are plain strings now, the markup is dropped in favor of a
    plain `'…'` quoting (`"Creates a new 'Product' record in your database"`); the now-dead
    `Aurora.Uix.Layout.Options.render_binary/2` helper is removed. Also fixes `edit_subtitle` never
    being routed through `dt/1`/Gettext, unlike its `new_subtitle`/`edit_title`/`new_title` siblings.

- **Multi-value atom and enum attributes not detected as multiple selects**
  - An Ash `{:array, :atom}` with an `items: [one_of: ...]` constraint, and its Ecto counterpart
    `{:array, Ecto.Enum}`, described a set of options the user picks from, but neither parser
    recognized the array wrapper: the field never became a select and the raw type tuple leaked
    into `type` and `html_type`.
  - Cardinality travels in `data.select.multiple`, which the render layer already honored — no new
    `%Field{}` type atom was needed.
  - Multi-value selects are excluded from filtering: the filter strip renders a single-value input
    and comparing it against an array column is a query-time error.
  - The index cell now joins option labels for a multi-value select instead of raising, since
    `Phoenix.HTML.Safe` does not accept a list of atoms.
  - Guide schemas updated on both backends (`Blog.Post`, `Inventory.Product`) so a real multi-value
    enum can be exercised end-to-end in tests.

### Added

- **Separate font-size variables for group titles and index empty states**
  - `--auix-font-size-title` drove the page title, group headings and the index empty-state message
    at once, so a host that wanted a larger page title had to override `.auix-group-title` by class
    to stop group headings growing with it. `--auix-font-size-group-title` and
    `--auix-font-size-empty-state` now cover those two roles.
  - Both carry a literal `1.125rem` default rather than aliasing `--auix-font-size-title`. An alias
    would not have decoupled them: `var()` resolves against the winning cascaded value at point of
    use, across layers, so any host override of `--auix-font-size-title` would still have propagated
    through. Default rendering is unchanged; a host that wants them to track the page title can
    alias them explicitly.

- **Multi-value selects render as a checkbox group**
  - A multi-value select no longer renders as a `<select multiple>`, which needs an undiscoverable
    modifier-key gesture, is unusable on touch and has nowhere to host bulk controls. `:form` now
    renders one checkbox per option through the shared `auix_checkbox_group` component, and `:show`
    renders only the selected options as a read-only list with a `No options to show` empty state —
    the same treatment `many_to_many` already had. Index cells are unchanged.
  - Ships `:default_toggle_all`, a tri-state checkbox beside the label that selects or clears every
    option, plus label / header / footer action strips registered under the new `:multi_select`
    action group, so hosts add, replace or remove controls from the layout DSL field options.
  - **Host contract:** like `many_to_many`, the group emits a hidden empty-value sentinel so that
    unchecking the last box still submits the key and the field can be cleared. The host must reject
    that blank — see `Blog.Post.reject_blank_labels/2` (Ash, which also needs
    `constraints: [nil_items?: true]` on the attribute) and `Inventory.Product` (Ecto) for the two
    reference implementations.

- **Read-only rendering for scalar arrays**
  - A scalar array attribute with no option set (no `one_of`, no enum) has no single-value input
    that could round-trip it. Both parsers now normalize it to its item type instead of leaking
    `{:array, _}` into `html_type`, and it renders as a read-only list — the same shape a
    `many_to_many` uses for its `:show` membership — rather than a lying `<input
    type="unimplemented">`.
  - Index cells join list values for display instead of crashing on `Phoenix.HTML.Safe`.

- **Ash enum modules and `NewType`-wrapped constraints detected as selects**
  - A module implementing `use Ash.Type.Enum` keeps its values on the module rather than in the
    attribute's constraints; it is now recognized by its `values/0` behaviour and rendered as a
    select using `AshPhoenix.AshEnum.options_for_select/1`.
  - A `NewType` narrowing an `Ash.Type.Atom`/`Ash.Type.Enum` subtype now resolves through to the
    subtype's `one_of` (or the subtype's own enum module), instead of falling through to a text
    input.

- **New action-label layout options and arity-0 name/title functions**
  - `:new_action_label` (`:index`), `:save_action_label` (`:form`), and `:edit_action_label` /
    `:back_action_label` (`:show`) — configurable labels for the corresponding action buttons,
    alongside the existing title/subtitle options.
  - A resource's `:name`/`:title` metadata (set via `auix_resource_metadata/3`) can now also be a
    captured 0-arity function returning a binary, resolved via the new
    `Aurora.Uix.Layout.Options.parse_value/1`, wherever these values are interpolated into title,
    subtitle and action-label defaults. This is separate from the existing arity-1,
    `assigns`-receiving functions already supported by per-layout title/subtitle options.

### Changed

- **`Aurora.Uix.Gettext` renamed to `Aurora.Uix.GettextResolver`**
  - The old name shadowed the `Gettext` library module, so code generated inside the macro's own
    `__using__/1` block could not call `Gettext.*` directly without the ambiguity. Every internal
    `use Aurora.Uix.Gettext` call site is updated; host apps using this macro must update the same.
  - The macro's injected `backend/0` helper is now private (`gettext_backend/0`) — it is only ever
    called from code generated in the same module, and being public caused it to be pulled in by
    `import Aurora.Uix.Templates.Basic.Helpers`, conflicting with an identically-named local
    function there.

- **Group containers are now flat by default** (visual change)
  - `.auix-group-container` painted a full card — background, border, radius — but a group is
    always rendered inside a container that already paints one (`.auix-show-content`,
    `.auix-form-container` or `.auix-sections-content`), so any `group`-based layout produced
    card-inside-card. `--auix-color-group-container-bg` and `--auix-color-group-container-border`
    now default to `transparent`; padding and border width are unchanged, so spacing and vertical
    rhythm stay identical.
  - To keep the previous look, restore the two variables in your own stylesheet:
    ```css
    :root {
      --auix-color-group-container-bg: var(--auix-color-bg-light);
      --auix-color-group-container-border: var(--auix-color-border-primary);
    }
    ```

- **`Templates.Basic.Helpers.many_to_many_candidate_ids/2` renamed to `select_candidate_ids/2`**
  - It now resolves the candidate set of any multi-value select, not only a many-to-many membership.
    The implementation is unchanged; only the name and docs are.

- **Updated Dependencies**
  - ash: 3.30.1 -> 3.31.0
  - phoenix_live_reload: 1.6.2 -> 1.7.0
  - postgrex: 0.22.3 -> 0.22.4

## [0.1.5] - 2026-07-28

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

- **`has_one` association support** [#311](https://github.com/wadvanced/aurora_uix/pull/311)
  - Both parsers now normalize `has_one` to the `:one_to_one_association` field type, reusing the
    existing one-to-one machinery instead of adding a new atom. Ecto's `has_one` and Ash's `has_one`
    previously fell through to no matching clause and raised `FunctionClauseError`.
  - New `Aurora.Uix.Templates.Basic.Renderers.OneToOne` renders the association as an inline nested
    form: `:form` uses `inputs_for` so the child submits in the same POST as the parent (the library
    stays transport-only — the host's `cast_assoc`/`manage_relationship` still owns persistence);
    `:show` renders the child's fields read-only, or an empty-state message when the association is
    unloaded/nil.
  - Guide schemas added for both backends: `Product has_one ProductBarcode` (Ecto) and
    `Author has_one AuthorProfile` (Ash).

- **`many_to_many` association support**
  - Both parsers now parse `many_to_many` as `:many_to_many_association` on the Ash and Ecto
    backends, and the layout layer routes the new type through the existing association consumers
    (preloads, layout defaults).
  - `:form` renders the related records as checkboxes for toggling membership, with bulk actions
    (a tri-state toggle-all/none control, replacing an earlier separate check-all/uncheck-all pair)
    and an action-group label.
  - `:show` renders only the current membership as a plain read-only list, with an empty state when
    no related records are attached.
  - Guide schemas added for both backends to exercise many-to-many membership end-to-end.

- **Per-layout custom field renderers**
  - `Aurora.Uix.Field` gains three per-layout renderer options — `index_renderer`, `edit_renderer`,
    and `show_renderer` — alongside the existing generic `renderer`.
  - The form (edit) and show layouts use `edit_renderer`/`show_renderer` when set and otherwise fall
    back to `renderer`, preserving existing behavior. Index columns, which previously had no custom
    renderer, honor `index_renderer` with no fallback to `renderer`.
  - Configurable via `field/2` options or index column keyword lists, e.g.
    `index_columns :product, [name: [index_renderer: &upcase_name/1]]`.

- **Ash calculations and aggregates support in `FieldsParser`**
  - `FieldsParser` now discovers and includes Ash calculations and aggregates alongside
    attributes when building the field map for a resource, so computed and aggregated
    fields are automatically available in generated UIs without manual configuration on
    ash backend.
  - `field_type/2` clauses added for all `Ash.Resource.Aggregate` kinds:
    `count` -> `:integer`, `exists` -> `:boolean`, `sum / max / min / avg` -> `:float`.

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

- **Copyable inputs**
  - The `<.input>` component (text and textarea variants) now accepts a `copyable` attribute. When `true`, a copy-to-clipboard button is rendered next to the field via the `AuixCopyToClipboard` JS hook.
  - Requires a valid, non-empty `id` (or a `field`); a `Logger.warning` is emitted at render time when missing, suppressible via `config :aurora_uix, :copyable_show_warnings?, false`.
  - Custom `renderer:` functions must render through Aurora UIX core components (or `use Aurora.Uix.CoreComponentsImporter`) so the hook and markup are available.
  - Copy confirmation surfaces as a toast notification.

### Changed

- **Guide reorganization moved styling content into a dedicated section**
  - `guides/core/styling.md` -> `guides/customization/styling.md`
  - `guides/advanced/writing_a_style_bridge.md` -> `guides/customization/writing_a_style_bridge.md`
  - Updated all cross-references across guides, README, CONTRIBUTING, `mix.exs` extras configuration, and docstrings

- **Updated `mix.exs` extras grouping** — added a new `"Customization & Extension"` section group; renamed the former `Core` group to `"Core Concepts"`; expanded the `Introduction` group to include `guides/overview/` entries

- **Simplified `CoreComponentsImporter`** — removed the deprecated `core_components_module` option, now superseded by the new runtime component resolver

- **Updated Dependencies**
  - ash: 3.27.8 -> 3.30.1
  - ash_phoenix: 2.3.23 -> 2.3.24
  - ash_postgres: 2.9.1 -> 2.11.0
  - bandit: 1.12.0 -> 1.12.4
  - image: 0.68.0 -> 0.72.0
  - lazy_html: 0.1.11 -> 0.1.12
  - phoenix: 1.8.7 -> 1.8.9
  - phoenix_live_view: 1.1.31 -> 1.2.8
  - postgrex: 0.22.2 -> 0.22.3
  - wallaby: 0.30.12 -> 0.31.0
  
### Fixes

- **Many-to-one select on Ecto integer foreign keys** — `field_placeholder/2` crashed (`FunctionClauseError`) when a `belongs_to` pointed at an integer (`:id`) primary key,
    because only UUID/`:binary_id` foreign keys had a clause. Added a fallback so default Phoenix schemas (integer ids) render the picker.
- **Many-to-one select on Ash resources** — building dropdown options raised `Protocol.Enumerable not implemented for Aurora.Ctx.Pagination`. `get_select_options/1` 
    now normalises the paginated Ash result (and the plain Ecto list) to a list of entries before mapping.
- **Update of index list upon creating/adding records** - After a record is created or updated, the index of records was not properly updated. Added missing tests to ensure no regressions.

### Documentation

- `guides/tutorial/build_your_first_app.md` — new **Tutorial** section: a zero-background, end-to-end walkthrough (install toolchain -> Phoenix app -> Ecto *or* Ash data layer -> Aurora UIX -> running CRUD app), linked prominently from the README and Getting Started.
- `guides/customization/overriding_components.md` — full reference with per-override-key function tables and configuration examples
- `guides/customization/customization.md` — hub page linking all customization mechanisms
- `guides/customization/custom_actions.md` — comprehensive guide on adding, replacing, inserting, and removing UI action buttons
- `guides/customization/theming.md` — guide for authoring custom registered themes
- Updated internal references across all existing core and advanced guides to point to the new customization paths

- **Ash generated fields (calculations/aggregates) auto-loaded in generated layouts**
  - Fields tagged as generated (`field.data == %{generated: true}`, i.e. Ash calculations/aggregates) referenced in
    index/form/show layouts are now automatically added to the resource's Ash `load` list, alongside association preloads.
    Resources no longer need `prepare build(load: :summary)` (or similar) on their read action purely to display a
    calculation/aggregate that is only referenced through a layout.
  - `auix_preloads/0` now returns a mixed list per resource (bare atoms for generated fields, `{name, nested}` tuples
    for associations), e.g. `%{post: [:summary, comment: [], author: [...]]}`.
  - `Aurora.Uix.Templates.Basic.Helpers.extract_association_preload/1` updated to tolerate bare-atom preload entries.
  - **Limitation**: only argument-less calculations/aggregates are auto-loaded (`[:summary]`). Calculations that take
    arguments still require an explicit `prepare build(load: [summary: %{arg: ...}])` on the resource's read action —
    this feature composes with (does not replace) that mechanism.

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
  - `ash`: `3.16.0` -> `3.27.8`
  - `ash_phoenix`: `2.3.19` -> `2.3.23` 
  - `ash_postgres`: `2.6.31` -> `2.9.1`
  - `bandit`: `1.10.2` -> `1.12.0`
  - `credo`: `1.7.16` -> `1.7.19`
  - `doctor`: `0.22.0` -> `0.23.0`
  - `ecto_sql`: `3.13.4` -> `3.14.0`
  - `ex_doc`: `0.40.1` -> `0.40.3`
  - `image`: `0.63.0` -> `0.68.0`
  - `phoenix`: `1.8.3` -> `1.8.7`
  - `phoenix_live_view`: `1.1.22` -> `1.1.31`
  - `postgrex`: `0.22.0` -> `0.22.2`


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
  - `ash`: `3.12.0` -> `3.16.0`
  - `ash_postgres`: `2.6.27` -> `2.6.31`
  - `bandit`: `1.10.1` -> `1.10.2`
  - `credo`: `1.7.15` -> `1.7.16`
  - `ex_doc`: `0.39.3` -> `0.40.1`
  - `lazy_html`: `0.1.8` -> `0.1.10`
  - `phoenix_live_view`: `1.1.19` -> `1.1.22`


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
  - `GET /path/:id/show` -> `.Index` module with `:show` action (was `GET /path/:id` to `.Show` module)
  - `GET /path/:id/show-edit` -> `.Index` module with `:show_edit` action (was `GET /path/:id/show/edit` to `.Show` module with `:edit` action)
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
