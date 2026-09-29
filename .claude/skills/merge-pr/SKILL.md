---
name: merge-pr
description: >
  Merge ONE section PR a human has labelled `approved` (or one spec PR, which
  needs no label), then clean up after it —
  refresh `origin/main` and local `main`, return the checkout to `main`, retire
  the section's worktree (remove it, then sweep its private test PostgreSQL
  instance) when one still holds the merged branch, and delete the merged
  section branch.
  Use this skill when the user says "merge the PR", "merge issue <n> <SEC-ID>",
  "land this section", or pastes an approved PR URL/number. Also invoked inline
  by the `epic-orchestrator` agent when a section's PR carries `approved`, and by
  `spec-store-write.sh` (direct mode) to land a spec PR. It
  reads the review labels and never writes one; a PR that is not approved, not
  green, or not mergeable is reported, never forced. Self-sufficient standalone
  — a human running it directly, or reconciling a PR merged on GitHub's UI,
  still gets the worktree and its test instance cleaned up.
---

# Skill: merge-pr

Land exactly one already-approved PR. This skill owns the **merge** and the
**after-merge cleanup** — nothing else in the pipeline performs either.

It is the last step of a section's life: `code-issue` writes it, `review-issue`
verifies it, `pr-from-issue` ships it, a human labels it `approved`, and this
skill merges it.

## Non-negotiables

1. **One PR per run.** Never a batch, never "and the others while I am here".
2. **The human's label is the only authority to merge** — except for a spec PR
   (see Step 0, *Spec PR recognition*), which needs no `approved`. `approved` on
   the PR, `amends-required` absent. This skill **reads** those labels and **never
   writes** one (`../shared/house-conventions.md` H-6) — reading `approved` to
   decide a merge is not touching it; adding or removing either is, and remains
   forbidden here as everywhere else. The spec-PR exemption skips reading
   `approved`; it never writes anything.
3. **Never force anything.** No `--admin`, no merge of a red or conflicted PR,
   no merge method but squash. Every gate that fails is reported and the PR is
   left exactly as it was found.
4. **Cleanup is guarded, never assumed.** A local branch is deleted only when
   the merge is confirmed on GitHub *and* its tip matches what merged. That tip
   equality, plus a clean working tree, is also what makes returning the
   checkout to `main` safe: once the branch holds nothing the merge commit does
   not, moving off it and deleting it can lose nothing.
5. **Every halt emits a terminal `STATUS: BLOCKED — <slug>` line**
   (`../shared/escalation.md`). Exit means exit: after the status line, write
   nothing and read nothing further.
6. **Turn discipline.** Follow `../shared/turn-discipline.md`: batch
   independent tool calls, never poll a background job, one edit per file per
   turn, no narration-only turns.

This skill never asks a question, so it behaves identically interactive and
under `NON_INTERACTIVE: true`. A condition it cannot clear is a `BLOCKED`, not
a `NEEDS_DECISION` — there is no answer a user could give that would make an
unapproved or conflicted PR safe to merge.

## Arguments

```
/skill merge-pr <n> <SEC-ID>       section mode — resolves the branch from the Section Map
/skill merge-pr <pr-number>        direct mode
/skill merge-pr <pr-url>           direct mode
```

Both modes converge on one PR number before Step 0 row 2. Section mode exists so
the orchestrator can name a section without knowing its PR; direct mode exists so
a human can land any PR by hand without an issue in front of them, and so
`spec-store-write.sh` can land the spec PR it just created by number. The
section-mode Section Map lookup does not apply to a spec PR: it has no Section
Map row, so it is only ever reached in direct mode.

## Step 0 — Preflight

Read-only, cheap, complete. Check **every** row before reporting any. Allowed
costs: `gh pr view`, `gh pr list`, `gh pr checks`, local `git` plumbing, and — in
section mode only — one `spec-load`. Never `mix`.

**Resolve the target first**, because every other row needs it.

*Section mode* resolves the branch exactly as `pr-from-issue` Step 1 does, and
for the same reason — the Section Map is the one place a section's branch is
named:

```bash
# spec-load <n> writes /tmp/spec-<n>.md; a BLOCKED from it fails this row
awk '/^### Section Map$/{f=1;next} f&&/^\|---/{next} f&&/^\|/{print} f&&!/^\|/{exit}' \
  /tmp/spec-<n>.md
# each row: | SEC-ID | Type | Scope | Depends on | Branch | PR title |

gh pr list --head "<branch>" --state all \
  --json number,state --jq '.[] | "\(.state) #\(.number)"'
```

