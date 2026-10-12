<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview

Replace the hand-rolled DSL front end in `lib/aurora_uix/layout/` with a Spark `Dsl.Extension`, keeping `%Aurora.Uix.TreePath{}`, `%Aurora.Uix.Resource{}` and `%Aurora.Uix.Field{}` as the intermediate representation so that nothing under `templates/`, `integration/` or the generators/handlers changes. Target release: **0.2** (breaking). This issue is delivered as one orchestrated run; the steps below are the order the work lands in, each one green on `mix consistency` + `mix test` and independently mergeable.

Three structural weaknesses of the current DSL, verified in code:

1. **No validation.** Unknown layout options are stored verbatim on `%TreePath{opts: …}` and ignored; unknown field options are dropped by `struct/2` in `ResourceMetadata.apply_field_change/2` (`resource_metadata.ex:442-446`); unknown runtime options surface only as `Logger.warning` (`options.ex:277`). The only real checks are `BehaviourHelper.validate(@auix_template, Template)` (`create_ui.ex:220`) and the `raise` in `Helpers.get_fields_parser_module/1` (`helpers.ex:197-201`).
2. **Documentation drifts.** Option tables in `guides/core/layouts.md` and `guides/core/resource_metadata.md` are hand-written, while the accepted set is discovered by introspecting `get_default/2` clause heads with `Module.get_definition/2` (`options.ex:107-113`).
3. **Non-deterministic ids.** `Blueprint.unique_titled_id/1` (`blueprint.ex:699-711`) mixes an md5 of `:os.system_time(:millisecond)` with `:erlang.unique_integer/1` into `group_id`, `sections_id` and `tab_id`. `AGENTS.md` already forbids asserting on `auix-field-*` ids because of it.

Spark gives typed `Spark.Options` schemas with file/line compile errors, generated cheat sheets, a production-proven recursive entity builder, transformers/verifiers as the home for the defaults/numbering/merge logic now spread across `Blueprint` and `CreateUI`, plus `Spark.Dsl.Fragment` and `Spark.Dsl.Patch.AddEntity`.

