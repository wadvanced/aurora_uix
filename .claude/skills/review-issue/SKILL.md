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
mix consistency  # auix.gen.tailwind_classes → format → compile --warnings-as-errors
                 # → credo --strict → dialyzer → doctor
mix test         # full suite (mix consistency does not run tests)
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
| AC-2 | <text> | FAIL | no test in test/cases/integration/ash/fields_parser_test.exs |

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
| **Both backends** (Ash + Ecto/ctx) parser-tested | PASS/FAIL/N/A | |
| Golden `%Field{}` metadata updated | PASS/FAIL/N/A | |
| Rendered output asserted in `test/cases_live/` (:index/:form/:show) | PASS/FAIL/N/A | |
| New routes registered in `test/support/app_web/routes.ex` | PASS/FAIL/N/A | |
| Database constraints (unique, FK) asserted | PASS/FAIL/N/A | |
| LiveView event coverage | PASS/FAIL/N/A | |
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

**First, define this helper and use it for every path-filtered grep:**

```bash
# Search only files in $CHANGED whose path MATCHES <path-regex> (default: all).
#   scoped '<rg-pattern>' [path-regex]
# Search only files in $CHANGED whose path does NOT match <path-regex>.
#   scoped_not '<rg-pattern>' <path-regex>
#
# Both are safe when the filtered file list comes back empty. This matters:
# plain `rg PATTERN` with no path arguments silently searches the entire
# working directory, so a naive `rg PATTERN $(echo "$CHANGED" | rg -v …)`
# reports hits in the very files it was meant to exclude.
_scoped_run() {
  local pattern="$1"; shift
  [ "$#" -eq 0 ] && return 0
  rg -n "$pattern" "$@" || true
}
scoped()     { local p="$1" f="${2:-.}"; _scoped_run "$p" $(printf '%s\n' $CHANGED | rg    "$f" || true); }
scoped_not() { local p="$1" f="$2";      _scoped_run "$p" $(printf '%s\n' $CHANGED | rg -v "$f" || true); }
```

Note `rg` has no look-around without `--pcre2`; use `scoped_not` for exclusions
rather than a negative lookahead. Where a filter appears below as
`$(echo "$CHANGED" | rg …)`, read it as the `scoped` / `scoped_not` equivalent.

**Backend abstraction boundary (blocking):**
- Ecto structs leaking outside `integration/ctx/`:
  `scoped_not 'Ecto\.Association\.|Ecto\.Embedded' 'integration/ctx/'`
- Ash structs leaking outside `integration/ash/`:
  `scoped_not 'Ash\.Resource\.(Relationships|Attribute|Aggregate)' 'integration/ash/'`
- A parser clause added to only one backend — if `$CHANGED` touches
  `integration/ash/fields_parser.ex` **xor** `integration/ctx/fields_parser.ex`,
  confirm the spec says why.

**New field type atom (blocking — the dominant failure mode):**
- If a new `:*_association` / type atom appears in `$CHANGED`, grep the whole
  `lib/` for a sibling atom and confirm every hit was consciously handled:
  `rg -n ':one_to_many_association' lib/`
  Each site needs an add / do-NOT-add decision matching the spec. Silent
  omission in `filter_preloads/1` or `replace_related_field_data/2` fails far
  from the change.

**Writes (blocking):**
- Library taking over changeset construction — it is transport-only:
  `scoped_not 'cast_assoc|cast_embed|put_assoc|manage_relationship' 'aurora_uix/guides/'`
  Hits outside `guides/` (which is demo host code) are a scope violation.

**LiveView / UI (blocking):**
- Inline `class=` outside the theme:
  `scoped_not 'class="' 'themes/'` — restricted to `templates/basic/` files
- New `auix-*` class not registered in the theme — for each new class in
  `$CHANGED`, grep `lib/aurora_uix/templates/basic/themes/base.ex`.
- Raw `<script>` in HEEx: `scoped '<script'`
- `phx-hook` without unique `id`: `scoped 'phx-hook'`
- `Heroicons.*` direct use: `scoped 'Heroicons\.'`
- `live_redirect` / `push_redirect`: `scoped 'live_redirect|push_redirect'`

**Tests (blocking):**
- Mock library: `scoped 'Mox|Mock|:meck'`
- `Process.sleep/1`: `scoped 'Process\.sleep'`
- Assertions on raw HTML strings:
  `scoped 'assert.*=~.*<' '^test/'`
- Assertions on counter-based ids (unstable across test ordering):
  `scoped 'auix-field-[a-z_]+-[a-z_]+-[0-9]' '^test/'`
- A `test/cases_live/` test whose route is missing from
  `test/support/app_web/routes.ex`.
- Wallaby (`test/browser_cases/`) where LiveViewTest would suffice
  (**non-blocking**).

**i18n (blocking):**
- User-visible string not wrapped in `dt/1`: manual scan of new strings in
  renderers/components.

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
| Backend parity: the change works for **both** Ash and Ecto, or the spec states why only one applies | | |
| Consumer audit: every site keyed off the affected type atoms has a decision matching the spec's add / do-NOT-add verdicts | | |
| Clause ordering: new parser clauses precede their catch-all — and where a function has **no** catch-all (`ash/fields_parser.ex`), the clause exists at all | | |
| Transport-only: no changeset construction added outside `lib/aurora_uix/guides/` | | |
| Migration safety: new migrations add indexes for new FKs (and a UNIQUE index where 1:1 is intended); Ash changes committed the `priv/resource_snapshots/` snapshot too | | |
| Docs: new/changed public modules carry `@moduledoc` with Key Features / Key Constraints, `@doc` + `@spec`; private functions have `@spec` | | |
| CSS: new `auix-*` classes added to `themes/base.ex` **and** the regenerated stylesheet committed | | |
| PR scope discipline: diff does not touch files unrelated to the spec (refactors, dep bumps, formatting churn elsewhere) — **flag only, non-blocking** | | |

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

1. AC-2: the Ash parser clause was added but is unreachable — it sits below
   the catch-all at `lib/aurora_uix/integration/ash/fields_parser.ex:395`.
   Required: move the `%Ash.Resource.Relationships.HasOne{}` clause above it
   and add a test in `test/cases/integration/ash/fields_parser_test.exs`
   asserting `type: :one_to_one_association`.

2. mix consistency failure (credo): `lib/aurora_uix/templates/basic/renderers/
   fields/one_to_one.ex:42` — alias order. Move `OneToOne` after `OneToMany`.

3. <next item>

### MISSING_COVERAGE   ← Full mode header
(or)
### MISSING_HINTS      ← Lite mode header

1. (Full mode) Backend parity gap: the Ecto (`ctx`) parser is tested but the
   Ash one is not. Add the mirrored fixture and assertion in
   `test/cases/integration/ash/fields_parser_test.exs`, and the golden entry
   in `test/cases/integration/fields_parser_validations_test.exs`.

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
