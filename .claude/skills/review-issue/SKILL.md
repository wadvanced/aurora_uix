---
name: review-issue
description: >
  Review and score the implementation produced by code-issue against the
  enriched spec from improve-issue. Use this skill when the user says "review
  the implementation", "check completeness", "validate coverage", or after
  code-issue finishes. Runs the project quality gate (mix consistency + mix test),
  produces a scored report, and writes outstanding gaps into the issue body
  marker block so code-issue Mode B can pick them up. Always run after
  code-issue, before deciding the issue is done.
---

# Skill: review-issue

Act as a senior Elixir/Phoenix/Ash code reviewer. Run real checks (not just
inspection), score the implementation, and persist the gap list into the
GitHub issue body so the next `code-issue` iteration can read it without
relying on chat context.

---

## Inputs

Always re-read the issue from GitHub — never trust chat context alone:

```bash
gh issue view <n> --json title,body,url
gh issue view <n> --comments
```

Extract the enriched spec from the `<!-- enriched-spec:start v1 -->` block.
This is the source of truth for what the implementation must satisfy.

**Read `### Test Ownership` from the spec.** It drives whether this review
runs in Full mode or Lite mode (mechanical branch — no judgment call):

| `Owner:` value | Review mode |
|---|---|
| `this-issue` | **Full** — Step 3 (Test Coverage) runs; PASS in Step 1 requires a test in `$CHANGED` |
| `parent:#<n>` or `sibling:#<n>` | **Lite** — Step 3 is skipped; PASS in Step 1 requires implementation + a Test Hint comment on `#<n>` (see Step 2) |

If `Test Ownership` is absent, default to **Full** and emit a single
INFO-level flag in Step 4 noting the missing field.

**When this issue is itself a test-owner** (Owner = `this-issue` AND the
body contains a `<!-- split-children:start v1 -->` block listing siblings
that delegated tests here), expand the AC list in Step 1 and the Test
Coverage table in Step 3 to grade the **union** of:
- this issue's own ACs, AND
- every sibling AC whose body says `> **Test owner:** parent` (current
  issue is the parent) or `sibling:#<this-issue>`.

Fetch each delegating sibling's enriched-spec block and pull their AC text
verbatim. Treat them as additional rows in this issue's AC table.

---

## Scope — review only what changed

Compute the review scope before anything else:

```bash
git fetch origin main --quiet
CHANGED=$(git diff --name-only origin/main...HEAD)
echo "$CHANGED"
```

Every file path you cite in flags, `INCOMPLETE_TASKS`, or `MISSING_COVERAGE`
**must** appear in `$CHANGED`, or be a test file that exercises code in
`$CHANGED`. If you cannot tie a finding to a changed file, **drop it**. Do
not flag pre-existing code, do not wander into unrelated modules, do not
cite paths from memory.

---

## Step 0 — Run the real quality gate

Before any scoring, run the actual project checks. **Reviews based only on
code inspection are unreliable; running the gate is the only way to know.**

```bash
mix consistency   # format → compile → docs → credo → doctor → dialyzer
mix test        # full suite (precommit does not run tests)
```

Capture exit codes and full failure output for each command.

- Any **non-zero exit** is a **blocking quality flag**.
- Append every failure to `INCOMPLETE_TASKS` with file:line and the failing
  assertion / lint message / dialyzer warning verbatim. The next
  `code-issue` Mode B iteration must be able to act on these without re-running
  the checks.

If the gate is green, continue to Step 1. If red, you can still score the
implementation — but the decision in Step 7 is forced to `🔄 LOOP`.

---

## Step 1 — AC completeness review

For each Acceptance Criterion in the spec, mark **PASS / FAIL / N/A**:

- **Full mode (`Owner: this-issue`)**:
  - **PASS** — implemented in `$CHANGED` *and* covered by a test in `$CHANGED`
  - **FAIL** — missing, broken, stubbed, or untested
- **Lite mode (`Owner: parent:#<n>` / `sibling:#<n>`)**:
  - **PASS** — implemented in `$CHANGED` *and* the owner issue has a
    `<!-- test-hints from:#<this> -->` comment containing this AC's ID
    (verify via the grep in Step 2)
  - **FAIL** — implementation missing or the hint comment is missing /
    does not list this AC
