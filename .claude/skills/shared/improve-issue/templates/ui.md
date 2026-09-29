# improve-issue · UI sections

Read by `improve-issue` **Draft** when a UI section is in scope. A UI section changes what the
library generates from normalized `%Field{}` metadata: `lib/aurora_uix/layout/`
(`blueprint.ex`, `create_ui.ex`, `resource_metadata.ex`) and `lib/aurora_uix/templates/basic/`
(renderers, generators, handlers, actions, themes, components). Everything in it is
backend-agnostic: it consumes `%Field{}` atoms and never references `Ecto.Association.*` or
`Ash.Resource.*`.

## Rules

1. Tests use `Phoenix.LiveViewTest` in `test/cases_live/`, on real data from
   `test/support/helper.ex`. Wallaby (`test/browser_cases/`) only when LiveViewTest cannot
   observe the behaviour (file downloads, native dialogs, multi-tab); the section says which and
   why.
2. Every route a `test/cases_live/` test visits is registered in `test/support/app_web/routes.ex`
   through `RoutesHelper.register_crud/2`. The section names the registration. It never extends
   `register_product_crud/2`.
3. A renderer implements `Aurora.Uix.Renderer` (`render/1`), is dispatched from
   `templates/basic/renderers/default_renderer.ex`, and delegates children through
   `Renderer.render_inner_elements/1`. Field renderers live under `renderers/fields/`; the module
   is `…Renderers.<Name>`, never `…Renderers.Fields.<Name>`. Aliases stay alphabetical.
4. State which `layout_type` values (`:index`, `:form`, `:show`) the section covers and which it
   leaves alone; every renderer branches on it.
5. No inline `class=`. Every style is an `auix-*` class defined as a `rule/1` clause in
   `templates/basic/themes/base.ex`; the section lists each class and its rule, and the
   regeneration commands (`mix auix.gen.stylesheet`, `mix auix.gen.tailwind_classes`).
6. Reuse `core_components.ex` (`<.icon>`, `<.input>`); never `Heroicons`. Prefer function
   components over raw HTML tags for styled elements. Streams for collections. No LiveComponent
   without a stated strong need. No raw `<script>`; hooks are colocated, name starting with `.`,
   unique DOM `id`.
7. Every new or extended component spells its contract: attrs (type, required?, default), slots,
   and the selectors the tests assert on.
8. Every user-visible string goes through `dt/1`; the section lists each msgid. Extraction into
   `priv/gettext/*.pot` is not an issue gate.
9. Selectors are stable: `input[name='parent[child][field]']`, container ids, component names.
   Never `auix-field-*` ids (they embed a global counter), never raw HTML string matching.
10. At least three ACs, at least one of them an error or empty path.

## Template

```markdown
<!-- section:UI-k:start -->
### UI-k — UI · <renderer | generator | handler | theme | layout unit>
Depends on: <ids>

#### Documentation references
<the guides § sections specifying this behaviour>

#### Implementation details
##### Acceptance criteria
- [ ] AC-1: Given <resource metadata + layout>, visiting <route>, then <observable — element,
      input name, navigation>

##### Test ports
- Route `"<path>"` registered in `routes.ex` via `register_crud/2` · layout types <list> ·
  observable: `has_element?/2` on `<selector>`

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|

##### Modules & components
1. `<Module>` at `lib/aurora_uix/templates/basic/<path>.ex` — new | modified; dispatched from
   `default_renderer.ex` clause `<exact head>`
2. Components: <reused component names; each new/extended component's contract>
3. Theme: <`auix-*` classes and their `rule/1` clauses in `themes/base.ex`, or "none">
4. `dt/1` strings: <msgids>

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-k:end -->
```
