<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
The card view's sort menu and the card ⋮ menu open through a theme rule on their toggle's `aria-expanded="true"`, not through an inline `display: flex` from `JS.toggle`, so a host rule can restyle either menu open. The rules that select the direction switch, the two menu toggles, a card menu item's action and a card's tap target by tag name now select them by an `auix-*` class: three new classes for the buttons, and the existing `auix-index-row-action` on every default row action, with the tag selectors kept as a fallback for host actions. The work is backend-agnostic action, component and theme code and covers Ash and Ecto resources alike. The issue owes no CHANGELOG entry: the menu open state and the new classes are a UI change, neither a feature nor a fix.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | guides/customization/custom_actions.md § Row actions in cards · guides/customization/styling.md § Class reference | none | federico/538-doc-1-theming-gaps | docs: theme-driven menus and classes for the sort control and index cards (#538 · DOC-1) |
| UI-1 | UI | action + component + theme · sort control (`sort_header_action/1`), card menu (`card_menu/1`), default row actions (index, one-to-many) | DOC-1 | federico/538-ui-1-theming-gaps | feat: theme-driven menus and classes for the sort control and index cards (#538 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `guides/customization/custom_actions.md § Row actions in cards`
- `guides/customization/styling.md § Class reference`

#### Implementation details

`CHANGELOG.md` is not edited: it stays byte for byte as on `origin/main`. The issue owes no CHANGELOG entry.

##### guides/customization/custom_actions.md
1. § `Row actions in cards` — after the paragraph
   ```
   An action that replaces `:default_row_delete` stays destructive unless it says
   `destructive?: false`. Each menu item gets a 44px touch target. The default row actions carry
   their label as `title` and `aria-label`; give your own action both, as
   [Custom actions on mobile](#custom-actions-on-mobile) shows.
   ```
   insert one blank line and this paragraph, verbatim:
   ```
   The default row actions carry the `auix-index-row-action` class, which the card menu and the
   card's tap target style. Give your own action the class to style it the same way. Without it,
   the menu styles the action's top `a` and `button` elements, and the tap target its top element.
   ```

##### guides/customization/styling.md
All edits are rows of the table under § `Class reference`. Each replacement swaps one whole row; each insertion adds one row directly below the named row.

1. Below the row that starts `` | `.auix-index-sort-select` | ``, insert verbatim:
   ```
   | `.auix-index-sort-select-direction` | Direction switch button of the card-view sort control, stretched to the select height | Structural only |
   ```
2. Replace the row
   ```
   | `.auix-index-sort-menu` | Icon button and menu of the card-view sort control; shown below the `sm` breakpoint | `--auix-touch-target-size` |
   ```
   with, verbatim:
   ```
   | `.auix-index-sort-menu` | Icon button and menu of the card-view sort control; shown below the `sm` breakpoint | Structural only |
   | `.auix-index-sort-menu-toggle` | Icon button that opens and closes the sort menu; its `aria-expanded` drives the open state | `--auix-touch-target-size` |
   ```
3. Replace the row that starts `` | `.auix-index-sort-menu-list` | `` with, verbatim:
   ```
   | `.auix-index-sort-menu-list` | Sort menu, opening below its button; hidden until `.auix-index-sort-menu-toggle` has `aria-expanded="true"` | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-border-primary`, `--auix-border-radius-default`, `--auix-color-bg-default`, `--auix-shadow-md` |
   ```
4. Replace the row that starts `` | `.auix-items-card-show` | `` with, verbatim:
   ```
   | `.auix-items-card-show` | Tap target of a card: the show action, stretched over the card and transparent; the action is matched as `.auix-index-row-action`, else as any child element | Structural only |
   ```
5. Replace the row
   ```
   | `.auix-items-card-menu` | ⋮ menu toggle at the end of the card header; hidden when no menu item renders | `--auix-touch-target-size` |
   ```
   with, verbatim:
   ```
   | `.auix-items-card-menu` | ⋮ menu at the end of the card header: its toggle and its list; hidden when no menu item renders | Structural only |
   | `.auix-items-card-menu-toggle` | ⋮ button that opens and closes the card menu; its `aria-expanded` drives the open state | `--auix-touch-target-size` |
   ```
6. Replace the row that starts `` | `.auix-items-card-menu-list` | `` with, verbatim:
   ```
   | `.auix-items-card-menu-list` | Row-action menu of the card header, opening below the toggle; hidden until `.auix-items-card-menu-toggle` has `aria-expanded="true"` | `--auix-color-bg-default`, `--auix-color-border-primary`, `--auix-border-radius-default`, `--auix-shadow-md` |
   ```
7. Replace the row that starts `` | `.auix-items-card-menu-item` | `` with, verbatim:
   ```
   | `.auix-items-card-menu-item` | One row action in the card menu; hidden when it renders nothing. Its action gets the touch target as `.auix-index-row-action`, else as an `a` element, else as a `button` element | `--auix-touch-target-size` |
   | `.auix-index-row-action` | Every default row action link (index and one-to-many): a touch target in the card menu, and the card's tap target as the show action | `--auix-touch-target-size` |
   ```

##### Acceptance criteria
- [x] AC-1: `CHANGELOG.md` is unchanged: the issue owes no CHANGELOG entry (mechanical — no red
      test; verified by `git diff --name-only origin/main...HEAD -- CHANGELOG.md` printing nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-538-enriched-spec.md`)
- [x] AC-3: `guides/customization/custom_actions.md § Row actions in cards` names the row action class (mechanical — no red test; verified by
      ``grep -c 'The default row actions carry the `auix-index-row-action` class' guides/customization/custom_actions.md`` returning 1)
- [x] AC-4: `guides/customization/styling.md § Class reference` lists the four classes and the open state (mechanical — no red test; verified by
      ``grep -cE '^\| `\.(auix-index-sort-select-direction|auix-index-sort-menu-toggle|auix-items-card-menu-toggle|auix-index-row-action)` \|' guides/customization/styling.md`` returning 4 and
      ``grep -c 'has `aria-expanded="true"`' guides/customization/styling.md`` returning 2)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · action + component + theme: menu open state and button classes
Depends on: DOC-1

#### Documentation references
- `guides/customization/styling.md § Class reference` (DOC-1)
- `guides/customization/custom_actions.md § Row actions in cards` (DOC-1)

#### Implementation details

Layout types: `:index` (the card-view sort control and the index cards), and the one-to-many list of `:form` and `:show` parents, which renders through the same `auix_items_card/1` (`Aurora.Uix.Templates.Basic.Renderers.OneToMany` `child_rows/1`). `edit_child_action/1` and `delete_child_action/1` render `~H""` outside a `:form` parent, so in a `:show` parent only the show link carries the class. The table view (`auix_items_table/1`) keeps its look: the rule `rule(:auix_index_row_action, …)` stays the empty `.auix-index-row-action{ }`, and every new selector is scoped under `.auix-items-card-menu-item`, `.auix-items-card-show`, `.auix-index-sort-select`, `.auix-index-sort-menu` and `.auix-items-card-menu`.

Facts this section builds on:
- `JS.toggle_attribute({"aria-expanded", "true", "false"}, …)` already runs before `JS.focus_first/1` in both toggles. LiveView's `focus_first` focuses through `el.focus()` (`ARIA.attemptFocus` in `deps/phoenix_live_view/priv/static/phoenix_live_view.js`), which recomputes styles, so the list the attribute change just opened is focusable.
- `Aurora.Uix.Templates.ThemeHelper` `style/2` passes every rule through `Aurora.Uix.Templates.CssSanitizer` `sanitize_css/1`. That function keeps an attribute selector and the `~` combinator: on `Base.rule(:auix_index_sort_menu_list)` with the open-state block below appended, it returns a string containing `.auix-index-sort-menu-toggle[aria-expanded="true"] ~ .auix-index-sort-menu-list { display: flex; }`; the card rule behaves the same.
- `Aurora.Uix.Templates.Basic.RoutingComponents` `auix_link/1` declares `attr(:rest, :global, include: ~w(class name download href lang referrer policy rel target type))`, so a `class` reaches the rendered `<a>` in all three clauses. `Phoenix.Component.link/1` (used by `delete_child_action/1`) takes `class` as a global attribute.
- `Aurora.Uix.Templates.Basic.CoreComponents` `button/1` renders `class={["auix-button-default", @class]}`, so a space-separated class string reaches the `<button>`.
- The new selectors are parent-qualified (`.auix-a > .auix-b`, specificity 0,2,0), at least as specific as the tag selectors they replace (`.auix-a > button`, 0,1,1). New names: `rg -n 'auix-index-sort-menu-toggle[^-]|auix-index-sort-select-direction|auix-items-card-menu-toggle|aria-expanded="true"' lib test guides CHANGELOG.md` returns nothing.

##### Acceptance criteria
- [ ] AC-1: Given `SortableColumnsTest` at `/sortable-columns-products`, the direction switch is `[name='auix-sort_action-product'] .auix-index-sort-select > button.auix-index-sort-select-direction[name='auix-sort_direction-product']`
- [ ] AC-2: In that view the sort menu toggle is `[name='auix-sort_menu'] > button.auix-index-sort-menu-toggle[name='auix-sort_menu_toggle']` with `aria-expanded='false'` and without `auix-index-sort-menu-toggle--active`; after the menu option `auix-sort_menu_field-name` is clicked, it carries both `auix-index-sort-menu-toggle` and `auix-index-sort-menu-toggle--active`
- [ ] AC-3: In that view the `phx-click` of `[name='auix-sort_menu']` holds the `"toggle_attr"` and `"focus_first"` commands and no `"toggle"` command, and its `phx-click-away` holds the `"set_attr"` command and no `"hide"` command
- [ ] AC-4: Given `IndexCardFrameTest` at `/index-card-frame-products`, each card's menu toggle is `[name='auix-card-menu'] > button.auix-items-card-menu-toggle[name='auix-card-menu-toggle']` with `aria-expanded='false'`; the `phx-click` of `[name='auix-card-menu']` holds `"toggle_attr"` and `"focus_first"` and no `"toggle"`, and its `phx-click-away` holds `"set_attr"` and no `"hide"`
- [ ] AC-5: In that view the default show, edit and delete actions in the card menu, and the show action of the tap target `[name='auix-card-show']`, are `a.auix-index-row-action`
- [ ] AC-6: Given the product edit form at `/association/one_to_many/layout/products/<id>/edit` with transactions, each child card of `div[name='auix-one_to_many-product']` has `a.auix-index-row-action` for the show link of its tap target, and for the show and edit links of its menu's actions group and the delete link of its destructive group
- [ ] AC-7: Host row actions keep their markup: given `IndexCardActionsTest` at `/index-card-actions-products`, `a[name='auix-copy-product']` and `a[name='auix-archive-product']` carry no `auix-index-row-action` class, while `a[name='auix-delete-product']` carries it
- [ ] AC-8: The card rules key the actions on the row action class and keep the tag fallbacks: `Base.rule(:auix_items_card_menu_item)` contains `.auix-items-card-menu-item > .auix-index-row-action`, `.auix-items-card-menu-item > a` and `.auix-items-card-menu-item > button`; `Base.rule(:auix_items_card_show)` contains `.auix-items-card-show > .auix-index-row-action` and `.auix-items-card-show > *`
- [ ] AC-9: The toggle and switch rules select by class: `Base.rule(:auix_items_card_menu)` contains `.auix-items-card-menu > .auix-items-card-menu-toggle`, `Base.rule(:auix_index_sort_menu)` contains `.auix-index-sort-menu > .auix-index-sort-menu-toggle`, `Base.rule(:auix_index_sort_select)` contains `.auix-index-sort-select > .auix-index-sort-select-direction`, and none of the three contains `> button`
- [ ] AC-10: The open state is a theme rule that survives sanitizing: `Base.rule(:auix_index_sort_menu_list)` still starts the list at `display: none` and contains `.auix-index-sort-menu-toggle[aria-expanded="true"] ~ .auix-index-sort-menu-list` followed by `display: flex`; `Base.rule(:auix_items_card_menu_list)` does the same with `.auix-items-card-menu-toggle[aria-expanded="true"] ~ .auix-items-card-menu-list`; `CssSanitizer.sanitize_css/1` of each rule keeps that selector with `{ display: flex; }`
- [ ] AC-11: At a 390px viewport, after `mix auix.gen.stylesheet`: a tap on the sort menu button opens the menu with focus on its first item, a second tap closes it, a tap elsewhere closes it, and `aria-expanded` follows each step; the card ⋮ menu behaves the same; an unlayered host rule `.auix-items-card-menu-toggle[aria-expanded="true"] ~ .auix-items-card-menu-list { display: grid; }` changes the open card menu's `display` (manual — no red test; verified by `iex -S mix run test/start_test_server.exs`, opening `/index-card-frame-products` and `/sortable-columns-products` in a browser at 390px with the developer tools)

##### Test ports
- Route `"/sortable-columns-products"`, registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(SortableColumnsTest.Product, "sortable-columns-products")` · layout type `:index` · observable: `has_element?/2` under `[name='auix-sort_action-product']`
- Route `"/index-card-frame-products"`, registered via `RoutesHelper.register_crud(IndexCardFrameTest.Product, "index-card-frame-products")` · layout type `:index` · observable: `has_element?/2` under `#auix-table-index-card-frame-products-index-mobile`
- Route `"/index-card-actions-products"`, registered via `RoutesHelper.register_crud(IndexCardActionsTest.Product, "index-card-actions-products")` · layout type `:index` · observable: `has_element?/2` under `#auix-table-index-card-actions-products-index-mobile`
- Route `"/association/one_to_many/layout/products/:id/edit"`, registered via `RoutesHelper.register_product_crud(AssociationOne2ManyUILayoutTest, "association/one_to_many/layout/")` · layout type `:form` (parent) · observable: `has_element?/2` under `div[name='auix-one_to_many-product']`
- No route: `Aurora.Uix.Templates.Basic.Themes.Base.rule/1` and `Aurora.Uix.Templates.CssSanitizer.sanitize_css/1` in `test/cases/templates/theme_rules_test.exs`

A JS command list is checked through the attribute that carries it: `has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click*='"toggle_attr"']))`. LiveViewTest decodes the attribute's entities, and `[attr*='"toggle"']` matches the `toggle` command without matching `toggle_attr`.

##### Markup changes — tests that drive the changed selectors
This section adds classes and changes the JS command lists; it removes no class, `name` nor `aria-*` attribute. `rg -n "auix-sort_menu|auix-card-menu|auix-sort_direction|auix-delete-|auix-show-|auix-edit-" test` returns only attribute and descendant selectors, each of which still matches. `rg -n "phx-click" test/cases_live` returns no selector on `[name='auix-sort_menu']` nor `[name='auix-card-menu']`. No existing test changes its drive; the tests amended below only gain assertions.

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2 (no sort), AC-3 | amend `test/cases_live/sortable_columns_test.exs` `"the card sort menu offers default order, the sortable fields and the directions"` | `view = prepare_sort_test(conn)`; `m = "[name='auix-sort_action-product']"`, as today | same | same | replace the selector `"#{m} .auix-index-sort-select button[name='auix-sort_direction-product']"` with `"#{m} .auix-index-sort-select > button.auix-index-sort-select-direction[name='auix-sort_direction-product']"`; replace `"#{m} [name='auix-sort_menu'] button[name='auix-sort_menu_toggle'][title='Sort']…"` with `"#{m} [name='auix-sort_menu'] > button.auix-index-sort-menu-toggle[name='auix-sort_menu_toggle'][title='Sort'][aria-label='Sort'][aria-haspopup='menu'][aria-expanded='false'] span.hero-arrows-up-down"`; after `refute has_element?(view, "#{m} .auix-index-sort-menu-toggle--active")` add `assert has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click*='"toggle_attr"'][phx-click*='"focus_first"']))`, `refute has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click*='"toggle"']))`, `assert has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click-away*='"set_attr"']))`, `refute has_element?(view, ~s(#{m} [name='auix-sort_menu'][phx-click-away*='"hide"']))` |
| AC-2 (active sort) | amend `test/cases_live/sortable_columns_test.exs` `"the card sort menu sorts, sets the direction and clears"` | as today | same | same | replace the selector `"#{m} button[name='auix-sort_menu_toggle'].auix-index-sort-menu-toggle--active"` with `"#{m} button[name='auix-sort_menu_toggle'].auix-index-sort-menu-toggle.auix-index-sort-menu-toggle--active"` |
| AC-4 | add to `test/cases_live/index_card_frame_test.exs`, `describe "card frame"` | the describe's setup, unchanged | same | `"the card menu opens through its toggle's aria-expanded"` | with `m = @mobile` and `menu = "#{m} [name='auix-card-menu']"`: `assert has_element?(view, "#{menu} > button.auix-items-card-menu-toggle[name='auix-card-menu-toggle'][aria-expanded='false']")`; `assert has_element?(view, ~s(#{menu}[phx-click*='"toggle_attr"'][phx-click*='"focus_first"']))`; `refute has_element?(view, ~s(#{menu}[phx-click*='"toggle"']))`; `assert has_element?(view, ~s(#{menu}[phx-click-away*='"set_attr"']))`; `refute has_element?(view, ~s(#{menu}[phx-click-away*='"hide"']))` |
| AC-5 | amend `test/cases_live/index_card_frame_test.exs` `"default row actions sit in the header menu"` and `"tapping a card runs its show action"` | the describe's setup, unchanged | same | same | in the first test, in the three selectors ending `a[name='auix-show-product'][title='Show'][aria-label='Show']`, `a[name='auix-edit-product'][title='Edit'][aria-label='Edit']` and `a[name='auix-delete-product'][title='Delete'][aria-label='Delete']`, replace `a[name=` with `a.auix-index-row-action[name=`; in the second test, replace the first selector with `"#{m} [name='auix-card'] > [name='auix-card-show']:first-child > a.auix-index-row-action[name='auix-show-product'][title='Show'][aria-label='Show']"` |
| AC-6 | add to `test/cases_live/association_one2many_ui_layout_test.exs`, after `"Test order_by"` | `delete_all_inventory_data()`; `product_id = 1 \|> create_sample_products_with_transactions(3, :test) \|> List.first() \|> elem(1) \|> Map.get(:id)`; `{:ok, view, _html} = live(conn, "/association/one_to_many/layout/products/#{product_id}/edit")` | same | `"default child actions carry the row action class"` | with `c = "div[name='auix-one_to_many-product'] [name='auix-card']"`: `assert has_element?(view, "#{c} > [name='auix-card-show']:first-child > a.auix-index-row-action[name^='auix-show-product__product_transaction-']")`; `assert has_element?(view, "#{c} [name='auix-card-menu-actions'] a.auix-index-row-action[name^='auix-show-product__product_transaction-']")`; `assert has_element?(view, "#{c} [name='auix-card-menu-actions'] a.auix-index-row-action[name^='auix-edit-product__product_transaction-']")`; `assert has_element?(view, "#{c} [name='auix-card-menu-destructive'] a.auix-index-row-action[name^='auix-delete-product__product_transaction-']")` |
| AC-7 | amend `test/cases_live/index_card_actions_test.exs` `"the menu lists the row actions in order, destructive last"` | as today | same | same | after the existing assertions add `refute has_element?(view, "#{m} a.auix-index-row-action[name='auix-copy-product']")`; `refute has_element?(view, "#{m} a.auix-index-row-action[name='auix-archive-product']")`; `assert has_element?(view, "#{m} [name='auix-card-menu-destructive'] > .auix-items-card-menu-item:nth-child(2) a.auix-index-row-action[name='auix-delete-product']")` |
| AC-8 | add to `test/cases/templates/theme_rules_test.exs`, `describe "card rules"` | none | same | `"key the card actions on the row action class, tags as fallback"` | `item = Base.rule(:auix_items_card_menu_item)`; `assert item =~ ".auix-items-card-menu-item > .auix-index-row-action"`; `assert item =~ ".auix-items-card-menu-item > a"`; `assert item =~ ".auix-items-card-menu-item > button"`; `show = Base.rule(:auix_items_card_show)`; `assert show =~ ".auix-items-card-show > .auix-index-row-action"`; `assert show =~ ".auix-items-card-show > *"` |
| AC-9 | add to `test/cases/templates/theme_rules_test.exs`, `describe "sort control rules"` | none | same | `"select the toggles and the switch by class"` | `for {name, selector} <- [{:auix_items_card_menu, ".auix-items-card-menu > .auix-items-card-menu-toggle"}, {:auix_index_sort_menu, ".auix-index-sort-menu > .auix-index-sort-menu-toggle"}, {:auix_index_sort_select, ".auix-index-sort-select > .auix-index-sort-select-direction"}] do assert Base.rule(name) =~ selector; refute Base.rule(name) =~ "> button" end` |
| AC-10 | add to `test/cases/templates/theme_rules_test.exs`, `describe "sort control rules"`; add `alias Aurora.Uix.Templates.CssSanitizer` after `alias Aurora.Uix.Templates.Basic.Themes.WhiteCharcoal` | none | same | `"open both menus from the toggle's aria-expanded"` | `for {name, base} <- [{:auix_index_sort_menu_list, "auix-index-sort-menu"}, {:auix_items_card_menu_list, "auix-items-card-menu"}] do rule = Base.rule(name); open = ~s(.#{base}-toggle[aria-expanded="true"] ~ .#{base}-list); assert rule =~ ~r/\.#{base}-list \{\s*display: none;/; assert rule =~ ~r/#{Regex.escape(open)} \{\s*display: flex;/; assert CssSanitizer.sanitize_css(rule) =~ "#{open} { display: flex; }" end` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Actions.Index` at `lib/aurora_uix/templates/basic/actions/index.ex` — modified.
   - `sort_header_action/1`, clause head `def sort_header_action(%{auix: %{layout_options: %{sort_disabled?: false}} = auix} = assigns) do`: in the direction switch, replace `<.button type="button" class="auix-button--alt"` with `<.button type="button" class="auix-button--alt auix-index-sort-select-direction"`.
   - `remove_row_action/1`: replace the line `      <.auix_link` (the opening of the link in its `~H`) with `      <.auix_link class="auix-index-row-action"`. `show_row_action/1` and `edit_row_action/1` already carry the class in both clauses and stay as they are.
   - `sort_menu_toggle_class/1`: replace the two clauses with
     ```elixir
     defp sort_menu_toggle_class(nil), do: "auix-button--iconized auix-index-sort-menu-toggle"

     defp sort_menu_toggle_class(_sort),
       do: "auix-button--iconized auix-index-sort-menu-toggle auix-index-sort-menu-toggle--active"
     ```
     Its comment line and `@spec` stay.
   - `toggle_sort_menu/0`: replace its body with
     ```elixir
     %JS{}
     |> JS.toggle_attribute({"aria-expanded", "true", "false"},
       to: {:inner, "[name='auix-sort_menu_toggle']"}
     )
     |> JS.focus_first(to: {:inner, "[name='auix-sort_menu_list']"})
     ```
   - `hide_sort_menu/0`: replace its body with
     ```elixir
     JS.set_attribute(%JS{}, {"aria-expanded", "false"},
       to: {:inner, "[name='auix-sort_menu_toggle']"}
     )
     ```
2. `Aurora.Uix.Templates.Basic.Components` at `lib/aurora_uix/templates/basic/components/components.ex` — modified.
   - `card_menu/1`: replace `<.button type="button" class="auix-button--iconized" name="auix-card-menu-toggle"` with `<.button type="button" class="auix-button--iconized auix-items-card-menu-toggle" name="auix-card-menu-toggle"`.
   - `toggle_card_menu/0`: replace its body with
     ```elixir
     %JS{}
     |> JS.toggle_attribute({"aria-expanded", "true", "false"},
       to: {:inner, "[name='auix-card-menu-toggle']"}
     )
     |> JS.focus_first(to: {:inner, "[name='auix-card-menu-list']"})
     ```
   - `hide_card_menu/0`: replace its body with
     ```elixir
     JS.set_attribute(%JS{}, {"aria-expanded", "false"},
       to: {:inner, "[name='auix-card-menu-toggle']"}
     )
     ```
3. `Aurora.Uix.Templates.Basic.Actions.OneToMany` at `lib/aurora_uix/templates/basic/actions/one_to_many.ex` — modified.
   - `show_child_action/1`, clause `def show_child_action(assigns) do`: replace `<.auix_link navigate={"/#{@auix.association.related_parsed_opts.uri_path}/#{elem(@auix.row_info, 0)}/show"}` with `<.auix_link class="auix-index-row-action" navigate={"/#{@auix.association.related_parsed_opts.uri_path}/#{elem(@auix.row_info, 0)}/show"}`.
   - `edit_child_action/1`, clause `def edit_child_action(%{auix: %{layout_type: :form}} = assigns) do`: replace `<.auix_link navigate={"/#{@auix.association.related_parsed_opts.uri_path}/#{elem(@auix.row_info, 0)}/edit?related_key=` with `<.auix_link class="auix-index-row-action" navigate={"/#{@auix.association.related_parsed_opts.uri_path}/#{elem(@auix.row_info, 0)}/edit?related_key=`; the rest of the line stays.
   - `delete_child_action/1`, clause `def delete_child_action(%{auix: %{layout_type: :form}} = assigns) do`: replace the line `      <.link` (the opening of the link in its `~H`) with `      <.link class="auix-index-row-action"`.
   - `add_new_child/1` stays as it is: it is a header action.
4. Theme: `lib/aurora_uix/templates/basic/themes/base.ex` — modified. No rule is added nor renamed.
   - `rule(:auix_items_card_show, …)`: replace the selector line `.auix-items-card-show > * {` with the two lines
     ```css
     .auix-items-card-show > .auix-index-row-action,
     .auix-items-card-show > * {
     ```
   - `rule(:auix_items_card_menu, …)`: replace the selector line `.auix-items-card-menu > button {` with `.auix-items-card-menu > .auix-items-card-menu-toggle {`.
   - `rule(:auix_items_card_menu_list, …)`: after the closing `}` of `.auix-items-card-menu-list { … }`, before the closing `"""`, insert, at the rule's two-space indent:
     ```css

       .auix-items-card-menu-toggle[aria-expanded="true"] ~ .auix-items-card-menu-list {
         display: flex;
       }
     ```
   - `rule(:auix_items_card_menu_item, …)`: replace the selector lines
     ```css
     .auix-items-card-menu-item,
     .auix-items-card-menu-item > a,
     .auix-items-card-menu-item > button {
     ```
     with
     ```css
     .auix-items-card-menu-item,
     .auix-items-card-menu-item > .auix-index-row-action,
     .auix-items-card-menu-item > a,
     .auix-items-card-menu-item > button {
     ```
   - `rule(:auix_index_sort_select, …)`: replace the selector line `.auix-index-sort-select > button {` with `.auix-index-sort-select > .auix-index-sort-select-direction {`. The comment above it stays.
   - `rule(:auix_index_sort_menu, …)`: replace the selector line `.auix-index-sort-menu > button {` with `.auix-index-sort-menu > .auix-index-sort-menu-toggle {`.
   - `rule(:auix_index_sort_menu_list, …)`: after the closing `}` of `.auix-index-sort-menu-list { … }`, before the closing `"""`, insert, at the rule's four-space indent:
     ```css

         .auix-index-sort-menu-toggle[aria-expanded="true"] ~ .auix-index-sort-menu-list {
           display: flex;
         }
     ```
   - `rule(:auix_index_row_action, …)` stays the empty `.auix-index-row-action{ }`.
   - Run `mix auix.gen.stylesheet` to regenerate the local `assets/css/auix-*.css` files (gitignored, not committed). `mix auix.gen.tailwind_classes` is unaffected: no `hero-*` name changes.
5. Components: `<.button>` and `<.auix_link>` / `<.link>` reused; no attr, slot nor component contract changes.
6. `dt/1` strings: none added nor changed.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- New `--auix-*` variables for `z-index`; the existing popups (`z-index: 10`, flash `50`) keep their literals.
- `auix-inline-container` documentation.
- A CHANGELOG entry: the menu open state and the new classes are a UI change, neither a feature nor a fix.
- Styling `.auix-index-row-action` in the table view: its rule stays empty.
- Adding `auix-index-row-action` to host row actions: a host action keeps its own markup and is styled through the tag fallbacks.
- Parser, CRUD and guide schema changes: the work is backend-agnostic UI code, so no Ash nor Ecto section applies.
<!-- enriched-spec:end -->