- **N/A** — the spec marks this AC out of scope for this iteration

No 0–10 scoring. No "partial". If it isn't fully done and tested, it's FAIL.

Output (omit PASS rows):

```
### AC Completeness

| AC | Description | Verdict | Evidence (file:line) |
|---|---|---|---|
| AC-2 | <text> | FAIL | no test in test/loga_money/foo_test.exs |

PASS: AC-1, AC-3, AC-4
N/A:  (none)
```

Every FAIL goes into `INCOMPLETE_TASKS`.

## Step 2 — Lite-mode Test Hints verification (skip in Full mode)

Only in Lite mode. Resolve the owner number from the `Owner:` line as
`$OWNER_ISSUE`, then:

```bash
gh issue view $OWNER_ISSUE --comments --json comments --jq '.comments[].body' \
  | grep -F "<!-- test-hints from:#<n> -->" \
  > /tmp/hints.md
```

If `/tmp/hints.md` is empty, every AC in this issue becomes a FAIL with the
reason `no test-hints comment on owner #<owner>`. Add a single entry to
`MISSING_HINTS` (see Step 6):

```
1. AC-*: no test-hints comment on owner #<owner>.
   Required: re-run /skill code-issue <n> so it posts Test Hints to #<owner>.
```

If the comment exists, for each AC in this issue grep for its ID in
`/tmp/hints.md`. Missing AC IDs become individual `MISSING_HINTS` entries
naming the missing AC.

---

## Step 3 — Test coverage review (Full mode only)

**In Lite mode, skip this entire step.** Emit one line:
`Test Coverage: N/A — tests owned by #<owner>` and move on to Step 4.

Binary PASS / FAIL / N/A per dimension. N/A is only valid when the dimension
genuinely does not apply (e.g. no LiveView in the diff → LiveView row is N/A).

```
### Test Coverage

| Dimension | Verdict | Evidence |
|---|---|---|
| Happy path covered for every AC | PASS/FAIL/N/A | |
| Error / edge path for every AC | PASS/FAIL/N/A | |
| Ash changeset / validation errors asserted | PASS/FAIL/N/A | |
| Ash policy / authorization asserted | PASS/FAIL/N/A | |
| Database constraints (unique, FK) asserted | PASS/FAIL/N/A | |
| LiveView event coverage | PASS/FAIL/N/A | |
| Async / Oban path coverage | PASS/FAIL/N/A | |
| Locale keys present in en + es_DO | PASS/FAIL/N/A | |
```

Every FAIL goes into `MISSING_COVERAGE`.

---

## Step 4 — Project quality flags (only what the gate cannot see)

`mix consistency` already enforces formatting, compilation warnings, doc
coverage, **credo** (long parameter lists, complex `with`, dynamic atom
creation, naming conventions, unused code, cyclomatic complexity, most of
the AGENTS.md Elixir anti-patterns), **doctor**, and **dialyzer** (type
errors, pattern coverage, dead code).

**Do not re-flag anything in those categories by inspection.** If
`mix consistency` was green, those checks passed — trust it. Your job here is
to flag only what the gate cannot see.

For each flag below, run the **exact grep** shown and cite `file:line`. If
grep returns nothing, do not emit a flag for it. Restrict every grep to
`$CHANGED` paths.

**Ash / data (blocking):**
- Missing Ash policy where the spec requires authorization — confirm
  by reading the resource files in `$CHANGED`.
- `Ecto.Multi` / `Repo.transaction` instead of `Ash.transaction`:
  `rg -n 'Ecto\.Multi|Repo\.transaction' $CHANGED`
- Hard delete of business data (no `is_deleted`/`deleted_at`):
  `rg -n 'Repo\.delete\(|destroy:' $CHANGED`
- Event-emitting actions missing `process_id` / `parent_event_id`:
  `rg -n 'process_id|parent_event_id' $CHANGED` — confirm both threaded.
- N+1: Ash queries the spec implies will load associations but lack `load:`.

