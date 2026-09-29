<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Issue #334 reports that an edit-form checkbox renders unchecked while the record holds `true`. The behaviour does not reproduce on `main`, so this issue delivers a regression guard only: LiveView tests on both backends (Ash and Ecto) asserting `[checked]` on edit-form booleans, with no library change. `DOC-1` is absent because the issue delivers neither a feature nor a fix; the issue is closed as cannot-reproduce once `UI-1` merges.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| UI-1 | UI | test-only · edit-form boolean `[checked]` guard, Ash + Ecto | none | federico/334-ui-1-checkbox-checked-guard | test: guard edit-form checkbox checked state on both backends (#334 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:UI-1:start -->
### UI-1 — UI · regression guard for the form-layout boolean checkbox
Depends on: none

#### Documentation references
- `guides/core/layouts.md` § Field Options — field-level options (`readonly`, `disabled`) apply in every layout.

#### Implementation details

Layout types covered: `:form` only (reached through the `:edit` and `:show_edit` live actions). `:index` and `:show` are left alone; `test/cases_live/predefined_renderers_test.exs` already covers them.

No file under `lib/` changes. Every file this section writes is under `test/`.

##### Acceptance criteria
- [ ] AC-1: Given an Ecto `Product` with `inactive: true`, visiting `/checkbox-checked-products/<id>/edit`, then `#auix-product-form input[type=checkbox][name='product[inactive]'][checked]` exists.
- [ ] AC-2: Given an Ecto `Product` with `deleted: true` and metadata `field(:deleted, disabled: true)`, visiting `/checkbox-checked-products/<id>/edit`, then `#auix-product-form input[type=checkbox][name='product[deleted]'][disabled][checked]` exists.
- [ ] AC-3: Given an Ecto `Product` with `inactive: true, deleted: true`, visiting `/checkbox-checked-products` and clicking the row's edit link, then both the AC-1 and the AC-2 checkboxes carry `[checked]`.
- [ ] AC-4: Given an Ecto `Product` with `inactive: true, deleted: true`, visiting `/checkbox-checked-products/<id>/show` and clicking the show edit link, then both the AC-1 and the AC-2 checkboxes carry `[checked]`.
- [ ] AC-5 (degraded path): Given an Ecto `Product` with `inactive: false, deleted: false`, visiting `/checkbox-checked-products/<id>/edit`, then both checkboxes exist and neither carries `[checked]`.
- [ ] AC-6: Given an Ash `CheckboxItem` with `active?: true`, visiting `/ash-checkbox-checked-items/<id>/edit`, then `#auix-checkbox_item-form input[type=checkbox][name='checkbox_item[active?]'][checked]` exists.
- [ ] AC-7: Given an Ash `CheckboxItem` with `is_deleted: true` and metadata `field(:is_deleted, disabled: true)`, visiting `/ash-checkbox-checked-items/<id>/edit`, then `#auix-checkbox_item-form input[type=checkbox][name='checkbox_item[is_deleted]'][disabled][checked]` exists.
- [ ] AC-8: Given an Ash `CheckboxItem` with `active?: true, is_deleted: true`, visiting `/ash-checkbox-checked-items` and clicking the row's edit link, then both the AC-6 and the AC-7 checkboxes carry `[checked]`.
- [ ] AC-9: Given an Ash `CheckboxItem` with `active?: true, is_deleted: true`, visiting `/ash-checkbox-checked-items/<id>/show` and clicking the show edit link, then both the AC-6 and the AC-7 checkboxes carry `[checked]`.
- [ ] AC-10 (degraded path): Given an Ash `CheckboxItem` with `active?: false, is_deleted: false`, visiting `/ash-checkbox-checked-items/<id>/edit`, then both checkboxes exist and neither carries `[checked]`.
- [ ] AC-11: Given the existing `PredefinedRenderersTest` product seeded with `inactive: true`, visiting `/predefined-renderers-products/<id>/edit`, then `input[type=checkbox][checked].auix-toggle-switch` exists.

