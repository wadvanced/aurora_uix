<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
The index card view (mobile) gets a sort control: the new `:default_sort` header action, a select of the sortable index fields plus a button that reverses the direction, both emitting the existing `"index-sort"` event. A new index layout option `:sort_disabled?` turns user sorting off for the whole index (table headers, card control and the event itself). Both are backend-agnostic: they consume `%Field{}.sortable?`, which both parsers already fill, and are tested on Ash and Ecto.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md` § [0.1.7]; `guides/core/layouts.md` § Index Layout Options; `guides/core/liveview.md` § Built-in Events, § How Sorting Works; `guides/customization/custom_actions.md` § Index Layout Actions, § Action Operations; `guides/customization/styling.md` § Class reference; `guides/whats_new/0.1.7.md` (new) | none | federico/375-doc-1-card-sort-docs | docs: document the card view sort control and sort_disabled? (#375 · DOC-1) |
| UI-1 | UI | layout option `:sort_disabled?` · table header sort buttons · `"index-sort"` guard | DOC-1 | federico/375-ui-1-sort-disabled | feat: add the sort_disabled? index layout option (#375 · UI-1) |
| UI-2 | UI | `:default_sort` header action (card view sort control) · theme | UI-1 | federico/375-ui-2-card-sort-control | feat: add a sort control to the mobile card view (#375 · UI-2) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § [0.1.7]
- `guides/core/layouts.md` § Index Layout Options
- `guides/core/liveview.md` § Built-in Events; § How Sorting Works
- `guides/customization/custom_actions.md` § Index Layout Actions; § Action Operations
- `guides/customization/styling.md` § Class reference
- `guides/whats_new/0.1.7.md` — new file; `guides/whats_new/0.1.6.md` § Upgrading from 0.1.5, § Click-to-sort column headers (shape to copy)

#### Implementation details

##### CHANGELOG.md
1. § `## [0.1.7]` — insert a new `### Added` subsection directly after the last bullet of `### Fixed` and directly before `### Changed`, verbatim:
   ```
   ### Added

   - **Sort control in the mobile card view**
     - The card view, which has no column headers, gets a select of the sortable fields and a
       button that reverses the direction, on both backends. It is the new `:default_sort` header
       action, hidden from the `md` breakpoint up. New classes `auix-index-sort-action` and
       `auix-index-sort-direction`.
     - New index layout option `sort_disabled?: true` turns user sorting off: no sortable column
       headers, no card sort control, and the `"index-sort"` event is ignored. `order_by` still
       applies.
   ```
   Leave one blank line between the inserted block and `### Changed`.

##### guides/core/layouts.md
1. § Index Layout Options — in the **Options:** list, insert directly after the line ``- `:pagination_disabled?` — Disable pagination (default: `false`)``, verbatim:
   ```
   - `:sort_disabled?` — Turn off user sorting: no sortable column headers, no sort control in the card view, and the `"index-sort"` event is ignored. `:order_by` still applies. Accepts a boolean or an arity-1 function of the assigns (default: `false`)
   ```

##### guides/core/liveview.md
1. § Built-in Events — under **Index LiveView:**, replace the line
   ``- `"index-sort"` - Sort the index by the column named in the `"key"` value; a second click on the same column reverses the direction``
   with, verbatim:
   ```
   - `"index-sort"` - Sort the index by the field named in the `"key"` value; sending the key of the current sort reverses the direction. Sent by the sortable column headers and by the card view's sort select and direction button; ignored when the layout option `sort_disabled?` is `true`
   ```
2. § How Sorting Works — replace the bullet
   ```
   - Is replaced when the user clicks a sortable column header; a second click reverses the direction. A column opts out with the field option `sortable?: false`
   ```
   with, verbatim:
   ```
   - Is replaced when the user sorts: a click on a sortable column header (a second click reverses the direction), or, in the mobile card view, the sort select and its direction button. A column opts out with the field option `sortable?: false`; the layout option `sort_disabled?: true` turns user sorting off for the whole index
   ```

##### guides/customization/custom_actions.md
1. § Index Layout Actions — in the diagram, replace the line
   `│  │  [toggle_filters]  [clear]  [submit]  [new]         │  │`
   with (same width, 61 characters), verbatim:
   `│  │  [toggle_filters]  [sort]  [clear]  [submit]  [new] │  │`
2. § Index Layout Actions — in the table row starting `` | `*_header_action` ``, replace `` `:default_toggle_filters`, `:default_clear`, `:default_submit`, `:default_new` `` with `` `:default_toggle_filters`, `:default_sort`, `:default_clear`, `:default_submit`, `:default_new` ``.
3. § Action Operations — in the **Add Action** code block, replace the comment `# Append an Export CSV button after the default header actions (toggle_filters, clear, submit, new)` with `# Append an Export CSV button after the default header actions (toggle_filters, sort, clear, submit, new)`.
4. § Action Operations — in the **Remove Action** code block, insert directly after the line `remove_header_action: :default_new` (keep the blank line that follows it before the next comment), verbatim:
   ```

   # Remove the card view's sort control (the column headers still sort)
   remove_header_action: :default_sort
   ```

