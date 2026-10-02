<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Adds a worked recipe for a host-defined bulk action over the rows selected in the index to the
custom actions guide, and a LiveView test that runs that recipe end to end. No library code
changes: `add_selected_action`, `auix_handle_event/3` and `auix.selection` already exist and are
backend-agnostic; the test runs on the Ecto `inventory/` guide schema.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | `CHANGELOG.md` § [0.1.6]; `guides/customization/custom_actions.md` § Bulk Actions on Selected Rows (new) | none | federico/373-doc-1-bulk-actions-guide | docs: guide recipe for bulk actions on selected rows (#373 · DOC-1) |
| UI-1 | UI | index handler · LiveView test of the bulk selected-action recipe | DOC-1 | federico/373-ui-1-bulk-action-test | test: prove the bulk selected-action recipe (#373 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § `## [0.1.6]` (current unreleased version; it has `### Fixes`, `### Added`,
  `### Changed` and no `### Documentation` yet)
- `guides/customization/custom_actions.md` § Index Layout Actions (the `*_selected_action` row)
- `guides/customization/custom_actions.md` § Refreshing the Index from a Custom Action
- `guides/core/liveview.md` § Index Handler Hook (LiveView)

#### Implementation details

##### CHANGELOG.md
1. § `## [0.1.6]` — add a new `### Documentation` heading as the last subsection of `## [0.1.6]`:
   after the last line of `### Changed` (the `- telemetry_metrics: 1.1.0 -> 1.2.0` line) and
   before `## [0.1.5] - 2026-07-28`, with one blank line on each side. Insert verbatim:
   ```
   ### Documentation

   - **Bulk actions on selected rows**
     - `guides/customization/custom_actions.md` gains a worked recipe for a host's own action over
       the rows selected in the index: the control in the selected-actions strip, the
       `add_selected_action` option, and the handler clause that reads the selection, writes the
       records and refreshes the index.
   ```

##### guides/customization/custom_actions.md
1. § Bulk Actions on Selected Rows — new section. Insert it immediately before the line
   `## Refreshing the Index from a Custom Action`, followed by one blank line. Insert verbatim
   (the outer fence below is not part of the text; the inner ```` ```elixir ```` fences are):

   ````markdown
   ## Bulk Actions on Selected Rows

   A bulk action runs over the rows the user ticked in the index. It takes three pieces: a control
   in the selected-actions strip, a layout option that places it there, and a handler clause that
   does the work. This recipe adds a **Deactivate selected** button that sets `inactive` on every
   selected product.

   **1. The control.** The selected-actions strip calls each action with `%{auix: auix}`.
   `auix.selection` is an `Aurora.Uix.Selection` struct:

   | Field | Content |
   |---|---|
   | `selected` | a `MapSet` of the selected rows' ids, across every page |
   | `selected_count` | the number of selected rows |
   | `toggle_all_mode` | `:none`, or `:check` / `:uncheck` while **Check all** / **Uncheck all** is still collecting ids — `selected` is incomplete until it returns to `:none` |

   Render the control only when rows are selected and no toggle-all is running, as the built-in
   **Delete selected** does:

   ```elixir
   defmodule MyAppWeb.ProductActions do
     use Aurora.Uix.CoreComponentsImporter

     def deactivate_selected(
           %{auix: %{selection: %{selected_count: count, toggle_all_mode: :none}}} = assigns
         )
         when count > 0 do
       ~H"""
       <.button
         type="button"
         class="auix-index-all-action-button"
         phx-click="deactivate_selected"
         name={"auix-selected-deactivate-#{@auix.module}"}
       >
         Deactivate selected
       </.button>
       """
     end

     def deactivate_selected(assigns), do: ~H""
   end
   ```

   **2. The layout option.** `add_selected_action` appends the control after the built-in ones;
   `handler_module` names the module that receives its event:

   ```elixir
   auix_create_ui do
     index_columns(:product, [:reference, :name, :inactive],
       handler_module: MyAppWeb.ProductIndexHandler,
       add_selected_action: {:deactivate_selected, &MyAppWeb.ProductActions.deactivate_selected/1}
     )
   end
   ```

   **3. The handler.** The control's `phx-click` reaches the index LiveView, which passes it to
   `auix_handle_event/3`. The event carries no ids; read them from
   `socket.assigns.auix.selection.selected`:

   ```elixir
   defmodule MyAppWeb.ProductIndexHandler do
     use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

     alias Aurora.Uix.Events
     alias MyApp.Inventory
     alias MyApp.Inventory.Product

     @impl IndexImpl
     def auix_handle_event("deactivate_selected", _params, socket) do
       Enum.each(socket.assigns.auix.selection.selected, fn id ->
         id |> Inventory.get_product!() |> Inventory.update_product(%{inactive: true})
       end)

       Events.changed(Product)
       Events.reset_selection()

       {:noreply, put_flash(socket, :info, "Products deactivated")}
     end

     def auix_handle_event(event, params, socket), do: super(event, params, socket)
   end
   ```

   - Keep the last clause. Overriding `auix_handle_event/3` replaces the default, and every
     built-in index event — selection, filters, sorting, pagination, **Delete selected** — arrives
     through it.
   - Aurora UIX never writes the records. The handler calls the host's own context function or Ash
     action; validation and its errors are the host's. This sketch ignores an
     `{:error, changeset}` result; report it in a real application.
   - `Events.changed(Product)` re-reads the page so the new values show, and
     `Events.reset_selection()` clears the selection, which hides the control again. See
     [Refreshing the Index from a Custom Action](#refreshing-the-index-from-a-custom-action).
   ````

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-373-enriched-spec.md`)
- [x] AC-3: `CHANGELOG.md` § `## [0.1.6]` has a `### Documentation` subsection carrying the
      **Bulk actions on selected rows** entry, before `## [0.1.5]` (mechanical — no red test;
      verified by `awk '/^## \[0.1.6\]/{f=1} /^## \[0.1.5\]/{f=0} f' CHANGELOG.md | grep -n -e '^### Documentation' -e 'Bulk actions on selected rows'` printing both lines)
- [x] AC-4: `guides/customization/custom_actions.md` § Bulk Actions on Selected Rows reads as
      prescribed and sits immediately before § Refreshing the Index from a Custom Action
      (mechanical — no red test; verified by
      `grep -n -e '^## Bulk Actions on Selected Rows' -e '^## Refreshing the Index from a Custom Action' -e 'add_selected_action: {:deactivate_selected' -e 'def auix_handle_event("deactivate_selected"' guides/customization/custom_actions.md`
      printing all four, the Bulk heading's line number lower than the Refreshing heading's)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · index handler (bulk selected action recipe test)
Depends on: DOC-1

#### Documentation references
- `guides/customization/custom_actions.md` § Bulk Actions on Selected Rows (DOC-1) — the recipe
  this test runs

#### Implementation details

No file under `lib/` changes. Layout type covered: `:index` only; `:form` and `:show` are left
alone. No theme rule, no new component, no `dt/1` string (the flash text belongs to the test's
host handler, as in the guide).

Existing behaviour the test relies on, verified at its definition:
- `lib/aurora_uix/action.ex` `@actions` map, `index:` key: `add_selected_action:
  {:index_selected_actions, :add_auix_action}`.
- `lib/aurora_uix/templates/basic/renderers/index_renderer.ex` `render/1`: the
  `auix-index-select-actions` div, outside `<.auix_simple_form>`, renders
  `{action.(%{auix: @auix})}` for each `%{function_component: action} <- @auix.index_selected_actions`.
- `lib/aurora_uix/templates/basic/handlers/index_impl.ex` `__using__/1`: `handle_event/3`
  delegates to `auix_handle_event/3`, which is `defoverridable`; the `__using__` quote aliases
  `IndexImpl` and imports `Phoenix.LiveView` (`put_flash/3`). `IndexImpl.auix_handle_event/3` has
  no catch-all clause.
- `lib/aurora_uix/selection.ex` `defstruct selected: MapSet.new(), …, selected_count: 0, …,
  toggle_all_mode: :none`. A row tick (`auix_handle_event("index-layout-change", %{"_target" =>
  ["selected_check__" <> id]}, …)`) adds the id string; Check all (`assign_async_selected_toggle_all/2`)
  adds `BasicHelpers.primary_key_value/2` values and resets `toggle_all_mode` to `:none` in
  `auix_handle_async(:auix_selection_toggle_all, …)`.
- `lib/aurora_uix/events.ex` `changed/2` and `reset_selection/1` (default `self()`);
  `index_impl.ex` `auix_handle_info({Events, :reset_selection}, socket)` assigns `Selection.new()`.
- `lib/aurora_uix/guides/inventory/product.ex` `changeset/2`: casts `:inactive`;
  `validate_required([:name, :status, :quantity_initial])`. `test/support/helper.ex`
  `create_sample_products/3` sets no `quantity_initial`, so the test passes
  `%{quantity_initial: Decimal.new(5)}` — without it `Inventory.update_product/2` returns
  `{:error, changeset}` and nothing is written.

##### Acceptance criteria
- [ ] AC-1: Given the recipe's `add_selected_action` control and handler on `:product`, visiting
      `/selected-bulk-action-products` with no row selected, then
      `button[name='auix-selected-deactivate-product']` is absent.
- [ ] AC-2: Given three products, ticking two rows and clicking
      `button[name='auix-selected-deactivate-product']` sets `inactive: true` on exactly those two,
      leaves the third `inactive: false`, shows the flash `Products deactivated`, and the control
      disappears because the selection is cleared.
- [ ] AC-3: Given three products, clicking Check all (`button[name='auix-selected_check_all-product']`),
      waiting for it with `render_async/1`, then clicking the control sets `inactive: true` on all
      three.

##### Test ports
- Route `"selected-bulk-action-products"` registered in `test/support/app_web/routes.ex` via
  `RoutesHelper.register_crud(SelectedBulkActionTest.Product, "selected-bulk-action-products")`
  · layout types `:index` · observable: `has_element?/2` on
  `button[name='auix-selected-deactivate-product']` and `#flash-info`, plus
  `Inventory.get_product!/1` for the written `inactive` value.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n "add_selected_action" test` and `rg -n "SelectedBulkAction" test` return nothing) | `delete_all_inventory_data()`; `create_sample_products(3, :test, %{quantity_initial: Decimal.new(5)})`; `live(conn, "/selected-bulk-action-products")` | `test/cases_live/selected_bulk_action_test.exs` | `"the control is hidden while nothing is selected"` | `refute has_element?(view, @control)` |
| AC-2 | same new file | as AC-1; `select_row(view, first.id)`, `select_row(view, second.id)` | `test/cases_live/selected_bulk_action_test.exs` | `"the control deactivates the ticked rows and clears the selection"` | `assert has_element?(view, @control, "Deactivate selected")`; click; `assert Inventory.get_product!(first.id).inactive`, same for `second`; `refute Inventory.get_product!(third.id).inactive`; `assert has_element?(view, "#flash-info", "Products deactivated")`; `refute has_element?(view, @control)` |
| AC-3 | same new file | as AC-1; click `button[name='auix-selected_check_all-product']`; `render_async(view)` | `test/cases_live/selected_bulk_action_test.exs` | `"the control covers every row after Check all"` | click `@control`; all three `Inventory.get_product!(id).inactive` are `true` |

##### Modules & components
1. `test/cases_live/selected_bulk_action_test.exs` — new. Write it with exactly this content:

   ```elixir
   defmodule Aurora.UixWeb.Test.SelectedBulkActionTest do
     use Aurora.UixWeb.Test.UICase, :phoenix_case
     use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

     use Aurora.Uix.CoreComponentsImporter

     alias Aurora.Uix.Guides.Inventory
     alias Aurora.Uix.Guides.Inventory.Product
     alias Phoenix.LiveView.Rendered

     @control "button[name='auix-selected-deactivate-product']"

     @spec deactivate_selected(map()) :: Rendered.t()
     def deactivate_selected(
           %{auix: %{selection: %{selected_count: count, toggle_all_mode: :none}}} = assigns
         )
         when count > 0 do
       ~H"""
       <.button
         type="button"
         class="auix-index-all-action-button"
         phx-click="deactivate_selected"
         name={"auix-selected-deactivate-#{@auix.module}"}
       >
         Deactivate selected
       </.button>
       """
     end

     def deactivate_selected(assigns), do: ~H""

     auix_resource_metadata(:product, context: Inventory, schema: Product)

     # When you define a link in a test, add a line to test/support/app_web/routes.ex
     auix_create_ui do
       index_columns(:product, [:reference, :name, :inactive],
         handler_module: Aurora.UixWeb.SelectedBulkActionIndexHandler,
         add_selected_action: {:deactivate_selected, &__MODULE__.deactivate_selected/1}
       )
     end

     setup do
       delete_all_inventory_data()

       %{"id_test-1" => first, "id_test-2" => second, "id_test-3" => third} =
         create_sample_products(3, :test, %{quantity_initial: Decimal.new(5)})

       %{products: [first, second, third]}
     end

     test "the control is hidden while nothing is selected", %{conn: conn} do
       {:ok, view, _html} = live(conn, "/selected-bulk-action-products")

       refute has_element?(view, @control)
     end

     test "the control deactivates the ticked rows and clears the selection", %{
       conn: conn,
       products: [first, second, third]
     } do
       {:ok, view, _html} = live(conn, "/selected-bulk-action-products")
       select_row(view, first.id)
       select_row(view, second.id)

       assert has_element?(view, @control, "Deactivate selected")

       view |> element(@control) |> render_click()

       assert Inventory.get_product!(first.id).inactive
       assert Inventory.get_product!(second.id).inactive
       refute Inventory.get_product!(third.id).inactive
       assert has_element?(view, "#flash-info", "Products deactivated")
       refute has_element?(view, @control)
     end

     test "the control covers every row after Check all", %{conn: conn, products: products} do
       {:ok, view, _html} = live(conn, "/selected-bulk-action-products")

       view |> element("button[name='auix-selected_check_all-product']") |> render_click()
       render_async(view)

       view |> element(@control) |> render_click()

       assert Enum.all?(products, &Inventory.get_product!(&1.id).inactive)
     end

     @spec select_row(term(), term()) :: binary()
     defp select_row(view, id),
       do: render_change(view, "index-layout-change", %{"_target" => ["selected_check__#{id}"]})
   end

   defmodule Aurora.UixWeb.SelectedBulkActionIndexHandler do
     use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

     alias Aurora.Uix.Events
     alias Aurora.Uix.Guides.Inventory
     alias Aurora.Uix.Guides.Inventory.Product
     alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl

     @impl IndexImpl
     def auix_handle_event("deactivate_selected", _params, socket) do
       Enum.each(socket.assigns.auix.selection.selected, fn id ->
         id |> Inventory.get_product!() |> Inventory.update_product(%{inactive: true})
       end)

       Events.changed(Product)
       Events.reset_selection()

       {:noreply, put_flash(socket, :info, "Products deactivated")}
     end

     def auix_handle_event(event, params, socket), do: super(event, params, socket)
   end
   ```

   Precedents: the action component defined in the test module and referenced as
   `&__MODULE__.<fun>/1` — `test/cases_live/create_ui_actions_index_test.exs`; the handler module
   as a second top-level module in the test file and `select_row/2` —
   `test/cases_live/events_test.exs` (`Aurora.UixWeb.EventsProbeIndexHandler`).
2. `test/support/app_web/routes.ex` `load_test_routes/0` — modified. Insert, directly after the
   line `RoutesHelper.register_crud(AshEventsTest.Author, "ash-events-authors")`:
   ```elixir
           RoutesHelper.register_crud(SelectedBulkActionTest.Product, "selected-bulk-action-products")
   ```
   Do not use `register_product_crud/2`.
3. Components: `<.button>` from `core_components.ex` `button/1` (attrs `type`, `class` — one of
   `auix-button`, `auix-button--alt`, `auix-index-all-action-button` — and global `name`,
   `phx-click`), imported through `use Aurora.Uix.CoreComponentsImporter`. No new component.
4. Theme: none — `auix-index-all-action-button` already exists (`@selected_button_class` in
   `lib/aurora_uix/templates/basic/actions/index.ex`).
5. `dt/1` strings: none.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- Any change under `lib/`: the selected-actions strip, `add_selected_action`, handler dispatch and
  `auix.selection` already work; this issue documents and tests them.
- An Ash-backend test of the recipe: the strip, the event dispatch and the selection are
  backend-agnostic code with no parser and no CRUD path involved; the only backend-specific line is
  the host handler's own write call, which is host code, not library behaviour.
- An export (file download) recipe: a download is not observable with `Phoenix.LiveViewTest`,
  and the issue names export and status change as alternatives; the status change is the one
  delivered.
- The `bulk_publish` sketch in `guides/core/liveview.md` § Index Handler Hook (LiveView).
<!-- enriched-spec:end -->
