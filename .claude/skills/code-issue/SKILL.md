---
name: code-issue
description: >
  Implement a GitHub issue in aurora_uix, an Elixir/Phoenix low-code UI
  generation library with Ash and Ecto backends, following an
  enriched spec produced by improve-issue. Use this skill when the user says
  "implement the issue", "code this up", "start coding", or provides an enriched
  spec from improve-issue. Also triggers on "fix the gaps", "address the review
  findings", or "retry with these requirements" — in those cases the gaps live
  in the review-gaps marker block of the issue body. Always write tests
  alongside implementation.
---

# Skill: code-issue

Implement every Acceptance Criterion from the enriched spec (or remaining gaps
from `review-issue`). Produce working, tested Elixir/Phoenix/Ash code that
respects every rule in CLAUDE.md.

---

## Inputs

This skill always reads the GitHub issue directly — never trust chat context
alone.

```bash
gh issue view <n> --json title,body,url
gh issue view <n> --comments
```

Look for two marker blocks in the body:

| Block | Written by | Meaning |
|---|---|---|
| `<!-- enriched-spec:start v1 -->` … `<!-- enriched-spec:end -->` | `improve-issue` | The implementation spec |
| `<!-- review-gaps:start v1 -->` … `<!-- review-gaps:end -->` | `review-issue` | Outstanding gaps from the last review (replaced each iteration) |

**Mode A — Fresh implementation**: only the spec block is present, or the
gaps block contains `✅ No outstanding gaps.`. Implement every AC.