##### Test ports
- Route `"checkbox-checked-products"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(CheckboxCheckedTest.Product, "checkbox-checked-products")` · layout types `:form` · observable: `has_element?/2` on `#auix-product-form input[type=checkbox][name='product[<field>]']`.
- Route `"ash-checkbox-checked-items"` registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(AshCheckboxCheckedTest.CheckboxItem, "ash-checkbox-checked-items")` · layout types `:form` · observable: `has_element?/2` on `#auix-checkbox_item-form input[type=checkbox][name='checkbox_item[<field>]']`.
- Route `"predefined-renderers-products"` already registered (`routes.ex`, `PredefinedRenderersTest.Product`).

##### Red tests
Every test below passes on current `main`: the defect does not reproduce. A test that fails on `main` is a real regression; stop and report it instead of changing `lib/`.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n "checkbox_checked\|CheckboxChecked\|checkbox-checked" test lib` returns nothing) | `seed(%{inactive: true})`; `live(conn, "/checkbox-checked-products/#{id}/edit")` | `test/cases_live/checkbox_checked_test.exs` | `"a true boolean renders checked"` in `describe "edit route"` | `assert has_element?(view, "#auix-product-form input[type=checkbox][name='product[inactive]'][checked]")` |
| AC-2 | add to `test/cases_live/checkbox_checked_test.exs` | `seed(%{deleted: true})`; same route | same | `"a true disabled boolean renders disabled and checked"` in `describe "edit route"` | `assert has_element?(view, "#auix-product-form input[type=checkbox][name='product[deleted]'][disabled][checked]")` |
| AC-5 | add to `test/cases_live/checkbox_checked_test.exs` | `seed(%{inactive: false, deleted: false})`; same route | same | `"a false boolean renders unchecked"` in `describe "edit route"` | `assert has_element?` on both `…[name='product[inactive]']` and `…[name='product[deleted]']`; `refute has_element?` on each with `[checked]` appended |
| AC-3 | add to `test/cases_live/checkbox_checked_test.exs` | `seed(%{inactive: true, deleted: true})`; `live(conn, "/checkbox-checked-products")`; `view \|> element("a[name='auix-edit-product'][phx-value-route_path$='#{id}/edit']") \|> render_click()` | same | `"index to edit keeps both booleans checked"` in `describe "navigation"` | `assert_checked(view)` |
| AC-4 | add to `test/cases_live/checkbox_checked_test.exs` | `seed(%{inactive: true, deleted: true})`; `live(conn, "/checkbox-checked-products/#{id}/show")`; `view \|> element("a[name='auix-edit-product'][phx-value-route_path$='#{id}/show-edit']") \|> render_click()` | same | `"show to edit keeps both booleans checked"` in `describe "navigation"` | `assert_checked(view)` |
| AC-6 | new file (`rg -n "AshCheckbox\|ash_checkbox\|ash-checkbox" test lib` returns nothing) | `seed(%{active?: true})`; `live(conn, "/ash-checkbox-checked-items/#{item.id}/edit")` | `test/cases_live/ash_checkbox_checked_test.exs` | `"a true boolean renders checked"` in `describe "edit route"` | `assert has_element?(view, "#auix-checkbox_item-form input[type=checkbox][name='checkbox_item[active?]'][checked]")` |
| AC-7 | add to `test/cases_live/ash_checkbox_checked_test.exs` | `seed(%{is_deleted: true})`; same route | same | `"a true disabled boolean renders disabled and checked"` in `describe "edit route"` | `assert has_element?(view, "#auix-checkbox_item-form input[type=checkbox][name='checkbox_item[is_deleted]'][disabled][checked]")` |
| AC-10 | add to `test/cases_live/ash_checkbox_checked_test.exs` | `seed(%{active?: false, is_deleted: false})`; same route | same | `"a false boolean renders unchecked"` in `describe "edit route"` | `assert has_element?` on both `…[name='checkbox_item[active?]']` and `…[name='checkbox_item[is_deleted]']`; `refute has_element?` on each with `[checked]` appended |
| AC-8 | add to `test/cases_live/ash_checkbox_checked_test.exs` | `seed(%{active?: true, is_deleted: true})`; `live(conn, "/ash-checkbox-checked-items")`; `view \|> element("a[name='auix-edit-checkbox_item'][phx-value-route_path$='#{item.id}/edit']") \|> render_click()` | same | `"index to edit keeps both booleans checked"` in `describe "navigation"` | `assert_checked(view)` |
| AC-9 | add to `test/cases_live/ash_checkbox_checked_test.exs` | `seed(%{active?: true, is_deleted: true})`; `live(conn, "/ash-checkbox-checked-items/#{item.id}/show")`; `view \|> element("a[name='auix-edit-checkbox_item'][phx-value-route_path$='#{item.id}/show-edit']") \|> render_click()` | same | `"show to edit keeps both booleans checked"` in `describe "navigation"` | `assert_checked(view)` |
| AC-11 | amend `test/cases_live/predefined_renderers_test.exs` `"renders the interactive widgets and falls back for read-only renderers"` | existing `seed(%{inactive: true})` | same | unchanged | replace `assert has_element?(view, "input[type=checkbox].auix-toggle-switch")` with `assert has_element?(view, "input[type=checkbox][checked].auix-toggle-switch")` |

`assert_checked/1` is a private helper in each new test file, `@spec assert_checked(Phoenix.LiveViewTest.View.t()) :: true`. It asserts the two `[checked]` selectors of that file's edit-route tests (Ecto: AC-1 and AC-2 selectors; Ash: AC-6 and AC-7 selectors).

##### Modules & components
1. `Aurora.UixWeb.Test.AshCheckbox.Domain` at `test/support/ash_checkbox/domain.ex` — new (`rg -n "AshCheckbox" test lib` returns nothing). Copy the shape of `test/support/ash_actor/policy_domain.ex` `AshActorTest.PolicyDomain`:
   ```elixir
   defmodule Aurora.UixWeb.Test.AshCheckbox.Domain do
     @moduledoc false
     use Ash.Domain

     resources do
       resource Aurora.UixWeb.Test.AshCheckbox.Item
     end
   end
   ```
2. `Aurora.UixWeb.Test.AshCheckbox.Item` at `test/support/ash_checkbox/item.ex` — new. Copy the shape of `test/support/ash_actor/public_item.ex` `AshActorTest.PublicItem` (ETS data layer, `private? false`, no authorizer). The two boolean attributes reproduce the issue's `active?` attribute and its disabled `is_deleted` field:
   ```elixir
   defmodule Aurora.UixWeb.Test.AshCheckbox.Item do
     @moduledoc false
     use Ash.Resource,
       data_layer: Ash.DataLayer.Ets,
       domain: Aurora.UixWeb.Test.AshCheckbox.Domain

     ets do
       private? false
     end

     attributes do
       uuid_primary_key :id
       attribute :name, :string, allow_nil?: false, public?: true
       attribute :active?, :boolean, allow_nil?: false, default: true, public?: true
       attribute :is_deleted, :boolean, allow_nil?: false, default: false, public?: true
     end

     actions do
       default_accept [:name, :active?, :is_deleted]
       defaults [:read, :destroy, :update, :create]
     end
   end
   ```
   Do not add the domain to `config :aurora_uix, ash_domains` in `config/config.exs`; `AshActorTest.PolicyDomain` is not listed there either.
3. `Aurora.UixWeb.Test.CheckboxCheckedTest` at `test/cases_live/checkbox_checked_test.exs` — new:
   1. `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`.
   2. `alias Aurora.Uix.Guides.Inventory` and `alias Aurora.Uix.Guides.Inventory.Product`.
   3. Metadata: `auix_resource_metadata :product, context: Inventory, schema: Product do field(:deleted, disabled: true) end`.
   4. Layout: `auix_create_ui do edit_layout :product do stacked([:reference, :name, :inactive, :deleted]) end end`.
   5. `@spec seed(map()) :: binary()` private `seed/1`: `delete_all_inventory_data()`, then `1 |> create_sample_products(:test, attrs) |> get_in([Access.key!("id_test-1"), Access.key!(:id)])`. This copies `seed/1` in `test/cases_live/predefined_renderers_test.exs`; `create_sample_products/3` (`test/support/helper.ex`) merges `attrs` into the `%Product{}` through `struct/2`, so `inactive` and `deleted` are persisted as given.
   6. `Product.inactive` and `Product.deleted` are `field(:inactive, :boolean, default: false)` and `field(:deleted, :boolean, default: false)` in `lib/aurora_uix/guides/inventory/product.ex`; the Ecto parser maps `%{type: :boolean}` to `html_type: :checkbox` (`lib/aurora_uix/integration/ctx/fields_parser.ex` `defp field_html_type(%{type: :boolean}, _attribute), do: :checkbox`).
4. `Aurora.UixWeb.Test.AshCheckboxCheckedTest` at `test/cases_live/ash_checkbox_checked_test.exs` — new:
   1. `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`.
   2. `alias Aurora.UixWeb.Test.AshCheckbox.Item`.
   3. Metadata: `auix_resource_metadata :checkbox_item, ash_resource: Item do field(:is_deleted, disabled: true) end`.
   4. Layout: `auix_create_ui do edit_layout :checkbox_item do stacked([:name, :active?, :is_deleted]) end end`.
   5. `@spec seed(map()) :: Item.t()` private `seed/1`: `Item |> Ash.Changeset.for_create(:create, Map.merge(%{name: "checkbox-item"}, attrs)) |> Ash.create!()`. Each test selects its own record by id; the ETS table is not cleared.
   6. The Ash parser maps `Ash.Type.Boolean` to `type: :boolean` (`lib/aurora_uix/integration/ash/fields_parser.ex` `defp field_type(_attrs, %{type: type}) when type in [Ash.Type.Boolean, Ash.Type.Boolean.EctoType, :boolean]`), and its `defp field_html_type(%{type: ecto_type}, %{association_or_embed: association_or_embed})` delegates to `lib/aurora_uix/integration/fields_parser.ex` `def field_html_type(:boolean, _association), do: :checkbox`.
5. `test/support/app_web/routes.ex` `load_test_routes/0` — modified. Append, after the `RoutesHelper.register_crud(AshActorPolicyTest.PublicItem, "ash-actor-public-items")` call and inside the same `quote`:
   ```elixir
   RoutesHelper.register_crud(
     CheckboxCheckedTest.Product,
     "checkbox-checked-products"
   )

   RoutesHelper.register_crud(
     AshCheckboxCheckedTest.CheckboxItem,
     "ash-checkbox-checked-items"
   )
   ```
   The generated modules are `<test module>.Product` and `<test module>.CheckboxItem`, as `AshActorPolicyTest.PublicItem` is for resource `:public_item`.
6. `test/cases_live/predefined_renderers_test.exs` — modified, AC-11 row only.
7. Selectors relied on, each verified at its definition:
   - form id `"auix-#{@auix.module}-form"` — `lib/aurora_uix/templates/basic/renderers/form_renderer.ex`;
   - input name `<module>[<field>]` — the form name is `auix.module` (`lib/aurora_uix/integration/ash/crud.ex` `change/5` passes `as: binary_form_name`);
   - `[checked]` and `[disabled]` on the checkbox — `lib/aurora_uix/templates/basic/components/core_components.ex` `def input(%{type: "checkbox", host_components: nil} = assigns)` renders `checked={@checked}` and spreads `{@rest}`, which carries `disabled={@field.disabled}` from `default_renderer.ex` `defp default_render_input(%{auix: %{layout_type: :form, primary_key: primary_key}} = assigns)`;
   - index edit link — `lib/aurora_uix/templates/basic/actions/index.ex`, `<.auix_link … patch={"/#{@auix.uri_path}/#{row_info_id(@auix)}/edit"} name={"auix-edit-#{@auix.module}"}>`;
   - show edit link — `lib/aurora_uix/templates/basic/actions/show_component.ex`, `<.auix_link patch={".../show-edit"} name={"auix-edit-#{@auix.module}"}>`;
   - `phx-value-route_path` — `lib/aurora_uix/templates/basic/components/routing_components.ex` `auix_link/1` patch clause.
8. Components: none new. Theme: none. `dt/1` strings: none.
9. Standing rules touched: no `Ash.Resource.*` reference is added under `lib/`; the ETS resource lives in `test/support/`, which is test code. Assert with `has_element?/2` only, never `=~` on HTML, never an `auix-field-*` id.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- Any change under `lib/`: the defect does not reproduce on `main`, so there is nothing to fix.
- `DOC-1` and a CHANGELOG entry: the issue ships no feature and no fix.
- A boolean attribute on the Ash guide schemas in `lib/aurora_uix/guides/blog/`: the Ash fixture lives in `test/support/` so the library ships unchanged.
- Checkbox state after a `phx-change` validate event: the reported symptom is at first render with empty params.
- Closing #334 as cannot-reproduce and unblocking #363: done after `UI-1` merges, outside this spec.
<!-- enriched-spec:end -->
