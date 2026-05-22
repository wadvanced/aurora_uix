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
- Which Phoenix/Ash layer(s) does it touch? (Router, LiveView, Ash domain,
  Ash resource, migration via `mix ash.codegen`, Oban job, PubSub, mail, etc.)
- Does it affect the data model? List affected Ash resources.

### 2b. Acceptance criteria extraction
Turn every vague requirement into a concrete, testable statement.

```
Bad:  "Borrowers should be able to request a loan more easily"
Good: "Given an authenticated borrower with completed KYC, submitting the
       loan-request LiveView form with valid amount and term creates a
       Loan resource in :pending status and emits a `loan.requested` event
       with `process_id` set to the originating request id."
```

### 2c. Edge cases & error paths
List at least 3 non-happy-path scenarios. For each: what triggers it, what is
the expected behaviour (`{:error, %Ash.Error{...}}` shape, HTTP status, flash
message). Include at least one authorization failure path when policies apply.

Phrasing depends on ownership (see 2g):

- **`this-issue`** — each row is a test target. The implementer will write
  the assertion.
- **non-owner** — each row describes *observable* behavior the owner can
  later assert on. Keep the same level of detail, but do not promise tests
  in this issue.

### 2d. Out-of-scope guard
State explicitly what this issue does NOT include, to prevent scope creep.

### 2e. Dependencies
- Migrations needed? (generated via `mix ash.codegen <name>` then
  `mix ash.migrate`)
- New Hex packages required? (justify each — note that this project uses `Req`
  for HTTP, never add `:httpoison` / `:tesla` / `:httpc`)
- External services / APIs?
- Feature flags?
- Localization keys required (gettext, default `es_DO`, also `en`)?

### 2f. Elixir/Phoenix/Ash project notes

Keep these in mind when expanding the spec — they shape what the AC must cover:

- **Ash, not bare Ecto**: business logic lives in Ash resources/domains.
  Multi-step DB ops use `Ash.transaction/1`, not `Ecto.Multi` or
  `Repo.transaction`.
- **Ash policies**: authorization is declared on the resource, not enforced
  in LiveView/controllers. AC must specify which roles are allowed.
- **Soft delete only**: business records use `is_deleted` + `deleted_at`.
  Never spec a hard delete.
- **Event audit trail**: any state-changing operation must thread
  `process_id` and `parent_event_id`. Spec must mention which events are
  emitted.
- **Localization**: every user-visible string must go through gettext.
  Default locale is `es_DO`; `en` is the test/dev locale.
- **LiveView (Phoenix 1.8)**:
  - Templates start with `<Layouts.app flash={@flash} ...>`
  - Use `<.icon>`, `<.input>`, function components from `core_components.ex`;
    no inline `class=` on LiveView templates
  - Use streams for collections
  - Avoid LiveComponents unless there is a specific, strong need
  - No raw `<script>` tags; colocated hooks only
  - Use `<.link navigate>` / `push_navigate` (not deprecated `live_redirect`)
- **Tests**: `DataCase` (business logic), `ConnCase` (HTTP/LiveView),
  `FeatureCase` (Wallaby — only when LiveViewTest is genuinely insufficient).
  Factories live in `test/support/factory.ex` (`build/2`, `insert!/2`).
  No mocks; no `Process.sleep/1`.

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
- `lib/loga_money/<domain>/<resource>.ex` — <reason>
- `lib/loga_money_web/live/<context>/<page>_live.ex` — <reason>
- `priv/repo/migrations/YYYYMMDDHHMMSS_<name>.exs` — generated via `mix ash.codegen`
- `test/loga_money/<domain>/<resource>_test.exs` — <test file>  ← omit when Owner != this-issue; replace with one line: `→ Tests owned by <owner>`
- `priv/gettext/{en,es_DO}/LC_MESSAGES/...` — <locale keys, if user-visible strings change>

### Edge Cases & Error Handling
| Scenario | Expected behaviour |
|---|---|
| ... | ... |

### Out of Scope
- ...

### Dependencies
- Migrations: yes/no — <details>
- New packages: none / `<package> ~> x.y` — <justification>
- External services: none / <name>
- Feature flags: none / <name>
- Localization keys: yes/no

### Project Conventions Touched
<list of CLAUDE.md rules this issue must respect, e.g. "soft-delete only",
"event audit fields", "gettext for new strings", "Ash.transaction wraps
multi-step actions">

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
    /<!-- enriched-spec:start v1 -->/ { print spec; skip=1; next }
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
2. Is there at least one error-path AC and at least one authorization-path AC
   (when policies apply)? If not, add them.
3. Are the affected files specific enough that a developer won't have to guess
   between `lib/loga_money/...` and `lib/loga_money_web/...`? If not, add detail.
4. Does the spec mention every CLAUDE.md convention this change must respect
   (Ash, soft delete, events, gettext, LiveView rules)? If not, expand 2f.
5. Would a mid-level Elixir/Ash developer be unblocked by this spec alone?
   If not, expand.

---

## Step 5 — Output

After the spec is written to the issue body, emit the spec verbatim in chat for
visibility, then end with:

```
✅ Enriched spec written to issue #<n>.
👉 Next: run /skill code-issue <n> to implement.
```