The `--head` probe, never a title search — the same probe `code-issue` row 5,
`review-issue` row 3, `pr-from-issue` row 8 and `epic-orchestrator`'s Classify all
use, so this skill can never disagree with them about which PR is a section's.

*Direct mode* takes the number from the argument (a URL's trailing path segment).
It also decides whether the PR is a spec PR (below), which changes row 5 only.

Then, on the resolved PR:

```bash
gh pr view <pr> --json number,url,title,state,isDraft,baseRefName,headRefName,\
headRefOid,labels,mergeable,mergeStateStatus > /tmp/merge-pr-<pr>.json
```

| # | Precondition | Slug on failure |
|---|---|---|
| 1 | **Target resolves to a PR.** Section mode found a Section Map row and a PR for its branch; direct mode's number exists. No PR at all → nothing to merge | `no-open-pr` |
| 2 | **PR is `OPEN`.** A `MERGED` state is **not** a failure — go straight to Step 2's cleanup and return `STATUS: ALREADY_MERGED <url>`. A `CLOSED` (unmerged) PR is | `pr-closed` |
| 3 | **Not a draft.** `isDraft` is `false`. A draft is a statement that the author is not finished | `draft-pr` |
| 4 | **Base is `main`.** `baseRefName == "main"` | `wrong-base` |
| 5 | **`approved` is among the labels** — skipped for a spec PR | `not-approved` |
| 6 | **`amends-required` is *not* among the labels** | `amends-required` |
| 7 | **Every check passes.** `gh pr checks <pr> --json name,state,bucket` — every entry's `bucket` is `pass` or `skipping` (a docs-only or spec-only PR's light CI run skips steps, not the required check `Build and test (1.19.4-otp-28, 28.2)`). `pending` is a wait, not a defect: name the check and stop. `fail` and `cancel` are both failures — a cancelled run proved nothing | `checks-pending` / `checks-failing: <names>` |
| 8 | **GitHub says it merges.** `mergeable` is `MERGEABLE` | `not-mergeable: <mergeStateStatus>` |

Rows 5 and 6 are read from the labels directly, so the failure names the real
condition and a human can fix it in one click. aurora_uix has no
`approval-check.yml` and its ruleset requires zero approving reviews, so nothing
in the repository enforces `approved` except this skill. If an approval workflow
is ever added it needs the same spec-PR exemption (all three conditions below)
and must not be made a required check without it.

**Spec PR recognition.** Row 5 is skipped — and only row 5 — when the PR is a
spec PR, recognised by **all** of:

1. head branch matches `^spec/[0-9]+-enriched-spec$`;
2. title starts with `docs(spec): enriched spec for issue #`;
3. every file in the PR (`gh pr view <pr> --json files --jq '.files[].path'`) is
   exactly `specs/issue-<n>-enriched-spec.md`, with the same `<n>` as the branch
   (and there is at least one file).

Condition 3 is what makes the exemption safe: the branch name alone would let a
branch called `spec/...` route code past review. If any condition fails, the PR
is an ordinary PR and row 5 applies. Every other row still applies to a spec PR:
not draft, base `main`, no `amends-required`, every check `pass` or `skipping`,
`mergeable`. Report a recognised spec PR in the preflight line.

Row 8's `mergeable` is computed asynchronously by GitHub and reads `UNKNOWN`
while that is in flight — most often on a PR opened seconds ago or on the second
merge of a pass, where the first merge just moved `main` under it. Re-poll
`gh pr view <pr> --json mergeable` twice, a few seconds apart, before failing
the row. `UNKNOWN` after that is reported as `not-mergeable: UNKNOWN`, never
merged on the hope that it resolves.

Rows 7 and 8 are re-read **immediately before** the merge in Step 1, not trusted
from a caller's earlier probe. When two approved PRs merge in one orchestrator
pass, the first changes `main` under the second; re-reading here is what turns
that into a `not-mergeable` report instead of a conflicted merge.

**On any failure**, emit every row — passes included, each with its evidence —
then the status line, then stop:

```
### ❌ Cannot merge — PR #<pr>

| Precondition | Verdict | Evidence | Fix |
|---|---|---|---|
| PR is OPEN | ✅ pass | OPEN | — |
| approved label present | ❌ fail | labels: bug | a reviewer labels the PR `approved` |
| ... every row ... | | | |

STATUS: BLOCKED — <slug>[, <slug>]
```

A table showing only failures is indistinguishable from a fail-fast preflight
that stopped at the first one.

On success, emit and continue in the same turn:

```
Preflight: 8/8 preconditions pass — merging #<pr> (<branch>).
```

