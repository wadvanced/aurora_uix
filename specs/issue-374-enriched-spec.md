<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Removes `:or_where` and `:select` from the index handler's query-option allowlist and documents that OR conditions belong inside `:where`. Neither option has reached the list query on either backend: `prepare_query_options/1` forwards only `:order_by`, `:where` and `:preload`. Ash and Ecto behave identically before and after; guard tests on both backends pin that behaviour.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.1.7] › Changed · guides/core/layouts.md § Index Layout Options | none | federico/374-doc-1-index-query-options | docs: state that or_where and select are not index options (#374 · DOC-1) |
| UI-1 | UI | handler · drop `:or_where` / `:select` from `@allowed_query_options`; guard tests on both backends | DOC-1 | federico/374-ui-1-index-query-allowlist | fix: stop accepting or_where and select as index options (#374 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md § [0.1.7] › Changed`
- `guides/core/layouts.md § Index Layout Options`
- `guides/core/ash_integration.md § Custom Actions` (link target only; not edited)

#### Implementation details

##### CHANGELOG.md
1. § `## [0.1.7]` › `### Changed` — insert verbatim as the first entry, above `- **Updated Dependencies**`, followed by one blank line:
   ```
   - **`:or_where` and `:select` are no longer accepted as index layout options**
     - Neither was documented, and neither ever reached the list query on either backend. An OR
       condition goes inside `:where`: a `dynamic/2` expression on Ecto resources, a custom read
       action on Ash resources.
   ```

##### guides/core/layouts.md
1. § Index Layout Options — replace the `:where` bullet

   ```
   - `:where` — Query filter; uses `Aurora.Ctx.QueryBuilder` syntax. Conditions submitted from the filter bar are added to it; they never replace it
   ```

   with, verbatim:

   ```
   - `:where` — Query filter; uses `Aurora.Ctx.QueryBuilder` syntax. Conditions submitted from the filter bar are added to it; they never replace it. An OR condition goes inside `:where` as a `dynamic/2` expression on Ecto resources; on Ash resources, filter in a custom read action (see [Custom Actions](ash_integration.md#custom-actions)). `:or_where` and `:select` are not index options
   ```

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-374-enriched-spec.md`)
- [x] AC-3: `guides/core/layouts.md § Index Layout Options` states that `:or_where` and `:select` are not index options (mechanical — no red test; verified by
      `grep -c 'are not index options' guides/core/layouts.md` returning `1`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · handler
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md § Index Layout Options` (as rewritten by DOC-1)
- `guides/core/layouts.md § QueryBuilder for Advanced Filtering`

#### Implementation details

Layout type covered: `:index` only. `:form` and `:show` are untouched. Renderers, components, theme rules and `dt/1` strings are unchanged. The handler stays backend-agnostic.

Grounded facts the steps rely on:

- `lib/aurora_uix/templates/basic/handlers/index_impl.ex` line 139 (module body, outside `__using__/1`): `@allowed_query_options [:where, :or_where, :order_by, :paginate, :select, :preload]`.
- Its only reader is `load_items/2` in the same file: `|> Enum.filter(&(elem(&1, 0) in @allowed_query_options))`, applied to `auix.layout_tree.opts`. `rg -n "allowed_query_options" lib test` returns these two lines only.
- `prepare_query_options/1` in the same file builds `base_options = [order_by: Keyword.get(load_items_options, :order_by), where: where]` and adds only `:preload` (`maybe_put_preload/2`) and the header sort (`maybe_put_sort/2`). `:or_where` and `:select` are dropped here today, on both backends.

Steps:

1. In `lib/aurora_uix/templates/basic/handlers/index_impl.ex`, replace

   ```elixir
   @allowed_query_options [:where, :or_where, :order_by, :paginate, :select, :preload]
   ```

   with

   ```elixir
   # `:or_where` would OR around the filter bar's conditions and `:select` would break the
   # index projection, so neither is an index option.
   @allowed_query_options [:where, :order_by, :paginate, :preload]
   ```

2. Leave `load_items/2`, `prepare_query_options/1` and `get_page_items_id/1` unchanged. `get_page_items_id/1` sets `:select` internally through `Keyword.put(:select, auix.primary_key)` on `auix.pagination.opts`; it does not read `@allowed_query_options`.

3. In `test/cases_live/where_layout_test.exs`, change the `index_columns/3` call inside `auix_create_ui` from

   ```elixir
   index_columns(:product, [:id, :reference, :name, :cost],
     order_by: :name,
     where: [{:reference, :between, "item_test_order-05", "item_test_order-13"}]
   )
   ```

   to

   ```elixir
   index_columns(:product, [:id, :reference, :name, :cost],
     order_by: :name,
     where: [{:reference, :between, "item_test_order-05", "item_test_order-13"}],
     or_where: [{:reference, :eq, "item_test_order-01"}],
     select: [:id]
   )
   ```

   Leave the test `"Test UI default order"` and `@test_references` unchanged.

4. In `test/cases_live/ash_where_layout_test.exs`, change the `index_columns/3` call inside `auix_create_ui` from

   ```elixir
   index_columns(:author, [:name, :email, :bio],
     order_by: :name,
     where: [
       {:email, :between, "author_test_order-05@test.com", "author_test_order-13@test.com"}
     ]
   )
   ```

   to

   ```elixir
   index_columns(:author, [:name, :email, :bio],
     order_by: :name,
     where: [
       {:email, :between, "author_test_order-05@test.com", "author_test_order-13@test.com"}
     ],
     or_where: [{:email, :eq, "author_test_order-01@test.com"}],
     select: [:id]
   )
   ```

   Leave the test `"index where and order_by select and sort the rows"` and `@test_names` unchanged.

##### Acceptance criteria
- [ ] AC-1: `@allowed_query_options` in `index_impl.ex` is `[:where, :order_by, :paginate, :preload]` (mechanical — no red test; verified by
      `rg -n '@allowed_query_options \[:where, :order_by, :paginate, :preload\]' lib/aurora_uix/templates/basic/handlers/index_impl.ex` returning one line, and `rg -c '@allowed_query_options \[' lib/aurora_uix/templates/basic/handlers/index_impl.ex` returning `1`)
- [ ] AC-2: Given the Ecto product resource with `index_columns` carrying `where:`, `or_where:` and `select:`, visiting `/where-layout-products`, the name column lists exactly the nine `where`-bounded products in name order: the `or_where` row `Item test_order-01` is absent and the name cells are not blanked by `select: [:id]` (mechanical — no red test: neither option reached the query before this change; verified by the amended `test/cases_live/where_layout_test.exs` `"Test UI default order"` passing)
- [ ] AC-3: Given the Ash author resource with `index_columns` carrying `where:`, `or_where:` and `select:`, visiting `/ash-where-layout-authors`, the name column lists exactly `@test_names`: the `or_where` row `Author test_order-01` is absent and the page renders without raising (mechanical — no red test: the Ash query parser's `process_option/2` catch-all already ignored both; verified by the amended `test/cases_live/ash_where_layout_test.exs` `"index where and order_by select and sort the rows"` passing)

##### Test ports
- Route `"/where-layout-products"`, already registered in `test/support/app_web/routes.ex` through `RoutesHelper.register_product_crud(WhereLayoutTest, "where-layout-")` · layout type `:index` · observable: the existing `LazyHTML` query `"table tbody tr td:nth-of-type(4)"` on the mounted page.
- Route `"/ash-where-layout-authors"`, already registered through `RoutesHelper.register_crud(AshWhereLayoutTest.Author, "ash-where-layout-authors")` · layout type `:index` · observable: the existing `column_texts(view, 2)` helper over `#auix-table-ash-where-layout-authors-index`.
- No new route, no new test module.

##### Red tests
None. No AC has behaviour that is red before this change: `prepare_query_options/1` already drops both options. The two amendments below are guards that pass before and after step 1.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-2 | amend `test/cases_live/where_layout_test.exs` "Test UI default order" | layout options in the module's `auix_create_ui`; data from `delete_all_inventory_data/0` + `create_sample_products(20, :test_order)` | `test/cases_live/where_layout_test.exs` | `Test UI default order` | unchanged: name-column texts `== @test_references` |
| AC-3 | amend `test/cases_live/ash_where_layout_test.exs` "index where and order_by select and sort the rows" | layout options in the module's `auix_create_ui`; data from `delete_all_blog_data/0` + the module's `create_shuffled_authors/1` | `test/cases_live/ash_where_layout_test.exs` | `index where and order_by select and sort the rows` | unchanged: `column_texts(view, 2) == @test_names` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Handlers.IndexImpl` at `lib/aurora_uix/templates/basic/handlers/index_impl.ex` — modified (module attribute only).
2. Components: none.
3. Theme: none.
4. `dt/1` strings: none.

##### Green tests
1. `mix test test/cases_live/where_layout_test.exs test/cases_live/ash_where_layout_test.exs` passes (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- Implementing `:or_where` or `:select` on either backend. `:select` would break the index projection (every column plus the primary key); a layout-level `:or_where` would OR around the filter bar's conditions.
- Raising or warning when `:or_where` or `:select` is given. `index_layout` / `index_columns` options are not validated anywhere; unknown keys are filtered alike, and a validation pass is separate work.
- Parser sections. Neither backend's parser, CRUD or query module changes: `Aurora.Uix.Integration.Ash.QueryParser` and `Aurora.Uix.Integration.Ctx.Crud` never received either option from the index handler. Both backends are covered by UI-1's guard tests.
- Filtering `auix_resource_metadata` options through `@allowed_query_options`, and the `:paginate` entry of the allowlist. Both are dropped by `prepare_query_options/1` and unchanged here.
<!-- enriched-spec:end -->