**LiveView / UI (blocking):**
- Inline `class=` on LiveView templates:
  `rg -n 'class="' $(echo "$CHANGED" | rg 'lib/.*_web/.*\.(heex|ex)$')`
- Bare `<button>` / `<div class="card">` instead of function components:
  `rg -n '<button|<div class="card' $CHANGED`
- `<.flash_group>` outside `layouts.ex`:
  `rg -n '<\.flash_group' $CHANGED`
- LiveView template missing `<Layouts.app>`:
  for each `*_live.ex` in `$CHANGED`, grep `Layouts.app`.
- Raw `<script>` in HEEx: `rg -n '<script' $CHANGED`
- `phx-hook` without unique `id`: `rg -n 'phx-hook' $CHANGED`
- `Heroicons.*` direct use: `rg -n 'Heroicons\.' $CHANGED`
- `live_redirect` / `push_redirect`: `rg -n 'live_redirect|push_redirect' $CHANGED`

**Tests (blocking):**
- Mock library: `rg -n 'Mox|Mock|:meck' $CHANGED`
- `Process.sleep/1`: `rg -n 'Process\.sleep' $CHANGED`
- `Ash.create!` for test seeding instead of factories:
  `rg -n 'Ash\.create!' $(echo "$CHANGED" | rg '^test/')`
- Assertions on raw HTML strings:
  `rg -n 'assert.*=~.*<' $(echo "$CHANGED" | rg '^test/')`
- Wallaby/`FeatureCase` where LiveViewTest would suffice (**non-blocking**).

**i18n (blocking):**
- User-visible string not wrapped in gettext (manual scan of new strings).
- New `msgid` present in `priv/gettext/en/**/*.po` but missing from
  `priv/gettext/es_DO/**/*.po` (or vice versa) — diff the `.po` files.

Output (omit categories with no findings):

```
### Quality Flags
- [BLOCKING] <file>:<line> — <issue> (grep: <command>)
- [INFO]     <file>:<line> — <issue>
(or "None ✓")
```

---

## Step 5 — Spec & integrity review (what only a reviewer can catch)

Binary PASS / FAIL. Every FAIL is **blocking**.

| Check | Verdict | Evidence |
|---|---|---|
| Spec drift: every AC addressed in the diff, no scope creep beyond AC | | |
| Authorization: each role-restricted action has an Ash policy in `$CHANGED` AND a test asserting `{:error, %Ash.Error.Forbidden{}}` for the wrong actor | | |
| Multi-tenancy: tenant-scoped queries pass `actor:` (no raw `Ash.read` without actor) | | |
| Migration safety: new migrations have a working `down/0` (or are documented irreversible), add indexes for new FKs, do not drop columns referenced in `$CHANGED` | | |
| Audit trail: actions emitting events thread `process_id` and `parent_event_id` end-to-end | | |
| PR scope discipline: diff does not touch files unrelated to the spec (refactors, dep bumps, formatting churn elsewhere) — **flag only, non-blocking** | | |
| i18n parity: every new `msgid` appears in both `en` and `es_DO` `.po` files | | |

---

## Step 6 — Build the gap report

Produce two named lists. Every entry **must** include:

  (a) the exact file path from `$CHANGED`,
  (b) the function or test name to add/change, and
  (c) the assertion or behavior expected.

No "consider improving X", no vague suggestions — those are useless to the
next iteration. If you cannot give all three, drop the entry. Include
exit-code captures from Step 0 verbatim where relevant.

```
### INCOMPLETE_TASKS

1. AC-2: changeset error for duplicate email is returned but not tested.
   Required: in `test/loga_money/accounts_test.exs`, add a test that
   asserts `{:error, %Ash.Error.Invalid{}}` with `field: :email` on a
   second `create_user/1` call with the same email.

2. mix consistency failure (credo): `lib/loga_money/loans/loan.ex:42` —
   "Function `disburse/2` is too complex (cyclomatic > 9)". Refactor.

3. <next item>

### MISSING_COVERAGE   ← Full mode header
(or)
### MISSING_HINTS      ← Lite mode header

1. (Full mode) Error path coverage for `request/2`: no test covers the policy
   rejection for non-borrower actors. Add a test in
   `test/loga_money/loans_test.exs` that passes an investor actor and
   asserts `{:error, %Ash.Error.Forbidden{}}`.

1. (Lite mode) AC-3 missing from test-hints comment on owner #<owner>.
   Required: re-run /skill code-issue <n> so the Test Hints comment lists
   AC-3 with a concrete assertion suggestion.

2. <next item>
```