For a spec PR: `Preflight: 7/8 preconditions pass, row 5 skipped (spec PR) —
merging #<pr> (<branch>).`

## Step 1 — Merge

Squash, with the house subject written explicitly:

```bash
gh pr merge <pr> --squash \
  --subject "merge - <PR title> (#<pr>)" \
  --match-head-commit <headRefOid>
```

Four details, each load-bearing:

- **`--match-head-commit` is the race guard.** It carries the `headRefOid` this
  run's preflight validated, and GitHub refuses the merge if the branch has
  moved since. Without it, a push landing between row 7's check read and the
  merge would land code no check ever ran against — the one window where an
  automated merge can do what a human merging by hand would not.

- **`--subject` is not optional.** The repository's
  `squash_merge_commit_title` is `PR_TITLE`, so GitHub's default subject is the
  PR title alone. The `merge - ` prefix every commit on `main` carries is typed
  at merge time, not built into the title — `--subject` is what reproduces
  `merge - feat: contains filter (#344)`. For a spec PR the subject is
  `merge - docs(spec): enriched spec for issue #<n> (#<pr>)`.
  Take `<PR title>` verbatim from the PR; never reformat, retype, or "improve"
  it. It is the Section Map's title and the pipeline's identity for the section.
- **No `--body`.** `squash_merge_commit_message` is `COMMIT_MESSAGES`, so
  GitHub composes the squash body from the branch's own conventional commits —
  the `* <subject>` bullets, their bodies, and their `Co-Authored-By:` /
  `Claude-Session:` trailers. If a merge ever lands with an **empty** body,
  that default is not being applied and the fix is to build the body explicitly:

  ```bash
  git log --reverse --format='* %s%n%n%b' origin/main..<headRefOid> > /tmp/merge-pr-<pr>-body.md
  gh pr merge <pr> --squash --subject "merge - <PR title> (#<pr>)" \
    --match-head-commit <headRefOid> --body-file /tmp/merge-pr-<pr>-body.md
  ```

- **No `--delete-branch`.** The repository sets `delete_branch_on_merge: true`,
  so GitHub removes the remote ref on its own. `gh`'s flag additionally deletes
  the **local** branch, bypassing every guard Step 2 applies — the tip-equality
  check that stands between `branch -D` and unpushed local work, and the
  clean-tree check that stands between a checkout switch and uncommitted
  changes carried onto `main`. Step 2 does this job, in the right order, with
  those guards.

A non-zero exit from `gh pr merge` is `STATUS: BLOCKED — merge-failed`, quoting
`gh`'s own message. Do not retry with different flags, and never reach for
`--admin`.

Confirm the merge landed before touching any branch:

```bash
gh pr view <pr> --json state,mergeCommit --jq '"\(.state) \(.mergeCommit.oid)"'
# MERGED <sha>
```

Anything but `MERGED` here is `merge-failed` — the cleanup does not run.

## Step 2 — After-merge cleanup

Five steps, each guarded and each idempotent, so a re-run on an
already-merged PR is a no-op rather than an error.

**1. Refresh the remote refs.**

```bash
git fetch origin --prune
```

`--prune` drops the remote-tracking ref GitHub just deleted; without it every
later `git branch -a` shows a branch that no longer exists.

**2. Fast-forward local `main`.** Which command depends on where the checkout is
standing, because git refuses to fetch into a branch that is checked out:

```bash
if [ "$(git rev-parse --abbrev-ref HEAD)" = main ]; then
  git merge --ff-only origin/main      # standing on main — the ordinary hand-run case
else
  git fetch origin main:main           # standing anywhere else — updates the ref in place
fi
```

Both refuse anything that is not a fast-forward, which is the safety, not a
limitation: local `main` should never carry a commit that is not on the remote,
and if it does, that is a person's problem to look at, not this skill's to
resolve. `git fetch origin main:main` additionally refuses while `main` is
checked out in **another** worktree.

Either failure is **non-fatal**: report which one and why, and carry on to
step 3. The merge already landed; a stale local ref is worth a line of output,
never a `BLOCKED`.

This step is not housekeeping. `do-pr` builds its PR description from **local**
`main` (`../do-pr/SKILL.md` § Step 6 — `git log main..HEAD`, `git diff
main...HEAD`), and until now nothing in the pipeline ever refreshed it. A local
`main` left behind by ten merges makes the next PR's generated summary describe
work that shipped weeks ago.

**3. Return the checkout to `main`**, when it is standing on the merged branch.

A hand-run from the section branch just shipped is the *ordinary* case, not the
exception — it is where `pr-from-issue` leaves you. Move off it, so step 5 can
finish the job:

