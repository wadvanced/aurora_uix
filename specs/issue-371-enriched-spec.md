<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
Issue #371 gives the index `where`, `order_by` and filter bar the same behaviour and the same LiveView coverage on the Ash and Ecto backends, fixes every divergence the parity tests expose, makes the `:in` condition list-only on both backends (the filter bar splits its "in list" text before any backend sees it), and adds sortable column headers with a `sortable?` flag parsed on both backends. Ecto (`ctx`) and Ash each get their own Parser sections; the UI sections are backend-agnostic and tested on both backends. External prerequisite: `UI-1` MUST NOT start until wadvanced/aurora_ctx#42 is closed and `aurora_ctx` 0.1.11 is published on Hex; `UI-2` and `UI-3` inherit it through their dependency on `UI-1`.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.1.6] › Added, Fixes, Changed · guides/core/layouts.md § Index Layout Options, § Field-Level Options, § QueryBuilder for Advanced Filtering · guides/core/liveview.md § Built-in Events, § How Sorting Works · guides/core/resource_metadata.md § Validation and Constraints · guides/customization/styling.md § Class reference | none | federico/371-doc-1-query-parity-and-sorting | docs: document index query parity and sortable columns (#371 · DOC-1) |
| PAR-1 | Parser | ctx · `sortable?` on `%Field{}` | DOC-1 | federico/371-par-1-ctx-sortable | feat: parse a sortable? flag for Ecto fields (#371 · PAR-1) |
| PAR-2 | Parser | ash · `sortable?` on `%Field{}` + shared golden metadata | PAR-1 | federico/371-par-2-ash-sortable | feat: parse a sortable? flag for Ash fields (#371 · PAR-2) |
| PAR-3 | Parser | ash · QueryParser accepts direction-first `order_by` and a single-tuple `where`; `:in` takes a list only | DOC-1 | federico/371-par-3-ash-query-parser | fix: accept QueryBuilder order_by and where forms on Ash (#371 · PAR-3) |
| UI-1 | UI | handler · layout `where` + filter merge, "in list" text split into a list, applied filters kept, `aurora_ctx` 0.1.11 bump (MUST: wadvanced/aurora_ctx#42 released list-only) | DOC-1 | federico/371-ui-1-where-filter-merge | fix: keep the layout where when the filter bar is submitted (#371 · UI-1) |
| UI-2 | UI | test parity · Ash index where, order_by, filter bar, association where/order_by + Ash one-to-many rows | UI-1, PAR-3 | federico/371-ui-2-ash-query-parity | test: cover index and association queries on the Ash backend (#371 · UI-2) |
| UI-3 | UI | components + handler + theme · sortable index column headers | PAR-2, PAR-3, UI-2 | federico/371-ui-3-sortable-columns | feat: sortable index column headers (#371 · UI-3) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § `## [0.1.6]` › `### Added`, `### Fixes`, `### Changed`
- `guides/core/layouts.md` § Index Layout Options, § Field-Level Options, § QueryBuilder for Advanced Filtering
- `guides/core/liveview.md` § Built-in Events, § How Sorting Works
- `guides/core/resource_metadata.md` § Validation and Constraints
- `guides/customization/styling.md` § Class reference
- `guides/customization/styling.md` § The five files and their cascade layers — its existing "Re-run the generator after every upgrade" warning already covers the new `auix-*` rule; it is not edited.
- `guides/core/ash_integration.md` § With Domain and Ordering and § Filtering and Sorting document `order_by: [desc: :published_at]` on Ash; `PAR-3` makes that sample work. Not edited.

#### Implementation details

##### CHANGELOG.md
Every entry below is one bold title and one sub-bullet of at most three lines. No entry gains a second sub-bullet.
1. § `## [0.1.6]` › `### Added` — insert verbatim as the first entry under the heading, above the `**Unsaved-changes guard on the form modal**` entry, followed by one blank line:
   ```
   - **Sortable index column headers**
     - Click a column header to sort the index by it; click again to reverse. The sort replaces the
       layout `order_by` on both backends. Unorderable columns (associations, embeds, arrays, maps)
       are skipped; opt any other out with `sortable?: false`. New class `auix-items-table-header-sort`.
   ```
2. § `## [0.1.6]` › `### Fixes` — insert verbatim as the first entries under the heading, above the `**Ash silently collapsed `:like` and `:ilike` where-clauses into `:eq`**` entry, followed by one blank line:
   ```
   - **A layout `where` was lost as soon as the filter bar was submitted**
     - Layout `where` and submitted filters were merged into a nested list that Ecto skipped and Ash
       rejected. Both now receive one flat list, and submitted filters survive closing a modal.

   - **The filter bar's "in list" condition was ignored on Ecto resources**
     - `aurora_ctx` 0.1.11 adds the `:in` operator for a list of values and raises `ArgumentError`
       for an unsupported condition instead of matching every row. The filter bar splits the typed
       comma-separated text into that list before either backend sees it.

   - **Ash rejected the direction-first `order_by`**
     - `order_by: [desc: :published_at]` now works on Ash, including the `*_nulls_first` and
       `*_nulls_last` directions, as does a single-tuple `where`.

   - **Ash one-to-many tables rendered no rows**
     - The renderer took Ash's paginated result for a stream map; it now lists its entries.
   ```
3. § `## [0.1.6]` › `### Changed` — insert verbatim as the first entry under the heading, above the `**`Aurora.Uix.Gettext` renamed to `Aurora.Uix.GettextResolver`**` entry, followed by one blank line:
   ```
   - **`:in` conditions take a list of values only**
     - The Ash query parser no longer splits a comma-separated string: `{:status, :in, "a,b"}` now
       yields an invalid query on Ash and raises `ArgumentError` on Ecto. Write `{:status, :in, ["a", "b"]}`.
   ```
4. § `## [0.1.6]` › `### Changed` › `- **Updated Dependencies**` — insert this line directly after the line `  - ash_postgres: 2.11.0 -> 2.13.1`:
   ```
     - aurora_ctx: 0.1.10 -> 0.1.11
   ```

##### guides/core/layouts.md
1. § Index Layout Options — in the code sample, replace the two lines
   ```
     order_by: [{:name, :asc}],
     where: dynamic([p], p.active == true)
   ```
   with
   ```
     order_by: [asc: :name],
     where: [{:active, true}]
   ```
   Reason: `order_by` takes the `Aurora.Ctx.QueryBuilder` direction-first form, and a `dynamic/2` `where` works on Ecto resources only.
2. § Index Layout Options — in the `**Options:**` list, replace the two bullets
   ```
   - `:order_by` — Initial sort order; uses `Aurora.Ctx.QueryBuilder` syntax
   - `:where` — Query filter; uses `Aurora.Ctx.QueryBuilder` syntax
   ```
   with
   ```
   - `:order_by` — Initial sort order; uses `Aurora.Ctx.QueryBuilder` syntax on both backends. Clicking a sortable column header replaces it until the page is reloaded
   - `:where` — Query filter; uses `Aurora.Ctx.QueryBuilder` syntax. Conditions submitted from the filter bar are added to it; they never replace it
   ```
3. § Field-Level Options — in the `**Relevant Field Options:**` list, insert this bullet directly after the `:placeholder` bullet:
   ```
   - `:sortable?` — Set to `false` to remove the sort control from this column's index header
   ```
4. § QueryBuilder for Advanced Filtering — replace the sentence
   ```
   Aurora UIX index layouts support advanced filtering and sorting. The `:where` and `:order_by` options are passed to `Aurora.Ctx.QueryBuilder.options/2` for query construction.
   ```
   with
   ```
   Aurora UIX index layouts support advanced filtering and sorting. The `:where` and `:order_by` options are passed to `Aurora.Ctx.QueryBuilder.options/2` on Ecto resources and translated by `Aurora.Uix.Integration.Ash.QueryParser` on Ash resources; both accept the syntax below.
   ```
5. § QueryBuilder for Advanced Filtering — in the `**Supported Comparison Operators:**` list, insert this bullet directly after the `:between` bullet:
   ```
   - `:in` - Membership in a list of values (`{:status, :in, [:active, :pending]}`); the value is always a list
   ```
6. § QueryBuilder for Advanced Filtering — append this paragraph after the last bullet of the `This enables:` list:
   ```

   `dynamic/2` expressions apply to Ecto resources only; the Ash query parser accepts the tuple forms above. On Ecto resources a condition `Aurora.Ctx.QueryBuilder` does not support raises `ArgumentError` instead of being ignored. A comma-separated string is not a list: `{:status, :in, "active,pending"}` raises on Ecto and yields an invalid query on Ash. The filter bar's "in list" condition splits the typed text on commas and passes a list.
   ```

##### guides/core/liveview.md
1. § Built-in Events — in the `**Index LiveView:**` list, insert this bullet directly after the `"filters-submit"` bullet:
   ```
   - `"index-sort"` - Sort the index by the column named in the `"key"` value; a second click on the same column reverses the direction
   ```
2. § How Sorting Works — replace the bullet
   ```
   - Can be dynamically changed by the user via column headers (if enabled)
   ```
   with
   ```
   - Is replaced when the user clicks a sortable column header; a second click reverses the direction. A column opts out with the field option `sortable?: false`
   ```

##### guides/core/resource_metadata.md
1. § Validation and Constraints — insert this bullet directly after the `filterable?` bullet:
   ```
   - `sortable?` - If true, the index column header offers sorting. The parser sets it from the column type; fields no parser produced default to `false`
   ```

##### guides/customization/styling.md
1. § Class reference — in the table, insert this row directly after the `.auix-sections-tab-button` row:
   ```
   | `.auix-items-table-header-sort` | Sortable index column header button (label + direction arrow) | `--auix-gap-minimal` |
   ```

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-371-enriched-spec.md`)
- [x] AC-3: `guides/core/layouts.md` carries the three `§ QueryBuilder for Advanced Filtering` edits, the `:sortable?` bullet and the corrected Index Layout Options sample (mechanical — no red test; verified by `grep -c -e "order_by: \[asc: :name\]" -e ":sortable?" -e "Membership in a list of values" -e "Aurora.Uix.Integration.Ash.QueryParser" -e "apply to Ecto resources only" guides/core/layouts.md` returning 5)
- [x] AC-4: `guides/core/liveview.md` documents `"index-sort"` and the header-driven sort (mechanical — no red test; verified by `grep -c '"index-sort"\|clicks a sortable column header' guides/core/liveview.md` returning 2)
- [x] AC-5: `guides/core/resource_metadata.md` documents `sortable?` (mechanical — no red test; verified by `grep -c "^- .sortable?. - If true, the index column header" guides/core/resource_metadata.md` returning 1)
- [x] AC-6: `guides/customization/styling.md` lists `.auix-items-table-header-sort` (mechanical — no red test; verified by `grep -c "auix-items-table-header-sort" guides/customization/styling.md` returning 1)
- [x] AC-7: the six CHANGELOG entries added under `### Added`, `### Fixes` and `### Changed` carry one sub-bullet each (mechanical — no red test; verified by `git diff origin/main...HEAD -- CHANGELOG.md | grep -cE '^\+  - '` returning 7: six entry sub-bullets plus the `aurora_ctx` line under `**Updated Dependencies**`)
- [x] AC-8: no `:in` example in the documentation set uses a string as the accepted value (mechanical — no red test; verified by `git diff origin/main...HEAD -- CHANGELOG.md guides | grep -cE '^\+.*:in, "' ` returning 2: the `{:status, :in, "a,b"}` counter-example of the `### Changed` entry and the `{:status, :in, "active,pending"}` counter-example of `guides/core/layouts.md` § QueryBuilder for Advanced Filtering, and nothing else)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->

<!-- section:PAR-1:start -->
### PAR-1 — Parser · ctx · `sortable?` on `%Field{}`
Depends on: DOC-1

#### Documentation references
- `guides/core/resource_metadata.md` § Validation and Constraints — `sortable?` (DOC-1).
- `guides/core/layouts.md` § Field-Level Options — `:sortable?` (DOC-1).

#### Implementation details
Mirrored by `PAR-2` (ash). This section adds the `%Field{}` key; `PAR-2` adds the shared golden entries, because the golden map is asserted by both backends' parser tests and the Ash parser does not set the key until `PAR-2`.

`sortable?` is a boolean key, not a type atom: no type-atom audit applies.

##### Acceptance criteria
- [x] AC-1: Given `Ctx.FieldsParserTest.AllTypes`, when `Ctx.FieldsParser.parse_fields/2` parses it, then `:id`, `:field_integer`, `:field_string`, `:field_utc_datetime`, `:field_duration` and `:field_status` have `sortable?: true`.
- [x] AC-2: Given the same schema, then `:field_multi_status`, `:field_string_array`, `:embeds_many` and `:embeds_one` have `sortable?: false`.
- [x] AC-3: Given the same schema, when `Ctx.FieldsParser.parse_associations/4` runs over the parsed fields, then `:belongs_to_field_id` has `sortable?: true` and `:belongs_to_field`, `:has_many_field`, `:has_one_field` and `:many_to_many_field` have `sortable?: false`.
- [x] AC-4 (degraded path): Given a `:map` column (`field :field_map, :map`, added to `AllTypes`), then `:field_map` has `sortable?: false`.
- [x] AC-5: Given `auix_resource_metadata(:product, context: Inventory, schema: Product)` with `field(:name, sortable?: false)`, then the resource's `:name` field has `sortable?: false`, `:reference` keeps `sortable?: true`, and `:data_virtual` (absent from the schema, added by the metadata block) has `sortable?: false`.

##### Test ports
- `Aurora.Uix.Integration.Ctx.FieldsParser.parse_fields/2` · in: `AllTypes` · out: `list(%Field{})` carrying `sortable?` · existing (`lib/aurora_uix/integration/ctx/fields_parser.ex`, `parse_fields/2`)
- `Aurora.Uix.Integration.Ctx.FieldsParser.parse_associations/4` · in: `AllTypes`, `:all_types`, `%{}`, parsed fields · out: association `%Field{}`s with `sortable?: false` · existing (`parse_associations/4`)
- `resource_configs/1` + `validate_schema/3` (`test/support/ui_case.ex`) over `auix_resource_metadata` · existing

##### Red tests (write first; each must fail before implementation)
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/integration/ctx/fields_parser_test.exs`, new `describe "sortable?"` | `fields = AllTypes \|> Ctx.FieldsParser.parse_fields(:all_types) \|> Map.new(&{&1.key, &1})` | test/cases/integration/ctx/fields_parser_test.exs | "scalar columns are sortable" | `for key <- [:id, :field_integer, :field_string, :field_utc_datetime, :field_duration, :field_status], do: assert fields[key].sortable?` |
| AC-2 | same `describe` | same | same | "arrays and embeds are not sortable" | `for key <- [:field_multi_status, :field_string_array, :embeds_many, :embeds_one], do: refute fields[key].sortable?` |
| AC-3 | same `describe` | `AllTypes \|> Ctx.FieldsParser.parse_fields(:all_types) \|> then(&Ctx.FieldsParser.parse_associations(AllTypes, :all_types, %{}, &1)) \|> Map.new(&{&1.key, &1})` | same | "only the foreign-key column of an association is sortable" | `assert fields[:belongs_to_field_id].sortable?`; `for key <- [:belongs_to_field, :has_many_field, :has_one_field, :many_to_many_field], do: refute fields[key].sortable?` |
| AC-4 | same `describe`; add `field :field_map, :map` to `AllTypes` directly after `field :field_string_array, {:array, :string}` | as AC-1 | same | "a map column is not sortable" | `refute fields[:field_map].sortable?` |
| AC-5 | amend `test/cases/metadata_modifying_fields_test.exs` "Test field modifications" | add `field(:name, sortable?: false)` to the `:product` metadata block, directly after `field(:inactive, length: 10)` | test/cases/metadata_modifying_fields_test.exs | "Test field modifications" | extend the `validate_schema(resource_configs, :product, …)` list with `reference: %{sortable?: true}`, `name: %{sortable?: false}` and extend `data_virtual:` to `%{html_type: :checkbox, sortable?: false}` |

`field :field_map, :map` does not change the golden test: `Validations.compare_maps/2` iterates the golden keys only.

##### Parser changes
1. `lib/aurora_uix/field.ex` — `defstruct`: insert the line `sortable?: false,` directly after the line `filterable?: true,`. `@type t()`: replace its last entry line `filterable?: boolean()` with the two lines `filterable?: boolean(),` and `sortable?: boolean()`.
2. `lib/aurora_uix/field.ex` `@moduledoc` — insert directly after the `filterable?` bullet:
   ```
       - `sortable?` (`boolean`) - If true, the index column header offers sorting. Parsers set it from the
         column type; it defaults to `false` for fields no parser produced.
   ```
3. `lib/aurora_uix/integration/ctx/fields_parser.ex` `parse_field/3` — in the `attrs` pipeline insert `|> set(&field_sortable/2, :sortable?, attribute)` directly after `|> set(&field_filterable/2, :filterable?, attribute)`.
4. Same file — new private function, placed directly after the last `field_filterable/2` clause:
   ```elixir
   # Determines if the index column header may sort by the field.
   # Associations, embeds, arrays and maps have no single orderable column value.
   @spec field_sortable(map(), map()) :: boolean()
   defp field_sortable(_attrs, %{association_or_embed: association_or_embed})
        when not is_nil(association_or_embed),
        do: false

   defp field_sortable(_attrs, %{ecto_type: {:array, _item_type}}), do: false
   defp field_sortable(_attrs, %{ecto_type: {:map, _value_type}}), do: false
   defp field_sortable(_attrs, %{ecto_type: ecto_type}) when ecto_type in [nil, :map], do: false
   defp field_sortable(_attrs, _attribute), do: true
   ```
   `parse_field/3` always builds `attribute` with both `:ecto_type` and `:association_or_embed`; an embed field reaches the first clause through `resource_schema.__schema__(:embed, field_key)`.
5. Same file `parse_association/5` — in the literal map `%{resource: resource_name, key: association_field_key, length: 0, filterable?: false}` add `sortable?: false` after `filterable?: false`.
6. How the metadata option reaches the struct, no change needed: `lib/aurora_uix/layout/resource_metadata.ex` `maybe_add_option_to_data/2` catch-all clause `defp maybe_add_option_to_data({key, value}, result), do: Map.put(result, key, value)` puts `:sortable?` into the attrs `Field.change/2` applies with `struct/2`, which keeps it once the struct defines the key. A field added by the metadata block (not in the schema) is built by `Field.new()` and gets the struct default `false`.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:PAR-1:end -->

<!-- section:PAR-2:start -->
### PAR-2 — Parser · ash · `sortable?` on `%Field{}`
Depends on: PAR-1

#### Documentation references
- `guides/core/resource_metadata.md` § Validation and Constraints — `sortable?` (DOC-1).

#### Implementation details
Mirror of `PAR-1` (ctx). The Ash decision delegates to `Ash.Resource.Info.sortable?/3` (`deps/ash/lib/ash/resource/info.ex`), which already returns `false` for arrays, `Ash.Type.Map`, relationships, non-expression calculations and unknown names. It returns `true` for an embedded single resource (its type is a module), so an `embedded?: true` clause runs first.

##### Acceptance criteria
- [ ] AC-1: Given `AllTypes` (`test/cases/integration/ash/fields_parser_test.exs`), when `Ash.FieldsParser.parse_fields/2` parses it, then `:id`, `:field_integer`, `:field_string`, `:field_utc_datetime`, `:field_duration` and `:field_status` have `sortable?: true`.
- [ ] AC-2 (edge path): Given the same resource, then `:field_multi_status`, `:field_string_array`, `:embeds_many` and `:embeds_one` have `sortable?: false` — `:embeds_one` included, although `Ash.Resource.Info.sortable?/3` alone answers `true` for it.
- [ ] AC-3: Given the same resource, when `Ash.FieldsParser.parse_associations/4` runs over the parsed fields, then `:belongs_to_field_id` has `sortable?: true` and `:belongs_to_field`, `:has_many_field`, `:has_one_field` and `:many_to_many_field` have `sortable?: false`.
- [ ] AC-4: Given the `Aggregates` resource, then the `:entries_count` aggregate has `sortable?: true`.
- [ ] AC-5 (error path): Given `Ash.FieldsParser.parse_field(AllTypes, :all_types, {:selected_check__, :boolean})` — a key the resource does not define — then the field has `sortable?: false`.
- [ ] AC-6: The shared golden metadata (`Validations.get(:all_types)` and `get(:with_associations)`) carries `sortable?` on every entry, and both backends' golden tests pass against it.

##### Test ports
- `Aurora.Uix.Integration.Ash.FieldsParser.parse_fields/2`, `parse_associations/4`, `parse_field/4` · in: `AllTypes` / `Aggregates` · out: `%Field{}` carrying `sortable?` · existing (`lib/aurora_uix/integration/ash/fields_parser.ex`)
- `Validations.compare_maps/2` over the golden map · existing (`test/cases/integration/fields_parser_validations_test.exs`)

##### Red tests (write first; each must fail before implementation)
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | add to `test/cases/integration/ash/fields_parser_test.exs`, new `describe "sortable?"` | `fields = AllTypes \|> Ash.FieldsParser.parse_fields(:all_types) \|> Map.new(&{&1.key, &1})` | test/cases/integration/ash/fields_parser_test.exs | "scalar attributes are sortable" | `for key <- [:id, :field_integer, :field_string, :field_utc_datetime, :field_duration, :field_status], do: assert fields[key].sortable?` |
| AC-2 | same `describe` | same | same | "arrays and embedded resources are not sortable" | `for key <- [:field_multi_status, :field_string_array, :embeds_many, :embeds_one], do: refute fields[key].sortable?` |
| AC-3 | same `describe` | `AllTypes \|> Ash.FieldsParser.parse_fields(:all_types) \|> then(&Ash.FieldsParser.parse_associations(AllTypes, :all_types, %{}, &1)) \|> Map.new(&{&1.key, &1})` | same | "only the source attribute of a relationship is sortable" | `assert fields[:belongs_to_field_id].sortable?`; `for key <- [:belongs_to_field, :has_many_field, :has_one_field, :many_to_many_field], do: refute fields[key].sortable?` |
| AC-4 | add to the existing `describe "aggregates"` | `aggregate_field(:entries_count)` (the file's existing private helper) | same | "a count aggregate is sortable" | `assert %{sortable?: true} = aggregate_field(:entries_count)` |
| AC-5 | same `describe "sortable?"` | `Ash.FieldsParser.parse_field(AllTypes, :all_types, {:selected_check__, :boolean})` | same | "a key the resource does not define is not sortable" | `refute field.sortable?` |
| AC-6 | amend `test/cases/integration/fields_parser_validations_test.exs` `get/2` fixtures | add a `sortable?:` key directly after `filterable?:` in every entry: `true` for `id`, `field_binary_id`, `field_integer`, `field_float`, `field_boolean`, `field_string`, `field_binary`, `field_bitstring`, `field_decimal`, `field_date`, `field_time`, `field_time_usec`, `field_naive_datetime`, `field_naive_datetime_usec`, `field_utc_datetime`, `field_utc_datetime_usec`, `field_duration`, `field_status`, `belongs_to_field_id`; `false` for `field_multi_status`, `field_string_array`, `embeds_many`, `embeds_one`, `has_many_field`, `many_to_many_field`, `has_one_field`, `belongs_to_field` | test/cases/integration/fields_parser_validations_test.exs (asserted by `ctx/fields_parser_test.exs` and `ash/fields_parser_test.exs` "Validate fields_parser" and "Validate association_parser") | the four existing golden tests | `assert Validations.compare_maps(validations, parsed) == []`, unchanged |

##### Parser changes
1. `lib/aurora_uix/integration/ash/fields_parser.ex` `parse_field/4` — in the `attrs` pipeline insert `|> set(&field_sortable/2, :sortable?, attribute)` directly after `|> set(&field_filterable/2, :filterable?, attribute)`.
2. Same file — new private function, placed directly after the last `field_filterable/2` clause:
   ```elixir
   # Determines if the index column header may sort by the field. An embedded resource is checked
   # first: `Ash.Resource.Info.sortable?/3` treats a single embedded type as sortable.
   @spec field_sortable(map(), map()) :: boolean()
   defp field_sortable(_attrs, %{embedded?: true}), do: false

   defp field_sortable(%{key: key}, %{resource_schema: resource_schema}),
     do: AshResourceInfo.sortable?(resource_schema, key)
   ```
   `attrs` always carries `:key`; `attribute` always carries `:embedded?` and the `resource_schema` module (the `Map.merge(%{resource_schema: resource_schema, embedded?: embedded?, …})` in `parse_field/4`). `AshResourceInfo` is the file's existing alias of `Ash.Resource.Info`.
3. Same file `parse_association/5` — in the `Field.new(…)` keyword list add `sortable?: false,` directly after `filterable?: false,`.
4. The golden fixture edit of AC-6 is part of this section.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:PAR-2:end -->

<!-- section:PAR-3:start -->
### PAR-3 — Parser · ash · QueryParser accepts direction-first `order_by` and a single-tuple `where`; `:in` takes a list only
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md` § QueryBuilder for Advanced Filtering — `order_by: [asc: :category, desc: :price, asc: :name]` (QueryBuilder form).
- `guides/core/ash_integration.md` § With Domain and Ordering — `order_by: [desc: :published_at]` on an Ash resource.
- `guides/core/resource_metadata.md` § Query Options for Many-to-One — `order_by: [desc: :reference]`.
- `guides/core/layouts.md` § QueryBuilder for Advanced Filtering — `:in` takes a list of values; a comma-separated string yields an invalid query on Ash (DOC-1).

#### Implementation details
Ecto side: `Aurora.Ctx.QueryBuilder` (`deps/aurora_ctx/lib/aurora/ctx/query_builder.ex` `option/2`) already accepts `order_by` as an atom, a `{direction, field}` tuple or a list of `{direction, field}` / atoms, and `where` as a single condition. Only Ash diverges, so there is no ctx counterpart: `### Out of Scope` records it.

Current Ash behaviour: `process_option({:order_by, values}, query)` passes `values` to `Ash.Query.sort/2` unchanged. Ash's `Ash.Sort.parse_sort/4` reads `{:desc, :title}` as field `:desc` with direction `:title` and records an `InvalidSortOrder` error. `process_option({:where, values}, query)` runs `Enum.reduce/3` over `values`, which raises `Protocol.UndefinedError` for a single tuple. `process_where_clause({field, :in, value}, query)` (the clause after the `when is_list(values)` one) splits a binary on `","`; this section deletes it, so `:in` accepts a list only and every other value falls through to the standard `{field, operation, value}` clause, where `Ash.Query.filter/2` records a type error and the query becomes invalid. Ecto: `aurora_ctx` 0.1.11 (`UI-1`'s prerequisite) is list-only as well.

Until `UI-1` merges, the Ash filter bar's "in list" condition hands this parser the typed text unchanged and gets an invalid query; `UI-1` splits the text in the handler. No test drives that path (`rg -n "filter_condition.*:in\b" test` returns nothing), so the suite stays green in between.

##### Acceptance criteria
- [ ] AC-1: Given `Ash.Query.new(Aurora.Uix.Guides.Blog.Post)`, when `QueryParser.parse/2` gets `order_by: [desc: :title]`, then `query.sort == [title: :desc]` and `query.valid?` is `true`.
- [ ] AC-2: Given the same query, `order_by: [desc_nulls_last: :title, asc: :content]` yields `query.sort == [title: :desc_nils_last, content: :asc]`.
- [ ] AC-3: Given the same query, the Ash form `order_by: [title: :desc]`, the atom `order_by: :title` and the single tuple `order_by: {:desc, :title}` yield `[title: :desc]`, `[title: :asc]` and `[title: :desc]`.
- [ ] AC-4: Given the same query, `where: {:title, :eq, "x"}` yields the same `query.filter` as `where: [{:title, :eq, "x"}]`.
- [ ] AC-5 (error path): Given the same query, an unsupported direction `order_by: [title: :sideways]` is passed to Ash unchanged and surfaces as an invalid query: `query.valid?` is `false`.
- [ ] AC-6: Given the same query, `where: [{:title, :in, ["a", "b"]}]` yields a valid query whose filter inspects as `#Ash.Filter<title in ["a", "b"]>`.
- [ ] AC-7 (error path): Given the same query, `where: [{:title, :in, "a,b"}]` is no longer split: `query.valid?` is `false`.

##### Test ports
- `Aurora.Uix.Integration.Ash.QueryParser.parse/2` · in: `Ash.Query.t()`, keyword opts · out: `Ash.Query.t()` with `sort` / `filter` · existing (`lib/aurora_uix/integration/ash/query_parser.ex`, `parse/2`)

##### Red tests (write first; each must fail before implementation)
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n "QueryParser" test` returns nothing) | `use ExUnit.Case, async: true`; `alias Aurora.Uix.Guides.Blog.Post`; `alias Aurora.Uix.Integration.Ash.QueryParser`; `query = Ash.Query.new(Post)` — no database | test/cases/integration/ash/query_parser_test.exs | "a direction-first order_by is translated to Ash's field-first form" | `parsed = QueryParser.parse(query, order_by: [desc: :title])`; `assert parsed.sort == [title: :desc]`; `assert parsed.valid?` |
| AC-2 | add to the same file | same | same | "nulls directions map to Ash's nils directions" | `assert QueryParser.parse(query, order_by: [desc_nulls_last: :title, asc: :content]).sort == [title: :desc_nils_last, content: :asc]` |
| AC-3 | add to the same file | same | same | "Ash sorts, atoms and a single tuple keep working" | `assert QueryParser.parse(query, order_by: [title: :desc]).sort == [title: :desc]`; `assert QueryParser.parse(query, order_by: :title).sort == [title: :asc]`; `assert QueryParser.parse(query, order_by: {:desc, :title}).sort == [title: :desc]` |
| AC-4 | add to the same file | same | same | "a single-tuple where equals its one-element list" | `assert QueryParser.parse(query, where: {:title, :eq, "x"}).filter == QueryParser.parse(query, where: [{:title, :eq, "x"}]).filter` |
| AC-5 | add to the same file | same | same | "an unsupported sort direction surfaces as an invalid query" | `refute QueryParser.parse(query, order_by: [title: :sideways]).valid?` |
| AC-6 | add to the same file | same | same | "an in condition takes a list" | `parsed = QueryParser.parse(query, where: [{:title, :in, ["a", "b"]}])`; `assert parsed.valid?`; `assert inspect(parsed.filter) == ~s(#Ash.Filter<title in ["a", "b"]>)` |
| AC-7 | add to the same file | same | same | "a comma-separated in value is not split" | `refute QueryParser.parse(query, where: [{:title, :in, "a,b"}]).valid?` |

##### Parser changes
1. `lib/aurora_uix/integration/ash/query_parser.ex` — add module attributes directly after `require Ash.Query`:
   ```elixir
   @query_builder_directions [
     :asc,
     :desc,
     :asc_nulls_first,
     :asc_nulls_last,
     :desc_nulls_first,
     :desc_nulls_last
   ]

   @ash_sort_directions [
     :asc,
     :desc,
     :asc_nils_first,
     :asc_nils_last,
     :desc_nils_first,
     :desc_nils_last
   ]
   ```
2. Same file, `process_option/2` clause `defp process_option({:order_by, values}, query) do` — replace its body with:
   ```elixir
   values
   |> List.wrap()
   |> Enum.map(&translate_sort/1)
   |> then(&Ash.Query.sort(query, &1))
   ```
3. Same file, clause `defp process_option({:where, values}, query) do` — replace `Enum.reduce(values, query, &process_where_clause/2)` with `values |> List.wrap() |> Enum.reduce(query, &process_where_clause/2)`.
4. Same file — delete the clause and its comment:
   ```elixir
   # Handles :in operator with comma-separated string values.
   defp process_where_clause({field, :in, value}, query) do
     values = String.split(value, ",")
     Ash.Query.filter(query, {^field, {:in, ^values}})
   end
   ```
   The clause `defp process_where_clause({field, :in, values}, query) when is_list(values),` directly above it stays. `process_where_clause/2` keeps its catch-all `defp process_where_clause({field, operation, value}, query) do`, which a non-list `:in` value now reaches.
5. Same file — new private functions, placed directly before `translate_operation/1`:
   ```elixir
   # `Aurora.Ctx.QueryBuilder` sorts are direction-first (`desc: :title`); Ash's are field-first
   # (`title: :desc`). An entry whose second element is an Ash direction is already Ash-shaped.
   @spec translate_sort(term()) :: term()
   defp translate_sort({direction, field})
        when direction in @query_builder_directions and is_atom(field) and
               field not in @ash_sort_directions,
        do: {field, ash_sort_direction(direction)}

   defp translate_sort(sort), do: sort

   @spec ash_sort_direction(atom()) :: atom()
   defp ash_sort_direction(:asc_nulls_first), do: :asc_nils_first
   defp ash_sort_direction(:asc_nulls_last), do: :asc_nils_last
   defp ash_sort_direction(:desc_nulls_first), do: :desc_nils_first
   defp ash_sort_direction(:desc_nulls_last), do: :desc_nils_last
   defp ash_sort_direction(direction), do: direction
   ```
6. Same file `@moduledoc` — in `## Key Features` replace `- Supports \`:order_by\` for sorting` with `- Supports \`:order_by\` in both the \`Aurora.Ctx.QueryBuilder\` direction-first form (\`[desc: :title]\`, \`*_nulls_first\` / \`*_nulls_last\`) and Ash's field-first form (\`[title: :desc]\`)`; delete the bullet `- Comma-separated string parsing for \`:in\` operations`; in `## Key Constraints` replace `- The \`:in\` operator expects either a list or comma-separated string` with `- The \`:in\` operator accepts a list of values only; any other value makes the query invalid` and append the bullet `- \`:where\` accepts a single condition tuple as well as a list; \`dynamic/2\` expressions are Ecto-only and are not supported`.
7. `@doc` of `parse/2` — replace `* \`:order_by\` (term()) - Sorting specification passed to \`Ash.Query.sort/2\`.` with `* \`:order_by\` (term()) - Sorting specification; direction-first entries are translated before \`Ash.Query.sort/2\`.`; in `## Examples` replace `iex> parse(query, where: [{:category, :in, "electronics,books"}])` with `iex> parse(query, where: [{:category, :in, ["electronics", "books"]}])`. These examples are not doctested (`rg -n "QueryParser" test` returns nothing).

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:PAR-3:end -->

<!-- section:UI-1:start -->
### UI-1 — UI · handler · layout `where` + filter merge, "in list" text split into a list, applied filters kept, `aurora_ctx` 0.1.11
Depends on: DOC-1

**Prerequisite (MUST be completed before this section starts):** wadvanced/aurora_ctx#42 ("QueryBuilder: support :in in where/or_where and stop silently dropping unknown conditions") is reworded to a list-only `:in` — `{field, :in, values}` with `values` a list; no comma-separated binary clause; every other value raises `ArgumentError` — then closed, and `aurora_ctx` 0.1.11 is published on Hex with that behaviour. The issue body in the aurora_ctx repository still reads "and for a comma-separated binary (split on \",\")"; its owner edits it there before the release. Check with `mix hex.info aurora_ctx` listing `0.1.11`. When it is not published, stop and report `STATUS: BLOCKED — aurora_ctx-0.1.11-unpublished`.

#### Documentation references
- `guides/core/layouts.md` § Index Layout Options — `:where` "Conditions submitted from the filter bar are added to it" (DOC-1).
- `guides/core/layouts.md` § QueryBuilder for Advanced Filtering — `:in` takes a list of values; the filter bar's "in list" condition splits the typed text on commas and passes a list (DOC-1).

#### Implementation details
Layout types covered: `:index`. `:form` and `:show` are left alone.

Current behaviour (`lib/aurora_uix/templates/basic/handlers/index_impl.ex`): `prepare_query_options/2` merges with `Keyword.merge(load_items_options, opts, fn _key, existing, acc -> [existing | acc] end)`. For `where: filters` it yields `[layout_where | filters]`, a nested list. Ecto's `Aurora.Ctx.QueryBuilder` `where_condition/2` drops the nested list in its catch-all; Ash's `QueryParser.process_where_clause/2` has no clause for a non-empty list and raises `FunctionClauseError`. `auix_handle_event("auix_route_back", …)` calls `load_items/2`, which rebuilds the query options without the submitted filters. `get_selected_filters/1` maps an "in list" filter through its catch-all `{_key, filter} -> {filter.key, filter.condition, filter.from}`, so the backend receives the typed text (`{:reference, :in, "a,b"}`); both backends take `:in` values as a list only (`PAR-3` for Ash, `aurora_ctx` 0.1.11 for Ecto), so the split happens here, in the backend-agnostic handler.

The `aurora_ctx` bump sits in this section, not in a Parser section: 0.1.11 raises `ArgumentError` on the nested `[[] | filters]` list the unfixed merge produces on every filter submit, so the bump is safe only together with the merge fix.

##### Acceptance criteria
- [ ] AC-1: Given `WhereFilterLayoutTest` (Ecto `Product`, layout `where: [{:reference, :between, "item_group_2b", "item_group_3d"}]`) and the 11-product fixture, with the filter bar open, setting `reference` to `ge` `"item_group_1a-2"` and submitting, then the table holds 5 rows (the layout `where` still applies).
- [ ] AC-2: Given the same page, setting `reference` to `in` and typing `"item_group_1a-1,item_group_2b-1,item_group_3c-2"`, then submitting, then the backend receives `{:reference, :in, ["item_group_1a-1", "item_group_2b-1", "item_group_3c-2"]}` and the table holds 2 rows (`aurora_ctx` 0.1.11 raises `ArgumentError` on the unsplit string, so the row count proves the list).
- [ ] AC-3 (degraded path): Given the same page, submitting with no filter value set, then the table holds 5 rows.
- [ ] AC-4: Given the same page, setting `reference` to `ge` `"item_group_3c-1"`, submitting, then pushing `"auix_route_back"`, then the table still holds 2 rows.
- [ ] AC-5 to AC-8: the same four cases on Ash — `AshWhereFilterLayoutTest` (Ash `Post`, layout `where: [{:title, :between, "post_group_2b", "post_group_3d"}]`, the 11-post fixture, filter on `title`) — with the same counts: 5, 2, 5, 2.
- [ ] AC-9: `test/cases_live/where_one2many_test.exs` "Test where" passes on `aurora_ctx` 0.1.11 with a flat expected-result `where`.
- [ ] AC-10 (degraded path): Given `WhereFilterLayoutTest`, setting `reference` to `in` and typing `" item_group_2b-1 ,item_group_3c-1,"` (surrounding spaces, trailing comma), then submitting, then the table holds 2 rows: entries are trimmed and empty entries dropped.
- [ ] AC-11 (degraded path): the same on Ash — `AshWhereFilterLayoutTest`, `title` set to `in` and typed `" post_group_2b-1 ,post_group_3c-1,"` — 2 rows.

##### Test ports
- Route `"where-filter-layout-products"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(WhereFilterLayoutTest.Product, "where-filter-layout-products")` · layout types `:index` · observable: row count of `#auix-table-where-filter-layout-products-index tr`.
- Route `"ash-where-filter-layout-posts"` registered via `RoutesHelper.register_crud(AshWhereFilterLayoutTest.Post, "ash-where-filter-layout-posts")` · `:index` · observable: row count of `#auix-table-ash-where-filter-layout-posts-index tr`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n "WhereFilterLayout\|where-filter-layout\|where_filter_layout" test lib` returns nothing) | `view = prepare_filters_test(conn)`; `set_filter_change(view, :filter_condition, :reference, :ge)`; `set_filter_change(view, :filter_from, :reference, "item_group_1a-2")` | test/cases_live/where_filter_layout_test.exs | "a submitted filter narrows the layout where instead of replacing it" | `assert submitted_row_count(view) == 5` |
| AC-2 | add to the same file | `prepare_filters_test(conn)`; condition `:in`, from `"item_group_1a-1,item_group_2b-1,item_group_3c-2"` (the text a user types; the handler hands the backend the three-element list) | same | "the in-list condition passes a list to Ecto" | `assert submitted_row_count(view) == 2` |
| AC-3 | add to the same file | `prepare_filters_test(conn)`; no filter change | same | "submitting without a filter keeps the layout where" | `assert submitted_row_count(view) == 5` |
| AC-4 | add to the same file | `prepare_filters_test(conn)`; condition `:ge`, from `"item_group_3c-1"`; `assert submitted_row_count(view) == 2`; then `render_click(view, "auix_route_back", %{})` | same | "submitted filters survive auix_route_back" | `assert row_count(view) == 2` |
| AC-5 … AC-8 | new file (`rg -n "AshWhereFilterLayout\|ash-where-filter-layout\|ash_where_filter_layout" test lib` returns nothing) | the same four tests, filtering `:title` with the `post_group_…` values (`"post_group_1a-2"`; `"post_group_1a-1,post_group_2b-1,post_group_3c-2"`; none; `"post_group_3c-1"`) | test/cases_live/ash_where_filter_layout_test.exs | the same four test names | the same four counts: 5, 2, 5, 2 |
| AC-9 | amend `test/cases_live/where_one2many_test.exs` "Test where" | replace `where: [[product_id: product_id], {:quantity, :between, 8, 16}]` in the `expected_result` query with `where: [{:product_id, product_id}, {:quantity, :between, 8, 16}]` | test/cases_live/where_one2many_test.exs | "Test where" | assertion unchanged |
| AC-10 | add to `test/cases_live/where_filter_layout_test.exs` | `prepare_filters_test(conn)`; condition `:in`, from `" item_group_2b-1 ,item_group_3c-1,"` | same | "in-list entries are trimmed and empty entries dropped" | `assert submitted_row_count(view) == 2` |
| AC-11 | add to `test/cases_live/ash_where_filter_layout_test.exs` | `prepare_filters_test(conn)`; condition `:in`, from `" post_group_2b-1 ,post_group_3c-1,"` | same | the AC-10 test name | `assert submitted_row_count(view) == 2` |

##### Modules & components
1. `mix.exs` `deps/0` — replace `{:aurora_ctx, "~> 0.1"}` with `{:aurora_ctx, "~> 0.1.11"}`; run `mix deps.update aurora_ctx`; commit `mix.exs` and `mix.lock` (`aurora_ctx` 0.1.10 → 0.1.11).
2. `lib/aurora_uix/templates/basic/handlers/index_impl.ex` `auix_mount/3` — insert `|> assign_auix(:filters_where, [])` directly after `|> assign_auix(:filters_enabled?, false)`.
3. Same file, `auix_handle_event/3` clause `"filters-submit"` — replace the piped body
   ```elixir
     socket
     |> assign_filters_selected_count()
     |> prepare_query_options(where: filters)
     |> refresh_current_page()}
   ```
   with
   ```elixir
     socket
     |> assign_filters_selected_count()
     |> assign_auix(:filters_where, filters)
     |> prepare_query_options()
     |> refresh_current_page()}
   ```
4. Same file `prepare_query_options/2` — contract change: arity 2 → 1. Replace the function, its comment and `@spec` with:
   ```elixir
   # Builds the list query from the layout and metadata options plus the submitted filters.
   # The layout `where` and the filters are concatenated into one flat condition list: both
   # `Aurora.Ctx.QueryBuilder` and the Ash query parser expect a flat list.
   # The resulting query is stored in :query_options assigns key.
   @spec prepare_query_options(Socket.t()) :: Socket.t()
   defp prepare_query_options(
          %{
            assigns: %{
              auix: %{load_items_options: load_items_options, filters_where: filters_where}
            }
          } = socket
        ) do
     where =
       load_items_options
       |> Keyword.get(:where)
       |> where_conditions()
       |> Kernel.++(filters_where)

     base_options = [order_by: Keyword.get(load_items_options, :order_by), where: where]
     query_options = maybe_put_preload(base_options, Keyword.get(load_items_options, :preload))

     assign_auix(socket, :query_options, query_options)
   end

   # A `where` may be a list, a map of equalities, a single condition or a dynamic expression.
   @spec where_conditions(term()) :: list()
   defp where_conditions(nil), do: []
   defp where_conditions(conditions) when is_list(conditions), do: conditions
   defp where_conditions(conditions) when is_non_struct_map(conditions), do: Map.to_list(conditions)
   defp where_conditions(condition), do: [condition]
   ```
   Current callers and their new call: `load_items/2` (`|> prepare_query_options()`, unchanged text); the `"filters-submit"` clause (step 3). No other caller: `rg -n "prepare_query_options" lib` lists these two call sites plus the function's own `@spec` and head.
5. Same file `get_selected_filters/1` — the function has two anonymous functions, each ending in a catch-all clause `{_key, filter} ->`. Insert one clause directly before each catch-all:
   - in the `Enum.reject/2` function, directly after the `{_key, %{condition: condition}} when condition in [false, true] -> false` clause:
     ```elixir
           {_key, %{condition: :in} = filter} ->
             is_nil(filter.from) or filter.from == ""
     ```
   - in the `Enum.map/2` function, directly after the `{_key, %{condition: condition} = filter} when condition in [false, true] -> {filter.key, condition}` clause:
     ```elixir
           {_key, %{condition: :in} = filter} ->
             {filter.key, :in, in_values(filter.from)}
     ```
   `filter.from` is the `"filter_from__<key>"` param, a binary (`update_filter/3` stores `params[from_key]`).
6. Same file — new private function, placed directly after `get_selected_filters/1` and before `escape/1`:
   ```elixir
   # The "in list" input is free text; both backends take `:in` values as a list only.
   @spec in_values(binary()) :: list(binary())
   defp in_values(text) do
     text
     |> String.split(",")
     |> Enum.map(&String.trim/1)
     |> Enum.reject(&(&1 == ""))
   end
   ```
   `assign_filters_selected_count/1` also calls `get_selected_filters/1`: an "in list" filter with an empty text no longer counts as selected, which matches `:contains`.
7. `test/support/app_web/routes.ex` `load_test_routes/0` — append, inside the same `quote`, directly after the `RoutesHelper.register_crud(FormDiscardGuardDisabledTest.Product, "form-discard-guard-disabled-products")` call:
   ```elixir
   RoutesHelper.register_crud(
     WhereFilterLayoutTest.Product,
     "where-filter-layout-products"
   )

   RoutesHelper.register_crud(
     AshWhereFilterLayoutTest.Post,
     "ash-where-filter-layout-posts"
   )
   ```
8. `Aurora.UixWeb.Test.WhereFilterLayoutTest` at `test/cases_live/where_filter_layout_test.exs` — new:
   1. `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `alias Aurora.Uix.Guides.Inventory`, `alias Aurora.Uix.Guides.Inventory.Product`, `alias Phoenix.LiveViewTest.View`.
   2. Metadata: `auix_resource_metadata(:product, context: Inventory, schema: Product, order_by: :reference)`.
   3. Layout: `auix_create_ui do index_columns(:product, [:reference, :name], where: [{:reference, :between, "item_group_2b", "item_group_3d"}]) end`.
   4. `@spec prepare_filters_test(Plug.Conn.t()) :: View.t()` private: `delete_all_inventory_data()`; `create_sample_products(2, :group_1a)`; `create_sample_products(3, :group_2b)`; `create_sample_products(2, :group_3c)`; `create_sample_products(4, :group_3d)`; `{:ok, view, _html} = live(conn, "/where-filter-layout-products")`; `view |> element("[name='auix-filter_toggle_open']") |> render_click()`; return `view`. References are `"item_group_1a-1"` … `"item_group_3d-4"` (`test/support/helper.ex` `create_sample_products/3` + `reference_id/3`). The layout `where` keeps the three `2b` and the two `3c` references: every `3d-*` reference sorts after `"item_group_3d"`.
   5. `@spec set_filter_change(View.t(), atom(), atom(), atom() | binary()) :: View.t()` — copy verbatim from `test/cases_live/special_fields_ui_test.exs`.
   6. `@spec row_count(View.t()) :: non_neg_integer()` private: `view |> render() |> LazyHTML.from_document() |> LazyHTML.query("#auix-table-where-filter-layout-products-index tr") |> Enum.count()`.
   7. `@spec submitted_row_count(View.t()) :: non_neg_integer()` private: `view |> element("[name='auix-index-header-actions'] [name='auix-filters_submit-product']") |> render_click()`, then `row_count(view)`.
9. `Aurora.UixWeb.Test.AshWhereFilterLayoutTest` at `test/cases_live/ash_where_filter_layout_test.exs` — new. Same shape as item 8, with these differences:
   1. `alias Aurora.Uix.Guides.Blog.Post`.
   2. Metadata: `auix_resource_metadata(:post, ash_resource: Post, order_by: :title)`.
   3. Layout: `auix_create_ui do index_columns(:post, [:title, :content], where: [{:title, :between, "post_group_2b", "post_group_3d"}]) end`.
   4. `prepare_filters_test/1`: `delete_all_blog_data()`; one `create_sample_posts(1, %{title: title})` call per title of `post_group_1a-1`, `post_group_1a-2`, `post_group_2b-1`, `post_group_2b-2`, `post_group_2b-3`, `post_group_3c-1`, `post_group_3c-2`, `post_group_3d-1`, `post_group_3d-2`, `post_group_3d-3`, `post_group_3d-4`; route `"/ash-where-filter-layout-posts"`. `create_sample_posts/2` keeps the `:title` key of `attrs`; `Post` `belongs_to :author` allows nil.
   5. `row_count/1` queries `#auix-table-ash-where-filter-layout-posts-index tr`; `submitted_row_count/1` clicks `[name='auix-index-header-actions'] [name='auix-filters_submit-post']`.
10. Selectors relied on, verified at their definition: tbody id `"auix-table-#{@auix.uri_path_id}-index"` (`index_renderer.ex` `render/1`); `auix-filter_toggle_open` and `"auix-filters_submit-#{@auix.module}"` (`lib/aurora_uix/templates/basic/actions/index.ex`); the `"auix_route_back"` clause of `auix_handle_event/3` calls `load_items/2`.
11. Components: none new. Theme: none. `dt/1` strings: none.
12. Standing rules touched: the change is in the backend-agnostic handler; it hands both backends the same flat list, with every `:in` value a list. No changeset is built.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

<!-- section:UI-2:start -->
### UI-2 — UI · Ash counterparts of the index and association query tests, Ash one-to-many rows
Depends on: UI-1, PAR-3

#### Documentation references
- `guides/core/layouts.md` § Index Layout Options — `index_columns` `:order_by` and `:where`.
- `guides/core/liveview.md` § Filtering and Sorting — metadata `order_by` and its layout override.
- `guides/core/resource_metadata.md` § Query Options for Many-to-One — `order_by` / `where` on a selector.
- `guides/core/ash_integration.md` § Filtering and Sorting — the same options on an Ash resource.

#### Implementation details
Layout types covered: `:index` (AC-1 to AC-12), `:show` (AC-13, AC-15), `:form` (AC-14).

Ecto originals mirrored: `where_layout_test.exs`, `order_by_layout_test.exs`, `order_by_metadata_test.exs`, the filter tests of `special_fields_ui_test.exs`, `where_one2many_test.exs`, `where_many2one_test.exs`. The Ash `contains` substring case is already covered by `test/cases_live/ash_default_layout_test.exs` "Test filters contains matches a substring, case-insensitively" and is not repeated.

Library change (one): `lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` `maybe_apply_where/1` stores the raw `apply_list_function/2` result in `entity.<field>`. For Ash the result is `%Aurora.Ctx.Pagination{}` (`lib/aurora_uix/integration/ash/crud.ex` `list/2`). `auix_items/1` hands it to `assign_rows/4` (`components.ex`), whose `%{} = streams` clause treats it as a streams map: it finds no rows and does not set `:empty_list?`, which `auix_items_table/1` reads as `@auix.empty_list?`. The Ecto list function returns a plain list, which the list clause handles.

##### Acceptance criteria
- [ ] AC-1: Given `AshWhereLayoutTest` (Ash `Author`, metadata `order_by: :email`, `index_columns(:author, [:name, :email, :bio], order_by: :name, where: [{:email, :between, "author_test_order-05@test.com", "author_test_order-13@test.com"}])`) and 20 authors created in shuffled order, visiting `/ash-where-layout-authors`, then the name cells read `"Author test_order-05"` through `"Author test_order-13"`, in ascending order, and nothing else.
- [ ] AC-2: Given `AshOrderByLayoutTest` (metadata `order_by: :email` over random emails, `index_columns(:author, [:name, :email, :bio], order_by: :name)`) and 20 authors created in shuffled order, visiting `/ash-order-by-layout-authors`, then the name cells read `"Author test_order-01"` through `"Author test_order-20"` in ascending order.
- [ ] AC-3: Given `AshOrderByMetadataTest` (metadata `order_by: :email`, `index_columns(:author, [:name, :email, :bio])`) and 20 authors created in shuffled order, visiting `/ash-order-by-metadata-authors`, then the email cells read `"author_test_order-01@test.com"` through `"author_test_order-20@test.com"` in ascending order.
- [ ] AC-4: Given `AshFilterBarTest` and the 11-post fixture, with the filter bar open, setting `title` to condition `eq` and value `"post_group_3d-1"`, then the input keeps that value, and after submit the table holds 1 row.
- [ ] AC-5: Given the same fixture, setting `title` to condition `ge` and value `"post_group_3d-2"`, then the input keeps that value, and after submit the table holds 3 rows.
- [ ] AC-6: Given the same fixture, setting `title` to condition `between`, from `"post_group_2b"` and to `"post_group_3d"`, then the `to` input keeps `"post_group_3d"`, and after submit the table holds 5 rows.
- [ ] AC-7: Given the same fixture, setting `author_id` to condition `eq` and value the second author's id, then that option is selected in the `author_id` filter select, and after submit the table holds 7 rows.
- [ ] AC-8: Given the same fixture, setting `title` to condition `contains` and value `"%"`, then submit yields 0 rows; value `"a_1"` also yields 0 rows.
- [ ] AC-9: Given the same fixture, setting `title` to condition `contains` and value `""`, then the `to` input is readonly and disabled, and submit yields all 11 rows.
- [ ] AC-10 (empty path): Given the same fixture, setting `title` to condition `eq` and value `"post_group_9z-1"`, then submit yields 0 rows and `div.auix-items-table-empty` is shown.
- [ ] AC-11: Given `/ash-filter-bar-posts`, the filter submit and clear buttons are absent until the filter toggle is clicked, and present after.
- [ ] AC-12: Given the same page with the filter bar open, the condition selects of `author_id` and `published_at` offer no `contains` option.
- [ ] AC-13: Given `AshWhereOne2ManyTest` (`edit_layout :author` with `posts: [order_by: [desc: :title], where: {:title, :between, "Posttest-08", "Posttest-14"}]`), an author with 20 posts `"Posttest-01"` … `"Posttest-20"` and a second author with posts `"Posttest-1"` … `"Posttest-3"`, visiting the first author's show page, then the one-to-many title cells read `"Posttest-14"` down to `"Posttest-08"` (7 rows), and none of the second author's posts.
- [ ] AC-14: Given `AshWhereMany2OneTest` (`field(:author_id, option_label: :name, order_by: [desc: :name], where: [{:name, :between, "Authortest-08", "Authortest-14"}])`), 20 authors and a post owned by `"Authortest-10"`, visiting the post's edit page, then the `author_id` select options starting with `"Authortest-"` read `"Authortest-14"` down to `"Authortest-08"`.
- [ ] AC-15 (empty path): Given the data of AC-13, visiting the show page of the third author, who owns no post, then its one-to-many table holds no row and shows `.auix-items-table-empty`.

##### Test ports
- Route `"ash-where-layout-authors"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(AshWhereLayoutTest.Author, "ash-where-layout-authors")` · `:index` · observable: cell texts under `#auix-table-ash-where-layout-authors-index tr td:nth-of-type(2)`.
- Route `"ash-order-by-layout-authors"` via `RoutesHelper.register_crud(AshOrderByLayoutTest.Author, "ash-order-by-layout-authors")` · `:index` · observable: `#auix-table-ash-order-by-layout-authors-index tr td:nth-of-type(2)`.
- Route `"ash-order-by-metadata-authors"` via `RoutesHelper.register_crud(AshOrderByMetadataTest.Author, "ash-order-by-metadata-authors")` · `:index` · observable: `#auix-table-ash-order-by-metadata-authors-index tr td:nth-of-type(3)`.
- Route `"ash-filter-bar-posts"` via `RoutesHelper.register_crud(AshFilterBarTest.Post, "ash-filter-bar-posts")` · `:index` · observable: `has_element?/2` on `[name='filter_from__<field>']` / `[name='filter_to__<field>']` / `[name='filter_condition__<field>']`, and the row count of `#auix-table-ash-filter-bar-posts-index tr`.
- Route `"ash-where-one_to_many-authors"` via `RoutesHelper.register_crud(AshWhereOne2ManyTest.Author, "ash-where-one_to_many-authors")` · `:show` · observable: `tbody#author__posts-show tr td:nth-of-type(1)` and `#auix-one_to_many-author__posts-show .auix-items-table-empty`.
- Route `"ash-where-many_to_one-posts"` via `RoutesHelper.register_crud(AshWhereMany2OneTest.Post, "ash-where-many_to_one-posts")` · `:form` · observable: `select[name='post[author_id]'] option` texts.

Column positions: the first `td` of every index row is the selection checkbox column (`IndexImpl.assign_index_fields/1` prepends `:selected_check__`). With `[:name, :email, :bio]`, `td:nth-of-type(2)` is `name` and `td:nth-of-type(3)` is `email`. The one-to-many table has no checkbox column: its columns are the related resource's index fields (`one_to_many.ex` `get_association_fields/2`), so with `index_columns(:post, [:title, :content])` `td:nth-of-type(1)` is `title`. The one-to-many tbody id is `"#{module}__#{field.key}-#{layout_type}"`, as `where_one2many_test.exs` queries `tbody#product__product_transactions-show`.

##### Red tests
AC-1 to AC-12 pass on the dependencies' merged code: they guard parity. AC-13 and AC-15 fail before the `one_to_many.ex` change; AC-13 and AC-14 also fail without `PAR-3`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n "AshWhereLayout\|ash-where-layout\|ash_where_layout" test lib` returns nothing) | `delete_all_blog_data()`; `create_shuffled_authors(@shuffled_references)`; `{:ok, view, _html} = live(conn, "/ash-where-layout-authors")` | test/cases_live/ash_where_layout_test.exs | "index where and order_by select and sort the rows" | `assert column_texts(view, 2) == @test_names` (`"Author test_order-05"` … `"Author test_order-13"`, 9 entries) |
| AC-2 | new file (`rg -n "AshOrderByLayout\|ash-order-by-layout\|ash_order_by_layout" test lib` returns nothing) | `delete_all_blog_data()`; `create_shuffled_authors(@shuffled_references)`; `live(conn, "/ash-order-by-layout-authors")` | test/cases_live/ash_order_by_layout_test.exs | "layout order_by overrides the metadata order_by" | `assert column_texts(view, 2) == @test_names` (`"Author test_order-01"` … `"Author test_order-20"`) |
| AC-3 | new file (`rg -n "AshOrderByMetadata\|ash-order-by-metadata\|ash_order_by_metadata" test lib` returns nothing) | `delete_all_blog_data()`; `create_shuffled_authors(@shuffled_references)`; `live(conn, "/ash-order-by-metadata-authors")` | test/cases_live/ash_order_by_metadata_test.exs | "metadata order_by sorts the index" | `assert column_texts(view, 3) == @test_emails` (`"author_test_order-01@test.com"` … `"author_test_order-20@test.com"`) |
| AC-4 | new file (`rg -n "AshFilterBar\|ash-filter-bar\|ash_filter_bar" test lib` returns nothing) | `{view, _authors} = prepare_filters_test(conn)`; `set_filter_change(view, :filter_condition, :title, :eq)`; `set_filter_change(view, :filter_from, :title, "post_group_3d-1")` | test/cases_live/ash_filter_bar_test.exs | "equality" in `describe "filter bar"` | `assert has_element?(view, "input[name='filter_from__title'][value='post_group_3d-1']")`; `assert submitted_row_count(view) == 1` |
| AC-5 | add to the same file | `prepare_filters_test(conn)`; condition `:ge`, from `"post_group_3d-2"` | same | "ge" in `describe "filter bar"` | `assert has_element?(view, "input[name='filter_from__title'][value='post_group_3d-2']")`; `assert submitted_row_count(view) == 3` |
| AC-6 | add to the same file | `prepare_filters_test(conn)`; condition `:between`, from `"post_group_2b"`, to `"post_group_3d"` | same | "between" in `describe "filter bar"` | `assert has_element?(view, "input[name='filter_to__title'][value='post_group_3d']")`; `assert submitted_row_count(view) == 5` |
| AC-7 | add to the same file | `{view, [_first, second, _third]} = prepare_filters_test(conn)`; `set_filter_change(view, :filter_condition, :author_id, :eq)`; `set_filter_change(view, :filter_from, :author_id, second.id)` | same | "many to one" in `describe "filter bar"` | `assert has_element?(view, "select[name='filter_from__author_id'] option[selected][value='#{second.id}']")`; `assert submitted_row_count(view) == 7` |
| AC-8 | add to the same file | `prepare_filters_test(conn)`; `set_filter_change(view, :filter_condition, :title, :contains)`; then, for each of `["%", "a_1"]`, `set_filter_change(view, :filter_from, :title, value)` | same | "contains escapes the ilike wildcards" in `describe "filter bar"` | inside the `for`: `assert submitted_row_count(view) == 0` |
| AC-9 | add to the same file | `prepare_filters_test(conn)`; condition `:contains`, from `""` | same | "contains ignores the to value and a blank from value" in `describe "filter bar"` | `assert has_element?(view, "[name='filter_to__title'][readonly][disabled]")`; `assert submitted_row_count(view) == 11` |
| AC-10 | add to the same file | `prepare_filters_test(conn)`; condition `:eq`, from `"post_group_9z-1"` | same | "a filter matching no row shows the empty state" in `describe "filter bar"` | `assert submitted_row_count(view) == 0`; `assert has_element?(view, "div.auix-items-table-empty")` |
| AC-11 | add to the same file | `delete_all_blog_data()`; `{:ok, view, _html} = live(conn, "/ash-filter-bar-posts")` | same | "the filter bar opens on the toggle" in `describe "filter bar"` | `refute has_element?(view, "[name='auix-filters_submit-post']")`; `refute has_element?(view, "[name='auix-filters_clear-post']")`; click `[name='auix-filter_toggle_open']`; `assert` both present |
| AC-12 | add to the same file | `{view, _authors} = prepare_filters_test(conn)` | same | "the condition select offers no contains option for non-text fields" in `describe "filter bar"` | `for field <- [:author_id, :published_at], do: refute has_element?(view, "select[name='filter_condition__#{field}'] option[value='contains']")` |
| AC-13 | new file (`rg -n "AshWhereOne2Many\|ash-where-one_to_many\|ash_where_one2many" test lib` returns nothing) | `delete_all_blog_data()`; `[first, second, _third] = create_sample_authors(3)`; `create_sample_posts(20, %{author_id: first.id})`; `create_sample_posts(3, %{author_id: second.id})`; `live(conn, "/ash-where-one_to_many-authors/#{first.id}/show")` | test/cases_live/ash_where_one2many_test.exs | "one-to-many where and order_by select and sort the related rows" | `assert column_texts(view, "tbody#author__posts-show tr td:nth-of-type(1)") == @expected_titles` (`"Posttest-14"` … `"Posttest-08"`, 7 entries) |
| AC-14 | new file (`rg -n "AshWhereMany2One\|ash-where-many_to_one\|ash_where_many2one" test lib` returns nothing) | `delete_all_blog_data()`; `authors = create_sample_authors(20)`; `[post] = create_sample_posts(1, %{author_id: Enum.at(authors, 9).id})`; `live(conn, "/ash-where-many_to_one-posts/#{post.id}/edit")` | test/cases_live/ash_where_many2one_test.exs | "many-to-one selector where and order_by select and sort the options" | option texts of `select[name='post[author_id]'] option`, filtered by `String.starts_with?(&1, "Authortest-")`, `== @expected_names` (`"Authortest-14"` … `"Authortest-08"`, 7 entries) |
| AC-15 | add to `test/cases_live/ash_where_one2many_test.exs` | same data as AC-13, binding `[_first, _second, third]`; `live(conn, "/ash-where-one_to_many-authors/#{third.id}/show")` | same | "an author with no post shows the empty one-to-many state" | `assert column_texts(view, "tbody#author__posts-show tr td:nth-of-type(1)") == []`; `assert has_element?(view, "#auix-one_to_many-author__posts-show .auix-items-table-empty")` |

##### Modules & components
1. `lib/aurora_uix/templates/basic/helpers.ex` — contract change: rename the private `select_option_entries/1` to the public `list_entries/1`, with `@doc`:
   ```elixir
   @doc """
   Returns the records of a list-function result.

   `apply_list_function/2` returns a plain list for the Ctx/Ecto backend but a paginated struct for
   Ash; both are normalised to a list of entries.

   ## Parameters
   - `results` (map() | list()) - A `%{entries: list()}` pagination struct or a plain list.

   ## Returns
   list() - The entries.
   """
   @spec list_entries(map() | list()) :: list()
   def list_entries(%{entries: entries}), do: entries
   def list_entries(results) when is_list(results), do: results
   ```
   Delete the old comment above `select_option_entries/1`. Current caller: `resource_select_options/1` (`|> select_option_entries()` → `|> list_entries()`). No other caller (`rg -n "select_option_entries" lib test`).
2. `lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` `maybe_apply_where/1` — insert `|> BasicHelpers.list_entries()` between the `|> then(&apply_list_function(…))` step and `|> then(&put_in(assigns, [:auix, :entity, Access.key!(field.key)], &1))`.
3. Same file `@moduledoc` `## Key Features` — replace `- Provides list display with sortable columns` with `- Lists the related records in a table, honouring the field's \`order_by\` and \`where\` options`.
4. `Aurora.UixWeb.Test.AshWhereLayoutTest` at `test/cases_live/ash_where_layout_test.exs` — new:
   1. `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `alias Aurora.Uix.Guides.Blog.Author`.
   2. `@shuffled_references` — copy the 20-entry list verbatim from `test/cases_live/order_by_layout_test.exs` `@shuffled_references`.
   3. Metadata: `auix_resource_metadata(:author, ash_resource: Author, order_by: :email)`.
   4. Layout: `auix_create_ui do index_columns(:author, [:name, :email, :bio], order_by: :name, where: [{:email, :between, "author_test_order-05@test.com", "author_test_order-13@test.com"}]) end`.
   5. `@spec create_shuffled_authors(list(binary())) :: :ok` private: `Enum.each(reference_ids, fn reference_id -> create_sample_authors(1, %{name: "Author #{reference_id}", email: "author_#{reference_id}@test.com", bio: "Bio #{reference_id}"}) end)`. `create_sample_authors/2` (`test/support/helper.ex`) keeps the `:name`, `:email` and `:bio` keys of `attrs` and creates one author per call, so creation order follows the list.
   6. `@spec column_texts(Phoenix.LiveViewTest.View.t(), pos_integer()) :: list(binary())` private: `view |> render() |> LazyHTML.from_document() |> LazyHTML.query("#auix-table-ash-where-layout-authors-index tr td:nth-of-type(#{position})") |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))` — the query `test/cases_live/ash_default_layout_test.exs` "Pagination navigation test" runs on `#auix-table-ash-default-layout-authors-index tr`.
5. `Aurora.UixWeb.Test.AshOrderByLayoutTest` at `test/cases_live/ash_order_by_layout_test.exs` — new. Same shape as item 4, with: layout `index_columns(:author, [:name, :email, :bio], order_by: :name)`; `create_shuffled_authors/1` sets `email: "#{Ash.UUID.generate()}@test.com"` (random metadata order, as `order_by_layout_test.exs` `create_shuffled_products/1` randomises `reference`); `column_texts/2` queries `#auix-table-ash-order-by-layout-authors-index tr td:nth-of-type(#{position})`.
6. `Aurora.UixWeb.Test.AshOrderByMetadataTest` at `test/cases_live/ash_order_by_metadata_test.exs` — new. Same shape as item 4, with: layout `index_columns(:author, [:name, :email, :bio])`; `create_shuffled_authors/1` as item 4; `column_texts/2` queries `#auix-table-ash-order-by-metadata-authors-index tr td:nth-of-type(#{position})`.
7. `Aurora.UixWeb.Test.AshFilterBarTest` at `test/cases_live/ash_filter_bar_test.exs` — new:
   1. `use` lines as item 4; `alias Aurora.Uix.Guides.Blog.Author`, `alias Aurora.Uix.Guides.Blog.Post`, `alias Phoenix.LiveViewTest.View`.
   2. Metadata: `auix_resource_metadata(:author, ash_resource: Author)` and `auix_resource_metadata :post, ash_resource: Post do field(:author_id, option_label: :name) end` (the metadata of `test/cases_live/ash_many_to_one_select_test.exs`).
   3. Layout: `auix_create_ui do index_columns(:post, [:title, :author_id, :published_at]) end`.
   4. `@spec prepare_filters_test(Plug.Conn.t()) :: {View.t(), list(struct())}` private: `delete_all_blog_data()`; `[first, second, third] = authors = create_sample_authors(3)`; 11 posts, one `create_sample_posts(1, %{title: title, author_id: author.id})` call each:

      | Titles | Author |
      |---|---|
      | `post_group_1a-1`, `post_group_1a-2` | `first` |
      | `post_group_2b-1`, `post_group_2b-2`, `post_group_2b-3` | `second` |
      | `post_group_3c-1`, `post_group_3c-2` | `third` |
      | `post_group_3d-1`, `post_group_3d-2`, `post_group_3d-3`, `post_group_3d-4` | `second` |

      then `{:ok, view, _html} = live(conn, "/ash-filter-bar-posts")`; `view |> element("[name='auix-filter_toggle_open']") |> render_click()`; return `{view, authors}`.
   5. `set_filter_change/4` and `submitted_row_count/1` — copy both private functions, with their `@spec`s, from `test/cases_live/special_fields_ui_test.exs`. In `submitted_row_count/1` replace the submit selector with `[name='auix-index-header-actions'] [name='auix-filters_submit-post']` and the row query `"tbody tr"` with `"#auix-table-ash-filter-bar-posts-index tr"`.
   6. Expected counts follow from the fixture: `ge "post_group_3d-2"` keeps `3d-2`, `3d-3`, `3d-4`; `between "post_group_2b"` and `"post_group_3d"` keeps the three `2b` and the two `3c` titles; `second` owns 3 + 4 posts.
8. `Aurora.UixWeb.Test.AshWhereOne2ManyTest` at `test/cases_live/ash_where_one2many_test.exs` — new:
   1. `use` lines as item 4; `alias Aurora.Uix.Guides.Blog.Author`, `alias Aurora.Uix.Guides.Blog.Post`.
   2. Metadata: `auix_resource_metadata(:author, ash_resource: Author)` and `auix_resource_metadata(:post, ash_resource: Post)`.
   3. Layout: `auix_create_ui do index_columns(:post, [:title, :content]); edit_layout :author do stacked([:name, :email, posts: [order_by: [desc: :title], where: {:title, :between, "Posttest-08", "Posttest-14"}]]) end end`.
   4. Titles: `create_sample_posts(20, …)` titles `"Posttest-01"` … `"Posttest-20"`; `create_sample_posts(3, …)` titles `"Posttest-1"` … `"Posttest-3"` (`reference_id/3` pads to the count's digit length). All three short titles sort inside the range, so a missing owner-key condition shows them.
   5. `column_texts/2` private, taking the full selector: `view |> render() |> LazyHTML.from_document() |> LazyHTML.query(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))`.
9. `Aurora.UixWeb.Test.AshWhereMany2OneTest` at `test/cases_live/ash_where_many2one_test.exs` — new:
   1. Metadata: `auix_resource_metadata(:author, ash_resource: Author)` and `auix_resource_metadata :post, ash_resource: Post do field(:author_id, option_label: :name, order_by: [desc: :name], where: [{:name, :between, "Authortest-08", "Authortest-14"}]) end`.
   2. Layout: `auix_create_ui do edit_layout :post do stacked([:title, :content, :author_id]) end end`.
   3. Author names are `"Authortest-01"` … `"Authortest-20"` (`create_sample_authors/2` `name: "Author#{reference_id}"`); `Enum.at(authors, 9)` is `"Authortest-10"`, inside the range.
10. `test/support/app_web/routes.ex` `load_test_routes/0` — append, inside the same `quote`, directly after the `RoutesHelper.register_crud(AshWhereFilterLayoutTest.Post, "ash-where-filter-layout-posts")` call (added by `UI-1`), one `RoutesHelper.register_crud/2` call per route listed under Test ports, in that order.
11. Components: none new. Theme: none. `dt/1` strings: none.
12. Standing rules touched: `list_entries/1` normalises a backend result shape inside backend-agnostic code without naming any backend struct. Assert with `has_element?/2` and with `LazyHTML` queries over `render(view)`, as the existing Ash tests do; never `=~` on HTML, never an `auix-field-*` id.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-2:end -->

<!-- section:UI-3:start -->
### UI-3 — UI · sortable index column headers
Depends on: PAR-2, PAR-3, UI-2

#### Documentation references
- `guides/core/layouts.md` § Index Layout Options — `:order_by` replaced by a header click (DOC-1).
- `guides/core/layouts.md` § Field-Level Options — `:sortable?` (DOC-1).
- `guides/core/liveview.md` § Built-in Events — `"index-sort"` (DOC-1); § How Sorting Works (DOC-1).
- `guides/customization/styling.md` § Class reference — `.auix-items-table-header-sort` (DOC-1).

#### Implementation details
Layout types covered: `:index`, desktop table only. The mobile card list (`auix_items_card/1`) has no header row and gets no sort control; it shows the same sorted stream. `:form` and `:show` are left alone; the one-to-many table passes plain `%{label, key, type}` column maps without `sortable?`, so it gets no control.

Sort state: `auix.sort` is `nil` or `%{key: atom(), direction: :asc | :desc}`. A click on an unsorted column sorts it ascending; a click on the ascending column sorts it descending; a click on the descending column sorts it ascending. The sort is emitted as `order_by: [{direction, key}]` (the `Aurora.Ctx.QueryBuilder` form; `PAR-3` translates it for Ash) and replaces the layout and metadata `order_by`.

##### Acceptance criteria
- [ ] AC-1: Given `SortableColumnsTest` (Ecto `Product`, metadata `order_by: :reference` with `field(:cost, sortable?: false)`, layout `index_columns(:product, [:reference, :name, :cost, description: [sortable?: false]])`), visiting `/sortable-columns-products`, then `reference` and `name` headers carry a sort button inside `th[aria-sort='none']`, and `cost`, `description` and the selection column carry none.
- [ ] AC-2: Given the three-product fixture (names `"Charlie"`, `"Alpha"`, `"Bravo"` in reference order), clicking the `name` sort button, then the name cells read `["Alpha", "Bravo", "Charlie"]` and the `name` header has `aria-sort='ascending'`; clicking it again, then they read `["Charlie", "Bravo", "Alpha"]` with `aria-sort='descending'`.
- [ ] AC-3: Given the same page with the filter bar open, `reference` filtered `ge` `"item_srt_2"` and submitted, then clicking the `name` sort button twice, the name cells read `["Bravo", "Alpha"]`.
- [ ] AC-4: Given `name` sorted ascending, pushing `"auix_route_back"`, then the name cells still read `["Alpha", "Bravo", "Charlie"]`.
- [ ] AC-5 (error path): Given the page, pushing `"index-sort"` with `"key"` `"cost"` (opted out), then with `"key"` `"not_a_column"`, then the name cells keep the reference order `["Charlie", "Alpha", "Bravo"]` and no header has `aria-sort='ascending'`.
- [ ] AC-6 to AC-8: the same on Ash — `AshSortableColumnsTest` (Ash `Author`, metadata `order_by: :email` with `field(:bio, sortable?: false)`, layout `index_columns(:author, [:name, :bio, email: [sortable?: false]])`, authors `"Charlie"`/`"author_1@test.com"`, `"Alpha"`/`"author_2@test.com"`, `"Bravo"`/`"author_3@test.com"`): AC-6 mirrors AC-1 (`name` sortable; `bio`, `email` and the selection column not), AC-7 mirrors AC-2, AC-8 mirrors AC-5 with key `"bio"`.

##### Test ports
- Route `"sortable-columns-products"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(SortableColumnsTest.Product, "sortable-columns-products")` · `:index` · observable: `has_element?/2` on `th[aria-sort='<none|ascending|descending>'] button[name='auix-sort-<key>']`; name cells `#auix-table-sortable-columns-products-index tr td:nth-of-type(3)`.
- Route `"ash-sortable-columns-authors"` via `RoutesHelper.register_crud(AshSortableColumnsTest.Author, "ash-sortable-columns-authors")` · `:index` · observable: the same button selectors; name cells `#auix-table-ash-sortable-columns-authors-index tr td:nth-of-type(2)`.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n "SortableColumns\|sortable-columns\|sortable_columns" test lib` returns nothing) | `prepare_sort_test(conn)` | test/cases_live/sortable_columns_test.exs | "sortable columns carry a sort button, opted-out columns do not" | `for key <- [:reference, :name], do: assert has_element?(view, "th[aria-sort='none'] button[name='auix-sort-#{key}']")`; `for key <- [:cost, :description, :selected_check__], do: refute has_element?(view, "button[name='auix-sort-#{key}']")` |
| AC-2 | add to the same file | `view = prepare_sort_test(conn)`; `click_sort(view, :name)` | same | "a header click sorts ascending, a second click descending" | `assert name_cells(view) == ["Alpha", "Bravo", "Charlie"]`; `assert has_element?(view, "th[aria-sort='ascending'] button[name='auix-sort-name']")`; `click_sort(view, :name)`; `assert name_cells(view) == ["Charlie", "Bravo", "Alpha"]`; `assert has_element?(view, "th[aria-sort='descending'] button[name='auix-sort-name']")` |
| AC-3 | add to the same file | `prepare_sort_test(conn)`; click `[name='auix-filter_toggle_open']`; `set_filter_change(view, :filter_condition, :reference, :ge)`; `set_filter_change(view, :filter_from, :reference, "item_srt_2")`; click `[name='auix-index-header-actions'] [name='auix-filters_submit-product']`; `click_sort(view, :name)` twice | same | "sorting keeps the submitted filters" | `assert name_cells(view) == ["Bravo", "Alpha"]` |
| AC-4 | add to the same file | `prepare_sort_test(conn)`; `click_sort(view, :name)`; `render_click(view, "auix_route_back", %{})` | same | "the sort survives auix_route_back" | `assert name_cells(view) == ["Alpha", "Bravo", "Charlie"]` |
| AC-5 | add to the same file | `prepare_sort_test(conn)`; `render_click(view, "index-sort", %{"key" => "cost"})`; `render_click(view, "index-sort", %{"key" => "not_a_column"})` | same | "an opted-out or unknown key leaves the order unchanged" | `assert name_cells(view) == ["Charlie", "Alpha", "Bravo"]`; `refute has_element?(view, "th[aria-sort='ascending']")` |
| AC-6 … AC-8 | new file (`rg -n "AshSortableColumns\|ash-sortable-columns\|ash_sortable_columns" test lib` returns nothing) | `prepare_sort_test(conn)` over the Ash fixture | test/cases_live/ash_sortable_columns_test.exs | the AC-1, AC-2 and AC-5 test names | as AC-1 (sortable `[:name]`; not `[:bio, :email, :selected_check__]`), AC-2, AC-5 (keys `"bio"`, `"not_a_column"`) |

Markup-change sweep (`rg -n "auix-column-label\|thead" test/`): `test/cases_live/create_ui_layout_test.exs` "Test index layout" reads the trimmed text of `thead tr th[name='auix-column-label']`; the `th` keeps its `name`, and its text stays the label (the icon `span` is empty), so the test is unchanged. `test/cases_live/manual_trees_test.exs`, `manual_layouts_test.exs` and `manual_ui_test.exs` refute `div[name='auix-column-label']`, a `div` this section does not create: unchanged.

##### Modules & components
1. `lib/aurora_uix/templates/basic/handlers/index_impl.ex`:
   1. `auix_mount/3` — insert `|> assign_auix(:sort, nil)` directly after `|> assign_auix(:filters_where, [])` (added by `UI-1`).
   2. `assign_index_fields/1` — replace `|> struct(%{label: select_toggle_function, filterable?: false})` with `|> struct(%{label: select_toggle_function, filterable?: false, sortable?: false})`.
   3. New `auix_handle_event/3` clause, placed directly after the `"filters-submit"` clause:
      ```elixir
      def auix_handle_event("index-sort", %{"key" => key}, %{assigns: %{auix: auix}} = socket) do
        case Enum.find(auix.index_fields, &(&1.sortable? and to_string(&1.key) == key)) do
          nil ->
            {:noreply, socket}

          %{key: field_key} ->
            {:noreply,
             socket
             |> assign_auix(:sort, next_sort(auix.sort, field_key))
             |> prepare_query_options()
             |> refresh_current_page()}
        end
      end
      ```
      The key is matched against the index fields, never turned into an atom.
   4. `prepare_query_options/1` (as left by `UI-1`) — bind `auix` in the head (`auix: %{load_items_options: load_items_options, filters_where: filters_where} = auix`) and replace `query_options = maybe_put_preload(base_options, Keyword.get(load_items_options, :preload))` with:
      ```elixir
      query_options =
        base_options
        |> maybe_put_preload(Keyword.get(load_items_options, :preload))
        |> maybe_put_sort(auix.sort)
      ```
   5. New private functions, placed directly after `maybe_put_preload/2`:
      ```elixir
      # A header sort replaces the layout and metadata order_by.
      @spec maybe_put_sort(keyword(), map() | nil) :: keyword()
      defp maybe_put_sort(query_options, nil), do: query_options

      defp maybe_put_sort(query_options, %{key: key, direction: direction}),
        do: Keyword.put(query_options, :order_by, [{direction, key}])

      @spec next_sort(map() | nil, atom()) :: map()
      defp next_sort(%{key: key, direction: :asc}, key), do: %{key: key, direction: :desc}
      defp next_sort(_sort, key), do: %{key: key, direction: :asc}
      ```
   6. `@moduledoc` `## Key Features` — replace `- Handles pagination, filtering, and item selection for large datasets` with `- Handles pagination, filtering, column-header sorting, and item selection for large datasets`.
2. `lib/aurora_uix/templates/basic/renderers/index_renderer.ex` `render/1` — in the `auix={%{…}}` map passed to `<.auix_items>`, add `sort: @auix.sort,` directly after `empty_list?: @auix.empty_list?,`. `@moduledoc` `## Key Features` — replace `- Table view with sortable columns` with `- Table view whose sortable column headers re-sort the rows`.
3. `lib/aurora_uix/templates/basic/components/components.ex` `auix_items_table/1` — replace the header `<th>` element
   ```heex
   <th :for={{col, i} <- Enum.with_index(@col)} 
       class={if i == 0, do: "auix-items-table-header-cell--first", else: "auix-items-table-header-cell"}
       name="auix-column-label"> 
     <.table_column_label auix={@auix} label={col.label} />
   </th>
   ```
   with
   ```heex
   <th :for={{col, i} <- Enum.with_index(@col)}
       class={if i == 0, do: "auix-items-table-header-cell--first", else: "auix-items-table-header-cell"}
       name="auix-column-label"
       aria-sort={column_aria_sort(@auix, col)}>
     <.table_column_sort :if={sortable_column?(col)} auix={@auix} col={col} />
     <.table_column_label :if={!sortable_column?(col)} auix={@auix} label={col.label} />
   </th>
   ```
   `column_aria_sort/2` returns `nil` for a column without a sort control, so HEEx omits the attribute.
4. Same file — new private component and helpers, placed directly after the last `table_column_label/1` clause:
   ```elixir
   # Renders a sortable column label as a button that emits "index-sort"
   attr(:auix, :map, required: true)
   attr(:col, :map, required: true)
   @spec table_column_sort(map()) :: Rendered.t()
   defp table_column_sort(%{auix: auix, col: %{field: field}} = assigns) do
     assigns = assign(assigns, :icon, auix |> column_sort_direction(field.key) |> sort_icon())

     ~H"""
     <button type="button" class="auix-items-table-header-sort" name={"auix-sort-#{@col.field.key}"}
       phx-click="index-sort" phx-value-key={@col.field.key}>
       <.table_column_label auix={@auix} label={@col.label} />
       <.icon name={@icon} class="auix-icon-size-4" />
     </button>
     """
   end

   @spec sortable_column?(map()) :: boolean()
   defp sortable_column?(%{field: %{sortable?: true}}), do: true
   defp sortable_column?(_col), do: false

   @spec column_aria_sort(map(), map()) :: binary() | nil
   defp column_aria_sort(auix, %{field: %{sortable?: true, key: key}}),
     do: auix |> column_sort_direction(key) |> aria_sort()

   defp column_aria_sort(_auix, _col), do: nil

   @spec column_sort_direction(map(), atom()) :: :asc | :desc | nil
   defp column_sort_direction(auix, key) do
     case Map.get(auix, :sort) do
       %{key: ^key, direction: direction} -> direction
       _sort -> nil
     end
   end

   @spec aria_sort(:asc | :desc | nil) :: binary()
   defp aria_sort(:asc), do: "ascending"
   defp aria_sort(:desc), do: "descending"
   defp aria_sort(nil), do: "none"

   @spec sort_icon(:asc | :desc | nil) :: binary()
   defp sort_icon(:asc), do: "hero-chevron-up"
   defp sort_icon(:desc), do: "hero-chevron-down"
   defp sort_icon(nil), do: "hero-chevron-up-down"
   ```
   `Map.get(auix, :sort)` is deliberate: `auix_items_table/1` also receives the one-to-many `auix` map, which has no `:sort`. The button is a raw `<button>`: `core_components.ex` `button/1` always adds `auix-button-default`, which paints a filled button. The three icon names are literals so `mix auix.gen.tailwind_classes` finds them; `deps/heroicons/optimized/24/outline/` holds `chevron-up.svg`, `chevron-down.svg` and `chevron-up-down.svg`.
5. Same file, `@doc` of `auix_items_table/1` — append the paragraph: `A \`:col\` whose \`field\` has \`sortable?: true\` renders its label as a button that emits \`"index-sort"\` with the field key; the header carries \`aria-sort\` from \`auix.sort\`.`
6. Theme: `lib/aurora_uix/templates/basic/themes/base.ex` — new clause placed directly after `def rule(:auix_items_table_header_cell__first) do`'s clause:
   ```elixir
   def rule(:auix_items_table_header_sort) do
     """
     .auix-items-table-header-sort {
       display: inline-flex;
       align-items: center;
       gap: var(--auix-gap-minimal);
       padding: 0;
       border: 0;
       background: transparent;
       color: inherit;
       font: inherit;
       cursor: pointer;
     }
     """
   end
   ```
   The icon reuses the existing `rule(:auix_icon_size_4)` class `auix-icon-size-4`. Run `mix auix.gen.tailwind_classes` (it rewrites `priv/static/classes.js` with the three new `hero-chevron-*` names; commit it) and `mix auix.gen.stylesheet` (its `assets/css/auix-*.css` output is gitignored).
7. `lib/aurora_uix/layout/resource_metadata.ex` `field/2` `@doc` `## Options` — insert directly after the `:filterable?` bullet: `  - \`:sortable?\` (\`boolean()\`) - If false, the index column header offers no sorting. Parsed from the column type when omitted.`
8. `test/support/app_web/routes.ex` `load_test_routes/0` — append, inside the same `quote`, directly after the last `RoutesHelper.register_crud/2` call added by `UI-2` (`AshWhereMany2OneTest.Post`, `"ash-where-many_to_one-posts"`), the two registrations listed under Test ports.
9. `Aurora.UixWeb.Test.SortableColumnsTest` at `test/cases_live/sortable_columns_test.exs` — new:
   1. `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `alias Aurora.Uix.Guides.Inventory`, `alias Aurora.Uix.Guides.Inventory.Product`, `alias Phoenix.LiveViewTest.View`.
   2. Metadata: `auix_resource_metadata :product, context: Inventory, schema: Product, order_by: :reference do field(:cost, sortable?: false) end`.
   3. Layout: `auix_create_ui do index_columns(:product, [:reference, :name, :cost, description: [sortable?: false]]) end`. Index columns: selection, `reference`, `name`, `cost`, `description`; `td:nth-of-type(3)` is `name`. The layout option reaches the `%Field{}` through `create_ui.ex` `fold_field_opts_into_config/1` and `helpers.ex` `get_field/3` (`Field.change(Map.get(field, :config, []))`).
   4. `@spec prepare_sort_test(Plug.Conn.t()) :: View.t()` private: `delete_all_inventory_data()`; `create_sample_products(1, :srt_1, %{name: "Charlie"})`; `create_sample_products(1, :srt_2, %{name: "Alpha"})`; `create_sample_products(1, :srt_3, %{name: "Bravo"})`; `{:ok, view, _html} = live(conn, "/sortable-columns-products")`; return `view`. References are `"item_srt_1-1"`, `"item_srt_2-1"`, `"item_srt_3-1"`.
   5. `@spec click_sort(View.t(), atom()) :: View.t()` private: `view |> element("button[name='auix-sort-#{key}']") |> render_click()`; return `view`.
   6. `@spec name_cells(View.t()) :: list(binary())` private: the `LazyHTML` query of `#auix-table-sortable-columns-products-index tr td:nth-of-type(3)`, texts trimmed.
   7. `set_filter_change/4` — copy verbatim from `test/cases_live/special_fields_ui_test.exs`.
10. `Aurora.UixWeb.Test.AshSortableColumnsTest` at `test/cases_live/ash_sortable_columns_test.exs` — new. Same shape as item 9, with: `alias Aurora.Uix.Guides.Blog.Author`; metadata `auix_resource_metadata :author, ash_resource: Author, order_by: :email do field(:bio, sortable?: false) end`; layout `index_columns(:author, [:name, :bio, email: [sortable?: false]])`; `prepare_sort_test/1` runs `delete_all_blog_data()` and `create_sample_authors(1, %{name: name, email: email})` for `{"Charlie", "author_1@test.com"}`, `{"Alpha", "author_2@test.com"}`, `{"Bravo", "author_3@test.com"}`, then visits `/ash-sortable-columns-authors`; `name_cells/1` queries `#auix-table-ash-sortable-columns-authors-index tr td:nth-of-type(2)`.
11. `dt/1` strings: none new; `aria-sort` values are not user-visible text.
12. Standing rules touched: the handler and components consume `%Field{}.sortable?` only; no backend struct appears. No inline utility class: the only classes are `auix-items-table-header-sort` (new rule) and `auix-icon-size-4` (existing rule). Icons through `<.icon>`. Streams unchanged (`refresh_current_page/1` resets the stream). No LiveComponent.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->

---

### Out of Scope
- A ctx Parser section for `order_by` / single-tuple `where`: `Aurora.Ctx.QueryBuilder` `option/2` already accepts every form `PAR-3` adds to Ash. The ctx `:in` support (list-only) is wadvanced/aurora_ctx#42, a prerequisite of `UI-1`, not code in this repository.
- A comma-separated string as an `:in` value, on either backend: `PAR-3` deletes the Ash split, `aurora_ctx` 0.1.11 never has one, and the filter bar's "in list" text is split once, in the handler (`UI-1`).
- `dynamic/2` `where` expressions on Ash: they are an Ecto construct; `DOC-1` documents them as Ecto-only.
- Index query options `:or_where` and `:select`: `IndexImpl` lists them in `@allowed_query_options`, yet `prepare_query_options/1` forwards only `:order_by`, `:where` and `:preload`, so a layout or metadata `or_where` / `select` never reaches either backend. Tracked in wadvanced/aurora_uix#374.
- Sort control for the mobile card list: the index card view (`auix_items_card/1`) has no header row, so `UI-3`'s sort control is desktop-only. Tracked in wadvanced/aurora_uix#375, which depends on `UI-3` of this issue.
<!-- enriched-spec:end -->
