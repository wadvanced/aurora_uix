---
name: pr-from-issue
description: >
  Open the PR for ONE section of an enriched-spec-v2 GitHub issue, after
  review-issue has approved it. Use this skill when the user says "pr from
  issue <n> <SEC-ID>", "open the PR", "ship this section", or right after
  review-issue returns DONE. Owns the section's identity — branch, PR title,
  issue reference — and delegates gate, tests, push, body and PR creation to
  `do-pr`. Always run review-issue first.
---

# Skill: pr-from-issue

Ship exactly one reviewed section. This skill owns the **issue-side** checks and
the section's identity; `do-pr` owns everything about making a PR. Do not
re-implement a `do-pr` step here.

## Non-negotiables

1. **One section per run.** One branch, one title. Never bundle two.
2. **Ship only what review approved.** The gate is the section's row in the
   `<!-- review-table #<n> -->` comment reading `COMPLETED` — not the
   issue-level completion phrase, which appears only once *every* section is
   done and would block every section PR but the last.
3. **This skill never writes to the issue.** No body edit, no checkbox, no
   comment. The completion phrase and the review table belong to `review-issue`.
4. **Never touch labels.** `approved` / `amends-required` are human-only
   (house-conventions H-6). This skill adds and removes no label on the PR or
   the issue.
5. **Every halt emits a terminal `STATUS: BLOCKED — <slug>` line**
   (`../shared/escalation.md`). After the status line, write nothing and read
   nothing further.
6. **Turn discipline.** Follow `../shared/turn-discipline.md`: batch
   independent tool calls, never poll a background job, one edit per file per
   turn, no narration-only turns.

## Step 0 — Preflight

Read-only, cheap, complete. Check **every** row before reporting any — a
preflight that stops at the first failure charges the user one round trip per
defect. Allowed costs: local `git` plumbing, one `gh issue view`, one comment
listing, `gh pr list`, `grep`. Never `mix`, never a sub-skill.

`epic-orchestrator` is the only caller that puts a `SECTION_STATE:` block in the
invoking prompt. Where a row below says the block substitutes a read, use it;
everywhere else the block changes nothing.

### 0.1 Resolve the target