```bash
git switch main
```

Only when all of these hold:

- guards 1 and 2 of step 5 below hold — the PR is `MERGED` with no `OPEN` one,
  and the local tip equals the merged `headRefOid`. Tip equality is the whole
  licence for this step: it proves the branch holds nothing the merge commit
  does not, so leaving it can strand no work.
- the working tree has no modified **tracked** files:
  `git status --porcelain --untracked-files=no` is empty.

Untracked files deliberately do **not** block — they survive both the switch and
the delete untouched. Modified tracked files do: carrying them onto `main` would
be a surprise, and this repository forbids working on `main` at all. Report the
uncommitted change, keep the branch, and say which:

> Checkout left on `<branch>` — uncommitted changes to tracked files. Commit or
> stash them, then `git switch main && git branch -D <branch>`.

The ordering matters. Step 2 ran `git fetch origin main:main` while the checkout
was still *off* `main`, so the switch here lands on an already-fresh `main`
rather than one ten merges stale.

A checkout standing anywhere else — on `main` already, or on some unrelated
branch — is a no-op: this step moves the checkout only off the branch it is
about to delete, never onto `main` from somewhere it has no business leaving.

Failure is **non-fatal**, exactly as step 2 is — an in-progress rebase, a
conflicting checkout, a local `main` step 2 could not create. Report the reason,
skip step 5, keep the branch. The merge already landed; none of this is a
`BLOCKED`. Step 4 is unaffected — it acts on the section's own worktree, not on
this checkout, so a failure here never skips it.

**4. Retire the section's worktree**, when one still holds the merged branch.

`epic-orchestrator` gives every section its own worktree under
`.claude/worktrees/`; a human running this skill standalone, or reconciling a
PR merged straight from GitHub's UI, still needs that worktree — and the
private test PostgreSQL instance it ran against (`scripts/test_pg.sh`, under
`/tmp/aurora_uix_pg/`) — cleaned up, or it survives the
branch's own deletion as an orphan. Retiring here, right after the merge is
confirmed and never before, is what keeps that invariant regardless of who
called this skill.

Locate it the same way guard 3 of step 5 below does, because a squash-merged
PR carries no worktree path of its own and section mode's `<n>`/`<sec>` are
not available in direct mode:

```bash
WT=$(git worktree list --porcelain | awk -v b="refs/heads/<branch>" \
  -v self="$(git rev-parse --show-toplevel)" \
  '/^worktree /{p=$2} /^branch /{if ($2==b && p!=self) print p}')
```

Retire it per `../shared/retire-worktree.md`: remove the worktree, then run
`scripts/test_pg.sh sweep`, which destroys the test instance of every checkout
that no longer exists. A missing `$WT` — no other worktree holds the branch,
the ordinary case for a PR shipped without one, or one a previous run of this
skill already retired — skips the removal but still runs the sweep. A spec PR
never has a worktree, so this step is a no-op for it. A refused
removal (dirty tree, or a lock naming a live pid)
is reported and skipped, never `--force`; step 5's guard 3 then reports that
same worktree as the reason it kept the branch, so nothing here silently
drops that guard's job.

**5. Delete the merged section branch.**

Only when all three hold:

- the `--head` probe shows a `MERGED` PR **and no `OPEN` one**. A re-used branch
  with a newer open PR is not history yet.
- the local tip equals the merged PR's head: `git rev-parse "<branch>"` is the
  `headRefOid` from `gh pr list --head "<branch>" --state merged --json
  headRefOid` (the newest, if several). `git branch -d` cannot be the guard —
  a squash-merged branch is never "merged" in git's eyes, and the remote ref is
  gone after merge — so this equality is what stands between `-D` and unpushed
  work. A mismatch is reported and the branch kept.
- no **other** worktree holds the branch: `git worktree list --porcelain` has no
  `branch refs/heads/<branch>` line under a `worktree` path other than this
  checkout's own (`git rev-parse --show-toplevel`). This is not a theoretical
  case — `epic-orchestrator` gives every section its own worktree under
  `.claude/worktrees/`, and `code-issue` / `review-issue` / `pr-from-issue`
  check the section branch out inside it, so that worktree can be holding the
  very branch about to be deleted. Step 4 above retires it immediately before
  this guard runs, for exactly that reason; reaching this guard with a
  worktree still standing means retirement was refused there — a dirty tree
  or a live lock — and already reported. A worktree this run cannot move is a
  hard stop: `branch -D` refuses it anyway. Report the path and move on.

