---
name: improve-issue
description: >
  Enrich and clarify a GitHub issue before any coding begins. Use this skill
  whenever a user says "work on issue", "implement issue", "fix issue", "start
  from a GitHub issue", or pastes issue text/URL. Always run this FIRST before
  code-issue — it produces the structured spec that code-issue consumes. Also
  trigger when the user says "improve issue description" or "clarify requirements".
---

# Skill: improve-issue

Transform a raw GitHub issue into a precise, implementation-ready specification
for this Elixir/Phoenix/Ash codebase. The enriched spec is **persisted into the
GitHub issue body** so it becomes the source of truth for `code-issue` and
`review-issue`.

---

## Step 1 — Ingest the issue

Resolve the issue number from the user input (URL, "#123", or pasted body).

Always run these read commands first — never rely on chat context:

```bash
gh issue view <n> --json title,body,labels,assignees,url
gh issue view <n> --comments
```

If the body or comments mention linked issues (e.g. `#142`, "depends on #99"),
fetch each one too. CLAUDE.md requires reading the full issue + linked issues
before starting.

If the body already contains `<!-- enriched-spec:start v1 -->`, **extract the
existing spec** from between the markers and treat it as the working draft to
update. Do not re-derive it from scratch — that biases the next run.

### Detect a propagated test-owner hint

If the body contains a line of the form `> **Test owner:** parent` or
`> **Test owner:** sibling:#<n>` (written by `split-issue` when this issue was
created as a child of a split), capture that value and use it as the default
for the Test Ownership field in Step 3. The line lives outside the
enriched-spec block; do not edit or remove it.

### Clarifying questions

If the issue is ambiguous, ask the user **one** clarifying question before
proceeding (pick the most important one). If the user is unavailable or the
ambiguity is minor, record it in **Open Questions** with a stated assumption
and continue.

---

## Step 2 — Analyse and expand

Work through these dimensions silently, then write them up.

### 2a. Domain understanding
- What feature/bug/refactor is this really about?
- Which layer(s) of the library does it touch?
  - **Parsers** — `lib/aurora_uix/integration/{ash,ctx}/fields_parser.ex`
    (backend-specific; a feature is incomplete until **both** support it)
  - **Layout / metadata** — `lib/aurora_uix/layout/`
    (`blueprint.ex`, `create_ui.ex`, `resource_metadata.ex`)
  - **Renderers** — `lib/aurora_uix/templates/basic/renderers/`
  - **Generators / handlers** — `templates/basic/{generators,handlers}/`
  - **Theme / CSS** — `templates/basic/themes/base.ex`
  - **Guide schemas** — `lib/aurora_uix/guides/{blog,inventory}/` (Ash / Ecto)
- Does it change the normalized `%Aurora.Uix.Field{}` shape or add a new
  `type` atom? If so, **every downstream consumer that pattern-matches on the
  existing atoms must be audited** — that list belongs in the spec.

### 2b. Acceptance criteria extraction
Turn every vague requirement into a concrete, testable statement. Prefer
observable rendered output or parsed metadata over prose.

```
Bad:  "has_one associations should work"
Good: "Given an Ecto schema with `has_one :spec, Child`, Ctx.FieldsParser
       produces a %Field{} with type: :one_to_one_association,
       html_type: :unimplemented, and data: %{related: Child,
       related_key: :parent_id, owner_key: :id}."
Good: "On /…/new the rendered form contains an input named
       parent[child_key][child_field] for each field in the child's :form
       layout, even though no child record exists."
```

### 2c. Edge cases & error paths
List at least 3 non-happy-path scenarios. For each: what triggers it and the
expected behaviour. For this library the recurring ones are:
- an unregistered related resource (`field.data.resource == nil`)
- an unloaded association (`%Ecto.Association.NotLoaded{}` / `%Ash.NotLoaded{}`)
  and whether the missing preload should raise or degrade
- a parser clause reached in the **wrong order** relative to a catch-all —
  note that several `ash/fields_parser.ex` functions have **no** catch-all, so
  a missing clause raises `FunctionClauseError` at blueprint-compile time
- host misconfiguration that must surface loudly rather than be swallowed

Phrasing depends on ownership (see 2g):

- **`this-issue`** — each row is a test target. The implementer will write
  the assertion.
- **non-owner** — each row describes *observable* behavior the owner can
  later assert on. Keep the same level of detail, but do not promise tests
  in this issue.

### 2d. Out-of-scope guard
State explicitly what this issue does NOT include, to prevent scope creep.

### 2e. Dependencies
- Migrations needed? Two distinct paths, split by guide backend (note
  `mix ash.codegen` exists via the `ash` dep but covers only the Ash side):
  Ecto guide schemas use hand-written migrations in `priv/repo/migrations/`;
  Ash guide resources use `mix ash_postgres.generate_migrations` and also
  produce a `priv/resource_snapshots/` snapshot that must be committed.
  Note `mix test` does **not** run migrations — CI runs `mix ecto.create &&
  mix ecto.migrate` separately.