- `pr-from-issue <n> <SEC-ID>` — arguments win.
- Otherwise parse the current branch. A v2 section branch is
  `<prefix>/<n>-<sec>-<slug>` (`federico/<n>-...`, the repo's branch convention):

  ```bash
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  N=$(printf '%s\n'   "$BRANCH" | sed -n 's|^[a-z]*/\([0-9]\{1,\}\)-.*|\1|p')
  SEC=$(printf '%s\n' "$BRANCH" | sed -n 's|^[a-z]*/[0-9]\{1,\}-\([a-z]\{2,3\}-[0-9]\{1,\}\)-.*|\1|p' \
        | tr '[:lower:]' '[:upper:]')
  # federico/360-sch-1-field-types → N=360  SEC=SCH-1
  # federico/360-doc-1-guides       → N=360  SEC=DOC-1
  ```

  `[a-z]\{2,3\}` must stay three-wide: `DOC`, `SCH` and `PAR` depend on it, and
  narrowing it would break only the sections that ship first.

If neither yields both values, do not guess — ask the user. Under
`NON_INTERACTIVE: true` return `NEEDS_DECISION` per `../shared/escalation.md`,
**not** `STATUS: BLOCKED` — the orchestrator can answer a one-word question.

### 0.2 Read the issue

Always, on every invocation — Step 1 decides the issue reference from this
copy, and a copy from an earlier run may predate the completion phrase:

```bash
gh issue view <n> --json body --jq '.body' > /tmp/pr-from-issue-<n>-body.md || {
  echo "⚠️ Could not read issue #<n>. Nothing was run."
  echo "STATUS: BLOCKED — preflight: issue-unreadable"; exit 1
}
[ -s /tmp/pr-from-issue-<n>-body.md ] || {
  echo "⚠️ Issue #<n> returned an empty body. Refusing to guess."
  echo "STATUS: BLOCKED — preflight: issue-unreadable"; exit 1
}
```

**Only without `SECTION_STATE:`**, also list the comments — row 7 reads the
review table from this file:

```bash
gh api "repos/{owner}/{repo}/issues/<n>/comments" --paginate \
  --jq '.[] | {id, body}' > /tmp/pr-from-issue-<n>-comments.json
```

### 0.3 Check every row

1. **Branch is not `main`.** `[ "$BRANCH" != main ]`. Slug: `on-main`.
   `do-pr` keeps its own copy because it is also invoked directly; catching it
   here saves the issue read and a sub-skill spawn.
2. **Target resolved.** `<n>` and `<SEC-ID>` both known. Slug:
   `target-unresolved`.
3. **Issue readable.** 0.2 succeeded. Slug: `issue-unreadable`. `<n>` may have
   come from a branch name, so a wrong number is a live possibility — unchecked
   it reaches `do-pr` and lands a reference on somebody else's issue.
4. **Enriched spec v2 present.** Invoke `spec-load <n>`; `STATUS: BLOCKED —
   spec-missing` fails this row. Every Section Map cell below is read from
   `/tmp/spec-<n>.md` (what `spec-load` writes), never from the body's mirror.
   Slug: `enriched-spec-v2-missing`.
5. **Section exists.** `<SEC-ID>` appears as a Section Map row **and** as a
   `<!-- section:<SEC-ID>:start -->` fence. Slug: `section-unknown`.
6. **Branch matches the Section Map.** The current branch equals that row's
   `Branch` cell verbatim. A PR from a branch the spec does not name is
   invisible to every `--head` probe in the pipeline: `code-issue` would not
   see the section as delivered, and dependents would start early. Slug:
   `branch-mismatch`.
7. **Section reviewed.** Its row in the `<!-- review-table #<n> -->` comment
   reads exactly `COMPLETED`. **With `SECTION_STATE:`**, read its
   `Review-table row:` line instead of the comments file.
   - failure notes → `❌ Section <SEC-ID> has unmet ACs. Run /skill code-issue <n> <SEC-ID>.`
   - `PENDING`, no row, or no table → `❌ Section <SEC-ID> has not been reviewed. Run /skill review-issue <n> <SEC-ID>.`
   - Slug: `section-not-reviewed`.

   `review-issue` writes `COMPLETED` only after running `mix consistency` and
   the full suite itself; the row is evidence a review passed.
8. **Section not already merged.** The exact `--head` probe, never a title
   search (`code-issue` row 5 carries the reasoning). **With `SECTION_STATE:`**,
   read its `PR:` line (`<state> #<num>` or `none`) instead:
   ```bash
   gh pr list --head "<branch>" --state all --json number,state \
     --jq '.[] | "\(.state) #\(.number)"'
   ```
   `MERGED` → nothing left to ship (`section-delivered`). `OPEN` is **not** a
   failure: `do-pr` refreshes that PR's description in place.

### 0.4 Report

**On any failure**, emit every row — passes included, each with its evidence —
then the status line, then stop:

```
### ❌ Preflight failed — issue #<n> · <SEC-ID>

| Precondition | Verdict | Evidence | Fix |
|---|---|---|---|
| Branch is not main | ✅ pass | federico/360-sch-1-field-types | — |
| Section reviewed | ❌ fail | review table row reads PENDING | /skill review-issue 360 SCH-1 |
| ... every row ... | | | |

STATUS: BLOCKED — preflight: <slug>[, <slug>]
```

A table showing only failures is indistinguishable from a fail-fast preflight.

**On success**, emit and continue in the same turn:

```
Level: <level> (from issue) · Ship: <model+effort>
Preflight: 8/8 preconditions pass — shipping <SEC-ID> (<new PR | refreshing #<k>>).
```

Level is the loaded spec's `**Complexity:**` line; Ship is pinned at every
level (`../shared/coder-model.md`).

## Step 1 — Resolve the section's identity

Three values, all read, none invented:

1. **Branch** — the Section Map row's `Branch` cell. Confirmed by preflight
   row 6.
2. **PR title** — the Section Map row's `PR title` cell, verbatim, ending
   `(#<n> · <SEC-ID>)`. A `DOC-1` row carries `docs:` rather than `feat:`; pass
   it through unchanged. The type was decided at enrichment and is the Section
   Map's business.
3. **Issue reference** — decided by the completion phrase in the body fetched
   at 0.2:

   ```bash
   grep -qF 'Issue is completed and ready to be closed.' /tmp/pr-from-issue-<n>-body.md
   ```

   | Phrase present | Reference |
   |---|---|
   | yes — every section is `COMPLETED` | `Closes #<n>` |
   | no — sections remain | `Part of #<n> · <SEC-ID>` |

   A section PR must not close the issue while sections remain. Only
   `review-issue` writes the phrase, and only when every row reads `COMPLETED`,
   so the phrase is exactly the condition under which closing is correct. Never
   add `Closes` on any other basis — not merge order, not "this looks like the
   last one".

## Step 2 — Delegate to `do-pr`

Invoke the `do-pr` skill via the Skill tool. It owns preconditions, the `gate`
quality skill, the full test suite (`.claude/scripts/suite.sh`, unless a matching
suite receipt already proves it green), push, the PR body, and `gh pr create` / refresh.

Pass these lines in the invoking prompt:

```
PR_TITLE: <the Section Map title, verbatim>
ISSUE_REF: <Closes #<n>  |  Part of #<n> · <SEC-ID>>
GATE_RECEIPT: <full-40-char-sha>        # only if the caller supplied one
```

`GATE_RECEIPT` is never read from the issue: forward it only when the caller
supplied it, and never infer it from the review table or the completion phrase
(`../shared/gate-receipt.md`). `do-pr` finds `.test-receipt.json` on its own
otherwise.

Branch on the `STATUS:` line `do-pr` returns:

- **`STATUS: BLOCKED — <reason>`** → stop here too; report its output verbatim.
- **`STATUS: PR_READY <pr-url>`** / **`STATUS: PR_REFRESHED <pr-url>`** → **do
  not end your turn.** A PR URL means `do-pr` is finished, not that this skill
  is. Continue immediately to Step 3.

## Step 3 — Output

This skill is outermost in the chain, so it owns the end of the turn, and is
**not complete until this block is printed**.

```
✅ Section shipped — #<n> · <SEC-ID>

**PR:** <pr-url> (<created | refreshed>)
**Title:** <the Section Map title>
**Issue reference:** <Closes #<n> | Part of #<n> · <SEC-ID>>

- [x] Section reviewed COMPLETED in the review table
- [x] Branch matches the Section Map row
- [x] do-pr: gate, full test suite, push — or skipped on a matching receipt, as do-pr reported

👉 Next: <one line, per the table below>
```

**The `👉 Next` line — first match wins:**

| Condition | Line |
|---|---|
| The completion phrase is present | `every section shipped — close #<n> once this PR merges` |
| Every remaining Section Map row depends, directly or transitively, on the section just shipped | `nothing can start until <this-pr-url> merges` |
| Some remaining row's dependencies are all merged | `code-issue <n> <SEC-ID>` |

The middle row is the ordinary outcome of an issue's **first** run: `DOC-1`
ships first and every other section's dependency chain reaches it. It costs no
`gh` call — the PR just opened is unmerged by definition, so the Section Map
alone settles it. Probe with `gh pr list --head` only for a candidate row whose
dependencies do *not* include the section just shipped.

## What this skill does not do

- **It does not merge.** That is `merge-pr`'s, once a human has labelled the PR
  `approved`; neither skill may touch that label.
- **It does not close the issue.** It writes `Closes` only when `review-issue`
  has declared the issue complete; GitHub does the rest on merge.
- **It does not label.** `approved` / `amends-required` are the human's.
- **It does not re-run the gate to double-check `review-issue`.** That is
  `do-pr`'s call, made against the tree in front of it.
- **It does not gate on unmerged dependencies.** `code-issue`'s preflight owns
  that check; the `👉 Next` table reports the state instead of blocking on it.