**Dependency cost: none.** `{:ash, "~> 3.34"}` (`mix.exs:230`) is a hard dep and already pins `spark 2.7.6` in `mix.lock`.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.2.0], guides/core/layouts.md, guides/core/resource_metadata.md, guides/whats_new/0.2.md, documentation/dsls/DSL-Aurora.Uix.md, AGENTS.md | none | federico/318-doc-1-spark-dsl-migration | docs: spark DSL migration (0.2) (#318 · DOC-1) |
| SCH-1 | Schema | lib/aurora_uix/dsl/entities/ and lib/aurora_uix/dsl/schemas/ | DOC-1 | federico/318-sch-1-dsl-entities | feat: spark DSL entity structs and schemas (#318 · SCH-1) |
| UI-1 | UI | lib/aurora_uix/uix.ex, lib/aurora_uix/layout/ → lib/aurora_uix/dsl/ transformers, auix_configurations contract | DOC-1, SCH-1 | federico/318-ui-1-spark-switch | feat: switch use Aurora.Uix to use Spark.Dsl (#318 · UI-1) |
| UI-2 | UI | lib/aurora_uix/dsl/transformers/ (parse_resources, lower_layout_tree, assign_node_ids, number_sections, merge_layout_trees, build_configurations) | DOC-1, SCH-1, UI-1 | federico/318-ui-2-transformers | feat: layout tree transformers for Spark DSL (#318 · UI-2) |

A section starts only when every dependency is **merged**. Independent sections may run in parallel. Status is derived from GitHub, never recorded here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation

Depends on: none

#### Documentation references

- `CHANGELOG.md` § `## [0.2.0] - Unreleased` › `### Added`
- `guides/core/layouts.md` § Layout Options by Type, § Field-Level Options
- `guides/core/resource_metadata.md` § Field Properties, § Per-layout renderers, § Query Options for Many-to-One
- `guides/whats_new/0.2.md` — new release notes file, new (verified by `ls guides/whats_new/0.2.md` returning nothing on main)
- `documentation/dsls/DSL-Aurora.Uix.md` — committed placeholder file, new (verified by `ls documentation/dsls/DSL-Aurora.Uix.md` returning nothing on main)
- `AGENTS.md` § Architecture, § Glossary

#### Implementation details

##### AGENTS.md

1. § Architecture — in the `lib/` tree, replace the `layout/` line with the `dsl/` tree lines below, keeping indentation style used by sibling lines:

   ```
     dsl/                  # Spark DSL extension, entities, schemas, transformers, verifiers
   ```

2. § Glossary — replace the **Layout tree** row text with the text below, keeping the table pipe format used by sibling rows:

   ```
   | **Layout tree** | The declarative `%TreePath{}` structure produced by the Spark DSL entities plus transformers, describing what renders where for a given `layout_type`. |
   ```

3. § Glossary — keep the **Resource** row plus the **Field** row unchanged.

##### CHANGELOG.md

1. § `## [0.2.0] - Unreleased` › `### Added` — insert verbatim as the first entry under the heading, followed by one blank line:

   ```
   - **Spark DSL migration to 0.2**
     - Replaced hand-rolled DSL in `lib/aurora_uix/layout/` with Spark `Dsl.Extension`
     - `%TreePath{}`, `%Resource{}`, `%Field{}` remain the intermediate representation
     - Unknown DSL options now fail at compile time with `Spark.Error.DslError`
     - `group_id` / `sections_id` / `tab_id` / `html_id` become deterministic
     - Layout macros importable at module top level; misuse raises verifier error
     - Function-valued options must be named captures (`&Mod.fun/1`)
     - `use Aurora.Uix` gains Spark's reserved options and attributes
     - `auix_create_layout` removed
     - Metadata-level and layout-level `field` share one schema
   ```

##### documentation/dsls/DSL-Aurora.Uix.md

1. Create directory `documentation/dsls/` when missing. Create file `documentation/dsls/DSL-Aurora.Uix.md` with the exact bytes below:

   ```
   # Aurora.Uix DSL — cheat sheet placeholder

   This file becomes the generated cheat sheet from `mix spark.cheat_sheets`
   when the Spark DSL extension lands in SCH-1 plus UI-1.

   Until that generation lands, see `guides/core/layouts.md`
   § Layout Options by Type plus § Field-Level Options,
   plus `guides/core/resource_metadata.md` § Field Properties,
   § Per-layout renderers, § Query Options for Many-to-One.
   ```

##### guides/core/layouts.md

1. § Index Layout Options — delete the `**Options:**` line plus the consecutive `- \`...\`` bullet lines directly below it, stopping at the blank line ahead of § Form Layout Options. Keep the heading, the introductory sentence, the code example. Insert in place of the deleted block the single line below:

   ```
   For the complete typed option reference, see [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md).
   ```

2. § Form Layout Options — delete the `**Options:**` line plus the consecutive bullet lines directly below it, stopping at the blank line ahead of § Show Layout Options. Keep the heading, the introductory sentence, the code example. Insert in place of the deleted block the single line below:

   ```
   For the complete typed option reference, see [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md).
   ```

3. § Show Layout Options — delete the `**Options:**` line plus the consecutive bullet lines directly below it, stopping at the blank line ahead of § Dynamic Titles & Subtitles. Keep the heading, the introductory sentence, the code example. Insert in place of the deleted block the single line below:

   ```
   For the complete typed option reference, see [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md).
   ```

4. § Field-Level Options — delete the `**Relevant Field Options:**` line plus the consecutive bullet lines directly below it, stopping at the blank line ahead of the next heading. Keep the heading, the introductory sentence, the code example. Insert in place of the deleted block the single line below:

   ```
   For the complete typed field option reference, see [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md).
   ```

5. Keep § Field Options, § Dynamic Titles & Subtitles, all code examples outside the deleted blocks, all narrative paragraphs outside the deleted blocks, unchanged.

##### guides/core/resource_metadata.md

1. § Field Properties — keep all subsection bullet lists verbatim. Insert directly below the introductory sentence beginning `Each field in the resource metadata` the single line below:

   ```
   For the DSL option reference, see [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md).
   ```

2. § Query Options for Many-to-One — delete the two bullet lines naming `:order_by` plus `:where` directly below the sentence beginning `When \`option_label\``, keeping the heading, all prose paragraphs, all code examples. Insert in place of the deleted lines the single line below:

   ```
   For the complete typed query option reference, see [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md).
   ```

3. § Per-layout renderers — keep the heading, all prose paragraphs, the code example, the precedence list verbatim. Insert directly below the first paragraph ending `returns a \`Phoenix.LiveView.Rendered.t()\`` the single line below:

   ```
   For the complete typed renderer option reference, see [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md).
   ```

##### guides/whats_new/0.2.md

1. Create file `guides/whats_new/0.2.md` with the exact bytes below:

   ```
   # What's new in 0.2 — Spark DSL migration

   ## Breaking changes

   - Unknown DSL options fail at compile time with a `Spark.Error.DslError`.
   - `group_id` / `sections_id` / `tab_id` / `html_id` become deterministic.
   - Layout macros are importable at module top level; misuse raises a verifier error instead of `undefined function`.
   - Function-valued options must be named captures (`&Mod.fun/1`).
   - `use Aurora.Uix` gains Spark reserved options plus attributes.
   - `auix_create_layout` is removed; rewrite call sites against `auix_create_ui`.
   - Metadata-level plus layout-level `field` share one schema.

   ## Migration path

   - Replace unknown option keys with keys named in the cheat sheet.
   - Update CSS plus test selectors matching the old deterministic id shape to the new `auix-group-<slug>-<n>` shape.
   - Replace anonymous function literals in DSL options with named captures.
   - Replace `auix_create_layout` blocks with `auix_create_ui` blocks.
   - See [DSL cheat sheet](../../documentation/dsls/DSL-Aurora.Uix.md) plus `guides/core/layouts.md` § Layout Options by Type.
   ```

#### Acceptance criteria

- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no issue-link suffix (mechanical — no red test; verified by `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file (its AC ticks) (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `guides/core/layouts.md`, `guides/core/resource_metadata.md`, `guides/whats_new/0.2.md`, `documentation/dsls/DSL-Aurora.Uix.md`, `AGENTS.md` and `specs/issue-318-enriched-spec.md`)
- [x] AC-3: `CHANGELOG.md` § `## [0.2.0] - Unreleased` › `### Added` carries the verbatim entry (mechanical — no red test; verified by `grep -nE 'Spark DSL migration' CHANGELOG.md` returning one line)
- [x] AC-4: `guides/core/layouts.md` option lists replaced by cheat-sheet link (mechanical — no red test; verified by `grep -n 'cheat_sheet\|DSL-Aurora.Uix' guides/core/layouts.md` returning a non-empty result)
- [x] AC-5: `guides/core/resource_metadata.md` option lists replaced by cheat-sheet link (mechanical — no red test; verified by `grep -n 'cheat_sheet\|DSL-Aurora.Uix' guides/core/resource_metadata.md` returning a non-empty result)
- [x] AC-6: `guides/whats_new/0.2.md` exists and covers the accepted breaks (mechanical — no red test; verified by `ls guides/whats_new/0.2.md` returning a file)
- [x] AC-7: `documentation/dsls/DSL-Aurora.Uix.md` exists as a committed placeholder pending generation when the Spark DSL extension lands (mechanical — no red test; verified by `ls documentation/dsls/DSL-Aurora.Uix.md` returning a file)
- [x] AC-8: `AGENTS.md` architecture tree names `dsl/` (mechanical — no red test; verified by `grep -n 'dsl/' AGENTS.md` returning a non-empty result)

##### Green checks

1. `mix consistency` clean
2. `mix test` — full suite green (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:SCH-1:start -->
### SCH-1 — Schema

Depends on: DOC-1

#### Documentation references

- `lib/aurora_uix/dsl/entities/resource_metadata.ex` — new entity struct
- `lib/aurora_uix/dsl/entities/field.ex` — new entity struct
- `lib/aurora_uix/dsl/entities/fields.ex` — new entity struct
- `lib/aurora_uix/dsl/schemas/field_options.ex` — new shared field schema
- `lib/aurora_uix/dsl/schemas/index_options.ex` — new index schema
- `lib/aurora_uix/dsl/schemas/form_options.ex` — new form schema
- `lib/aurora_uix/dsl/schemas/show_options.ex` — new show schema
- `lib/aurora_uix/dsl/schemas/action_options.ex` — new action schema

#### Implementation details

Entity files follow the Reactor precedent (`deps/ash/lib/ash/reactor/dsl/actor.ex`): each file defines one target struct module carrying `__spark_metadata__: nil` (required for `Spark.Dsl.Entity.anno/1`, `deps/spark/lib/spark/dsl/entity.ex`), an `@type t` naming `Spark.Dsl.Entity.spark_meta/0` for that key, plus `@doc false` `__entity__/0` returning the `%Spark.Dsl.Entity{}` declaration consumed by the UI-1 extension. Schema files follow the Ash precedent (`Ash.Resource.Attribute.integer_primary_key_schema/0`, `deps/ash/lib/ash/resource/dsl.ex`): each file defines one module exposing `schema/0` returning a `Spark.Options` keyword schema. Spark option types used below come from the `deps/spark/lib/spark/options/options.ex` vocabulary (`:atom`, `:string`, `:boolean`, `:integer`, `:non_neg_integer`, `:map`, `:module`, `:keyword_list`, `{:or, [...]}`, `{:in, ...}`, `{:list, ...}`, `{:tuple, ...}`, `{:fun, ...}`, `{:map, ...}`).

1. Create `lib/aurora_uix/dsl/entities/resource_metadata.ex` defining `Aurora.Uix.Dsl.Entity.ResourceMetadata` (new; `grep -rn 'Dsl.Entity' lib/ --include='*.ex'` returns nothing). Defstruct keys: `name`, `schema`, `context`, `ash_resource`, `ash_actor_assign`, `actor_assign`, `type`, `order_by`, `renderers`, `__spark_metadata__`. `__entity__/0` returns `%Spark.Dsl.Entity{}` with name `:resource_metadata`, `args: [:name]`, `identifier: :name`, `target: __MODULE__`, and schema keys: `name` (`:atom`, required `true`); `schema` (`:module`, required `false`, the Ecto schema module read by `define_schema_and_type/1`, `lib/aurora_uix/layout/resource_metadata.ex`); `context` (`:module`, required `false`); `ash_resource` (`:module`, required `false`); `ash_actor_assign` (`:atom`, required `false`); `actor_assign` (`:atom`, required `false`, alias honoured by first-wins lookup of `[:ash_actor_assign, :actor_assign]` in `get_actor_assign/1`, `lib/aurora_uix/integration/ash/context_parser_defaults.ex`); `type` (`{:in, [:ash, :ctx]}`, required `false`, absent keeps the `resource_type/1` sniffing in `lib/aurora_uix/layout/resource_metadata.ex`); `order_by` (`{:or, [:atom, :keyword_list, {:list, :atom}]}`, required `false`, the three shapes in the `auix_resource_metadata/3` docs, `lib/aurora_uix/layout/resource_metadata.ex`); `renderers` (`{:map, :atom, {:or, [:atom, {:fun, 1}}]}`, required `false`, the `html_type => renderer` table in the `auix_resource_metadata/3` docs).
2. Create `lib/aurora_uix/dsl/entities/field.ex` defining `Aurora.Uix.Dsl.Entity.Field` (new; same empty search as step 1). Defstruct keys: every key of `Aurora.Uix.Dsl.Schema.FieldOptions.schema/0` (step 4) plus `__spark_metadata__`. `__entity__/0` returns `%Spark.Dsl.Entity{}` with name `:field`, `args: [:key]`, `identifier: :key`, `target: __MODULE__`, `schema: Aurora.Uix.Dsl.Schema.FieldOptions.schema/0`. Metadata-level `field` plus layout-level `field` share this one schema.
3. Create `lib/aurora_uix/dsl/entities/fields.ex` defining `Aurora.Uix.Dsl.Entity.Fields` (new; same empty search as step 1). Defstruct keys: `keys`, `opts`, `__spark_metadata__`. `__entity__/0` returns `%Spark.Dsl.Entity{}` with name `:fields`, `args: [:keys]`, `target: __MODULE__`, `transform: {__MODULE__, :validate_keys, []}`, schema keys: `keys` (`{:list, :atom}`, required `true`); `opts` (`:keyword_list`, required `false`, default `[]`). `validate_keys/1` returns `{:ok, struct}` for a non-empty atom list, `{:error, message}` otherwise. Expansion of one `fields` entity into N `field` entities in `keys` order happens in the UI-2 lowering transformer.
4. Create `lib/aurora_uix/dsl/schemas/field_options.ex` defining `Aurora.Uix.Dsl.Schema.FieldOptions` (new; `grep -rn 'Dsl.Schema' lib/ --include='*.ex'` returns nothing) with `schema/0` returning exactly these keys, every key required `false`: `key` (`:atom`); `type` (`:atom`); `label` (`:string`); `placeholder` (`:string`); `length` (`:non_neg_integer`); `precision` (`:non_neg_integer`); `scale` (`:non_neg_integer`); `readonly` (`:boolean`); `hidden` (`:boolean`); `required` (`:boolean`); `disabled` (`:boolean`); `omitted` (`:boolean`); `filterable?` (`:boolean`); `sortable?` (`:boolean`); `renderer` (`{:or, [:atom, {:fun, 1}]}`, arity-1 function plus predefined atom per the `field/2` docs, `lib/aurora_uix/layout/resource_metadata.ex`); `index_renderer` (same type); `edit_renderer` (same type); `show_renderer` (same type); `expanded` (`{:or, [:boolean, {:fun, 1}]}`, boolean plus arity-1 capture per the `field/2` docs); `option_label` (`{:or, [:atom, {:fun, 1}, {:fun, 2}]}`, atom plus arity-1 and arity-2 functions per the many-to-one docs, `lib/aurora_uix/layout/blueprint.ex`, exercised in `index_value/1`, `lib/aurora_uix/templates/basic/renderers/default_renderer.ex`); `order_by` (`{:or, [:atom, :keyword_list, {:list, :atom}]}`, same three shapes as step 1); `where` (`:keyword_list`, the keyword clauses in the `index_columns/3` docs, `lib/aurora_uix/layout/blueprint.ex`). Field struct defaults (`lib/aurora_uix/field.ex` defstruct) stay the defaults; this schema only validates input.
5. Create `lib/aurora_uix/dsl/schemas/index_options.ex` defining `Aurora.Uix.Dsl.Schema.IndexOptions` (new; same empty search as step 4) with `schema/0` returning exactly these keys, every key required `false`: `pagination_disabled?` (`{:or, [:boolean, {:fun, 1}]}`, per the `:index` options docs, `lib/aurora_uix/layout/options/index.ex`); `sort_disabled?` (same type, same source); `pagination_items_per_page` (`:non_neg_integer`, default `40` in `get_default/2`, `lib/aurora_uix/layout/options/index.ex`); `pages_bar_range_offset` (`{:or, [:non_neg_integer, {:fun, 2}]}`, integer attr in `lib/aurora_uix/templates/basic/components/components.ex`, arity-2 default `&page_bar_range_offset/2` invoked as `.fun.(nil, media)` in `lib/aurora_uix/templates/basic/actions/index.ex`); `get_streams` (`{:fun, 1}`, invoked as `.fun.(assigns)` in `lib/aurora_uix/templates/basic/renderers/index_renderer.ex`); `row_id` (`{:fun, 1}`, invoked as `.fun.(row)` in `lib/aurora_uix/templates/basic/components/components.ex`); `infinite_scroll_items_load` (`:non_neg_integer`, default `200` in `get_default/2`); `alternate_streams_suffixes` (`{:list, :string}`, default `["mobile"]` in `get_default/2`); `page_title` (`{:or, [:string, {:fun, 1}]}`, per the `:index` options docs); `page_subtitle` (same type, same source); `new_action_label` (`{:or, [:string, {:fun, 0}]}`, binary plus 0-arity function via `parse_value/1`, `lib/aurora_uix/layout/options.ex`); `order_by` (same type as step 1, layout value beats metadata per the `index_columns/3` docs); `where` (`:keyword_list`, same source); `handler_module` (`:module`, read by `handler_module/2`, `lib/aurora_uix/templates/basic/modules_generator.ex`); `renderers` (`{:map, :atom, {:or, [:atom, {:fun, 1}}]}`, the index table in the `index_columns/3` docs).
6. Create `lib/aurora_uix/dsl/schemas/form_options.ex` defining `Aurora.Uix.Dsl.Schema.FormOptions` (new; same empty search as step 4) with `schema/0` returning exactly these keys, every key required `false`: `edit_title` (`{:or, [:string, {:fun, 1}]}`, per the `:form` options docs, `lib/aurora_uix/layout/options/form.ex`); `edit_subtitle` (same type, same source); `new_title` (same type, same source); `new_subtitle` (same type, same source); `save_action_label` (`{:or, [:string, {:fun, 0}]}`, same source); `record_navigator` (`{:or, [{:in, [:top, :bottom]}, {:list, {:in, [:top, :bottom]}}]}`, atom plus atom list per the `:form` options docs); `unsaved_changes_guard_disabled?` (`:boolean`, same source); `edit_handler_module` (`:module`, read by `handler_module/2`, `lib/aurora_uix/templates/basic/modules_generator.ex`); `renderers` (same type as step 5, the form table in `lib/aurora_uix/layout/blueprint.ex`).
7. Create `lib/aurora_uix/dsl/schemas/show_options.ex` defining `Aurora.Uix.Dsl.Schema.ShowOptions` (new; same empty search as step 4) with `schema/0` returning exactly these keys, every key required `false`: `page_title` (`{:or, [:string, {:fun, 1}]}`, per the `:show` options docs, `lib/aurora_uix/layout/options/show.ex`); `page_subtitle` (same type, same source); `edit_action_label` (`{:or, [:string, {:fun, 0}]}`, same source); `back_action_label` (same type, same source); `record_navigator` (same type as step 6, same source); `show_handler_module` (`:module`, read by `handler_module/2`, `lib/aurora_uix/templates/basic/modules_generator.ex`); `renderers` (same type as step 5, the show table in `lib/aurora_uix/layout/blueprint.ex`).
8. Create `lib/aurora_uix/dsl/schemas/action_options.ex` defining `Aurora.Uix.Dsl.Schema.ActionOptions` (new; same empty search as step 4) with `schema/0` derived at compile time from `Action.action_option_names/0` (`lib/aurora_uix/action.ex`, compile-time capture precedent: `@field_action_names Action.action_option_names()`, `lib/aurora_uix/layout/helpers.ex`): each name with an `add_`/`insert_`/`replace_` prefix maps to `{:tuple, [:atom, {:fun, 1}]}` (the `{name, &fun/1}` shape in the `index_columns/3` Actions docs, `lib/aurora_uix/layout/blueprint.ex`); each name with a `remove_` prefix maps to `:atom` (the bare-name shape in the same docs); every key required `false`.
9. Leave `lib/aurora_uix/layout/resource_metadata.ex` unmodified in this section. `auix_resources/0`, `auix_resource/1` plus the `@auix_resource_metadata` composition keep working through the current `__before_compile__/1`; `resource_type/1` keeps sniffing `{:__spark_placeholder__, 0}` on the schema module. The macro-layer deletion plus the Spark caller move belong to UI-1. Backend parsers in `lib/aurora_uix/integration/ash/` plus `lib/aurora_uix/integration/ctx/` stay untouched. New files reference no `Ecto.Association.*`, `Ecto.Embedded`, `Ash.Resource.*` modules; everything downstream keeps consuming `%Field{}` atoms.

##### Red tests

| AC | Placement | Setup | Assertion sketch |
|---|---|---|---|
| AC-4, AC-5, AC-6, AC-7, AC-8 | new file `test/cases/dsl_schemas_test.exs` (`grep -rln 'Dsl.Schema' test/` returns nothing) | no DB; call each `schema/0` directly | `FieldOptions.schema/0` carries exactly the 22 keys of step 4 with the prescribed types; `IndexOptions`/`FormOptions`/`ShowOptions` carry exactly the keys of steps 5–7; `ActionOptions.schema/0` carries every member of `Action.action_option_names/0` with tuple type for `add_`/`insert_`/`replace_` prefixes plus atom type for `remove_` prefix |
| AC-3 | new file `test/cases/dsl_entities_test.exs` (`grep -rln 'Dsl.Entity' test/` returns nothing) | no DB; build the structs directly | `%ResourceMetadata{}`, `%Field{}`, `%Fields{}` carry the prescribed fields plus `__spark_metadata__`; each `__entity__/0` returns `%Spark.Dsl.Entity{}` with the prescribed name, args plus target; `Fields.validate_keys/1` returns `{:ok, _}` for `[:a, :b]` plus `{:error, _}` for `[]` |

Assertion API: plain `assert` on keyword schemas plus struct maps (parser-output layer, no DB, no mocks).

#### Acceptance criteria

- [x] AC-1: `lib/aurora_uix/dsl/entities/resource_metadata.ex` compiles with `--warnings-as-errors` and defines `Aurora.Uix.Dsl.Entity.ResourceMetadata` with `__entity__/0` naming `:resource_metadata`, args `[:name]` (mechanical — no red test; verified by `mix compile --warnings-as-errors` clean plus `mix run -e 'IO.inspect(Aurora.Uix.Dsl.Entity.ResourceMetadata.__entity__().name)'` printing `:resource_metadata`)
- [x] AC-2: `lib/aurora_uix/dsl/entities/field.ex` compiles with `--warnings-as-errors` and defines `Aurora.Uix.Dsl.Entity.Field` with `__entity__/0` naming `:field`, args `[:key]`, schema `FieldOptions.schema/0` (mechanical — no red test; verified by `mix compile --warnings-as-errors` clean plus the same `mix run -e` inspection printing `:field`)
- [x] AC-3: `lib/aurora_uix/dsl/entities/fields.ex` compiles and defines `Aurora.Uix.Dsl.Entity.Fields` with `validate_keys/1` plus struct expansion input for the UI-2 lowering transformer
- [x] AC-4: `lib/aurora_uix/dsl/schemas/field_options.ex` compiles and defines `Aurora.Uix.Dsl.Schema.FieldOptions` with `schema/0` carrying exactly the 22 keys of step 4
- [x] AC-5: `lib/aurora_uix/dsl/schemas/index_options.ex` compiles and defines `Aurora.Uix.Dsl.Schema.IndexOptions` with `schema/0` carrying exactly the keys of step 5
- [x] AC-6: `lib/aurora_uix/dsl/schemas/form_options.ex` compiles and defines `Aurora.Uix.Dsl.Schema.FormOptions` with `schema/0` carrying exactly the keys of step 6
- [x] AC-7: `lib/aurora_uix/dsl/schemas/show_options.ex` compiles and defines `Aurora.Uix.Dsl.Schema.ShowOptions` with `schema/0` carrying exactly the keys of step 7
- [x] AC-8: `lib/aurora_uix/dsl/schemas/action_options.ex` compiles and defines `Aurora.Uix.Dsl.Schema.ActionOptions` with `schema/0` derived from `Action.action_option_names/0` with tuple type for `add_`/`insert_`/`replace_` prefixes plus atom type for `remove_` prefix
- [x] AC-9: `lib/aurora_uix/layout/resource_metadata.ex` unmodified; `auix_resources/0` and `auix_resource/1` keep working (mechanical — no red test; verified by `git diff --name-only origin/main...HEAD` excluding `lib/aurora_uix/layout/` plus `mix test test/cases/metadata_modifying_fields_test.exs` green)
- [x] AC-10: `resource_type/1` (`resource_metadata.ex:608-619`) unmodified, still sniffs `{:__spark_placeholder__, 0}` on the schema module (mechanical — no red test; verified by `grep -n '__spark_placeholder__' lib/aurora_uix/layout/resource_metadata.ex` returning the sniffing clause plus `mix test test/cases/metadata_modifying_fields_test.exs` green)

##### Green checks

1. `mix compile --warnings-as-errors` clean for all new files
2. `mix test test/cases/dsl_schemas_test.exs test/cases/dsl_entities_test.exs test/cases/metadata_modifying_fields_test.exs` green
3. `mix test` — parser test suites (both backends) green
<!-- section:SCH-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI

Depends on: DOC-1, SCH-1

#### Documentation references

- `lib/aurora_uix/uix.ex` — `__using__/1` module attribute change
- `guides/core/layouts.md` — updated option tables (DOC-1)

#### Implementation details

1. **`lib/aurora_uix/uix.ex` (`Aurora.Uix.__using__/1`)**: replace the current macro-based DSL setup with:

   ```elixir
   use Spark.Dsl, default_extensions: [extensions: [Aurora.Uix.Dsl]]
   ```

   This switches the module to Spark's DSL system while keeping the `Aurora.Uix.Dsl` extension loaded. The generated module keeps emitting `auix_resources/0`, `auix_resource/1` (`resource_metadata.ex:111,352`), `auix_layout_trees/0`, `auix_configurations/0`, `auix_preloads/0` (`create_ui.ex:73-88`), so tests and the documented `@auix_resource_metadata Mod.auix_resource(:name)` composition (`guides/advanced/advanced_usage.md:265-296`) keep working.

2. **`auix_configurations/0` contract**: the map handed to `template.generate_module/1` (`create_ui.ex:327-335`) must stay structurally identical except where a step below declares an intentional change. Add a compile-time test verifying the map's shape is preserved.

3. **`use Spark.Dsl, default_extensions: [extensions: [Aurora.Uix.Dsl]]`** ensures that `auix_resource_metadata … do … end` and `auix_create_ui do … end` remain callable at the top of a view module (no wrapper block), thanks to Spark's `top_level?: true` mechanic (`spark/dsl/extension.ex`).

#### Acceptance criteria

- [ ] AC-1: `lib/aurora_uix/uix.ex` compiles with `--warnings-as-errors` and uses `use Spark.Dsl, default_extensions: [extensions: [Aurora.Uix.Dsl]]`
- [ ] AC-2: The generated module still emits `auix_resources/0`, `auix_resource/1`, `auix_layout_trees/0`, `auix_configurations/0`, `auix_preloads/0` with the correct shapes
- [ ] AC-3: `auix_resource_metadata :product, context: MyApp.Accounts, schema: MyApp.Accounts.Product do … end` still calls correctly at module top level
- [ ] AC-4: `auix_create_ui do … end` still calls correctly at module top level
- [ ] AC-5: The compile-time test for `auix_configurations/0` map shape passes

##### Green checks

1. `mix compile --warnings-as-errors` clean
2. `mix test` — full suite green (review-issue runs the suite)
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI

Depends on: DOC-1, SCH-1, UI-1

#### Documentation references

- `lib/aurora_uix/dsl/transformers/parse_resources.ex` — new transformer module
- `lib/aurora_uix/dsl/transformers/lower_layout_tree.ex` — new transformer module
- `lib/aurora_uix/dsl/transformers/assign_node_ids.ex` — new transformer module
- `lib/aurora_uix/dsl/transformers/number_sections.ex` — new transformer module
- `lib/aurora_uix/dsl/transformers/merge_layout_trees.ex` — new transformer module
- `lib/aurora_uix/dsl/transformers/build_configurations.ex` — new transformer module

#### Implementation details

1. **`lib/aurora_uix/dsl/transformers/parse_resources.ex`** (`Aurora.Uix.Dsl.Transformers.ParseResources`):

   - Reproduces `ResourceMetadata.resource_metadata/1` (`resource_metadata.ex:313-320`) exactly
   - Routes `option_label` → `field.data`, `order_by`/`where` → `field.data.query_opts`, `expanded` → `field.data.expanded`
   - Calls `configure_many_to_one_selectors/1` and `add_new_fields_from_changes/2` ordering

2. **`lib/aurora_uix/dsl/transformers/lower_layout_tree.ex`** (`Aurora.Uix.Dsl.Transformers.LowerLayoutTree`):

   - Converts each layout node to `%TreePath{tag:, name:, config:, opts:, inner_elements:}`
   - Handles `inline`, `stacked`, `group`, `sections`, `section`, `field` nodes with `recursive_as: :inner_elements`
   - Expands each `Aurora.Uix.Dsl.Entity.Fields` entity (SCH-1 step 3) into N `field` entities in `keys` order before lowering.

3. **`lib/aurora_uix/dsl/transformers/assign_node_ids.ex`** (`Aurora.Uix.Dsl.Transformers.AssignNodeIds`):

   - Replaces `Blueprint.unique_titled_id/1` with a per-module counter seeded at `auix_create_ui`
   - Produces `auix-group-<slug>-<n>`, `auix-<slug>-<n>`, `auix-section-<slug>-<n>`
   - Stable across compiles and test ordering

4. **`lib/aurora_uix/dsl/transformers/number_sections.ex`** (`Aurora.Uix.Dsl.Transformers.NumberSections`):

   - Ports `Blueprint.parse_sections/2` and `normalize_sections_and_tabs/8` (`blueprint.ex:681-932`)
   - Handles `sections_index`, `tabs`, `active`, `tab_parent_id`, `maybe_mark_first_tab/2`

5. **`lib/aurora_uix/dsl/transformers/merge_layout_trees.ex`** (`Aurora.Uix.Dsl.Transformers.MergeLayoutTrees`):

   - Ports `CreateUI.merge_layout_trees/1` (`create_ui.ex:155-178`)
   - Merges by `{name, tag}`, opts `Keyword.merge`, inner elements concatenated in order, later duplicates rejected

6. **`lib/aurora_uix/dsl/transformers/build_configurations.ex`** (`Aurora.Uix.Dsl.Transformers.BuildConfigurations`):

   - Ports `CreateUI.build_configurations/4` incl. `Blueprint.build_default_layout_paths/4` (`blueprint.ex:571-644`: association rejection rules, `:default_fields_layout`)
   - Ports `fill_missing_paths/3` (form → show cloning, `create_ui.ex:347-367`)
   - Ports `fold_field_opts_into_config/1` (`create_ui.ex:140-151` — still needed because `get_field/3` in `templates/basic/helpers.ex` merges only `:config`)
   - Ports `extract_resource_preloads/1` and the renderer-table validation

7. **`use Aurora.Uix` → `use Spark.Dsl` switch** (from UI-1) ensures that `auix_layout_trees/0`, `auix_configurations/0`, `auix_preloads/0` keep their shapes.

#### Acceptance criteria

- [ ] AC-1: `lib/aurora_uix/dsl/transformers/parse_resources.ex` compiles and correctly lowers resource entities
- [ ] AC-2: `lib/aurora_uix/dsl/transformers/lower_layout_tree.ex` compiles and converts layout nodes to `%TreePath{}` with correct `inner_elements`
- [ ] AC-3: `lib/aurora_uix/dsl/transformers/assign_node_ids.ex` compiles and produces deterministic ids (`auix-group-<slug>-<n>`, etc.)
- [ ] AC-4: `lib/aurora_uix/dsl/transformers/number_sections.ex` compiles and correctly numbers sections and tabs
- [ ] AC-5: `lib/aurora_uix/dsl/transformers/merge_layout_trees.ex` compiles and merges layout trees correctly
- [ ] AC-6: `lib/aurora_uix/dsl/transformers/build_configurations.ex` compiles and builds configurations with correct layout paths
- [ ] AC-7: Golden diff test (step 1) passes for representative view modules
- [ ] AC-8: `mix compile --warnings-as-errors` clean for all new transformer files

##### Green checks

1. `mix compile --warnings-as-errors` clean for all new transformer files
2. `mix test` — full suite green (review-issue runs the suite)
3. Golden diff empty except for step-2 ids (deterministic node ids)
<!-- section:UI-2:end -->

---

### Out of Scope

- Any change to `%Field{}` type atoms, the backend parsers (`integration/ash/`, `integration/ctx/`), renderers, generators, handlers or themes.
- Changing merge semantics of repeated `auix_create_ui` blocks or duplicate `{name, tag}` layouts — they must be reproduced exactly (the golden diff proves it).
- Ecto `has_one` / `has_many` / `embeds_one` / `embeds_many` association rendering changes.
- Any behavior that would change the `%Field{}` shape or the backend parser output.

<!-- enriched-spec:end -->