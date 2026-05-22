---
name: orchestrate-issue
description: >
  Coding loop for a GitHub issue that already has an enriched spec in this
  Elixir/Phoenix/Ash codebase. Use when the user says "run the coding loop",
  "code → review this issue", "handle the implementation of this issue", or
  wants the code → review → loop pipeline run in one go. Requires
  `improve-issue` to have been run first — this skill does NOT enrich specs.
  The GitHub issue is the source of truth: spec lives in the enriched-spec
  marker block, outstanding gaps live in the review-gaps marker block. On
  ✅ DONE, this skill runs mix test as the final gate, then auto-invokes
  pr-from-issue.
---

# Skill: orchestrate-issue

Run the code → review loop for a GitHub issue whose enriched spec already
lives in the issue body. State is passed **through the GitHub issue itself**
(marker blocks in the body), not through chat context — so any iteration can
be resumed in a future session.

Spec enrichment is a separate, analysis-oriented concern handled by
`improve-issue` (intended to be run with a more capable model). This skill is
deliberately scoped to the mechanical coding loop so it can be run with a
smaller, coding-oriented model.

---

## Required input

The issue number (or URL). Resolve to a numeric `<n>` and pass it explicitly to
every sub-skill invocation. Do not rely on context from prior runs.

## Precondition

The issue body **must already contain** the `<!-- enriched-spec:start v1 -->`
marker block. If it does not, fail fast — do not invoke `improve-issue` from
here. The user is expected to have run `improve-issue` first (typically with a
more capable model).

## Defaults (no prompting)

| Setting | Default |
|---|---|
| Max iterations | 3 |
| AC threshold | 8.0 |
| Test threshold | 8.0 |

The user can override these by stating values in the request. Otherwise use
defaults silently — do not interrupt with a configuration prompt.

---

## Pipeline

```
[INPUT: issue #<n> with enriched-spec block already in body]
         │
         ▼
   Phase 0 — precondition check
         │
         ▼
┌─────────────────────────┐
│  code-issue <n>         │  Mode A on iter 1; Mode B (reads review-gaps
│                         │  block) on iter 2+
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  review-issue <n>       │  runs mix consistency + mix test, writes
│                         │  review-gaps block to issue body
└─────────────────────────┘
         │
   decision?
         │
   ✅ DONE  → run mix test final gate → invoke pr-from-issue
   🔄 LOOP  → if iter < max: code-issue Mode B
              if iter = max: post needs-followup label, stop
```

---

## Phase 0 — Precondition check

State: `🔎 Phase 0 — checking issue #<n> has an enriched spec...`

Verify the issue body already contains the enriched-spec marker. Do not
attempt to enrich it from here.

```bash
gh issue view <n> --json body --jq '.body' \
  | grep -q '<!-- enriched-spec:start v1 -->' \
  || { echo "❌ Issue #<n> has no enriched spec. Run /skill improve-issue <n> first (preferably with a more capable model), then re-run orchestrate-issue."; exit 1; }
```

If the check fails, stop with that message — do not proceed to Phase 1.

After the enriched-spec check passes, grep the body for the `Owner:` line
inside `### Test Ownership`:

```bash
OWNER=$(gh issue view <n> --json body --jq '.body' \
  | awk '/### Test Ownership/{flag=1; next} flag && /^Owner:/{print; exit}' \
  | sed 's/^Owner: //')
echo "Owner: ${OWNER:-this-issue}"
```

If absent, default to `this-issue` and surface a single-line warning in
the final summary. Capture this as `$OWNER_MODE`:

| `$OWNER` matches | `$OWNER_MODE` |
|---|---|
| `this-issue` (or absent) | `full` |
| `parent:#*` or `sibling:#*` | `lite` |

State: `🔎 Phase 0 complete — enriched spec found on issue #<n>. Test owner: ${OWNER:-this-issue} (mode: $OWNER_MODE).`

---

## Phase 1 — Code + Review loop