- New Hex packages required? (justify each — `ash`, `ash_phoenix`,
  `ash_postgres`, `ecto_sql`, `phoenix_ecto` and `aurora_ctx` are already
  hard deps)
- New test routes required in `test/support/app_web/routes.ex`?
- New `auix-*` CSS classes (⇒ `themes/base.ex` +
  `mix auix.gen.tailwind_classes` + regenerated CSS committed)?
- Localization: user-visible strings go through `dt/1`
  (`use Aurora.Uix.Gettext`), extracted to `priv/gettext/*.pot`. This project
  ships no per-locale translations.

### 2f. Project notes

`aurora_uix` is a **low-code UI generation library**, not an application. It
generates LiveView index/form/show UIs from resource metadata over **two
interchangeable backends**: Ash and Ecto (via `aurora_ctx`). Keep these in mind
when expanding the spec — they shape what the AC must cover:

- **Backend abstraction boundary**: `Ecto.Association.*` appears only in
  `integration/ctx/`, `Ash.Resource.*` only in `integration/ash/`. Everything
  downstream consumes the normalized `%Field{}` atoms and must stay
  backend-agnostic. Spec both backends or say explicitly why only one.
- **New field type atoms** are the highest-risk change in this codebase. The
  spec must enumerate every consumer site keyed off the existing atoms with an
  explicit **add / do-NOT-add verdict and justification**. Silent omission
  fails far from the change.
- **Renderers** implement the `Aurora.Uix.Renderer` behaviour (`render/1`) and
  are dispatched from `templates/basic/renderers/default_renderer.ex`. Prefer
  swapping `auix` keys and delegating to `Renderer.render_inner_elements/1`
  over hand-written child markup.
- **The library is transport-only for writes.** It renders input names and
  forwards params untouched; it never builds a changeset. Host applications
  declare `cast_assoc`/`cast_embed` (Ecto) or `manage_relationship` (Ash).
  Do not spec library-owned changeset construction without flagging it as a
  significant scope expansion.
- **Documentation is gated** by `doctor`: `@moduledoc` with
  `## Key Features` / `## Key Constraints`, `@doc` + `@spec` on public
  functions (first clause only), `@spec` on private functions too.
- **Tests**: `use Aurora.UixWeb.Test.UICase, :phoenix_case` +
  `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`. Layers:
  `test/cases/integration/` (parser, no DB), `test/cases/` (metadata/layout,
  no DB), `test/cases_live/` (LiveView — the default for UI work),
  `test/browser_cases/` (Wallaby, last resort), `test/doctests/`.
  There is no `FeatureCase` and no `test/support/factory.ex`; sample data comes
  from `test/support/helper.ex`. No mocks; no `Process.sleep/1`.
- **Gate**: `mix consistency` (`auix.gen.tailwind_classes → format →
  compile --warnings-as-errors → credo --strict → dialyzer → doctor`) then
  `mix test`. There is no `mix precommit`.

### 2g. Test ownership

A single issue does **not** automatically own its own tests. Decide who will
write the integrated tests for the behaviors this issue introduces:

- **`this-issue`** (default) — standalone issue, or the designated test-owner
  of a split. Tests for every AC live in this issue's diff.
- **`parent:#<n>`** — this issue is a child of split `#<n>`, and the parent
  keeps the integrated test surface. Children write implementation + smoke
  only; downstream skills (`code-issue`, `review-issue`) will skip per-AC
  test authoring and instead post Test Hints to the parent.
- **`sibling:#<n>`** — this issue is a child of a split, and a dedicated
  test-focused sibling (`#<n>`) owns the integrated test surface for all
  siblings. Same behavior as `parent`, but Test Hints flow to `#<n>`.

Pick the value using, in order:

1. The propagated `> **Test owner:** ...` line in the body (if present).
2. The user's stated intent in chat.
3. Default to `this-issue` if there is no parent reference and no hint.

Record the choice in the spec template under `### Test Ownership`. The
downstream skills branch on this field — getting it right here saves
re-running the loop.

---

## Step 3 — Write the enriched spec

Output a markdown block wrapped in idempotent markers. This block is appended
to the issue body if absent, or replaced in place if already present.