##### guides/customization/styling.md
1. § Class reference — append two rows directly after the row starting `` | `.auix-items-table-header-sort` ``, verbatim:
   ```
   | `.auix-index-sort-action` | Card-view sort control in the index header actions (field select + direction button); hidden from the `md` breakpoint up, where the column headers sort | `--auix-gap-minimal` |
   | `.auix-index-sort-direction` | Card-view sort direction button (arrow icon) | Structural only |
   ```

##### guides/whats_new/0.1.7.md
1. New file (`ls guides/whats_new` lists only `0.1.6.md`). Write it verbatim; the `# What's New in <version>` title, the intro paragraph, the link list, the `## Upgrading from <previous>` checklist first and the `## Where to go next` list copy the shape of `guides/whats_new/0.1.6.md`:
   ````
   # What's New in 0.1.7

   This page walks through the changes of this release that you are most likely to use, with
   examples you can paste into your own project. It is rewritten for every release; the
   [CHANGELOG](../../CHANGELOG.md) keeps the complete history, including every fix.

   - [Upgrading from 0.1.6](#upgrading-from-0-1-6)
   - [Sort control in the mobile card view](#sort-control-in-the-mobile-card-view)
   - [Turning user sorting off](#turning-user-sorting-off)

   ## Upgrading from 0.1.6

   This release is additive. One step is required.

   **1. Re-generate the stylesheet.** The card view's sort control brings two new theme classes
   (`auix-index-sort-action`, `auix-index-sort-direction`), and the generated `auix-*.css` files
   are not rebuilt by a dependency update:

   ```shell
   mix auix.gen.stylesheet
   ```

   ## Sort control in the mobile card view

   Below the `md` breakpoint the index renders cards instead of a table, and cards have no column
   headers to click. The card view now carries a sort control: a select of the sortable fields
   and, once a field is chosen, a button that reverses the direction. It emits the same
   `"index-sort"` event and honours the same `sortable?` field flag as the column headers, on
   both backends, so an index that sorts by its headers needs no change:

   ```elixir
   index_columns :product, [:reference, :name, :cost],
     order_by: [asc: :name]            # the initial order, until the user sorts
   ```

   Fields opted out with `sortable?: false` are not offered. The control is the `:default_sort`
   header action, hidden from the `md` breakpoint up, where the column headers sort. To drop it
   and keep the column headers:

   ```elixir
   index_columns :product, [:reference, :name, :cost],
     remove_header_action: :default_sort
   ```

   ## Turning user sorting off

   The new index layout option `sort_disabled?` turns user sorting off for the whole index: no
   sortable column headers, no card sort control, and the `"index-sort"` event is ignored.
   `order_by` still applies:

   ```elixir
   index_columns :product, [:reference, :name, :cost],
     order_by: [asc: :name],
     sort_disabled?: true
   ```

   It accepts a boolean or an arity-1 function of the assigns, like `pagination_disabled?`.

   ## Where to go next

   - The full list of fixes and changes: [CHANGELOG](../../CHANGELOG.md)
   - Index layout options: [Layouts](../core/layouts.md#index-layout-options)
   - Adding, replacing and removing actions: [Custom Actions](../customization/custom_actions.md)
   ````
   The file ends with one newline after the last list item.
2. `mix.exs` `docs.extras` and the `README.md` What's New link keep pointing at `guides/whats_new/0.1.6.md`: `prepare-release` repoints them when 0.1.7 is cut, and `mix.exs` is outside this section's file set (AC-2). An unlisted `guides/whats_new/*.md` file is exempt from the extras check by its `-not -path 'guides/whats_new/*'` clause.

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-375-enriched-spec.md`)
- [x] AC-3: `guides/core/layouts.md § Index Layout Options` lists `:sort_disabled?` directly after `:pagination_disabled?` (mechanical — no red test; verified by `grep -n -A1 'pagination_disabled?\` — Disable pagination' guides/core/layouts.md` showing the `:sort_disabled?` line)
- [x] AC-4: `guides/core/liveview.md` § Built-in Events and § How Sorting Works read as prescribed (mechanical — no red test; verified by `grep -c 'sort_disabled?' guides/core/liveview.md` returning `2`)
- [x] AC-5: `guides/customization/custom_actions.md` names `:default_sort` in the table and the remove example, and the diagram line keeps 61 characters (mechanical — no red test; verified by `grep -c ':default_sort' guides/customization/custom_actions.md` returning `2` and `grep -cF '│  │  [toggle_filters]  [sort]  [clear]  [submit]  [new] │  │' guides/customization/custom_actions.md` returning `1`)
- [x] AC-6: `guides/customization/styling.md § Class reference` carries the two new class rows (mechanical — no red test; verified by `grep -c 'auix-index-sort-' guides/customization/styling.md` returning `2`)
- [x] AC-7: `guides/whats_new/0.1.7.md` exists with the prescribed headings and `mix.exs` is untouched (mechanical — no red test; verified by `grep -c '^## ' guides/whats_new/0.1.7.md` returning `4`, `grep -c 'sort_disabled?: true' guides/whats_new/0.1.7.md` returning `1`, and `git diff --name-only origin/main...HEAD -- mix.exs` returning nothing)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · layout option `:sort_disabled?`
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md` § Index Layout Options — `:sort_disabled?` (DOC-1).
- `guides/core/liveview.md` § Built-in Events — `"index-sort"` ignored when disabled (DOC-1).

#### Implementation details
Layout types covered: `:index` only. `:form` and `:show` are left alone. The one-to-many table (`renderers/fields/one_to_many.ex`) passes an `auix` map without `:sort_disabled?` and its columns carry no `sortable?`, so it is unaffected.

`:sort_disabled?` is a layout option: `Aurora.Uix.Layout.Options` discovers it from the new `get_default/2` clause (`__before_compile__/1` reads the clause heads), `index_impl.ex` `assign_layout_options/1` stores it in `auix.layout_options`, and `Aurora.Uix.Layout.Options.get_option/3` evaluates an arity-1 function value against the assigns at mount. It is never part of the query: `index_impl.ex` `@allowed_query_options [:where, :order_by, :paginate, :preload]` keeps it out. It is backend-agnostic — no parser reads it — so its red tests run on Ecto only; the card control that honours it is tested on both backends in `UI-2`.

New-name evidence: `rg -n 'sort_disabled|SortDisabled|sort-disabled' lib test guides` returns nothing.

Mobile mockup: `05-sort-disabled.svg` in UI-2 § Mobile mockups shows the card view of this option; UI-2 delivers the card control it removes.

##### Acceptance criteria
- [x] AC-1: Given `SortDisabledTest` (Ecto `Product`, metadata `order_by: :reference`, layout `index_columns(:product, [:reference, :name], sort_disabled?: true)`), visiting `/sort-disabled-products`, then no `button[name^='auix-sort-']` exists and no `th` carries `aria-sort`; the `name` and `reference` headers render as plain labels.
- [x] AC-2 (error path): Given the same page with the three-product fixture (names `"Charlie"`, `"Alpha"`, `"Bravo"` in reference order), pushing `"index-sort"` with `"key"` `"name"` twice, then the name cells keep `["Charlie", "Alpha", "Bravo"]` and no `th` carries `aria-sort`.
- [x] AC-3: Given any index layout without `:sort_disabled?`, the column header sort buttons and the `"index-sort"` event behave as before (mechanical — no red test; verified by `test/cases_live/sortable_columns_test.exs` and `test/cases_live/ash_sortable_columns_test.exs` passing unmodified).

##### Test ports
- Route `"sort-disabled-products"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(SortDisabledTest.Product, "sort-disabled-products")` · `:index` · observable: `has_element?/2` on `button[name^='auix-sort-']` and `th[aria-sort]`; name cells `#auix-table-sort-disabled-products-index tr td:nth-of-type(3)` (columns: selection, `reference`, `name`).

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n 'SortDisabled\|sort-disabled\|sort_disabled' test lib` returns nothing) | `view = prepare_sort_test(conn)` | test/cases_live/sort_disabled_test.exs | "sort_disabled? removes every column sort button" | `refute has_element?(view, "button[name^='auix-sort-']")`; `refute has_element?(view, "th[aria-sort]")` |
| AC-2 | add to the same file | `view = prepare_sort_test(conn)`; `render_click(view, "index-sort", %{"key" => "name"})` twice | same | "a forged index-sort event is ignored when sorting is disabled" | `assert name_cells(view) == ["Charlie", "Alpha", "Bravo"]`; `refute has_element?(view, "th[aria-sort]")` |

Markup-change sweep (`rg -n "aria-sort|auix-sort-" test/`): only `test/cases_live/sortable_columns_test.exs` and `test/cases_live/ash_sortable_columns_test.exs` drive these selectors; neither sets `:sort_disabled?`, so `sortable_column?/2` returns what `sortable_column?/1` returned and both files stay unchanged.

##### Modules & components
1. `lib/aurora_uix/layout/options/index.ex`:
   1. New `get_default/2` clause, placed directly after the `get_default(%{auix: %{layout_tree: %{tag: :index}}}, :pagination_disabled?)` clause:
      ```elixir
      defp get_default(%{auix: %{layout_tree: %{tag: :index}}}, :sort_disabled?),
        do: {:ok, false}
      ```
   2. `@moduledoc` `## Options` — insert directly after the `:pagination_disabled?` bullet (after its `- Default: \`false\` (pagination active)` line), verbatim:
      ```
        * `:sort_disabled?` - Turns off user sorting: the column headers and the card view's sort
          control offer none, and the `"index-sort"` event is ignored. `:order_by` still applies.
          - Accepts `boolean()` or function of arity 1 that receives assigns and returns boolean
          - Default: `false` (sorting active)
      ```
2. `lib/aurora_uix/layout/blueprint.ex` `index_columns/3` `@doc` `## Options` — insert directly after the line ``- `:pagination_disabled?` (boolean()) - If true, pagination is not used for populating the index list.``, verbatim:
   ```
     - `:sort_disabled?` (boolean() | (map() -> boolean())) - If true, the index offers no user sorting: no sortable column headers, no card-view sort control, and the `"index-sort"` event is ignored. `:order_by` still applies.
   ```
3. `lib/aurora_uix/templates/basic/renderers/index_renderer.ex` `render/1` — in the `auix={%{…}}` map passed to `<.auix_items>`, insert `sort_disabled?: @auix.layout_options.sort_disabled?,` directly after `sort: @auix.sort,`.
4. `lib/aurora_uix/templates/basic/components/components.ex`:
   1. `auix_items_table/1` header `<th>` — replace
      ```heex
      <.table_column_sort :if={sortable_column?(col)} auix={@auix} col={col} />
      <.table_column_label :if={!sortable_column?(col)} auix={@auix} label={col.label} />
      ```
      with
      ```heex
      <.table_column_sort :if={sortable_column?(@auix, col)} auix={@auix} col={col} />
      <.table_column_label :if={!sortable_column?(@auix, col)} auix={@auix} label={col.label} />
      ```
      The `aria-sort={column_aria_sort(@auix, col)}` attribute stays as is.
   2. Replace the `sortable_column?/1` and `column_aria_sort/2` definitions
      ```elixir
      @spec sortable_column?(map()) :: boolean()
      defp sortable_column?(%{field: %{sortable?: true}}), do: true
      defp sortable_column?(_col), do: false

      @spec column_aria_sort(map(), map()) :: binary() | nil
      defp column_aria_sort(auix, %{field: %{sortable?: true, key: key}}),
        do: auix |> column_sort_direction(key) |> aria_sort()

      defp column_aria_sort(_auix, _col), do: nil
      ```
      with
      ```elixir
      # Map.get/2: the one-to-many table's auix map carries no :sort_disabled?.
      @spec sortable_column?(map(), map()) :: boolean()
      defp sortable_column?(auix, %{field: %{sortable?: true}}),
        do: Map.get(auix, :sort_disabled?) != true

      defp sortable_column?(_auix, _col), do: false

      @spec column_aria_sort(map(), map()) :: binary() | nil
      defp column_aria_sort(auix, %{field: %{key: key}} = col) do
        if sortable_column?(auix, col), do: auix |> column_sort_direction(key) |> aria_sort()
      end

      defp column_aria_sort(_auix, _col), do: nil
      ```
      `column_aria_sort/2` returns `nil` for a column without a sort control, so HEEx omits the attribute.
   3. `@doc` of `auix_items_table/1` — replace the paragraph `` A `:col` whose `field` has `sortable?: true` renders its label as a button that emits `"index-sort"` with the field key; the header carries `aria-sort` from `auix.sort`. `` with `` A `:col` whose `field` has `sortable?: true` renders its label as a button that emits `"index-sort"` with the field key, unless `auix.sort_disabled?` is `true`; the header carries `aria-sort` from `auix.sort`. ``
5. `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — new `auix_handle_event/3` clause, placed directly before the existing `def auix_handle_event("index-sort", %{"key" => key}, %{assigns: %{auix: auix}} = socket) do` clause:
   ```elixir
   def auix_handle_event(
         "index-sort",
         _params,
         %{assigns: %{auix: %{layout_options: %{sort_disabled?: true}}}} = socket
       ),
       do: {:noreply, socket}
   ```
   The guard is server-side, so a forged event cannot sort a disabled index.
6. `test/support/app_web/routes.ex` `load_test_routes/0` — insert, directly after the `RoutesHelper.register_crud(AshSortableColumnsTest.Author, "ash-sortable-columns-authors")` call (the multi-line form), the line `RoutesHelper.register_crud(SortDisabledTest.Product, "sort-disabled-products")`.
7. `Aurora.UixWeb.Test.SortDisabledTest` at `test/cases_live/sort_disabled_test.exs` — new:
   1. `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `alias Aurora.Uix.Guides.Inventory`, `alias Aurora.Uix.Guides.Inventory.Product`, `alias Phoenix.LiveViewTest.View`.
   2. Metadata: `auix_resource_metadata(:product, context: Inventory, schema: Product, order_by: :reference)`.
   3. Layout, with the comment lines copied from `test/cases_live/sortable_columns_test.exs` above it: `auix_create_ui do index_columns(:product, [:reference, :name], sort_disabled?: true) end` (the keyword third argument follows `test/cases_live/infinity_scroll_test.exs`).
   4. `@spec prepare_sort_test(Plug.Conn.t()) :: View.t()` private: `delete_all_inventory_data()`; `create_sample_products(1, :srt_1, %{name: "Charlie"})`; `create_sample_products(1, :srt_2, %{name: "Alpha"})`; `create_sample_products(1, :srt_3, %{name: "Bravo"})`; `{:ok, view, _html} = live(conn, "/sort-disabled-products")`; return `view`.
   5. `@spec name_cells(View.t()) :: list(binary())` private: copy `name_cells/1` from `test/cases_live/sortable_columns_test.exs` with the selector `#auix-table-sort-disabled-products-index tr td:nth-of-type(3)`.
   6. The two red tests above, at top level (no `describe`).
8. `dt/1` strings: none new.
9. Standing rules touched: the option is read from the layout tree, never from a backend struct; the handler and the component consume `%Field{}.sortable?` and `auix.layout_options` only. No markup class added. No LiveComponent.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI · `:default_sort` header action (card view sort control)
Depends on: UI-1

#### Documentation references
- `guides/customization/custom_actions.md` § Index Layout Actions — `:default_sort` (DOC-1).
- `guides/core/liveview.md` § How Sorting Works — card view select and direction button (DOC-1).
- `guides/customization/styling.md` § Class reference — `.auix-index-sort-action`, `.auix-index-sort-direction` (DOC-1).

#### Implementation details
Layout types covered: `:index` only; `:form` and `:show` are left alone.

The control is a header action, not markup inside `auix_items_card/1`: `index_renderer.ex` `render/1` renders every `@auix.index_header_actions` entry in `div[name='auix-index-header-actions']` on every viewport, so a host override of `auix_items_card/1` keeps the control, and hosts remove it with `remove_header_action: :default_sort` (the generic `Actions.modify_actions/2` path). The theme hides it from the `md` breakpoint up, where `.auix-items-mobile` is hidden and the column headers sort.

The header actions sit outside the `index_layout_form` (`index_renderer.ex` `render/1` closes `div[name='auix-index-header-actions']` before `<.auix_simple_form … phx-change="index-layout-change">`), and LiveView serializes a changed input through `input.form`. The select therefore sits in its own `<.form phx-change="index-sort">` with `name="key"`: a change sends `%{"key" => <field key>, "_target" => ["key"]}` to the existing `index_impl.ex` clause `def auix_handle_event("index-sort", %{"key" => key}, %{assigns: %{auix: auix}} = socket) do`, which keeps its allow-list (`&1.sortable? and to_string(&1.key) == key`) and `next_sort/2`. A newly chosen key sorts ascending; the direction button sends the current key, which `next_sort/2` flips. The prompt option (value `""`) matches no field and is ignored. No handler change.

Sort state shape (from #371·UI-3): `auix.sort` holds `nil` while unsorted and `%{key: atom(), direction: :asc | :desc}` once sorted.

New-name evidence: `rg -n 'auix-index-sort|auix_index_sort|default_sort|sort_header_action|sort_direction|sort-form|sort_action' lib test guides` returns nothing.

##### Mobile mockups
Generated wireframes of the final mobile design, one SVG and one PNG per state, in `~/Downloads/issue-375-mobile-mockups/` (not committed; the text below is the reference). Viewport 375 px, below the `md` breakpoint, so `.auix-items-mobile` shows the card view. Fixture: the three-product `SortableColumnsTest` page `/sortable-columns-products` (`item_srt_1-1` Charlie, `item_srt_2-1` Alpha, `item_srt_3-1` Bravo; `order_by: :reference`). Every frame shares one layout:

- Title `Listing Products` (the `:page_title` default `"Listing #{title}"`).
- One `.auix-index-actions` row (`justify-content: space-between`): on the left `div[name='auix-index-select-actions']` with `Check all`; on the right `div[name='auix-index-header-actions']` in `add_default_header_actions/1` order — filter toggle (funnel), the new sort control, `New Product`. `Clear Filters` and `Submit` join the row only while the filters are open.
- One card per row: selection checkbox on the left; the `reference`, `name`, `cost`, `image`, `description` fieldsets stacked (bold caption label, italic value); the show, edit and delete row-action icons stacked on the right. Pagination bar below.

| File | State | What the frame shows |
|---|---|---|
| `01-unsorted.svg` | initial, AC-1 | The sort control is a select reading `Sort by` (the prompt). No direction button. Cards in `order_by` order: Charlie, Alpha, Bravo. |
| `02-select-open.svg` | select opened, AC-1 | The native option list: `Sort by`, `Reference`, `Name`. No `Cost`, `Description`, `Image` and no selection-column option. |
| `03-sorted-name-ascending.svg` | after choosing `Name`, AC-2 | The select reads `Name`; the prompt is gone. A borderless direction button with `hero-chevron-up` sits right of the select. Cards: Alpha, Bravo, Charlie. |
| `04-sorted-name-descending.svg` | after tapping the direction button, AC-2 | The select still reads `Name`; the button shows `hero-chevron-down`. Cards: Charlie, Bravo, Alpha. |
| `05-sort-disabled.svg` | `/sort-disabled-products`, AC-4, UI-1 | No sort control: the right side holds the filter toggle and `New Product` only. Cards in `order_by` order. An index with no sortable field (AC-5) renders the same row. |
| `06-desktop-control-hidden.svg` | `md` and up, AC-8 | For contrast: the table view. The sort control is absent (`display: none`); the `Reference` and `Name` column headers carry the sort buttons from #371. |

The select and the direction button sit inside one `.auix-index-sort-action` flex row with `--auix-gap-minimal` between them; the header actions row keeps its `--auix-gap-default` between actions.

##### Acceptance criteria
- [x] AC-1: Given `SortableColumnsTest` (sortable `reference`, `name`; opted out `cost`, `description`; upload `image`), visiting `/sortable-columns-products`, then `#auix-sort-form-product select[name='key']` offers `option[value='']` (prompt `"Sort by"`), `option[value='reference']` and `option[value='name']`, offers no option for `cost`, `description`, `image` and `selected_check__`, and no `button[name='auix-sort_direction-product']` exists.
- [x] AC-2: Given the three-product fixture, changing the sort select to `"name"`, then the card name values read `["Alpha", "Bravo", "Charlie"]`, `option[value='name'][selected]` is present, the `name` column header has `aria-sort='ascending'` and the direction button shows `hero-chevron-up`; clicking the direction button, then the card name values read `["Charlie", "Bravo", "Alpha"]`, the header has `aria-sort='descending'` and the button shows `hero-chevron-down`.
- [x] AC-3 (error path): Given the same page, changing the sort select to the prompt value `""`, then the card name values keep `["Charlie", "Alpha", "Bravo"]` and no direction button exists.
- [x] AC-4 (error path): Given `SortDisabledTest` `/sort-disabled-products` (`sort_disabled?: true`), then neither `#auix-sort-form-product` nor `[name='auix-sort_action-product']` exists.
- [x] AC-5 (degraded path): Given `SortDisabledTest` `:product_location` (metadata `field(:reference, sortable?: false)`, `field(:name, sortable?: false)`; layout `index_columns(:product_location, [:reference, :name])`), visiting `/sort-disabled-product-locations`, then no `[name='auix-sort_action-product_location']` exists.
- [x] AC-6 to AC-7: the same on Ash — `AshSortableColumnsTest` (sortable `name`; opted out `bio`; upload `email`): AC-6 mirrors AC-1 (`#auix-sort-form-author` offers `''` and `name`; no option for `bio`, `email`, `selected_check__`), AC-7 mirrors AC-2 (`button[name='auix-sort_direction-author']`).
- [x] AC-8: from the `md` breakpoint up the control is hidden (visual — no red test; verified by `grep -A12 'auix-index-sort-action {' assets/css/auix-rules.css` after `mix auix.gen.stylesheet` showing the `display: none` media rule, and a narrow-viewport manual check via `iex -S mix run test/start_test_server.exs`).

##### Test ports
- Route `"sortable-columns-products"` (registered by #371·UI-3) · `:index` · observable: `has_element?/2` on `#auix-sort-form-product select[name='key'] option[value='<key>']`, `button[name='auix-sort_direction-product'] span.hero-chevron-<up|down>`, `th[aria-sort='<ascending|descending>'] button[name='auix-sort-name']`; card name values `#auix-table-sortable-columns-products-index-mobile .auix-items-card-item > div:nth-of-type(2) [name='auix-column-value']` (card fieldsets: `reference`, `name`, `cost`, `image`, `description`; the selection column renders outside `.auix-items-card-item`, `components.ex` `get_cols/2`).
- Route `"ash-sortable-columns-authors"` (registered by #371·UI-3) · `:index` · observable: the same selectors with `author`; card name values `#auix-table-ash-sortable-columns-authors-index-mobile .auix-items-card-item > div:nth-of-type(1) [name='auix-column-value']`.
- Route `"sort-disabled-products"` (registered by UI-1) and new route `"sort-disabled-product-locations"` registered via `RoutesHelper.register_crud(SortDisabledTest.ProductLocation, "sort-disabled-product-locations")` · `:index` · observable: `has_element?/2` on `[name='auix-sort_action-<module>']`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to test/cases_live/sortable_columns_test.exs (top level, after the last test) | `view = prepare_sort_test(conn)` | test/cases_live/sortable_columns_test.exs | "the card sort control offers only the sortable fields" | `for value <- ["", "reference", "name"], do: assert has_element?(view, "#auix-sort-form-product select[name='key'] option[value='#{value}']")`; `for value <- ["cost", "description", "image", "selected_check__"], do: refute has_element?(view, "#auix-sort-form-product option[value='#{value}']")`; `refute has_element?(view, "button[name='auix-sort_direction-product']")` |
| AC-2 | add to the same file | `view = conn \|> prepare_sort_test() \|> select_sort("name")` | same | "the card sort select sorts ascending, its direction button reverses" | `assert mobile_name_cells(view) == ["Alpha", "Bravo", "Charlie"]`; `assert has_element?(view, "#auix-sort-form-product option[value='name'][selected]")`; `assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")`; `assert has_element?(view, "button[name='auix-sort_direction-product'] span.hero-chevron-up")`; `view \|> element("button[name='auix-sort_direction-product']") \|> render_click()`; `assert mobile_name_cells(view) == ["Charlie", "Bravo", "Alpha"]`; `assert has_element?(view, "th[aria-sort='descending'] button[name='auix-sort-name']")`; `assert has_element?(view, "button[name='auix-sort_direction-product'] span.hero-chevron-down")` |
| AC-3 | add to the same file | `view = conn \|> prepare_sort_test() \|> select_sort("")` | same | "the card sort prompt leaves the order unchanged" | `assert mobile_name_cells(view) == ["Charlie", "Alpha", "Bravo"]`; `refute has_element?(view, "button[name='auix-sort_direction-product']")` |
| AC-4 | add to test/cases_live/sort_disabled_test.exs (created by UI-1) | `view = prepare_sort_test(conn)` | test/cases_live/sort_disabled_test.exs | "sort_disabled? removes the card sort control" | `refute has_element?(view, "#auix-sort-form-product")`; `refute has_element?(view, "[name='auix-sort_action-product']")` |
| AC-5 | add to the same file | `{:ok, view, _html} = live(conn, "/sort-disabled-product-locations")` | same | "an index without sortable fields renders no card sort control" | `refute has_element?(view, "[name='auix-sort_action-product_location']")` |
| AC-6 | add to test/cases_live/ash_sortable_columns_test.exs (top level, after the last test) | `view = prepare_sort_test(conn)` | test/cases_live/ash_sortable_columns_test.exs | "the card sort control offers only the sortable fields" | `for value <- ["", "name"], do: assert has_element?(view, "#auix-sort-form-author select[name='key'] option[value='#{value}']")`; `for value <- ["bio", "email", "selected_check__"], do: refute has_element?(view, "#auix-sort-form-author option[value='#{value}']")` |
| AC-7 | add to the same file | `view = conn \|> prepare_sort_test() \|> select_sort("name")` | same | "the card sort select sorts ascending, its direction button reverses" | as AC-2 with `author`, `#auix-sort-form-author`, `button[name='auix-sort_direction-author']` and this file's `mobile_name_cells/1` |

Test helpers, private, each with `@spec`:
- `test/cases_live/sortable_columns_test.exs`:
  - `@spec select_sort(View.t(), binary()) :: View.t()` — `view |> form("#auix-sort-form-product", %{"key" => key}) |> render_change()`; return `view`. `Phoenix.LiveViewTest.form/3` validates `key` against the select's options; `""` is valid only while unsorted, when the prompt option exists.
  - `@spec mobile_name_cells(View.t()) :: list(binary())` — same body as `name_cells/1` with the selector `#auix-table-sortable-columns-products-index-mobile .auix-items-card-item > div:nth-of-type(2) [name='auix-column-value']`.
- `test/cases_live/ash_sortable_columns_test.exs`: `select_sort/2` with `#auix-sort-form-author`; `mobile_name_cells/1` with `#auix-table-ash-sortable-columns-authors-index-mobile .auix-items-card-item > div:nth-of-type(1) [name='auix-column-value']`.

Markup-change sweep: the header actions gain one entry. `rg -n "auix-index-header-actions" test/` — every hit (`special_fields_ui_test.exs`, `where_filter_layout_test.exs`, `ash_default_layout_test.exs`, `ash_filter_bar_test.exs`, `ash_where_filter_layout_test.exs`, `sortable_columns_test.exs`) targets a named descendant (`[name='auix-filters_submit-…']`); `create_ui_actions_index_test.exs` "Test index header custom actions" queries only `a[name^='auix-new-product']`. All unchanged. Text refutes on index pages (`rg -n 'refute .*=~' test/cases_live`): `embeds_one_test.exs` `"Profile"` and `embeds_many_test.exs` `"Emails"` name embed fields, which `assign_index_fields/1` rejects from `auix.index_fields`, so they never become options: unchanged.

##### Modules & components
1. `lib/aurora_uix/templates/basic/helpers.ex`:
   1. New public function, placed directly after the `assign_auix_option/3` clause (`def assign_auix_option(socket, option, option_value)`):
      ```elixir
      @doc """
      Returns the icon name for a sort direction.

      Shared by the sortable column headers and the card view's sort direction button.

      ## Parameters
      - `direction` (:asc | :desc | nil) - The sort direction; `nil` for an unsorted column.

      ## Returns
      binary() - A `hero-*` icon name.
      """
      @spec sort_icon(:asc | :desc | nil) :: binary()
      def sort_icon(:asc), do: "hero-chevron-up"
      def sort_icon(:desc), do: "hero-chevron-down"
      def sort_icon(nil), do: "hero-chevron-up-down"
      ```
   2. `@moduledoc` `## Key Features` — append the bullet `- Sort direction icon names for the index sort controls`.
2. `lib/aurora_uix/templates/basic/components/components.ex`:
   1. Insert `alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers` directly before `alias Phoenix.LiveView.JS`.
   2. `table_column_sort/1` — replace `auix |> column_sort_direction(field.key) |> sort_icon()` with `auix |> column_sort_direction(field.key) |> BasicHelpers.sort_icon()`.
   3. Delete the private `@spec sort_icon(:asc | :desc | nil) :: binary()` and its three `defp sort_icon/1` clauses. The three `hero-chevron-*` literals now live in `helpers.ex`, still under `lib/`, so `mix auix.gen.tailwind_classes` leaves `priv/static/classes.js` unchanged.
3. `lib/aurora_uix/templates/basic/actions/index.ex`:
   1. New public component, placed directly after the last `toggle_filters_action/1` clause:
      ```elixir
      @doc """
      Renders the sort control for the index card view: a select of the sortable index fields
      and, once a sort is active, a button that reverses its direction. Both emit `"index-sort"`.

      ## Parameters
      - `assigns` (map()) - Assigns map containing:
        * `:auix` (map()) - Required context with:
          - `:index_fields` (list()) - Index fields; only those with `sortable?: true` are offered
          - `:sort` (map() | nil) - The active sort, `%{key: atom(), direction: :asc | :desc}`
          - `:layout_options` (map()) - Must contain `:sort_disabled?`
          - `:module` (binary()) - Context module name

      ## Returns
      Rendered.t() - The sort control, or an empty fragment when sorting is disabled or no
      field is sortable
      """
      @spec sort_header_action(map()) :: Rendered.t()
      def sort_header_action(%{auix: %{layout_options: %{sort_disabled?: false}} = auix} = assigns) do
        sort_options =
          for %{sortable?: true} = field <- auix.index_fields,
              do: {dt(field.label), to_string(field.key)}

        assigns = Map.put(assigns, :sort_options, sort_options)

        ~H"""
        <div :if={@sort_options != []} class="auix-index-sort-action" name={"auix-sort_action-#{@auix.module}"}>
          <.form for={%{}} id={"auix-sort-form-#{@auix.module}"} phx-change="index-sort">
            <.input type="select" id={"auix-sort-key-#{@auix.module}"} name="key"
                options={@sort_options}
                value={@auix.sort && to_string(@auix.sort.key)}
                prompt={if is_nil(@auix.sort), do: dt("Sort by")}
                omit_label?={true} />
          </.form>
          <button :if={@auix.sort} type="button" class="auix-index-sort-direction"
              name={"auix-sort_direction-#{@auix.module}"}
              phx-click="index-sort" phx-value-key={@auix.sort.key}
              aria-label={dt("Reverse sort direction")}>
            <.icon name={BasicHelpers.sort_icon(@auix.sort.direction)} class="auix-icon-size-5" />
          </button>
        </div>
        """
      end

      def sort_header_action(assigns), do: ~H""
      ```
      `.form` is `Phoenix.Component.form/1` (`use Phoenix.Component`); `.input` and `.icon` come from `core_components.ex` (`input/1` `type: "select"` clause: attrs `id`, `name`, `options`, `value`, `prompt`, `omit_label?`; `icon/1`: attrs `name`, `class`). The direction button is a raw `<button>` for the same reason as `components.ex` `table_column_sort/1`: `core_components.ex` `button/1` always adds `auix-button-default`. `@auix.sort && …` is nil-logic on a map, so `&&` is correct.
   2. `add_default_header_actions/1` — insert `default_sort: &sort_header_action/1,` directly after `default_toggle_filters: &toggle_filters_action/1,`.
   3. `@moduledoc` `## Key Features` — insert directly after `- Offers filter management actions (clear/submit)` the bullet `- Offers a card-view sort control (sortable-field select and direction toggle)`.
4. Theme: `lib/aurora_uix/templates/basic/themes/base.ex` — two new clauses, placed directly after the `def rule(:auix_index_header_actions) do` clause:
   ```elixir
   def rule(:auix_index_sort_action) do
     """
       .auix-index-sort-action {
         display: flex;
         flex-direction: row;
         align-items: center;
         gap: var(--auix-gap-minimal);
       }

       @media (min-width: #{breakpoint(:md)}) {
         .auix-index-sort-action {
           display: none;
         }
       }
     """
   end

   def rule(:auix_index_sort_direction) do
     """
     .auix-index-sort-direction {
       display: inline-flex;
       align-items: center;
       padding: 0;
       border: 0;
       background: transparent;
       color: inherit;
       cursor: pointer;
     }
     """
   end
   ```
   The icon reuses `rule(:auix_icon_size_5)`; the select reuses the `auix-fieldset` and `auix-select` classes `input/1` emits. Run `mix auix.gen.tailwind_classes` and `mix auix.gen.stylesheet` (its `assets/css/auix-*.css` output is gitignored).
5. `test/support/app_web/routes.ex` `load_test_routes/0` — insert, directly after `RoutesHelper.register_crud(SortDisabledTest.Product, "sort-disabled-products")` (added by UI-1), the line `RoutesHelper.register_crud(SortDisabledTest.ProductLocation, "sort-disabled-product-locations")`.
6. `test/cases_live/sort_disabled_test.exs` (from UI-1):
   1. Add `alias Aurora.Uix.Guides.Inventory.ProductLocation` after the `Product` alias.
   2. Add, directly after the `:product` metadata, `auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation do field(:reference, sortable?: false); field(:name, sortable?: false) end` (one `field/2` call per line).
   3. Add `index_columns(:product_location, [:reference, :name])` inside the existing `auix_create_ui` block, after the `:product` entry. The generated module is `SortDisabledTest.ProductLocation` and `@auix.module` is `"product_location"` (`parsers/common.ex` `option_value/4` `:module` clause).
   4. The AC-4 and AC-5 red tests, at top level.
7. `test/cases_live/sortable_columns_test.exs` and `test/cases_live/ash_sortable_columns_test.exs` — the red tests and helpers listed above.
8. `dt/1` strings: `"Sort by"`, `"Reverse sort direction"`; option labels go through `dt(field.label)`, as the index column labels do in `index_renderer.ex` `render/1`.
9. Standing rules touched: the action consumes `%Field{}.sortable?`, `auix.sort` and `auix.layout_options` only; no backend struct appears. No inline utility class: the only classes are `auix-index-sort-action`, `auix-index-sort-direction` (new rules) and `auix-icon-size-5` (existing rule). Icons through `<.icon>`, the select through `<.input>`. No raw `<script>`. Streams unchanged. No LiveComponent.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-2:end -->

---

### Out of Scope
- Parser and query work: `sortable?` is already on every `%Field{}` from both parsers (#371), and `"index-sort"` reaches the query through the backend-agnostic `prepare_query_options/1`.
- A "clear sort" control: the column headers have none either.
- Sorting by more than one field at once.
- A test of `remove_header_action: :default_sort`: it runs through the generic `Actions.modify_actions/2` path the other header actions already exercise.
- An Ash twin of the UI-1 tests: `:sort_disabled?` is a layout option no parser reads; UI-2 covers the card control on both backends.
<!-- enriched-spec:end -->