**Mode B — Gap remediation**: the gaps block contains `INCOMPLETE_TASKS` and
either `MISSING_COVERAGE` (Full mode) or `MISSING_HINTS` (Lite mode). Focus
exclusively on those entries. Do not re-implement what already passes. Read
both the spec (for context) and the gaps (for the actual work). The header
name tells you which mode the previous review ran in — it must match the
current `Test Ownership` value; if they differ, trust the current
`Test Ownership` value (it's the source of truth) and treat
`MISSING_COVERAGE` items in a Lite-mode run as `MISSING_HINTS` to re-post.

If linked issues are referenced in the body, fetch them too.

---

## Step 0 — Read Test Ownership (mechanical)

Inside the enriched-spec block, find `### Test Ownership` and read the
`Owner:` value. Three possible values drive the entire skill's test
behavior:

| `Owner:` value | Mode | Behavior |
|---|---|---|
| `this-issue` | **Full** | Author tests per AC. Step 3's per-AC test rule applies. Step 4's 8-row Test Coverage Self-Check runs. |
| `parent:#<n>` | **Implementation-only** | Do NOT write per-AC tests. Step 4's coverage self-check is replaced by the 3-row smoke check. Step 5 posts Test Hints to issue `#<n>`. |
| `sibling:#<n>` | **Implementation-only** | Same as `parent:#<n>` but Test Hints go to issue `#<n>` (the test-owner sibling). |

If the field is missing, default to **Full** mode and add a one-line
warning to the Implementation Summary in Step 5.

Capture the owner issue number (when delegated) as `$OWNER_ISSUE` — every
Test Hints write uses it.

---

## Step 1 — Parse what to do

Extract internally:
- All Acceptance Criteria (AC-1, AC-2, …) and the affected-files list
- Edge cases from the error-handling table
- Open Questions — resolve each with a reasonable default and state the
  assumption in your output
- In Mode B: every numbered entry from `INCOMPLETE_TASKS` and
  `MISSING_COVERAGE`, including the file:line and assertion if specified

---

## Step 2 — Plan before coding

Output a short **Implementation Plan** before touching any file:

```
### Implementation Plan

**Order of operations:**
1. Parser / metadata layer (`lib/aurora_uix/integration/{ash,ctx}/`, `lib/aurora_uix/layout/`)
2. Downstream consumers keyed off the changed metadata (renderers, generators, handlers)
3. Renderer / component changes (`lib/aurora_uix/templates/basic/`)
4. Theme classes (`templates/basic/themes/base.ex`) + `mix auix.gen.tailwind_classes`
5. Guide schemas, migrations and test routes (`lib/aurora_uix/guides/`,
   `priv/repo/migrations/`, `test/support/app_web/routes.ex`)
6. Tests (alongside each step above)

**Key design decisions:**
- <decision and rationale>

**Assumptions (for any open questions):**
- <assumption>
```

If running under `orchestrate-issue`, never block on this plan — proceed
immediately. Otherwise, ask only when an Open Question affects the data model
or a public API contract.

---

## Step 3 — Implement, AC by AC

### Non-negotiables

`aurora_uix` is a **low-code UI generation library**, not an application. It
generates LiveView index/form/show UIs from resource metadata, over **two
interchangeable backends**: Ash and Ecto (via `aurora_ctx`). Every change must
respect these. Re-read before each AC:

- **Backend abstraction boundary** (the single most important rule):
  - `Ecto.Association.*` / `Ecto.Embedded` may be referenced **only** in
    `lib/aurora_uix/integration/ctx/`.
  - `Ash.Resource.*` may be referenced **only** in
    `lib/aurora_uix/integration/ash/`.
  - Both parsers normalize into a common `%Aurora.Uix.Field{}` shape
    (`type`, `html_type`, `data`). Everything downstream — layout, renderers,
    generators, handlers — consumes the normalized atoms and must stay
    backend-agnostic.
  - A feature is not complete until **both** parsers support it.
- **Adding a new field type atom**: audit every downstream consumer that
  pattern-matches on the existing atoms. Grep for a sibling atom (e.g.
  `:one_to_many_association`) and decide add / do-NOT-add for each hit, with a
  justification. Silent omission is the dominant failure mode here — a missing
  entry in `filter_preloads/1` or `replace_related_field_data/2` fails far from
  the change.
- **Renderers**:
  - Implement the `Aurora.Uix.Renderer` behaviour (`render/1`).
  - Field renderers live in `templates/basic/renderers/fields/`. Note the
    convention: the module is `…Renderers.OneToMany`, **not**
    `…Renderers.Fields.OneToMany`, despite the path.
  - Prefer swapping `auix` keys (`:layout_tree`, `:resource_name`, `:form`,
    `:entity`) and delegating to `Renderer.render_inner_elements/1` over
    hand-writing child markup — that keeps renderer overrides, sections and
    groups working.
  - Dispatch is added in `templates/basic/renderers/default_renderer.ex`.
    Keep aliases alphabetical (credo enforces this).
- **Styling**: no inline `class=`. New `auix-*` classes go in
  `templates/basic/themes/base.ex`, then re-run `mix auix.gen.tailwind_classes`
  and commit the regenerated CSS — it is the first stage of `mix consistency`
  and fails on unknown classes.
- **LiveView**:
  - Use `<.icon name="hero-...">`, `<.input>` and the other components from
    `templates/basic/core_components.ex`. Never use `Heroicons` directly.
  - Use streams for collections; track counts/empty-state in separate assigns
    (streams are not enumerable).
  - Avoid LiveComponents unless there is a specific, strong need.
  - No raw `<script>` tags. Colocated hooks only
    (`:type={Phoenix.LiveView.ColocatedHook}`, name starts with `.`).
  - Use `<.link navigate>` / `push_navigate` — never deprecated
    `live_redirect`.
- **Localization**: user-visible strings go through `dt/1`
  (`use Aurora.Uix.Gettext`). Templates are extracted to `priv/gettext/*.pot`;
  this project ships no per-locale translations.
- **Documentation** (enforced by `doctor` in `mix consistency`):
  - `@moduledoc` with `## Key Features` / `## Key Constraints` sections.
  - `@doc` + `@spec` on public functions — on the **first clause only**.
  - `@spec` on private functions too; this codebase specs them consistently.
  - See the `documentation` skill for the full rule set.
- **Elixir gotchas**:
  - Lists do **not** support `mylist[i]` — use `Enum.at/2` or pattern match.
  - Block expressions must rebind: `socket = if ... do ... end`.
  - Never call `String.to_atom/1` on user input.
  - Never nest multiple modules in the same file.
  - Predicate functions end with `?`, not `is_` prefix.
- **Tests**:
  - Case modules: `use Aurora.UixWeb.Test.UICase, :phoenix_case` and
    `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`. There is no
    `FeatureCase` and no `test/support/factory.ex`.
  - Test data comes from the guide schemas via helpers in
    `test/support/helper.ex` (`create_sample_products/2`,
    `delete_all_inventory_data/0`, …).
  - No mocks. Use real implementations against the real repo.
  - No `Process.sleep/1`. Use `start_supervised!/1`,
    `_ = :sys.get_state(pid)`, or `Process.monitor/1` +
    `assert_receive {:DOWN, ...}`.

### Per-AC workflow

For each AC (or each gap entry in Mode B):

1. State: `### Implementing AC-N: <text>` (or `### Fixing gap: <id>`).
2. Write the implementation code.
3. **In Full mode** (`Owner: this-issue`): write the corresponding test(s)
   immediately after.
   **In Implementation-only mode** (`Owner: parent:#<n>` /
   `Owner: sibling:#<n>`): do NOT write per-AC tests. Instead, append a
   one-line Test Hint to your in-memory hints list:
   ```
   AC-N: <observable behavior> · assert: <suggested ExUnit assertion> · test file: <test/...>
   ```
   These hints are posted to `$OWNER_ISSUE` in Step 5.
4. Run `mix format` to keep the diff clean.

Defer `mix credo --strict` and `mix dialyzer` — they run as part of the single
`mix consistency` at the end of Step 4. Per-AC dialyzer would dominate runtime
(~10 min first run per CLAUDE.md).

### Reusable patterns

**Parser clause — normalize a backend construct into `%Field{}`**

Both parsers map a native struct to a common atom + `data` map. Clause order
matters: the specific clause must precede the catch-all, and in
`ash/fields_parser.ex` several functions have **no** catch-all, so a missing
clause raises `FunctionClauseError` at blueprint-compile time rather than
degrading.

```elixir
# lib/aurora_uix/integration/ctx/fields_parser.ex   (Ecto)
defp field_type(_attrs, %{ecto_type: %AssociationHas{cardinality: :one}}),
  do: :one_to_one_association

# lib/aurora_uix/integration/ash/fields_parser.ex   (Ash — fully qualified;
# this file deliberately keeps no relationship aliases)
defp field_type(nil, %Ash.Resource.Relationships.HasOne{}),
  do: :one_to_one_association

defp field_data(_attrs, %Ash.Resource.Relationships.HasOne{
       destination_attribute: related_key,
       destination: related_schema,
       source_attribute: owner_key
     }),
     do: %{owner_key: owner_key, related: related_schema, related_key: related_key}
```

**Field renderer — delegate to the engine, don't hand-write child markup**

```elixir
def render(%{field: %{data: %{resource: resource_name}} = field,
             auix: %{layout_type: :form}} = assigns) do
  assigns =
    assigns
    |> BasicHelpers.assign_auix(:layout_tree, BasicHelpers.get_layout(assigns, resource_name, :form))
    |> BasicHelpers.assign_auix(:resource_name, resource_name)

  ~H"""
  <div class="auix-one-to-one-container">
    <.inputs_for :let={child_form} field={@auix.form[@field.key]}>
      <Renderer.render_inner_elements auix={Map.put(@auix, :form, child_form)} />
    </.inputs_for>
  </div>
  """
end
```

**Migrations**

Two separate paths, depending on which guide backend the schema belongs to.
(`mix ash.codegen` does exist — the `ash` dep provides it — but it only covers
the Ash resources; it is not the migration path for the Ecto guide schemas.)

```bash
# Ecto guide schemas (lib/aurora_uix/guides/inventory/) — hand-written
# migrations in priv/repo/migrations/
mix ecto.gen.migration create_<name>_table

# Ash guide resources (lib/aurora_uix/guides/blog/) — generated
mix ash_postgres.generate_migrations --name <name>
# commit BOTH the migration and the priv/resource_snapshots/ snapshot
```

`mix test` does **not** run migrations (`test_helper.exs` only starts ExUnit and
the test app). CI runs `mix ecto.create && mix ecto.migrate` separately, so run
`mix ecto.migrate` locally or DB-backed tests fail with a confusing
`relation "…" does not exist`.

### Test patterns

**Prefer `Phoenix.LiveViewTest` for all UI tests** — it is faster, requires no
browser driver, and covers the vast majority of LiveView interactions. Use
`has_element?/2` and `element/2` for assertions; never assert on raw HTML.

Pick the layer that matches what you changed:

| Directory | Covers | DB? |
|---|---|---|
| `test/cases/integration/{ash,ctx}/` | parser output for one backend | no |
| `test/cases/integration/fields_parser_validations_test.exs` | shared golden `%Field{}` metadata | no |
| `test/cases/` | resource metadata, layout/blueprint generation | no |
| `test/cases_live/` | rendered LiveView behaviour (**the default for UI work**) | yes |
| `test/browser_cases/` | Wallaby — last resort only | yes |
| `test/doctests/` | doctests | no |

Parser tests are pure compile-time introspection — run them first as the fast
feedback loop.

```elixir
# test/cases/integration/ctx/fields_parser_test.exs — fixtures are schemas
# declared inside the test module; no database involved.
test "Validate association_parser" do
  validations = Validations.get(:with_associations)

  parsed_schema =
    AllTypes
    |> Ctx.FieldsParser.parse_fields(:all_types)
    |> then(&Ctx.FieldsParser.parse_associations(AllTypes, :all_types, %{}, &1))
    |> Map.new(&{&1.key, &1})

  assert Validations.compare_maps(validations, parsed_schema) == []
end

# test/cases_live/ — declare metadata + layout, then drive the generated UI.
defmodule Aurora.UixWeb.Test.MyFeatureTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product do
      stacked([:reference, :name])
    end
  end

  test "renders the field", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = live(conn, "/my-feature/products/new")
    assert has_element?(view, "input[name='product[reference]']")
  end
end
```

**Every route used by a `test/cases_live/` test must be registered in
`test/support/app_web/routes.ex`** via `RoutesHelper.register_crud/2` —
otherwise the test 404s. Do **not** extend `register_product_crud/2`; it
hardcodes three modules and is called from ~20 sites.

Assert on stable selectors — `input[name='parent[child][field]']`, container
ids, `has_element?/2`. Never assert on raw HTML strings, and avoid
`auix-field-*` ids: they embed a global counter and are not stable across test
ordering.

**Wallaby (`test/browser_cases/`) is a last resort.** Only when LiveViewTest is
genuinely insufficient — file downloads, native dialogs, multi-tab. Document
**why** in a comment above the test.

---

## Step 4 — Final quality gate

After all ACs are implemented, run the full project gate:

```bash
mix consistency
```

This runs `auix.gen.tailwind_classes → format → compile --warnings-as-errors →
credo --strict → dialyzer → doctor`. Then run `mix test` (CI runs them as
separate steps; `mix consistency` does **not** include tests).
Fix every warning and error before declaring this skill complete. If
`mix consistency` fails, treat the failures as additional work to do in this
same skill invocation — do not hand off red.

### Test coverage self-check

**Full mode (`Owner: this-issue`)** — tick each box. If any are unchecked,
add the missing tests:

```
- [ ] Happy path for each AC
- [ ] At least one error/edge path per AC
- [ ] **Both backends covered** — Ash and Ecto (`ctx`) parser tests
- [ ] Golden `%Field{}` metadata updated (`fields_parser_validations_test.exs`)
- [ ] Rendered output tested in `test/cases_live/` for :index, :form and :show
      as applicable
- [ ] Every new route registered in `test/support/app_web/routes.ex`
- [ ] Database constraints tested (unique, FK) if a migration was added
- [ ] All new public functions have at least one test
```

**Implementation-only mode (`Owner: parent:#<n>` / `sibling:#<n>`)** —
3-row smoke check only. If any is unchecked, fix before declaring done:

```
- [ ] `mix compile --warnings-as-errors` is clean
- [ ] `mix test` is still green (no pre-existing test became red)
- [ ] Every new public function is reachable from a sibling AC (no orphans)
```

Do **not** author new tests in this mode — the owner issue will. If a
new test is genuinely required to keep `mix test` green (e.g. a contract
change that broke an existing test), add the *minimum* fix and note it in
the Implementation Summary as `regression-fix`, not as AC coverage.

---

## Step 5 — Output and write back

Emit a structured **Implementation Summary** in chat:

```
### Implementation Summary

**ACs addressed:** AC-1, AC-2, …
**Files created/modified:**
- `lib/aurora_uix/...` — <what changed>
**Tests written:** <N> test cases across <M> describe blocks  ← in Full mode
**Tests written:** none — owner is <Owner value>            ← in Implementation-only mode
**Assumptions made:**
- <list>
**Known limitations / TODOs:**
- <list, or "none">
```

**In Implementation-only mode**, also include a `Test Hints for Owner`
subsection — one bullet per AC, verbatim from the in-memory list captured
in Step 3:

```
**Test Hints for Owner (#<owner>):**
- AC-1: <observable behavior> · assert: <suggested assertion> · test file: <path>
- AC-2: ...
```

Then write back to the GitHub issue:

1. **Tick completed AC checkboxes in the spec block.** Re-fetch the body
   first to avoid clobbering concurrent edits:

   ```bash
   gh issue view <n> --json body --jq '.body' > /tmp/body.md
   # edit /tmp/body.md: change `- [ ] AC-N` → `- [x] AC-N` for each completed AC
   gh issue edit <n> --body-file /tmp/body.md
   ```

2. **Post the Implementation Summary as a comment** on the current issue
   for audit trail:

   ```bash
   gh issue comment <n> --body-file /tmp/summary.md
   ```

3. **In Implementation-only mode** — also post the Test Hints to the
   owner issue so the owner doesn't have to scrape sibling comments. The
   comment must be prefixed with a fixed marker so `review-issue` can
   detect it when checking `MISSING_HINTS`:

   ```bash
   TMP_HINTS=$(mktemp)
   cat > "$TMP_HINTS" <<EOF
   <!-- test-hints from:#<n> -->
   ## Test Hints from #<n>

   - AC-1: <observable behavior> · assert: <suggested assertion> · test file: <path>
   - AC-2: ...
   EOF
   gh issue comment $OWNER_ISSUE --body-file "$TMP_HINTS"
   ```

   The `from:#<n>` marker is mandatory — `review-issue` greps it to verify
   hints were posted for each non-owner sibling.

End with:

- Full mode: `👉 Next: run /skill review-issue <n>.`
- Implementation-only mode: `👉 Next: run /skill review-issue <n>. Test Hints posted to #<owner>.`
