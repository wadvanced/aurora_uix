<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Below the `sm` breakpoint (640px) the card view's sort control is one icon button that opens a menu: "Default order", the sortable fields, then "Ascending" and "Descending". A check marks the active field and the active direction, and the button is highlighted while a field sort is on. From `sm` up the field select and the direction switch stay as they are. The work is backend-agnostic action, handler and theme code and covers Ash and Ecto resources alike. The issue owes no CHANGELOG entry: the sort menu is a UI change, neither a feature nor a fix.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | guides/core/layouts.md § Index Cards · guides/core/liveview.md § Built-in Events · guides/customization/custom_actions.md § Action Icons · guides/customization/styling.md § Sizes & dimensions, § Class reference | none | federico/515-doc-1-sort-menu | docs: icon sort menu for the mobile card view (#515 · DOC-1) |
| UI-1 | UI | action + handler + theme · card-view sort menu below `sm` (`sort_header_action/1`), `"index-sort-direction"` with `"direction"` | DOC-1 | federico/515-ui-1-sort-menu | feat: icon sort menu for the mobile card view (#515 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `guides/core/layouts.md § Index Cards`
- `guides/core/liveview.md § Built-in Events`
- `guides/customization/custom_actions.md § Action Icons`
- `guides/customization/styling.md § Sizes & dimensions`, `§ Class reference`

#### Implementation details

`CHANGELOG.md` is not edited: it stays byte for byte as on `origin/main`. The issue owes no CHANGELOG entry.

##### guides/core/layouts.md
1. § `Index Cards` — after the paragraph
   ```
   A column the card omits stays sortable and filterable. With `show_on: :all` the table headers are
   gone, so the card sort control and the filter cards show at every breakpoint.
   ```
   insert one blank line and this paragraph, verbatim:
   ```
   The card sort control is a field select and a direction switch. Below the 640px breakpoint it is
   one icon button instead: its menu lists "Default order" and the sortable fields, then "Ascending"
   and "Descending", and checks the active field and direction. The button is highlighted while a
   field sort is on.
   ```

##### guides/core/liveview.md
1. § `Built-in Events` › **Index LiveView:** — replace the bullet that starts `` - `"index-sort"` - Sort the index. `` with, verbatim:
   ```
   - `"index-sort"` - Sort the index. Sent by the sortable column headers with the field `"key"`: each click moves the sort through ascending, descending and back to the backend order. The card view's sort select and sort menu instead send `"sort"` as a field key, or `""` to return to the backend order; a newly chosen field keeps the current direction. Ignored when the layout option `sort_disabled?` is `true`
   ```
2. Same list — replace the bullet that starts `` - `"index-sort-direction"` `` with, verbatim:
   ```
   - `"index-sort-direction"` - Change the direction of the active sort. The card view's direction switch sends no parameter and reverses it; the card view's sort menu sends `"direction"` as `"asc"` or `"desc"` and sets it, and any other value is ignored. A no-op without an active sort, and ignored when `sort_disabled?` is `true`
   ```

##### guides/customization/custom_actions.md
1. § `Action Icons` — in the paragraph that starts `` `:default_toggle_all_selected`, `:default_sort` and `:default_pagination` are not keys: they ``, replace the words `render a checkbox, a select and a pager.` with `render a checkbox, a sort control with fixed icons and a pager.` The rest of the paragraph stays as it is.

##### guides/customization/styling.md
1. § `Sizes & dimensions` — replace the `--auix-touch-target-size` row with, verbatim:
   ```
   | `--auix-touch-target-size` | `2.75rem` | Minimum width and height of the card ⋮ menu toggle, of the sort menu button and of each menu item |
   ```
2. § `Class reference` — replace the `.auix-index-sort-action` row with these rows, verbatim and in this order:
   ```
   | `.auix-index-sort-action` | Card-view sort control in the index header actions: the field select and direction switch from the `sm` breakpoint up, the sort menu below it; hidden from the `md` breakpoint up, where the column headers sort | Structural only |
   | `.auix-index-sort-select` | Field select plus direction switch button of the card-view sort control; shown from the `sm` breakpoint up | `--auix-gap-minimal`, `--auix-font-size-caption`, `--auix-font-weight-bold` |
   | `.auix-index-sort-menu` | Icon button and menu of the card-view sort control; shown below the `sm` breakpoint | `--auix-touch-target-size` |
   | `.auix-index-sort-menu-toggle--active` | Sort menu button while a field sort is on | `--auix-color-icon-info`, `--auix-color-bg-secondary` |
   | `.auix-index-sort-menu-list` | Sort menu, opening below its button (hidden until toggled) | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-border-primary`, `--auix-border-radius-default`, `--auix-color-bg-default`, `--auix-shadow-md` |
   | `.auix-index-sort-menu-group` | One group of the sort menu: the fields, then the directions below a divider | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-border-primary` |
   | `.auix-index-sort-menu-item` | One option of the sort menu; a check marks the active field and the active direction | `--auix-gap-default`, `--auix-touch-target-size`, `--auix-padding-default`, `--auix-font-size-caption`, `--auix-color-bg-hover`, `--auix-color-text-inactive` |
   | `.auix-index-sort-menu-check--off` | Check of an inactive sort menu option, kept invisible so the labels line up | Structural only |
   ```

##### Acceptance criteria
- [x] AC-1: `CHANGELOG.md` is unchanged: the issue owes no CHANGELOG entry (mechanical — no red
      test; verified by `git diff --name-only origin/main...HEAD -- CHANGELOG.md` printing nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-515-enriched-spec.md`)
- [x] AC-3: `CHANGELOG.md` carries no sort-control entry (mechanical — no red test; verified by
      `grep -c 'Card-view sort control on phones' CHANGELOG.md` returning 0)
- [x] AC-4: `guides/core/layouts.md § Index Cards` describes the sort menu (mechanical — no red test;
      verified by `grep -c 'one icon button instead: its menu lists' guides/core/layouts.md`
      returning 1)
- [x] AC-5: `guides/core/liveview.md § Built-in Events` documents the `"direction"` parameter
      (mechanical — no red test; verified by `grep -c 'sort menu sends' guides/core/liveview.md`
      returning 1 and `grep -c 'sort select and sort menu instead send' guides/core/liveview.md`
      returning 1)
- [x] AC-6: `guides/customization/custom_actions.md § Action Icons` reads as prescribed (mechanical —
      no red test; verified by `grep -c 'a sort control with fixed icons and a pager' guides/customization/custom_actions.md`
      returning 1 and `grep -c 'a select and a pager' guides/customization/custom_actions.md` returning 0)
- [x] AC-7: `guides/customization/styling.md` lists the sort menu classes (mechanical — no red test;
      verified by `grep -c 'auix-index-sort-' guides/customization/styling.md` returning 9 and
      `grep -c 'of the sort menu button and of each menu item' guides/customization/styling.md`
      returning 1)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · action + handler + theme: card-view sort menu
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md § Index Cards` (DOC-1)
- `guides/core/liveview.md § Built-in Events` (DOC-1)
- `guides/customization/styling.md § Class reference`, `§ Sizes & dimensions` (DOC-1)

#### Implementation details

Layout type: `:index` only — the generated `Index` LiveView and the `IndexComponent`, which both take their header actions from `Aurora.Uix.Templates.Basic.Actions.Index` `set_actions/1` (`handlers/index_impl.ex` through `IndexList.init/3`; `handlers/index_component_impl.ex`). One-to-many lists take their actions from `OneToManyActions.set_actions/1` and render no sort control: untouched. `:form` and `:show` are untouched. The table view's sortable column headers are untouched.

Facts this section builds on:
- `sort_header_action/1` (`lib/aurora_uix/templates/basic/actions/index.ex`) is the `:default_sort` header action (`add_default_header_actions/1`). Its first clause matches `%{auix: %{layout_options: %{sort_disabled?: false}} = auix}`; the fallback `def sort_header_action(assigns), do: ~H""` renders nothing. The menu goes inside the first clause's `:if={@sort_options != []}` container, so `sort_disabled?: true` and an index without sortable fields render no menu.
- The field options reuse the existing `"index-sort"` clause `def handle_event("index-sort", %{"sort" => key}, %{assigns: %{auix: auix}} = socket) do` (keeps the current direction, `:asc` when no sort is on), and "Default order" reuses `def handle_event("index-sort", %{"sort" => ""}, socket),` (`lib/aurora_uix/templates/basic/handlers/index_list.ex`).
- The direction options need an explicit direction: the existing `def handle_event("index-sort-direction", _params, %{assigns: %{auix: auix}} = socket) do` flips the direction, so a tap on the checked direction would reverse it. Implementation step 2 adds a clause for `%{"direction" => direction}`. The guard clause `def handle_event(event, _params, %{assigns: %{auix: %{layout_options: %{sort_disabled?: true}}}} = socket) when event in ["index-sort", "index-sort-direction"],` sits above it and keeps ignoring every sort event when sorting is disabled.
- The menu follows the card menu (`card_menu/1`, `toggle_card_menu/0`, `hide_card_menu/0` in `lib/aurora_uix/templates/basic/components/components.ex`): the container carries `phx-click` (toggle) and `phx-click-away` (hide), addressing the list and the toggle with `{:inner, …}`. A menu option carries its own `phx-click`, which LiveView runs instead of the container's (the closest binding wins). The option's JS pushes the event, then runs `JS.exec("phx-click-away", to: {:closest, "[name='auix-sort_menu']"})`, which executes the container's hide with the container as its source element (`exec_exec` → `liveSocket.execJS(el, …)` in `deps/phoenix_live_view/assets/js/phoenix_live_view/js.js`).
- `Phoenix.LiveViewTest` runs the `push` op of a `phx-click` JS command with its `value` and `target` and skips the other ops (`maybe_js_commands/6` in `deps/phoenix_live_view/lib/phoenix_live_view/test/client_proxy.ex`); clicking a `disabled` element fails the test with `cannot click element … because it is disabled`.
- `BasicHelpers.target_opts/2` (`lib/aurora_uix/templates/basic/helpers.ex`) adds `target: auix._myself` in a component and nothing in the LiveView; `remove_row_action/1` already pushes with it.
- `<.button>` (`core_components.ex` `button/1`) renders `class={["auix-button-default", @class]}`; `.auix-button-default` has no rule of its own (`_auix_button_default` is only imported, renamed, into `auix_button`, `auix_button__alt` and `auix_button_badge`), so a menu option is styled by `.auix-index-sort-menu-item` alone. Its `:global` rest takes `role`, `title`, `aria-*` and `phx-*`; `name` and `disabled` are included explicitly.
- HEEx drops an attribute whose value is `false`, so every `aria-checked` value goes through `to_string/1`.
- `Aurora.Uix.Templates.CssSanitizer` `@allowed_properties` admits every property this section writes (`display`, `position`, `inset-inline-end`, `top`, `z-index`, `flex-*`, `min-width`, `min-height`, `gap`, `padding-*`, `border-*`, `background-color`, `color`, `font-size`, `white-space`, `cursor`, `visibility`, `box-shadow`, `justify-content`, `align-items`, `margin`, `box-sizing`, `font-weight`); selectors pass through unchanged.
- `mix auix.gen.tailwind_classes` (the first stage of `mix consistency`) adds `hero-arrows-up-down` to `priv/static/classes.js`, which is committed. `deps/heroicons/optimized/24/outline/arrows-up-down.svg` exists.

##### Acceptance criteria
- [x] AC-1: Given `index_columns(:product, [:reference, :name, :cost, :image, description: [sortable?: false]])` with `field(:cost, sortable?: false)` and an `upload` on `:image`, at `/sortable-columns-products`, `[name='auix-sort_action-product']` holds `.auix-index-sort-select` (holding `#auix-sort-form-product` and `button[name='auix-sort_direction-product']`) and `[name='auix-sort_menu']`; the menu holds `button[name='auix-sort_menu_toggle']` with `title` and `aria-label` `Sort`, `aria-haspopup='menu'`, `aria-expanded='false'` and a `span.hero-arrows-up-down`, and `[name='auix-sort_menu_list'][role='menu']` holding `button[name='auix-sort_menu_default']` (text `Default order`), `button[name='auix-sort_menu_field-reference']` (text `Reference`), `button[name='auix-sort_menu_field-name']` (text `Name`), `button[name='auix-sort_menu_direction-asc']` (text `Ascending`) and `button[name='auix-sort_menu_direction-desc']` (text `Descending`), each with `role='menuitemradio'`; no `auix-sort_menu_field-` option exists for `cost`, `description`, `image` and `selected_check__`
- [x] AC-2: With no active sort, `auix-sort_menu_default` has `aria-checked='true'` and a `span.hero-check` without `auix-index-sort-menu-check--off`; every field option has `aria-checked='false'` and a `span.hero-check.auix-index-sort-menu-check--off`; both direction options have `aria-checked='false'` and `disabled`; the toggle has no `auix-index-sort-menu-toggle--active`
- [x] AC-3: Clicking `auix-sort_menu_field-name` sorts the cards by name ascending (Alpha, Bravo, Charlie); then the name option and `auix-sort_menu_direction-asc` have `aria-checked='true'`, `auix-sort_menu_default` has `aria-checked='false'`, and the toggle has `auix-index-sort-menu-toggle--active`
- [x] AC-4: Clicking `auix-sort_menu_direction-desc` then sorts descending (Charlie, Bravo, Alpha) and gives it `aria-checked='true'` and `auix-sort_menu_direction-asc` `aria-checked='false'`; clicking `auix-sort_menu_direction-desc` again keeps the descending order
- [x] AC-5: Clicking `auix-sort_menu_default` then returns to the backend order (Charlie, Alpha, Bravo), removes `auix-index-sort-menu-toggle--active` and disables both direction options
- [x] AC-6 (edge): `"index-sort-direction"` with `%{"direction" => "desc"}` and no active sort leaves the backend order; with a name sort on, `%{"direction" => "sideways"}` leaves the ascending order
- [x] AC-7: Given the Ash `:author` index at `/ash-sortable-columns-authors`, clicking `auix-sort_menu_field-name`, then `auix-sort_menu_direction-desc`, then `auix-sort_menu_default` gives Alpha, Bravo, Charlie, then Charlie, Bravo, Alpha, then Charlie, Alpha, Bravo
- [x] AC-8: Given two `IndexComponent` instances `a` and `b` on one page, clicking `#a button[name='auix-sort_menu_field-reference']` checks that option in `a` and leaves it unchecked in `b`
- [x] AC-9 (edge): With `sort_disabled?: true` at `/sort-disabled-products`, no `[name='auix-sort_menu']` renders, and a forged `"index-sort-direction"` with `%{"direction" => "desc"}` leaves the backend order
- [x] AC-10: The theme swaps the controls at `sm`: `Base.rule(:auix_index_sort_select)` sets `.auix-index-sort-select` to `display: none` and to `display: flex` inside `@media (min-width: 640px)`; `Base.rule(:auix_index_sort_menu)` sets `.auix-index-sort-menu` to `display: none` inside `@media (min-width: 640px)`; `Base.rule(:auix_index_sort_action)` keeps `.auix-index-sort-action` at `display: none` inside `@media (min-width: 768px)` and holds no `button` selector
- [x] AC-11: `Base.rule(:auix_index_sort_menu_list)` contains `top: 100%` and none of `bottom`, `left`, `right`; `Base.rule(:auix_index_sort_menu_toggle__active)` contains `.auix-index-sort-menu > .auix-index-sort-menu-toggle--active` and `color: var(--auix-color-icon-info)`; `Base.rule(:auix_index_sort_menu_check__off)` contains `visibility: hidden`; `Base.rule(:auix_index_sort_menu_group)` contains `.auix-index-sort-menu-group + .auix-index-sort-menu-group`
- [x] AC-12: At a 390px viewport the card view shows the sort icon button and no select; a tap opens the menu below the button with checks on the active field and direction; a tap on an option sorts and closes the menu; a tap outside closes it; the button is highlighted while a field sort is on; at a 700px viewport the select and the direction switch show and the icon button does not (manual — no red test; verified by `mix auix.gen.stylesheet`, then `iex -S mix run test/start_test_server.exs`, opening `/sortable-columns-products` in a browser at 390px and at 700px)

##### Test ports
- Route `"/sortable-columns-products"`, registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(SortableColumnsTest.Product, "sortable-columns-products")` · layout type `:index` · observable: `has_element?/2` under `[name='auix-sort_action-product']`, card order through the file's `mobile_name_cells/1`
- Route `"/ash-sortable-columns-authors"`, registered via `RoutesHelper.register_crud(AshSortableColumnsTest.Author, "ash-sortable-columns-authors")` · layout type `:index` · observable: card order through the file's `mobile_name_cells/1`
- Route `"/sort-disabled-products"`, registered via `RoutesHelper.register_crud(SortDisabledTest.Product, "sort-disabled-products")` · layout type `:index` · observable: `has_element?/2`, the file's `name_cells/1`
- No route: `live_isolated(conn, Host, …)` through `mount_components/2` in `test/cases_live/components_index_test.exs` · observable: `has_element?/2` under `#a` and `#b`
- No route: `Aurora.Uix.Templates.Basic.Themes.Base.rule/1` in `test/cases/templates/theme_rules_test.exs`

##### Markup changes — tests that drive the changed selectors
The select form and the direction switch move into a new `<div class="auix-index-sort-select">`; their ids, names and attributes stay. `rg -n "auix-sort-form|auix-sort_direction|auix-sort_action|auix-index-sort-action" test` returns hits in `test/cases_live/sortable_columns_test.exs`, `test/cases_live/ash_sortable_columns_test.exs`, `test/cases_live/sort_disabled_test.exs`, `test/cases_live/index_card_grid_test.exs` and `test/cases_live/index_card_content_test.exs`. Every hit selects by id, by `name` attribute and by class as a descendant, with no child combinator (`>`; the only `>` on those lines is the `|>` operator), so every drive stays as it is. The new option names start with `auix-sort_menu`, never `auix-sort-`, so `element(view, "button[name='auix-sort-name']")` in `test/cases_live/load_items_options_test.exs` and `sortable_columns_test.exs` still matches one element, and `refute has_element?(view, "button[name^='auix-sort-']")` in `sort_disabled_test.exs` still holds.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2 | add to `test/cases_live/sortable_columns_test.exs`, after `"the card sort select and direction switch sort, reverse and clear"` | `view = prepare_sort_test(conn)` | same | `"the card sort menu offers default order, the sortable fields and the directions"` | with `m = "[name='auix-sort_action-product']"`: `has_element?(view, "#{m} .auix-index-sort-select #auix-sort-form-product")`; `has_element?(view, "#{m} .auix-index-sort-select button[name='auix-sort_direction-product']")`; `has_element?(view, "#{m} [name='auix-sort_menu'] button[name='auix-sort_menu_toggle'][title='Sort'][aria-label='Sort'][aria-haspopup='menu'][aria-expanded='false'] span.hero-arrows-up-down")`; `refute has_element?(view, "#{m} .auix-index-sort-menu-toggle--active")`; `has_element?(view, "#{m} [name='auix-sort_menu_list'][role='menu'] button[name='auix-sort_menu_default'][role='menuitemradio'][aria-checked='true']", "Default order")`; `refute has_element?(view, "#{m} button[name='auix-sort_menu_default'] .auix-index-sort-menu-check--off")`; `for {key, label} <- [{"reference", "Reference"}, {"name", "Name"}], do: assert has_element?(view, "#{m} button[name='auix-sort_menu_field-#{key}'][role='menuitemradio'][aria-checked='false'] span.hero-check.auix-index-sort-menu-check--off", label)`; `for key <- ["cost", "description", "image", "selected_check__"], do: refute has_element?(view, "#{m} button[name='auix-sort_menu_field-#{key}']")`; `for {direction, label} <- [{"asc", "Ascending"}, {"desc", "Descending"}], do: assert has_element?(view, "#{m} button[name='auix-sort_menu_direction-#{direction}'][role='menuitemradio'][aria-checked='false'][disabled]", label)` |
| AC-3, AC-4, AC-5 | add to `test/cases_live/sortable_columns_test.exs`, after the row above; add the private helper `click_sort_menu/2` (new: `git grep -n click_sort_menu origin/main -- test` returns nothing) after `select_sort/2` | `view = prepare_sort_test(conn)`; `click_sort_menu/2` is `view \|> element("[name='auix-sort_action-product'] button[name='#{name}']") \|> render_click()`, returning `view`, with `@spec click_sort_menu(View.t(), binary()) :: View.t()` | same | `"the card sort menu sorts, sets the direction and clears"` | with `m = "[name='auix-sort_action-product']"`: `click_sort_menu(view, "auix-sort_menu_field-name")`; `assert mobile_name_cells(view) == ["Alpha", "Bravo", "Charlie"]`; `has_element?(view, "#{m} button[name='auix-sort_menu_toggle'].auix-index-sort-menu-toggle--active")`; `has_element?(view, "#{m} button[name='auix-sort_menu_field-name'][aria-checked='true']")`; `has_element?(view, "#{m} button[name='auix-sort_menu_default'][aria-checked='false']")`; `has_element?(view, "#{m} button[name='auix-sort_menu_direction-asc'][aria-checked='true']")`; `click_sort_menu(view, "auix-sort_menu_direction-desc")`; `== ["Charlie", "Bravo", "Alpha"]`; `has_element?(view, "#{m} button[name='auix-sort_menu_direction-desc'][aria-checked='true']")`; `has_element?(view, "#{m} button[name='auix-sort_menu_direction-asc'][aria-checked='false']")`; `click_sort_menu(view, "auix-sort_menu_direction-desc")`; `== ["Charlie", "Bravo", "Alpha"]`; `click_sort_menu(view, "auix-sort_menu_default")`; `== ["Charlie", "Alpha", "Bravo"]`; `refute has_element?(view, "#{m} .auix-index-sort-menu-toggle--active")`; `has_element?(view, "#{m} button[name='auix-sort_menu_direction-asc'][disabled]")` |
| AC-6 | add to `test/cases_live/sortable_columns_test.exs`, after the row above | `view = prepare_sort_test(conn)` | same | `"a menu direction without an active sort, or an unknown one, leaves the order"` | `render_click(view, "index-sort-direction", %{"direction" => "desc"})`; `assert mobile_name_cells(view) == ["Charlie", "Alpha", "Bravo"]`; `click_sort_menu(view, "auix-sort_menu_field-name")`; `render_click(view, "index-sort-direction", %{"direction" => "sideways"})`; `assert mobile_name_cells(view) == ["Alpha", "Bravo", "Charlie"]` |
| AC-7 | add to `test/cases_live/ash_sortable_columns_test.exs`, after `"the card sort select and direction switch sort, reverse and clear"`; add the private helper `click_sort_menu/2` after `select_sort/2`, as in the Ecto file with `[name='auix-sort_action-author']` | `view = prepare_sort_test(conn)` | same | `"the card sort menu sorts, sets the direction and clears"` | `click_sort_menu(view, "auix-sort_menu_field-name")`; `assert mobile_name_cells(view) == ["Alpha", "Bravo", "Charlie"]`; `click_sort_menu(view, "auix-sort_menu_direction-desc")`; `== ["Charlie", "Bravo", "Alpha"]`; `click_sort_menu(view, "auix-sort_menu_default")`; `== ["Charlie", "Alpha", "Bravo"]` |
| AC-8 | add to `test/cases_live/components_index_test.exs`, after `"an instance takes its page and its options"` | `sample_products(3)`; `{:ok, view, _html} = mount_components(conn, [%{module: C, id: "a", props: %{}}, %{module: C, id: "b", props: %{}}])` | same | `"the card sort menu sorts its own instance"` | `view \|> element("#a button[name='auix-sort_menu_field-reference']") \|> render_click()`; `assert has_element?(view, "#a button[name='auix-sort_menu_field-reference'][aria-checked='true']")`; `assert has_element?(view, "#b button[name='auix-sort_menu_field-reference'][aria-checked='false']")` |
| AC-9 | amend `test/cases_live/sort_disabled_test.exs` `"sort_disabled? removes the card sort control"` and `"a forged index-sort event is ignored when sorting is disabled"` | unchanged | same | both names unchanged | first test: add `refute has_element?(view, "[name='auix-sort_menu']")`. Second test: add `render_click(view, "index-sort-direction", %{"direction" => "desc"})` after the existing `render_click(view, "index-sort-direction", %{})`; its assertions stay |
| AC-10, AC-11 | add to `test/cases/templates/theme_rules_test.exs` a new `describe "sort control rules"` after `describe "card rules"` | none | same | `"swap the select for the menu at the sm breakpoint"` (AC-10); `"the sort menu opens below its button and marks the active sort"` (AC-11) | AC-10: `select = Base.rule(:auix_index_sort_select)`; `assert select =~ ~r/\.auix-index-sort-select \{\s*display: none;/`; `assert select =~ ~r/@media \(min-width: 640px\) \{\s*\.auix-index-sort-select \{\s*display: flex;/`; `assert Base.rule(:auix_index_sort_menu) =~ ~r/@media \(min-width: 640px\) \{\s*\.auix-index-sort-menu \{\s*display: none;/`; `action = Base.rule(:auix_index_sort_action)`; `assert action =~ ~r/@media \(min-width: 768px\) \{\s*\.auix-index-sort-action \{\s*display: none;/`; `refute action =~ "button"`. AC-11: `list = Base.rule(:auix_index_sort_menu_list)`; `assert list =~ "top: 100%"`; `refute list =~ "bottom"`; `refute list =~ "left"`; `refute list =~ "right"`; `active = Base.rule(:auix_index_sort_menu_toggle__active)`; `assert active =~ ".auix-index-sort-menu > .auix-index-sort-menu-toggle--active"`; `assert active =~ "color: var(--auix-color-icon-info)"`; `assert Base.rule(:auix_index_sort_menu_check__off) =~ "visibility: hidden"`; `assert Base.rule(:auix_index_sort_menu_group) =~ ".auix-index-sort-menu-group + .auix-index-sort-menu-group"` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Actions.Index` at `lib/aurora_uix/templates/basic/actions/index.ex` — modified.
   1. `@moduledoc` `## Key Features`: replace the line `` - Offers a card-view sort control (a select of default order plus the sortable fields, and a direction switch) `` with:
      ```
        - Offers a card-view sort control (a select of default order plus the sortable fields, and a direction switch; below the `sm` breakpoint, one icon button with a menu of the fields and directions)
      ```
   2. `sort_header_action/1` `@doc`: replace the two paragraphs from `Renders the sort control for the index card view: a select of "Default order" (the backend` through `` emits `"index-sort-direction"`. `` with, verbatim:
      ```
      Renders the sort control for the index card view. From the `sm` breakpoint up it is a select
      of "Default order" (the backend order, no user sort) and the sortable index fields, plus a
      switch button that reverses the direction of the active sort; the switch is disabled while
      the default order is shown. Below the `sm` breakpoint it is one icon button that opens a menu
      of "Default order", the sortable fields, "Ascending" and "Descending": a check marks the
      active field and direction, the directions are disabled while the default order is shown,
      and the button is highlighted while a field sort is on. The control shows below the `md`
      breakpoint; with the card's `show_on: :all` it shows at every breakpoint.

      The select and the menu's field options emit `"index-sort"` with `"sort"` set to the field
      key (`""` for "Default order"). The switch emits `"index-sort-direction"`; the menu's
      direction options emit it with `"direction"` set to `"asc"` and `"desc"`.
      ```
   3. `sort_header_action/1`, first clause (`def sort_header_action(%{auix: %{layout_options: %{sort_disabled?: false}} = auix} = assigns) do`): in the `assigns` pipeline, insert after `|> Map.put(:sort_icon, BasicHelpers.sort_icon(auix.sort && auix.sort.direction))`:
      ```elixir
      |> Map.put(:sort_direction, auix.sort && auix.sort.direction)
      |> Map.put(:menu_toggle_class, sort_menu_toggle_class(auix.sort))
      ```
   4. Same clause: replace the whole `~H"""…"""` template with, verbatim:
      ```heex
      <div :if={@sort_options != []} class={["auix-index-sort-action", @always? && "auix-index-sort-action--always"]} name={"auix-sort_action-#{@auix.module}"}>
        <div class="auix-index-sort-select">
          <.form for={%{}} id={BasicHelpers.instance_dom_id(@auix, "auix-sort-form")} phx-change="index-sort" phx-target={@auix[:_myself]}>
            <.input type="select" id={BasicHelpers.instance_dom_id(@auix, "auix-sort-key")} name="sort"
                options={@sort_options}
                value={@sort_key}
                prompt={dt("Default order")}
                omit_label?={true} />
          </.form>
          <.button type="button" class="auix-button--alt"
              name={"auix-sort_direction-#{@auix.module}"}
              disabled={is_nil(@auix.sort)}
              phx-click="index-sort-direction"
              phx-target={@auix[:_myself]}
              aria-label={dt("Reverse sort direction")}>
            <.icon name={@sort_icon} />
          </.button>
        </div>
        <div class="auix-index-sort-menu" name="auix-sort_menu"
            phx-click={toggle_sort_menu()} phx-click-away={hide_sort_menu()}>
          <.button type="button" class={@menu_toggle_class} name="auix-sort_menu_toggle"
              title={dt("Sort")} aria-label={dt("Sort")} aria-haspopup="menu" aria-expanded="false">
            <.icon name="hero-arrows-up-down" />
          </.button>
          <div class="auix-index-sort-menu-list" name="auix-sort_menu_list" role="menu">
            <div class="auix-index-sort-menu-group" role="group" aria-label={dt("Sort by")}>
              <.button type="button" class="auix-index-sort-menu-item" name="auix-sort_menu_default"
                  role="menuitemradio" aria-checked={to_string(is_nil(@auix.sort))}
                  phx-click={push_sort_menu(@auix, "index-sort", %{sort: ""})}>
                <.icon name="hero-check" class={sort_menu_check_class(is_nil(@auix.sort))} />
                {dt("Default order")}
              </.button>
              <.button :for={{label, key} <- @sort_options} type="button" class="auix-index-sort-menu-item"
                  name={"auix-sort_menu_field-#{key}"}
                  role="menuitemradio" aria-checked={to_string(@sort_key == key)}
                  phx-click={push_sort_menu(@auix, "index-sort", %{sort: key})}>
                <.icon name="hero-check" class={sort_menu_check_class(@sort_key == key)} />
                {label}
              </.button>
            </div>
            <div class="auix-index-sort-menu-group" role="group" aria-label={dt("Sort direction")}>
              <.button type="button" class="auix-index-sort-menu-item" name="auix-sort_menu_direction-asc"
                  role="menuitemradio" aria-checked={to_string(@sort_direction == :asc)}
                  disabled={is_nil(@auix.sort)}
                  phx-click={push_sort_menu(@auix, "index-sort-direction", %{direction: "asc"})}>
                <.icon name="hero-check" class={sort_menu_check_class(@sort_direction == :asc)} />
                {dt("Ascending")}
              </.button>
              <.button type="button" class="auix-index-sort-menu-item" name="auix-sort_menu_direction-desc"
                  role="menuitemradio" aria-checked={to_string(@sort_direction == :desc)}
                  disabled={is_nil(@auix.sort)}
                  phx-click={push_sort_menu(@auix, "index-sort-direction", %{direction: "desc"})}>
                <.icon name="hero-check" class={sort_menu_check_class(@sort_direction == :desc)} />
                {dt("Descending")}
              </.button>
            </div>
          </div>
        </div>
      </div>
      ```
   5. New private functions, placed after `put_action/3` (new: `git grep -n -E "sort_menu|sort-menu|sort_select|sort-select" origin/main -- lib test guides` returns nothing):
      ```elixir
      # The class of the sort menu button; highlighted while a field sort is on
      @spec sort_menu_toggle_class(map() | nil) :: binary()
      defp sort_menu_toggle_class(nil), do: "auix-button--iconized"

      defp sort_menu_toggle_class(_sort),
        do: "auix-button--iconized auix-index-sort-menu-toggle--active"

      # The class of a sort menu option's check; an inactive option keeps it invisible
      @spec sort_menu_check_class(boolean()) :: binary() | nil
      defp sort_menu_check_class(true), do: nil
      defp sort_menu_check_class(false), do: "auix-index-sort-menu-check--off"

      # Opens or closes the sort menu, addressed relative to the menu element
      @spec toggle_sort_menu() :: JS.t()
      defp toggle_sort_menu do
        %JS{}
        |> JS.toggle(to: {:inner, "[name='auix-sort_menu_list']"}, display: "flex")
        |> JS.toggle_attribute({"aria-expanded", "true", "false"},
          to: {:inner, "[name='auix-sort_menu_toggle']"}
        )
        |> JS.focus_first(to: {:inner, "[name='auix-sort_menu_list']"})
      end

      # Closes the sort menu, addressed relative to the menu element
      @spec hide_sort_menu() :: JS.t()
      defp hide_sort_menu do
        %JS{}
        |> JS.hide(to: {:inner, "[name='auix-sort_menu_list']"})
        |> JS.set_attribute({"aria-expanded", "false"},
          to: {:inner, "[name='auix-sort_menu_toggle']"}
        )
      end

      # Pushes a sort event from a sort menu option, then runs the menu's own hide
      @spec push_sort_menu(map(), binary(), map()) :: JS.t()
      defp push_sort_menu(auix, event, value) do
        event
        |> JS.push(BasicHelpers.target_opts(auix, value: value))
        |> JS.exec("phx-click-away", to: {:closest, "[name='auix-sort_menu']"})
      end
      ```
   6. `JS` is already aliased (`alias Phoenix.LiveView.JS`); no new alias.
2. `Aurora.Uix.Templates.Basic.Handlers.IndexList` at `lib/aurora_uix/templates/basic/handlers/index_list.ex` — modified.
   1. Insert this clause directly before `def handle_event("index-sort-direction", _params, %{assigns: %{auix: auix}} = socket) do`, so the flip clause stays last for the event:
      ```elixir
      # Card view menu: "asc" or "desc" sets the direction of the active sort.
      def handle_event(
            "index-sort-direction",
            %{"direction" => direction},
            %{assigns: %{auix: auix}} = socket
          ) do
        case {auix.sort, to_direction(direction)} do
          {nil, _direction} -> {:noreply, socket}
          {_sort, nil} -> {:noreply, socket}
          {sort, new_direction} -> {:noreply, apply_sort(socket, %{sort | direction: new_direction})}
        end
      end
      ```
   2. Insert after `defp flip(:desc), do: :asc` (new: `git grep -n -E "\bto_direction\b" origin/main -- lib test` returns nothing):
      ```elixir

      @spec to_direction(term()) :: :asc | :desc | nil
      defp to_direction("asc"), do: :asc
      defp to_direction("desc"), do: :desc
      defp to_direction(_direction), do: nil
      ```
   3. `events/0` and the `@moduledoc` stay: the event list is unchanged.
3. Theme: `lib/aurora_uix/templates/basic/themes/base.ex` — modified.
   1. Replace the whole `rule(:auix_index_sort_action, """…""")` clause with:
      ```elixir
      rule(:auix_index_sort_action, """
        .auix-index-sort-action {
          display: flex;
          flex-direction: row;
          align-items: stretch;
        }

        @media (min-width: #{breakpoint(:md)}) {
          .auix-index-sort-action {
            display: none;
          }
        }
      """)
      ```
   2. `rule(:auix_index_sort_action__always, …)` stays as it is.
   3. Insert after `rule(:auix_index_sort_action__always, …)`, before `rule(:auix_index_select_actions, …)`:
      ```elixir
      rule(:auix_index_sort_select, """
        .auix-index-sort-select {
          display: none;
          flex-direction: row;
          align-items: stretch;
          gap: var(--auix-gap-minimal);
        }

        .auix-index-sort-select form,
        .auix-index-sort-select .auix-fieldset {
          display: flex;
          margin: 0;
          padding: 0;
        }

        /* The hero icon keeps its own 1.5rem box, so the switch drops its vertical padding and
           stretches to the select height, matching the other header buttons. */
        .auix-index-sort-select > button {
          padding-top: 0;
          padding-bottom: 0;
          justify-content: center;
        }

        .auix-index-sort-select .auix-select {
          box-sizing: border-box;
          font-size: var(--auix-font-size-caption);
          font-weight: var(--auix-font-weight-bold);
        }

        @media (min-width: #{breakpoint(:sm)}) {
          .auix-index-sort-select {
            display: flex;
          }
        }
      """)

      rule(:auix_index_sort_menu, """
        .auix-index-sort-menu {
          position: relative;
          display: inline-flex;
          flex-shrink: 0;
        }

        .auix-index-sort-menu > button {
          min-width: var(--auix-touch-target-size);
          min-height: var(--auix-touch-target-size);
          justify-content: center;
        }

        @media (min-width: #{breakpoint(:sm)}) {
          .auix-index-sort-menu {
            display: none;
          }
        }
      """)

      rule(:auix_index_sort_menu_toggle__active, """
        .auix-index-sort-menu > .auix-index-sort-menu-toggle--active {
          color: var(--auix-color-icon-info);
          background-color: var(--auix-color-bg-secondary);
        }
      """)

      rule(:auix_index_sort_menu_list, """
        .auix-index-sort-menu-list {
          display: none;
          position: absolute;
          inset-inline-end: 0;
          top: 100%;
          z-index: 10;
          flex-direction: column;
          min-width: max-content;
          border-width: var(--auix-border-width-default);
          border-style: var(--auix-border-style-default);
          border-color: var(--auix-color-border-primary);
          border-radius: var(--auix-border-radius-default);
          background-color: var(--auix-color-bg-default);
          box-shadow: var(--auix-shadow-md);
        }
      """)

      rule(:auix_index_sort_menu_group, """
        .auix-index-sort-menu-group {
          display: flex;
          flex-direction: column;
        }

        .auix-index-sort-menu-group + .auix-index-sort-menu-group {
          border-top-width: var(--auix-border-width-default);
          border-top-style: var(--auix-border-style-default);
          border-top-color: var(--auix-color-border-primary);
        }
      """)

      rule(:auix_index_sort_menu_item, """
        .auix-index-sort-menu-item {
          display: flex;
          flex-direction: row;
          align-items: center;
          gap: var(--auix-gap-default);
          min-height: var(--auix-touch-target-size);
          padding-inline: var(--auix-padding-default);
          border: none;
          background-color: transparent;
          color: inherit;
          font-size: var(--auix-font-size-caption);
          white-space: nowrap;
          cursor: pointer;
        }

        .auix-index-sort-menu-item:hover {
          background-color: var(--auix-color-bg-hover);
        }

        .auix-index-sort-menu-item:disabled {
          background-color: transparent;
          color: var(--auix-color-text-inactive);
          cursor: default;
        }
      """)

      rule(:auix_index_sort_menu_check__off, """
        .auix-index-sort-menu-check--off {
          visibility: hidden;
        }
      """)
      ```
   4. Run `mix auix.gen.tailwind_classes` and commit the regenerated `priv/static/classes.js` (it gains `hero-arrows-up-down`). Run `mix auix.gen.stylesheet` for the AC-12 check; its `assets/css/auix-*.css` output is gitignored.
4. Components: reused `<.button>`, `<.icon>`, `<.form>`, `<.input>` from `core_components.ex`; no new component, no LiveComponent, no hook.
5. `dt/1` strings: `Sort`, `Sort by`, `Sort direction`, `Ascending`, `Descending` (new); `Default order`, `Reverse sort direction` (existing).

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- A CHANGELOG entry: the sort menu is a UI change, neither a feature nor a fix.
- The sort control from the `sm` breakpoint up: the field select and the direction switch keep their markup and behaviour.
- The table view's sortable column headers.
- An `action_icons:` key for the sort menu button: its icon is fixed, like the direction switch's.
- One-to-many lists: they render no sort control.
<!-- enriched-spec:end -->