For each iteration starting at 1:

### 1a. Code

State: `⚙️ Iteration <i> — running code-issue on #<n>...`

Invoke `code-issue` with the issue number.
- Iteration 1 → Mode A (read enriched-spec block)
- Iteration 2+ → Mode B (read review-gaps block — `INCOMPLETE_TASKS` and
  `MISSING_COVERAGE`)

`code-issue` ticks completed AC boxes in the issue body and posts an
implementation summary as a comment for audit trail.

### 1b. Review

State: `🔍 Iteration <i> — running review-issue on #<n>...`

Invoke `review-issue` with the issue number. It runs `mix consistency` and
`mix test`, scores the work, and writes the `review-gaps` block to the issue
body (replacing any prior content of that block).

### 1c. Loop decision

Read `review-issue`'s decision:

- **`✅ DONE`** → continue to Phase 2.
- **`🔄 LOOP`** with `iter < max` → increment, return to 1a.
- **`🔄 LOOP`** with `iter = max` → emit warning, post follow-up artefacts on
  the issue, then stop:

  ```bash
  gh issue edit <n> --add-label needs-followup
  gh issue comment <n> --body "⚠️ orchestrate-issue stopped after $MAX iterations. Outstanding gaps remain in the review-gaps block of the body. Address manually or re-run /skill orchestrate-issue <n>."
  ```

  State:
  ```
  ⚠️ Max iterations (<max>) reached. Outstanding gaps in issue #<n> body
     under <!-- review-gaps:start v1 -->.
     Recommend addressing manually or raising a follow-up issue.
  ```

  Stop.

---

## Phase 2 — Final gate + PR

This phase only runs after `review-issue` returned `✅ DONE`.

### 2a. Final mix test

The coding loop is closed by one more full `mix test` run, regardless of what
`review-issue` already ran. This catches any drift between iterations.

```bash
mix test
```

- **Green** → continue to 2b.
- **Red** → append failures to the `review-gaps` block (use the same splice
  procedure as `review-issue`), then go back to Phase 1a (counts against
  `max iterations`). If already at max, follow the max-iterations stop above.

In **Lite mode (`$OWNER_MODE = lite`)**, a green `mix test` does **not**
indicate that new behavior is covered — it only indicates no regression.
That is expected: tests for new ACs will be authored at the owner issue.
Make this explicit in the final summary so the user is not surprised by a
"passing" PR with zero new test files.

### 2b. Mark issue ready for PR

`pr-from-issue` requires the body to contain the literal phrase
`Issue is completed and ready to be closed.`. Add it idempotently:

```bash
gh issue view <n> --json body --jq '.body' > /tmp/body.md
if ! grep -q 'Issue is completed and ready to be closed.' /tmp/body.md; then
  printf '\n\n%s\n' 'Issue is completed and ready to be closed.' >> /tmp/body.md
  gh issue edit <n> --body-file /tmp/body.md
fi
```

### 2c. Invoke pr-from-issue

State: `🚀 Phase 2 — running pr-from-issue on #<n>...`

Invoke `pr-from-issue` with the issue number. It will run `mix test` again
(belt-and-braces) and create the PR.

---

## Final summary

After ✅ done or ⚠️ max-iter stop, emit:

```
## Issue #<n> orchestration summary

**Title:** <title>
**Iterations:** <i>
**Test owner mode:** Full (this-issue) / Lite (owner: #<n>)
**Final AC score:** X.X / 10
**Final test score:** X.X / 10 (— in Lite mode this row is "N/A — owner #<n>")
**Status:** ✅ Complete and PR opened / ⚠️ Partial (see review-gaps block)
**Tests authored here:** <N> / 0 (in Lite mode 0 is expected; integrated tests live on #<owner>)

**Files changed:**
- <list>

**PR:** <url, if created>
```

If a PR was created, show its URL. If max iterations was hit, point to the
`review-gaps` block in the issue body and the `needs-followup` label.
