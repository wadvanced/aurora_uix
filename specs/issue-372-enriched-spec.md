<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Issue #371 already shipped click-to-sort index column headers on both backends. Issue #372 owes one gap: an upload column (a `%Field{}` whose `data` carries an `:upload` map) still offers a sort control. This issue removes that control and its `"index-sort"` handling for upload columns, backend-agnostically, with LiveView coverage on the Ecto and Ash backends.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.1.6] › Added · guides/core/layouts.md § Field-Level Options | none | federico/372-doc-1-upload-sort-note | docs: note that upload columns never sort (#372 · DOC-1) |
| UI-1 | UI | handler · upload index columns lose the sort control, tested on Ecto and Ash | DOC-1 | federico/372-ui-1-upload-columns-unsortable | fix: offer no sort control on upload index columns (#372 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § `## [0.1.6]` › `### Added` › `- **Sortable index column headers**` — `0.1.6` is the current unreleased version (no release date). The sortable-headers entry has not shipped, so this section amends it instead of adding a `### Fixes` entry.
- `guides/core/layouts.md` § Field-Level Options › `**Relevant Field Options:**`

#### Implementation details

##### CHANGELOG.md
1. § `## [0.1.6]` › `### Added` — replace the entry
   ```
   - **Sortable index column headers**
     - Click a column header to sort the index by it; click again to reverse. The sort replaces the
       layout `order_by` on both backends. Unorderable columns (associations, embeds, arrays, maps)
       are skipped; opt any other out with `sortable?: false`. New class `auix-items-table-header-sort`.
   ```
   verbatim with
   ```
   - **Sortable index column headers**
     - Click a column header to sort the index by it; click again to reverse. The sort replaces the
       layout `order_by` on both backends. Unorderable columns (associations, embeds, arrays, maps,
       uploads) are skipped; opt any other out with `sortable?: false`. New class `auix-items-table-header-sort`.
   ```

##### guides/core/layouts.md
1. § Field-Level Options — in the `**Relevant Field Options:**` list, replace the bullet
   ```
   - `:sortable?` — Set to `false` to remove the sort control from this column's index header
   ```
   with
   ```
   - `:sortable?` — Set to `false` to remove the sort control from this column's index header. An upload field (`data: %{upload: …}`) never offers one, even with `sortable?: true`
   ```

##### Acceptance criteria
- [ ] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [ ] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-372-enriched-spec.md`)
- [ ] AC-3: `guides/core/layouts.md § Field-Level Options` reads as prescribed (mechanical — no red
      test; verified by `grep -n 'An upload field (`data: %{upload: …}`) never offers one' guides/core/layouts.md`
      returning one line)
- [ ] AC-4: the `**Sortable index column headers**` entry names uploads among the skipped columns
      (mechanical — no red test; verified by `grep -n 'uploads) are skipped' CHANGELOG.md` returning one line)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · handler (index columns)
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md` § Field-Level Options (`:sortable?`, as `DOC-1` leaves it)
- `guides/core/resource_metadata.md` § Field Data (the `data: %{upload: …}` contract)
- `guides/core/liveview.md` § How Sorting Works

#### Implementation details

Layout types: `:index` only. `:form` and `:show` render no sort control and are left alone.

Backends: the `:upload` key is host metadata, set through the `field/2` `:data` option (`lib/aurora_uix/layout/resource_metadata.ex` `field/2`); neither parser produces it. The gate therefore lives once, in the backend-agnostic index handler, and needs no Parser section. Both backends are covered by the red tests below.

Load guarantee: every consumer of the sort control reads `auix.index_fields`, which only `assign_index_fields/1` writes:
- `lib/aurora_uix/templates/basic/renderers/index_renderer.ex` — `<:col … :for={field <- @auix.index_fields} … field={field}>` feeds `auix_items_table/1`;
- `lib/aurora_uix/templates/basic/components/components.ex` `sortable_column?/1` (`defp sortable_column?(%{field: %{sortable?: true}}), do: true`) and `column_aria_sort/2` (`defp column_aria_sort(auix, %{field: %{sortable?: true, key: key}})`) gate the `button[name='auix-sort-<key>']` and the `aria-sort` attribute on `col.field.sortable?`;
- `lib/aurora_uix/templates/basic/handlers/index_impl.ex` `auix_handle_event/3` clause `def auix_handle_event("index-sort", %{"key" => key}, %{assigns: %{auix: auix}} = socket) do` accepts only `Enum.find(auix.index_fields, &(&1.sortable? and to_string(&1.key) == key))`.

Setting `sortable?: false` on upload fields inside `assign_index_fields/1` therefore removes the button, the `aria-sort` attribute and the event handling together. Leave `components.ex`, `index_renderer.ex` and the `"index-sort"` clause unchanged.

1. `lib/aurora_uix/templates/basic/handlers/index_impl.ex` `assign_index_fields/1` — in the pipeline that starts `layout_tree.inner_elements`, insert one line between the closing `)` of the `Enum.reject(` call and `|> then(&[select_field | &1])`:
   ```elixir
       |> Enum.map(&drop_upload_sort/1)
   ```
2. Same file, directly after `assign_index_fields/1` ends, add the private function `drop_upload_sort/1` (new — `rg -n 'drop_upload_sort' lib test` returns nothing):
   ```elixir
     # An upload column holds an opaque file reference, so it never offers a sort control.
     @spec drop_upload_sort(Aurora.Uix.Field.t()) :: Aurora.Uix.Field.t()
     defp drop_upload_sort(field) do
       if BasicHelpers.upload_field?(field), do: struct(field, %{sortable?: false}), else: field
     end
   ```
   `BasicHelpers` is the existing alias `alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers` in this file. `upload_field?/1` is `lib/aurora_uix/templates/basic/helpers.ex` `upload_field?/1` (`def upload_field?(%{data: data}) when is_map(data), do: is_map(Map.get(data, :upload))`). The override is unconditional: an explicit `sortable?: true` on an upload field is replaced by `false`.
3. `lib/aurora_uix/layout/resource_metadata.ex` `field/2` `@doc`, `## Options` list — replace the line
   ```
     - `:sortable?` (`boolean()`) - If false, the index column header offers no sorting. Parsed from the column type when omitted.
   ```
   with
   ```
     - `:sortable?` (`boolean()`) - If false, the index column header offers no sorting. Parsed from the column type when omitted. An upload field (`:data` with an `:upload` map) never offers sorting.
   ```

##### Acceptance criteria
- [ ] AC-1: Given an Ecto resource whose `:image` field carries `data: %{upload: …}` and `sortable?: true`, listed in `index_columns`, visiting `/sortable-columns-products`, then no `button[name='auix-sort-image']` renders, while `button[name='auix-sort-reference']` and `button[name='auix-sort-name']` still render under `th[aria-sort='none']`
- [ ] AC-2: Given an Ash resource whose `:email` field carries `data: %{upload: …}` and `sortable?: true`, listed in `index_columns`, visiting `/ash-sortable-columns-authors`, then no `button[name='auix-sort-email']` renders, while `button[name='auix-sort-name']` still renders under `th[aria-sort='none']`
- [ ] AC-3: Given the AC-1 resource, an `"index-sort"` event with `"key" => "image"` leaves the row order unchanged and sets no `th[aria-sort='ascending']` (degraded path)
- [ ] AC-4: Given the AC-2 resource, an `"index-sort"` event with `"key" => "email"` leaves the row order unchanged and sets no `th[aria-sort='ascending']` (degraded path)

##### Test ports
- Route `"/sortable-columns-products"` — already registered in `test/support/app_web/routes.ex` as `RoutesHelper.register_crud(SortableColumnsTest.Product, "sortable-columns-products")` · layout type `:index` · observable: `has_element?/2` on `button[name='auix-sort-<key>']` and `th[aria-sort='<value>']`
- Route `"/ash-sortable-columns-authors"` — already registered in `test/support/app_web/routes.ex` for `AshSortableColumnsTest.Author` · layout type `:index` · same observables
- No new route. The markup gated here (`button[name='auix-sort-<key>']`) is driven only by `test/cases_live/sortable_columns_test.exs` and `test/cases_live/ash_sortable_columns_test.exs` (`rg -ln 'auix-sort-|index-sort' test/`); both are amended below and every other test in them keeps its drive unchanged.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | amend `test/cases_live/sortable_columns_test.exs` "sortable columns carry a sort button, opted-out columns do not" | In the module's `auix_resource_metadata :product` block add, after `field(:cost, sortable?: false)`, the line `field(:image, sortable?: true, data: %{upload: %{allow: [accept: ~w(.png)], consume: &Function.identity/1}})`. In `auix_create_ui`, change `index_columns(:product, [:reference, :name, :cost, description: [sortable?: false]])` to `index_columns(:product, [:reference, :name, :cost, :image, description: [sortable?: false]])`. Data from `prepare_sort_test/1` (`create_sample_products/3`). | `test/cases_live/sortable_columns_test.exs` | sortable columns carry a sort button, opted-out columns do not | change the refute list `[:cost, :description, :selected_check__]` to `[:cost, :description, :image, :selected_check__]`; the `[:reference, :name]` assert loop is unchanged |
| AC-3 | amend `test/cases_live/sortable_columns_test.exs` "an opted-out or unknown key leaves the order unchanged" | the AC-1 module setup | `test/cases_live/sortable_columns_test.exs` | an opted-out or unknown key leaves the order unchanged | add `render_click(view, "index-sort", %{"key" => "image"})` after the `"cost"` click; the existing `name_cells(view) == ["Charlie", "Alpha", "Bravo"]` and `refute has_element?(view, "th[aria-sort='ascending']")` stay |
| AC-2 | amend `test/cases_live/ash_sortable_columns_test.exs` "sortable columns carry a sort button, opted-out columns do not" | In the module's `auix_resource_metadata :author` block add, after `field(:bio, sortable?: false)`, the line `field(:email, sortable?: true, data: %{upload: %{allow: [accept: ~w(.png)], consume: &Function.identity/1}})`. In `auix_create_ui`, change `index_columns(:author, [:name, :bio, email: [sortable?: false]])` to `index_columns(:author, [:name, :bio, :email])`. Data from `prepare_sort_test/1` (`create_sample_authors/2`). The column-level `sortable?: false` opt-out stays covered on Ecto by the `description: [sortable?: false]` column above; that merge is backend-agnostic. | `test/cases_live/ash_sortable_columns_test.exs` | sortable columns carry a sort button, opted-out columns do not | the assertions stay as they are: `refute` over `[:bio, :email, :selected_check__]` now fails before the fix (the explicit `sortable?: true` renders `button[name='auix-sort-email']`) and passes after it |
| AC-4 | amend `test/cases_live/ash_sortable_columns_test.exs` "an opted-out or unknown key leaves the order unchanged" | the AC-2 module setup | `test/cases_live/ash_sortable_columns_test.exs` | an opted-out or unknown key leaves the order unchanged | add `render_click(view, "index-sort", %{"key" => "email"})` after the `"bio"` click; the existing `name_cells(view) == ["Charlie", "Alpha", "Bravo"]` and `refute has_element?(view, "th[aria-sort='ascending']")` stay |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Handlers.IndexImpl` at `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — modified: `assign_index_fields/1` pipeline, new `drop_upload_sort/1`
2. `Aurora.Uix.Layout.ResourceMetadata` at `lib/aurora_uix/layout/resource_metadata.ex` — modified: `field/2` `@doc` only
3. Components: none changed; `auix_items_table/1` in `components.ex` is reused as is
4. Theme: none
5. `dt/1` strings: none

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- Click-to-sort headers, the direction toggle, the active-column indicator, and the exclusion of associations, embeds, arrays and maps: delivered by #371 (`PAR-1`, `PAR-2`, `UI-3`) on both backends.
- Any parser change: the `:upload` key is host metadata that neither parser produces, so `field_sortable/2` in `integration/ctx/fields_parser.ex` and `integration/ash/fields_parser.ex` stays as is.
- Changing the `%Field{}` `sortable?` value stored in resource metadata: only the index columns built by `assign_index_fields/1` drop it.
<!-- enriched-spec:end -->
