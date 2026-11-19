<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Index cards lose their footer action bar. Tapping a card runs its show action, and every other row action moves into a ⋮ menu at the end of the card header, with destructive actions last, below a divider, in the danger color. The row checkbox lines up with the first line of the title. The work is backend-agnostic component, renderer and theme code. It covers Ash and Ecto resources alike, and the one-to-many lists that render through the same card.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.2.1] · guides/core/layouts.md § Index Cards · guides/customization/custom_actions.md § Understanding the Action System, § Row actions in cards · guides/customization/overriding_components.md § `:basic_components` · guides/customization/styling.md § Sizes & dimensions, § Class reference | none | federico/527-doc-1-card-header-menu | docs: index card header menu and tap to show (#527 · DOC-1) |
| UI-1 | UI | component + renderer + theme · card tap target, header ⋮ menu, checkbox alignment (`auix_items_card/1`) | DOC-1 | federico/527-ui-1-card-header-menu | feat: index card header menu and tap to show (#527 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md § [0.2.1]`
- `guides/core/layouts.md § Index Cards`
- `guides/customization/custom_actions.md § Understanding the Action System`, `§ Row actions in cards`
- `guides/customization/overriding_components.md § :basic_components — Aurora.Uix.Templates.Basic.Components`
- `guides/customization/styling.md § Sizes & dimensions`, `§ Class reference`

#### Implementation details

##### CHANGELOG.md
1. § `## [0.2.1]` — replace every line from `## [0.2.1]` up to, and not including, the line
   `## [0.2.0] - 2026-10-21` with the text below, verbatim, followed by one blank line. It
   replaces every entry of the section, `### Added`, `### Changed` and `### Build`, with the change
   alone and at most a pointer to its guide.
   ```
   ## [0.2.1]

   ### Added

   - **Reusable components**: `IndexComponent`, `FormComponent` and `ShowComponent` can be embedded in
     any LiveView (Reusable Components guide).
   - **Action icons**: default actions show an icon (Custom Actions guide, "Action Icons").
   - **Index cards**: a card layout for the index list (Layouts guide, "Index Cards").

   ### Changed

   - **Updated Dependencies**
     - ash: 3.36.1 -> 3.37.6
     - ash_phoenix: 2.3.25 -> 2.3.26
     - ash_postgres: 2.15.1 -> 2.16.0
     - bandit: 1.13.1 -> 1.15.0
     - dialyxir: 1.4.8 -> 1.4.9
     - image: 0.72.0 -> 0.73.0
     - lazy_html: 0.1.13 -> 0.1.14
     - phoenix_html: 4.3.0 -> 4.4.0
     - sourceror: 1.12.4 -> 1.13.0
   - **Generated module names (breaking)**: a duplicate generated module name fails compilation, and an
     embedded field generates no modules (What's New in 0.2.1, "Upgrading from 0.2.0").
   - **Associations to imported resources**: an association links to a resource imported with
     `@auix_resource_metadata`.
   - **Form navigation in LiveView tests**: the generated `Index` LiveView redirects after a form saves
     or closes (What's New in 0.2.1, "Upgrading from 0.2.0").
   - **Index card styling (CSS class changes)**: the `auix-items-card-*` classes changed (Styling
     guide, "Class reference").

   ### Build

   - Claude Code cloud sessions restore a cached build at start. Dialyzer PLTs live in `priv/plts`.
   ```
2. Every line from `## [0.2.0] - 2026-10-21` to the end of the file stays byte for byte.

##### guides/core/layouts.md
1. § `Index Cards` — replace the paragraph
   ```
   The selection checkbox and the row actions belong to the card frame: the checkbox opens the
   header, and the row actions fill a footer bar (see
   [Custom Actions › Row actions in cards](../customization/custom_actions.md#row-actions-in-cards)).
   ```
   with, verbatim:
   ```
   The selection checkbox and the row actions belong to the card frame. The header holds the
   checkbox, the title and subtitle, and a ⋮ menu of row actions; tapping the card opens the
   record's show view (see
   [Custom Actions › Row actions in cards](../customization/custom_actions.md#row-actions-in-cards)).
   ```

##### guides/customization/custom_actions.md
1. § `Understanding the Action System` — replace the bullet that starts `` - `:destructive?` `` with, verbatim:
   ```
   - `:destructive?` — `true` for an action that destroys data. Index cards list destructive row actions last in their ⋮ menu, in the danger color (default `false`; `true` for `:default_row_delete`)
   ```
2. § `Row actions in cards` — replace the whole body of the section, from the line that starts `In the card view the row actions fill a footer bar` through the line `` [Custom actions on mobile](#custom-actions-on-mobile) shows. ``, with, verbatim:
   ````
   In the card view the show action is the card itself: tapping the card opens the record's show
   view, and the selection checkbox and the ⋮ menu keep their own taps. An action that replaces
   `:default_row_show` becomes the card's tap target; with `remove_row_action: :default_row_show`
   tapping the card opens nothing.

   The other row actions sit in a ⋮ menu at the end of the card header, in the order they are
   declared. Destructive actions go last, below a divider, in the danger color.

   `:default_row_delete` is destructive. Mark your own action with `destructive?: true`:

   ```elixir
   index_columns :product, [:reference, :name],
     add_row_action: {:archive, &MyAppWeb.ProductActions.archive_action/1, destructive?: true}
   ```

   An action that replaces `:default_row_delete` stays destructive unless it says
   `destructive?: false`. Each menu item gets a 44px touch target. The default row actions carry
   their label as `title` and `aria-label`; give your own action both, as
   [Custom actions on mobile](#custom-actions-on-mobile) shows.
   ````

##### guides/customization/overriding_components.md
1. § `` `:basic_components` — `Aurora.Uix.Templates.Basic.Components` `` — replace the `auix_items_card/1` table row with, verbatim:
   ```
   | `auix_items_card/1` | Card view for collections: one card per record with a header (checkbox, title, subtitle, ⋮ menu of row actions) and a body, and the filter cards; tapping a card runs its show action |
   ```

##### guides/customization/styling.md
1. § `Sizes & dimensions` — replace the `--auix-touch-target-size` row with, verbatim:
   ```
   | `--auix-touch-target-size` | `2.75rem` | Minimum width and height of the card ⋮ menu toggle and of each menu item |
   ```
2. § `Class reference` — apply these row edits, each row verbatim:
   1. Replace the `.auix-items-card-item-content` row with:
      ```
      | `.auix-items-card-item-content` | One index card; the show action is stretched over it | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-border-primary`, `--auix-border-radius-default`, `--auix-color-bg-default`, `--auix-color-items-card-item-content-text` |
      ```
   2. Insert after the `.auix-items-card-item-content` row:
      ```
      | `.auix-items-card-show` | Tap target of a card: the show action, stretched over the card and transparent | Structural only |
      ```
   3. Replace the `.auix-items-card-item-group` row with:
      ```
      | `.auix-items-card-item-group` | Card header: checkbox, heading and ⋮ menu | `--auix-gap-large`, `--auix-padding-default` |
      ```
   4. Replace the `.auix-items-card-select` row with:
      ```
      | `.auix-items-card-select` | Checkbox slot of the card header; centers the checkbox on the first line of the title | `--auix-line-height-relaxed` |
      ```
   5. Replace the `.auix-items-card-title` row with:
      ```
      | `.auix-items-card-title` | Card title | `--auix-font-size-subtitle`, `--auix-font-weight-bold`, `--auix-line-height-relaxed` |
      ```
   6. Delete the four rows `.auix-items-card-actions`, `.auix-items-card-actions-leading`, `.auix-items-card-actions-trailing` and `.auix-items-card-action`.
   7. Replace the `.auix-items-card-menu` row with:
      ```
      | `.auix-items-card-menu` | ⋮ menu toggle at the end of the card header; hidden when no menu item renders | `--auix-touch-target-size` |
      ```
   8. Replace the `.auix-items-card-menu-list` row with:
      ```
      | `.auix-items-card-menu-list` | Row-action menu of the card header, opening below the toggle (hidden until toggled) | `--auix-color-bg-default`, `--auix-color-border-primary`, `--auix-border-radius-default`, `--auix-shadow-md` |
      ```
   9. Insert after the `.auix-items-card-menu-list` row:
      ```
      | `.auix-items-card-menu-group` | One group of the card menu: the row actions, then the destructive ones below a divider; hidden when none of its items renders | `--auix-border-width-default`, `--auix-border-style-default`, `--auix-color-border-primary` |
      | `.auix-items-card-menu-group--destructive` | Destructive group of the card menu, in the danger color | `--auix-color-icon-danger` |
      | `.auix-items-card-menu-item` | One row action in the card menu; hidden when it renders nothing | `--auix-touch-target-size` |
      ```

##### Acceptance criteria
- [ ] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [ ] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-527-enriched-spec.md`)
- [ ] AC-3: `CHANGELOG.md § [0.2.1]` reads as prescribed: 34 lines, the nine dependency lines its
      only sub-bullets, and no footer bar (mechanical — no red test; verified by
      `awk '/^## \[0.2.1\]/{f=1} /^## \[0.2.0\]/{f=0} f' CHANGELOG.md | wc -l` returning 34, the
      same `awk` piped to `grep -c '^  - '` returning 9, and `grep -c 'footer bar' CHANGELOG.md`
      returning 0)
- [ ] AC-4: `guides/core/layouts.md § Index Cards` reads as prescribed (mechanical — no red test;
      verified by `grep -c 'footer bar' guides/core/layouts.md` returning 0 and
      `grep -c '⋮ menu of row actions' guides/core/layouts.md` returning 1)
- [ ] AC-5: `guides/customization/custom_actions.md § Row actions in cards` reads as prescribed
      (mechanical — no red test; verified by
      `grep -c 'footer bar' guides/customization/custom_actions.md` returning 0 and
      `grep -c "the card's tap target" guides/customization/custom_actions.md` returning 1)
- [ ] AC-6: `guides/customization/overriding_components.md` describes the card menu and the tap
      (mechanical — no red test; verified by
      `grep -c 'tapping a card runs its show action' guides/customization/overriding_components.md`
      returning 1)
- [ ] AC-7: `guides/customization/styling.md` lists the new classes and none of the footer ones
      (mechanical — no red test; verified by
      `grep -c 'auix-items-card-actions' guides/customization/styling.md` returning 0,
      `grep -c 'auix-items-card-menu-' guides/customization/styling.md` returning 4 and
      `grep -c 'auix-items-card-show' guides/customization/styling.md` returning 1)
- [ ] AC-8: every released section of `CHANGELOG.md`, from `## [0.2.0] - 2026-10-21` to the end
      of the file, is unchanged (mechanical — no red test; verified by
      `diff <(git show origin/main:CHANGELOG.md | sed -n '/^## \[0.2.0\]/,$p') <(sed -n '/^## \[0.2.0\]/,$p' CHANGELOG.md)`
      printing nothing)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · component + renderer + theme: card tap target and header menu
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md § Index Cards` (DOC-1)
- `guides/customization/custom_actions.md § Row actions in cards` (DOC-1)
- `guides/customization/styling.md § Class reference`, `§ Sizes & dimensions` (DOC-1)

#### Implementation details

Layout types: `:index`, and the one-to-many list of `:form` and `:show` parents, which renders through the same `auix_items_card/1` (`Aurora.Uix.Templates.Basic.Renderers.OneToMany` `child_rows/1`). The table view (`auix_items_table/1`) is untouched: it keeps every row action, show included, in its action cell.

Facts this section builds on:
- The tap target is the show action itself, rendered once more into a transparent element stretched over the card. Every show variant then keeps its own route: the index link (`Aurora.Uix.Templates.Basic.Actions.Index` `show_row_action/1`, both clauses) is an `<.auix_link>` carrying `phx-click="auix_route_forward"` (patch clause) and `phx-click="auix_open"` (`notify` clause), the one-to-many link (`Aurora.Uix.Templates.Basic.Actions.OneToMany` `show_child_action/1`) is an `<.auix_link navigate=…>`, and a host action that replaces `:default_row_show` keeps that name (`Aurora.Uix.Templates.Basic.Helpers` `replace_auix_action/3`).
- Paint order keeps the checkbox and the menu tappable: the tap target is the first child of the card and is positioned; `.auix-items-card-select` and `.auix-items-card-menu` are positioned and come after it, so they paint above it. `.auix-items-card-menu-list` keeps `z-index: 10`, so an open menu paints above the next cards.
- In a `:show` parent and in a component (`notify`) parent, `edit_child_action/1` and `delete_child_action/1` render `~H""` (`Aurora.Uix.Templates.Basic.Actions.OneToMany`). The theme hides a menu item that renders no element, a menu group with no rendered item, and a menu with no rendered item.
- `Aurora.Uix.Templates.CssSanitizer` keeps `:has(…)` and `:not(…)` selectors: `sanitize_css/1` on `.auix-a:not(:has(> *)) { display: none; }` and `.auix-g:has(.auix-c > *) + .auix-g--d { … }` returns them unchanged. Every property this section writes is in `@allowed_properties`.

##### Acceptance criteria
- [ ] AC-1: Given `index_columns(:product, [:reference, :name, :quantity_at_hand])` at `/index-card-frame-products`, no card has `[name='auix-card-actions']`, and each card's header `.auix-items-card-item-group` holds `.auix-items-card-select`, `.auix-items-card-heading` and `[name='auix-card-menu']`, adjacent and in that order
- [ ] AC-2: In that view `[name='auix-card-menu-actions']` holds `a[name='auix-edit-product']` with `title` and `aria-label` `Edit`, `[name='auix-card-menu-destructive']` holds `a[name='auix-delete-product']` with `title` and `aria-label` `Delete`, and `[name='auix-card-menu-list']` holds no `a[name='auix-show-product']`
- [ ] AC-3: In that view the first child of each card is `[name='auix-card-show']`, holding `a[name='auix-show-product']` with `title` and `aria-label` `Show`; clicking the one of product `id_test-1` patches to `/index-card-frame-products/<id>/show`
- [ ] AC-4: Given `remove_row_action: :default_row_show`, `insert_row_action: {:archive, &archive_action/1, destructive?: true}` and `add_row_action: {:copy, &copy_action/1}` at `/index-card-actions-products`, the menu's actions group holds edit then copy, its destructive group holds archive then delete, and the card has no `[name='auix-card-show']`
- [ ] AC-5: The menu toggle `button[name='auix-card-menu-toggle']` sits in the card header with `aria-label='More actions'` and `aria-expanded='false'`
- [ ] AC-6: Given the product edit form at `/association-one_to_many-actions-products/<id>/edit`, each child card of `div[name='auix-one_to_many-product']` has `[name='auix-card-show']` as its first child holding `a[name^='auix-show-product__product_transaction-']`, its menu's actions group holds the `Custom edit` link, its destructive group holds `a[name^='auix-delete-product__product_transaction-']`, and its menu list holds no show link
- [ ] AC-7: A menu item that renders nothing, a menu group with no rendered item and a menu with no rendered item are hidden: `Base.rule(:auix_items_card_menu_item)` contains `.auix-items-card-menu-item:not(:has(> *))`, `Base.rule(:auix_items_card_menu_group)` contains `.auix-items-card-menu-group:not(:has(.auix-items-card-menu-item > *))` and `Base.rule(:auix_items_card_menu)` contains `.auix-items-card-menu:not(:has(.auix-items-card-menu-item > *))`, each followed by `display: none`
- [ ] AC-8: The menu opens below its toggle and uses no physical side: `Base.rule(:auix_items_card_menu_list)` contains `top: 100%` and neither `bottom`, `left` nor `right`
- [ ] AC-9: The destructive group is set apart: `Base.rule(:auix_items_card_menu_group__destructive)` contains `color: var(--auix-color-icon-danger)`, and `Base.rule(:auix_items_card_menu_group)` contains `.auix-items-card-menu-group:has(.auix-items-card-menu-item > *) + .auix-items-card-menu-group--destructive` with `border-top-width: var(--auix-border-width-default)`
- [ ] AC-10: The checkbox carries no table spacing and centers on the title's first line: `Base.rule(:auix_items_card_select)` contains `height: var(--auix-line-height-relaxed)`, `.auix-items-card-select .auix-fieldset` and `.auix-items-card-select .auix-checkbox`; `Base.rule(:auix_items_card_title)` contains `line-height: var(--auix-line-height-relaxed)`
- [ ] AC-11: The tap target covers the card and the footer rules are gone: `Base.rule(:auix_items_card_show)` contains `position: absolute` and `inset: 0`, `Base.rule(:auix_items_card_item_content)` contains `position: relative`, and `Base.rule/1` returns `""` for `:auix_items_card_actions`, `:auix_items_card_actions_leading`, `:auix_items_card_actions_trailing` and `:auix_items_card_action`
- [ ] AC-12: At a 390px viewport a tap on a card's body opens the show view; a tap on the checkbox toggles it and a tap on ⋮ opens the menu below the toggle, neither opening the show view; the checkbox is centered on the title's first line; a one-to-many list on a product show page shows no ⋮ menu (manual — no red test; verified by `iex -S mix run test/start_test_server.exs`, opening `/index-card-frame-products` and a product show page with transactions in a browser at 390px)

##### Test ports
- Route `"/index-card-frame-products"`, registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud(IndexCardFrameTest.Product, "index-card-frame-products")` · layout type `:index` · observable: `has_element?/2` under `#auix-table-index-card-frame-products-index-mobile`
- Route `"/index-card-actions-products"`, registered via `RoutesHelper.register_crud(IndexCardActionsTest.Product, "index-card-actions-products")` · layout type `:index` · observable: `has_element?/2` under `#auix-table-index-card-actions-products-index-mobile`
- Route `"/association-one_to_many-actions-products"`, already registered for `AssociationOne2ManyUIActionsTest` in `test/support/app_web/routes.ex` · layout type `:form` (parent) · observable: `has_element?/2` under `div[name='auix-one_to_many-product']`
- No route: `Aurora.Uix.Templates.Basic.Themes.Base.rule/1` in `test/cases/templates/theme_rules_test.exs`

##### Markup changes — tests that drive the changed selectors
`rg -n "auix-card-actions|auix-card-menu|items-card-action|items_card_action" test` returns these hits:
| Test | Current drive | New drive |
|---|---|---|
| `test/cases_live/index_card_frame_test.exs` `"default row actions sit in the footer bar"` | `[name='auix-card-actions-leading']` / `[name='auix-card-actions-trailing']` holding delete, show, edit; `refute` `[name='auix-card-menu']` | renamed `"default row actions sit in the header menu"`; asserts AC-1 and AC-2 (Red tests row 1) |
| `test/cases_live/index_card_actions_test.exs` `"extra row actions move into the menu"` | archive in `[name='auix-card-actions-leading']`; show and edit in `[name='auix-card-actions-trailing'] > .auix-items-card-action`; delete and copy in `[name='auix-card-menu-list']`; the toggle | renamed `"the menu lists the row actions in order, destructive last"`; asserts AC-4 and AC-5 (Red tests row 3) |
| `test/cases/templates/theme_rules_test.exs` `describe "card rules"` `"use no physical side"` | `Base.rule(:auix_items_card_actions)` and `Base.rule(:auix_items_card_menu_list)` | replaced by `"the card menu opens below its toggle and uses no physical side"` on `Base.rule(:auix_items_card_menu_list)` (Red tests row 5) |

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1, AC-2 | amend `test/cases_live/index_card_frame_test.exs` `"default row actions sit in the footer bar"`, renamed `"default row actions sit in the header menu"` | the `describe "card frame"` setup, unchanged layout | same | `"default row actions sit in the header menu"` | with `m = @mobile`: `refute has_element?(view, "#{m} [name='auix-card-actions']")`; `has_element?(view, "#{m} [name='auix-card'] > .auix-items-card-item-group > .auix-items-card-select + .auix-items-card-heading + [name='auix-card-menu']")`; `has_element?(view, "#{m} [name='auix-card-menu-actions'] a[name='auix-edit-product'][title='Edit'][aria-label='Edit']")`; `has_element?(view, "#{m} [name='auix-card-menu-destructive'] a[name='auix-delete-product'][title='Delete'][aria-label='Delete']")`; `refute has_element?(view, "#{m} [name='auix-card-menu-list'] a[name='auix-show-product']")` |
| AC-3 | add to `test/cases_live/index_card_frame_test.exs`, `describe "card frame"`; amend that describe's setup to `products = create_sample_products(3, :test)` and return `%{view: view, products: products}`; add `alias Aurora.UixWeb.Test.NavigationHelper` | `id = products["id_test-1"].id` | same | `"tapping a card runs its show action"` | `has_element?(view, "#{m} [name='auix-card'] > [name='auix-card-show']:first-child a[name='auix-show-product'][title='Show'][aria-label='Show']")`; `view \|> element("#{m} [name='auix-card-show'] a[phx-value-route_path$='/#{id}/show']") \|> render_click()`; `{path, _query, _stack} = view \|> assert_patch() \|> NavigationHelper.decode_route()`; `assert path == "/index-card-frame-products/#{id}/show"` |
| AC-4, AC-5 | amend `test/cases_live/index_card_actions_test.exs` `"extra row actions move into the menu"`, renamed `"the menu lists the row actions in order, destructive last"`; in its `auix_create_ui` block, add `remove_row_action: :default_row_show,` as the first option of `index_columns(:product, [:reference, :name], …)` | one sample product, `live(conn, "/index-card-actions-products")`, as today | same | `"the menu lists the row actions in order, destructive last"` | with `m = "#auix-table-index-card-actions-products-index-mobile"`: `has_element?(view, "#{m} [name='auix-card-menu-actions'] > .auix-items-card-menu-item:nth-child(1) a[name='auix-edit-product']")`; `… :nth-child(2) a[name='auix-copy-product']`; `has_element?(view, "#{m} [name='auix-card-menu-destructive'] > .auix-items-card-menu-item:nth-child(1) a[name='auix-archive-product']")`; `… :nth-child(2) a[name='auix-delete-product']`; `refute has_element?(view, "#{m} [name='auix-card-show']")`; `has_element?(view, "#{m} .auix-items-card-item-group button[name='auix-card-menu-toggle'][aria-label='More actions'][aria-expanded='false']")` |
| AC-6 | add to `test/cases_live/association_one2many_ui_actions_test.exs` | `delete_all_inventory_data()`; `product_id = 1 \|> create_sample_products_with_transactions(3, :test) \|> List.first() \|> elem(1) \|> Map.get(:id)`, as `"Test row actions"` does; `live(conn, "/association-one_to_many-actions-products/#{product_id}/edit")` | same | `"Test row actions in child cards"` | with `c = "div[name='auix-one_to_many-product'] [name='auix-card']"`: `has_element?(view, "#{c} > [name='auix-card-show']:first-child a[name^='auix-show-product__product_transaction-']")`; `has_element?(view, "#{c} [name='auix-card-menu-actions'] a", "Custom edit")`; `has_element?(view, "#{c} [name='auix-card-menu-destructive'] a[name^='auix-delete-product__product_transaction-']")`; `refute has_element?(view, "#{c} [name='auix-card-menu-list'] a[name^='auix-show-product__']")` |
| AC-7, AC-8, AC-9, AC-10, AC-11 | amend `test/cases/templates/theme_rules_test.exs` `describe "card rules"`: replace `"use no physical side"`, add the other tests to the same describe | none | same | `"the card menu opens below its toggle and uses no physical side"` (AC-8); `"hide a menu that renders nothing"` (AC-7); `"set the destructive group apart"` (AC-9); `"align the checkbox with the title"` (AC-10); `"stretch the show action over the card"` (AC-11) | AC-8: `rule = Base.rule(:auix_items_card_menu_list)`; `assert rule =~ "top: 100%"`; `refute rule =~ "bottom"`; `refute rule =~ "left"`; `refute rule =~ "right"`. AC-7: `assert Base.rule(:auix_items_card_menu_item) =~ ~r/\.auix-items-card-menu-item:not\(:has\(> \*\)\) \{\s*display: none;/`; `assert Base.rule(:auix_items_card_menu_group) =~ ~r/\.auix-items-card-menu-group:not\(:has\(\.auix-items-card-menu-item > \*\)\) \{\s*display: none;/`; `assert Base.rule(:auix_items_card_menu) =~ ~r/\.auix-items-card-menu:not\(:has\(\.auix-items-card-menu-item > \*\)\) \{\s*display: none;/`. AC-9: `=~ "color: var(--auix-color-icon-danger)"`; `=~ ".auix-items-card-menu-group:has(.auix-items-card-menu-item > *) + .auix-items-card-menu-group--destructive"`. AC-10: `=~ "height: var(--auix-line-height-relaxed)"`, `=~ ".auix-items-card-select .auix-fieldset"`, `=~ ".auix-items-card-select .auix-checkbox"`; title `=~ "line-height: var(--auix-line-height-relaxed)"`. AC-11: `=~ "position: absolute"`, `=~ "inset: 0"`; content `=~ "position: relative"`; `for name <- [:auix_items_card_actions, :auix_items_card_actions_leading, :auix_items_card_actions_trailing, :auix_items_card_action], do: assert Base.rule(name) == ""` |

##### Modules & components
1. `Aurora.Uix.Templates.Basic.Components` at `lib/aurora_uix/templates/basic/components/components.ex` — modified.
   - `@moduledoc` `## Components`: replace the line `` - `auix_items_card/1` — card view for collections: header, body and a footer bar of row actions. `` with `` - `auix_items_card/1` — card view for collections: a header with a menu of row actions, a body, and the show action as the card's tap target. ``
   - `auix_items/1` and `auix_items_card/1`: in both, replace
     ```elixir
     slot :action, doc: "the slot for showing user actions" do
       attr(:destructive?, :boolean, doc: "places the action at the leading edge of a card footer")
     end
     ```
     with
     ```elixir
     slot :action, doc: "the slot for showing user actions" do
       attr(:name, :atom, doc: "the action name; `:default_row_show` is a card's tap target")
       attr(:destructive?, :boolean, doc: "lists the action last in a card menu, in the danger color")
     end
     ```
   - `auix_items_card/1` `@doc`: replace the paragraph that starts `Each card has a header (the selection checkbox and the first non-checkbox column as its` and ends `from an overflow menu.` with:
     ```
     Each card has a header (the selection checkbox, the first non-checkbox column as its title,
     and a ⋮ menu) and a body of `label · value` rows for the remaining columns. The `:action`
     entry named `:default_row_show` is stretched over the card, so tapping the card runs it; the
     checkbox and the menu keep their own taps. The menu holds every other `:action` entry in
     order, the entries with `destructive?: true` last.
     ```
   - `auix_items_card/1`, clause head `def auix_items_card(%{host_components: nil} = assigns) do`, inside the row element `<div :for={row <- @rows} … name="auix-card">`:
     1. Insert as the first lines inside `<%= if Enum.at(@col, 0) != nil do %>`, before `<div class="auix-items-card-item-group">`:
        ```heex
        <div :for={show <- show_actions(@action)} class="auix-items-card-show" name="auix-card-show">
          {render_slot(show, @row_item.(row))}
        </div>
        ```
     2. Inside `<div class="auix-items-card-item-group">`, after the closing `</div>` of `<div class="auix-items-card-heading">`, insert:
        ```heex
        <.card_menu :if={menu_actions(@action) != []} action={menu_actions(@action)} row={@row_item.(row)} />
        ```
     3. Delete the line `<.card_actions :if={@action != []} action={@action} row={@row_item.(row)} />`.
   - New private functions, placed after `body_cols/2` (`rg -n "\bcard_menu\b|\bshow_actions\b|\bmenu_actions\b" lib` returns nothing):
     ```elixir
     # Returns the :action entry stretched over a card: the show action
     @spec show_actions(list()) :: list()
     defp show_actions(actions),
       do: actions |> Enum.filter(&(Map.get(&1, :name) == :default_row_show)) |> Enum.take(1)

     # Returns the :action entries of a card menu: every action but show
     @spec menu_actions(list()) :: list()
     defp menu_actions(actions), do: Enum.reject(actions, &(Map.get(&1, :name) == :default_row_show))
     ```
   - Replace the private component `card_actions/1` — its two comment lines, its two `attr` lines, its `@spec` and its body — with `card_menu/1`:
     ```elixir
     # Renders a card's row-action menu: the actions in order, then the destructive ones
     attr(:action, :list, required: true, doc: "the :action slot entries of the menu")
     attr(:row, :any, required: true, doc: "the mapped row")

     @spec card_menu(map()) :: Rendered.t()
     defp card_menu(assigns) do
       {destructive, regular} =
         Enum.split_with(assigns.action, &(Map.get(&1, :destructive?, false) == true))

       assigns =
         assigns
         |> assign(:regular, regular)
         |> assign(:destructive, destructive)

       ~H"""
       <div class="auix-items-card-menu" name="auix-card-menu"
           phx-click={toggle_card_menu()} phx-click-away={hide_card_menu()}>
         <.button type="button" class="auix-button--iconized" name="auix-card-menu-toggle"
             title={dt("More actions")} aria-label={dt("More actions")} aria-haspopup="menu" aria-expanded="false">
           <.icon name="hero-ellipsis-vertical" />
         </.button>
         <div class="auix-items-card-menu-list" name="auix-card-menu-list" role="menu">
           <div :if={@regular != []} class="auix-items-card-menu-group" name="auix-card-menu-actions">
             <div :for={action <- @regular} class="auix-items-card-menu-item">{render_slot(action, @row)}</div>
           </div>
           <div :if={@destructive != []} class="auix-items-card-menu-group auix-items-card-menu-group--destructive" name="auix-card-menu-destructive">
             <div :for={action <- @destructive} class="auix-items-card-menu-item">{render_slot(action, @row)}</div>
           </div>
         </div>
       </div>
       """
     end
     ```
   - `toggle_card_menu/0` and `hide_card_menu/0` stay as they are: they address the list and the toggle relative to `.auix-items-card-menu` (`{:inner, …}`).
2. `Aurora.Uix.Templates.Basic.Renderers.IndexRenderer` at `lib/aurora_uix/templates/basic/renderers/index_renderer.ex` — modified. In `index_list/1`, replace the slot opening line `<:action :let={row_info} :for={action <- @auix.index_row_actions} destructive?={action.destructive?}>` with `<:action :let={row_info} :for={action <- @auix.index_row_actions} name={action.name} destructive?={action.destructive?}>`.
3. `Aurora.Uix.Templates.Basic.Renderers.OneToMany` at `lib/aurora_uix/templates/basic/renderers/fields/one_to_many.ex` — modified. In `child_rows/1`, replace the slot opening line `<:action :let={entity} :for={action <- @auix.one_to_many_row_actions} destructive?={action.destructive?}>` with `<:action :let={entity} :for={action <- @auix.one_to_many_row_actions} name={action.name} destructive?={action.destructive?}>`.
4. Theme: `lib/aurora_uix/templates/basic/themes/base.ex` — modified.
   - `rule(:auix_items_card_item_content, …)`: insert `position: relative;` after `flex-direction: column;`.
   - Add after `rule(:auix_items_card_item_content, …)`:
     ```css
     /* rule(:auix_items_card_show, …) */
     .auix-items-card-show {
       position: absolute;
       inset: 0;
     }

     .auix-items-card-show > * {
       display: block;
       width: 100%;
       height: 100%;
       opacity: 0;
     }
     ```
   - `rule(:auix_items_card_select, …)`: replace its CSS with:
     ```css
     .auix-items-card-select {
       position: relative;
       display: flex;
       align-items: center;
       flex-shrink: 0;
       height: var(--auix-line-height-relaxed);
     }

     .auix-items-card-select .auix-fieldset {
       padding: 0;
       gap: 0;
     }

     .auix-items-card-select .auix-checkbox {
       margin: 0;
     }
     ```
   - `rule(:auix_items_card_heading, …)`: insert `flex: 1;` after `flex-direction: column;`.
   - `rule(:auix_items_card_title, …)`: insert `line-height: var(--auix-line-height-relaxed);` after `font-weight: var(--auix-font-weight-bold);`.
   - Delete the clauses `rule(:auix_items_card_actions, …)`, `rule(:auix_items_card_actions_leading, …)`, `rule(:auix_items_card_actions_trailing, …)` and `rule(:auix_items_card_action, …)`. `rg -n "auix_items_card_action|auix-items-card-action" lib` then returns nothing.
   - `rule(:auix_items_card_menu, …)`: replace its CSS with:
     ```css
     .auix-items-card-menu {
       position: relative;
       display: inline-flex;
       flex-shrink: 0;
     }

     .auix-items-card-menu > button {
       min-width: var(--auix-touch-target-size);
       min-height: var(--auix-touch-target-size);
       justify-content: center;
     }

     .auix-items-card-menu:not(:has(.auix-items-card-menu-item > *)) {
       display: none;
     }
     ```
   - `rule(:auix_items_card_menu_list, …)`: replace `bottom: 100%;` with `top: 100%;`.
   - Add after `rule(:auix_items_card_menu_list, …)`, one `rule/1` clause per comment:
     ```css
     /* rule(:auix_items_card_menu_group, …) */
     .auix-items-card-menu-group {
       display: flex;
       flex-direction: column;
     }

     .auix-items-card-menu-group:not(:has(.auix-items-card-menu-item > *)) {
       display: none;
     }

     .auix-items-card-menu-group:has(.auix-items-card-menu-item > *) + .auix-items-card-menu-group--destructive {
       border-top-width: var(--auix-border-width-default);
       border-top-style: var(--auix-border-style-default);
       border-top-color: var(--auix-color-border-primary);
     }

     /* rule(:auix_items_card_menu_group__destructive, …) */
     .auix-items-card-menu-group--destructive {
       color: var(--auix-color-icon-danger);
     }

     /* rule(:auix_items_card_menu_item, …) */
     .auix-items-card-menu-item,
     .auix-items-card-menu-item > a,
     .auix-items-card-menu-item > button {
       display: inline-flex;
       align-items: center;
       justify-content: center;
       min-width: var(--auix-touch-target-size);
       min-height: var(--auix-touch-target-size);
     }

     .auix-items-card-menu-item:not(:has(> *)) {
       display: none;
     }
     ```
   - Regenerate: `mix auix.gen.stylesheet`. `hero-ellipsis-vertical` is already in `priv/static/classes.js`, so `mix auix.gen.tailwind_classes` changes nothing.
5. Theme variables: none. `--auix-line-height-relaxed`, `--auix-touch-target-size` and `--auix-color-icon-danger` exist (`lib/aurora_uix/templates/basic/themes/base_variables.ex`, and the theme variants for the color).
6. `dt/1` strings: none new; `"More actions"` exists.
7. No inline `class=` beyond `auix-*` theme classes; the menu is JS commands only, no LiveComponent, no hook, no `<script>`.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files, plus `test/cases_live/index_card_content_test.exs`,
   `test/cases_live/index_card_grid_test.exs`, `test/cases_live/sortable_columns_test.exs` and
   `test/cases_live/ash_sortable_columns_test.exs`)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- `CHANGELOG.md` sections of released versions, `[0.2.0]` and earlier: published history, left as they are.
- `AGENTS.md` and `CLAUDE.md`: agent guidance, outside the documentation set `DOC-1` edits.
- Labels inside the ⋮ menu: an action renders there as its function component renders it.
- The table view's row actions: they stay in the table's action cell.
- Parser sections: the change is component, renderer and theme code over the action list, so it covers the Ash and the Ecto backend alike.
<!-- enriched-spec:end -->