```bash
git branch -D "<branch>"
```

No local branch is a no-op, and the ordinary case after a relaunch. Never delete
the **remote** branch by hand — GitHub did that.

## Step 3 — Output

This skill owns the end of its turn when a human invoked it, and hands back to
the caller when a skill or the orchestrator did. Either way it is **not complete
until this block is printed**:

```
✅ Merged — #<pr>[ · #<n> · <SEC-ID>]

**PR:** <pr-url>
**Title:** <the PR title, verbatim>
**Merge commit:** merge - <PR title> (#<pr>) — <sha>

- [x] `approved` present, `amends-required` absent — read, never written <or: spec PR — `approved` not required>
- [x] All checks green (<count> checks)
- [x] Squash-merged onto `main`
- [x] Remote branch removed by GitHub (`delete_branch_on_merge`)
- [x] Local `main` fast-forwarded <or: not fast-forwarded — <reason>>
- [x] Checkout returned to `main` <or: left on `<branch>` — <reason>; or: already on `main`>
- [x] Section worktree retired <or: none held the branch; or: kept — <reason>>
- [x] Local branch `<branch>` deleted <or: kept — <which guard failed>>

STATUS: MERGED <pr-url>
```

## Terminal status

One line, always, so a caller can branch on it:

| Status | Meaning |
|---|---|
| `STATUS: MERGED <pr-url>` | merged and cleaned up |
| `STATUS: ALREADY_MERGED <pr-url>` | the PR was merged before this run; cleanup ran (or was already a no-op) and nothing else happened |
| `STATUS: BLOCKED — <slug>` | `no-open-pr`, `pr-closed`, `draft-pr`, `wrong-base`, `not-approved`, `amends-required`, `checks-pending`, `checks-failing: <names>`, `not-mergeable: <state>`, `merge-failed` |

`ALREADY_MERGED` is deliberately distinct from `MERGED`. A caller that reports
"merged" for a PR someone else landed is claiming an action it did not take, and
the orchestrator's pass log is the record of what the run actually did.

## What this skill does not do

- **It does not label.** Not `approved`, not `amends-required`. H-6 is unchanged by this skill's existence.
- **It does not close the issue.** `pr-from-issue` writes `Closes #<n>` into the
  last section's PR body once `review-issue` has declared the issue complete;
  GitHub closes it on merge. Nothing here calls `gh issue close`.
- **It does not touch the spec.** `specs/issue-<n>-enriched-spec.md` stays
  exactly as it is (landing a spec PR merges someone else's edit; this skill
  authors none). A merged section is history that `spec-store`'s
  merged-section guard protects — deleting or archiving the file would destroy
  the record that guard depends on.
- **It does not review.** It reads a label a human wrote; it forms no opinion
  about whether the code deserves it, and never re-runs the gate. `review-issue`
  did that before the PR existed and CI did it again on the PR.
- **It does not decide *whether* a section should merge.** That is the label.

## Forbidden

- `gh pr merge --admin`, `--auto`, or any flag that bypasses a failing check.
  `--auto` in particular hands the merge to GitHub to perform later, outside this
  run's sight, with no `--match-head-commit` guard and no cleanup.
- Any merge method but `--squash`.
- Merging a PR without `approved`, or one carrying `amends-required` — including
  when CI is otherwise green, when the work was self-reviewed, or when a caller
  says to. The only exemption is a spec PR meeting all three recognition
  conditions; a failed condition means an ordinary PR, never a partial pass.
- Adding or removing any label, on the PR or on the issue.
- `--delete-branch` on `gh pr merge`, or deleting the remote branch by hand.
- `git branch -D` on a branch whose PR is not `MERGED`, whose branch also has an
  `OPEN` PR, whose local tip differs from the merged `headRefOid`, or which
  **another** worktree holds.
- `git switch` away from the merged branch while its tip differs from the merged
  `headRefOid`, or while tracked files are modified. Both are Step 2 step 3's
  guards, and they are what make the switch safe rather than presumptuous.
- Removing a worktree for any branch but the one this run just confirmed
  `MERGED`, or with `--force`. Step 2 step 4 retires exactly one worktree,
  exactly once the merge is confirmed, and only when
  `../shared/retire-worktree.md`'s own guards allow it.
- Moving another worktree's checkout, or checking out inside it, to free its
  branch. This skill's only touch on another worktree is the guarded removal
  in Step 2 step 4 — never a partial reach into it.
- `git push --force`, `git reset --hard`, or any rewrite of `main`.
- Merging more than one PR in a run.
- Reporting `MERGED` for a PR this run did not merge.