Pick exactly one header per iteration — never emit both. The header name
goes into the marker block written in Step 8 unchanged so `code-issue` can
detect which mode the gap report came from.

---

## Step 7 — Decision

```
### Review Decision

Review mode:          Full / Lite (owner: #<n>)
mix consistency:        ✓ green / ✗ red
mix test:             ✓ green / ✗ red
AC FAILs:             N
Coverage FAILs:       N (— in Lite mode this row is always 0)
Hint FAILs:           N (Lite mode only)
Step 5 FAILs:         N
Blocking quality flags: N
```

Apply this logic in order:

1. If `mix consistency` or `mix test` is red → `🔄 LOOP`.
2. If any **blocking** quality flag is present → `🔄 LOOP`.
3. If any AC, Coverage, or Step 5 row is FAIL → `🔄 LOOP`.
4. Otherwise → `✅ DONE`.

---

## Step 8 — Persist the gap report to the issue body

The gap report goes into a marker block in the issue body. **Replace, never
append** — each iteration overwrites the block with the current outstanding
gaps.

```bash
# Compose the new gap block:
TMP_GAPS=$(mktemp)
cat > "$TMP_GAPS" <<'GAPS'
<!-- review-gaps:start v1 -->
## Review Gaps (iteration <i>, <YYYY-MM-DD>, mode: Full|Lite)

### INCOMPLETE_TASKS
... (or empty section)

### MISSING_COVERAGE      ← Full mode header — omit in Lite mode
### MISSING_HINTS         ← Lite mode header — omit in Full mode
... (or empty section)

### Quality Flags
... (or "None ✓")
<!-- review-gaps:end -->
GAPS

# Fetch the body, splice the block in (replace if present, else append):
TMP_BODY=$(mktemp)
gh issue view <n> --json body --jq '.body' > "$TMP_BODY"

if grep -q '<!-- review-gaps:start v1 -->' "$TMP_BODY"; then
  awk -v gaps_file="$TMP_GAPS" '
    BEGIN { while ((getline line < gaps_file) > 0) gaps = gaps line ORS }
    /<!-- review-gaps:start v1 -->/ { print gaps; skip=1; next }
    /<!-- review-gaps:end -->/ { skip=0; next }
    !skip { print }
  ' "$TMP_BODY" > "$TMP_BODY.new" && mv "$TMP_BODY.new" "$TMP_BODY"
else
  printf '\n\n' >> "$TMP_BODY"
  cat "$TMP_GAPS" >> "$TMP_BODY"
fi

gh issue edit <n> --body-file "$TMP_BODY"
```

**On `✅ DONE`, write the block with a single completion line** (not empty —
later sessions need to distinguish "completed clean" from "never reviewed"):

```
<!-- review-gaps:start v1 -->
## Review Gaps

✅ No outstanding gaps. (iteration <i>, <YYYY-MM-DD>)
<!-- review-gaps:end -->
```

---

## Step 9 — Output

Emit the full review report (sections 1–5) in chat. End with:

- On `🔄 LOOP`:
  ```
  🔄 LOOP — gaps written to issue #<n>.
  👉 Next: run /skill code-issue <n> in Mode B.
  ```
- On `✅ DONE`:
  ```
  ✅ DONE — issue #<n> review is clean.
  ```

---

## Tone & output budget

Be direct and specific. The purpose of this review is to make the code
better, not to validate effort.

- Emit only **failing** rows in tables. Omit PASS rows (list them as a
  single comma-separated line under the table).
- Do not echo the spec back. Do not summarize what the implementation does.
- Total chat report **≤ 150 lines**. If you would exceed that, you are
  over-explaining — cut.