```markdown
<!-- enriched-spec:start v1 -->
## Enriched Spec

### Summary
<2-3 sentence plain-language description>

### Test Ownership
Owner: this-issue | parent:#<n> | sibling:#<n>
Rationale: <one line — why this issue holds / delegates tests>

### Acceptance Criteria
- [ ] AC-1: <testable criterion>
- [ ] AC-2: ...
(minimum 3, maximum 10)

### Affected Files / Modules (estimated)
- `lib/aurora_uix/integration/{ash,ctx}/fields_parser.ex` — <clause added, and why order matters>
- `lib/aurora_uix/layout/<module>.ex` — <consumer verdict: add / do-NOT-add + why>
- `lib/aurora_uix/templates/basic/renderers/<renderer>.ex` — <reason>
- `lib/aurora_uix/templates/basic/themes/base.ex` — <new auix-* classes, if any>
- `lib/aurora_uix/guides/{blog,inventory}/<schema>.ex` — <demo schema, if any>
- `priv/repo/migrations/YYYYMMDDHHMMSS_<name>.exs` — hand-written (Ecto) or via `mix ash_postgres.generate_migrations` (Ash, + snapshot)
- `test/support/app_web/routes.ex` — <route registration, if a cases_live test is added>
- `test/cases/integration/{ash,ctx}/fields_parser_test.exs` — <test file>  ← omit when Owner != this-issue; replace with one line: `→ Tests owned by <owner>`
- `test/cases_live/<feature>_test.exs` — <test file>  ← same rule

### Edge Cases & Error Handling
| Scenario | Expected behaviour |
|---|---|
| ... | ... |

### Out of Scope
- ...

### Dependencies
- Migrations: yes/no — <Ecto hand-written and/or Ash generated + snapshot>
- New packages: none / `<package> ~> x.y` — <justification>
- Test routes: none / <routes.ex registrations needed>
- New `auix-*` CSS classes: yes/no — <requires themes/base.ex + regenerated CSS>
- Localization: yes/no — <new `dt/1` strings>

### Project Conventions Touched
<list of conventions this issue must respect, e.g. "backend abstraction
boundary — Ecto structs stay in integration/ctx", "both parsers must support
it", "renderer dispatch via default_renderer.ex", "library stays transport-only
for writes", "doctor doc coverage: @moduledoc Key Features/Key Constraints,
@spec on private functions", "auix-* classes regenerated">

### Open Questions
<remaining ambiguities with assumed defaults; leave empty if none>

<!-- enriched-spec:end -->
```

### Persist back to the issue (REQUIRED)

The spec is the source of truth for downstream skills, so it must be written
into the issue body. Do this idempotently:

```bash
# 1. Save the spec block (just the marker-wrapped section above) to a file:
TMP_SPEC=$(mktemp)
cat > "$TMP_SPEC" <<'SPEC'
<!-- enriched-spec:start v1 -->
... spec content ...
<!-- enriched-spec:end -->
SPEC

# 2. Fetch the current body:
TMP_BODY=$(mktemp)
gh issue view <n> --json body --jq '.body' > "$TMP_BODY"

# 3. Replace existing block if present, else append:
if grep -q '<!-- enriched-spec:start v1 -->' "$TMP_BODY"; then
  awk -v spec_file="$TMP_SPEC" '
    BEGIN { while ((getline line < spec_file) > 0) spec = spec line ORS }
    /<!-- enriched-spec:start v1 -->/ { printf "%s", spec; skip=1; next }
    /<!-- enriched-spec:end -->/ { skip=0; next }
    !skip { print }
  ' "$TMP_BODY" > "$TMP_BODY.new" && mv "$TMP_BODY.new" "$TMP_BODY"
else
  printf '\n\n' >> "$TMP_BODY"
  cat "$TMP_SPEC" >> "$TMP_BODY"
fi

# 4. Push the updated body back:
gh issue edit <n> --body-file "$TMP_BODY"
```

This is idempotent: re-running `improve-issue` replaces the spec block in place
without stacking duplicates and without overwriting the original description.

---

## Step 4 — Self-review loop

Before pushing the spec, silently ask yourself:
1. Test Ownership is set, and every AC is phrased as **observable behavior**
   (input → output / state change / event) so the owner can assert it
   directly. If Owner is `this-issue`, can every AC also be turned into an
   ExUnit test from this issue's diff alone? If not, rewrite.
2. Is there at least one error-path AC? If not, add one.
3. Are the affected files specific enough that a developer won't have to guess
   between `lib/aurora_uix/integration/…`, `lib/aurora_uix/layout/…` and
   `lib/aurora_uix/templates/basic/…`? If not, add detail.
4. If a new `%Field{}` type atom is introduced, does the spec give an explicit
   **add / do-NOT-add verdict with justification for every consumer site**?
   A bare list of files is not enough — omission is the dominant failure mode.
5. Are **both backends** (Ash and Ecto/`ctx`) covered, or is it stated
   explicitly why only one applies?
6. Does the spec mention every convention this change must respect (backend
   abstraction boundary, transport-only writes, doctor doc coverage, `auix-*`
   class regeneration, test routes)? If not, expand 2f.
7. Would a mid-level Elixir developer unfamiliar with this library be unblocked
   by this spec alone? If not, expand.

---

## Step 5 — Output

After the spec is written to the issue body, emit the spec verbatim in chat for
visibility, then end with:

```
✅ Enriched spec written to issue #<n>.
👉 Next: run /skill code-issue <n> to implement.
```
