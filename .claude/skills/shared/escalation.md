# Non-interactive escalation contract

Single source of truth for how a skill behaves when it is running **without a
user to prompt** — typically because `epic-orchestrator` spawned it as a
subagent. Referenced from the skills that prompt; never duplicated into them.

## When this applies

**Only** when the invoking prompt contains the literal line:

```
NON_INTERACTIVE: true
```

Absent that line, the skill is being driven by a human and every existing
`AskUserQuestion` behaves exactly as documented in its own `SKILL.md`. This
file adds a branch; it removes nothing. A skill that changes its interactive
behaviour because of this document has been edited wrongly.

## The contract

A subagent cannot call `AskUserQuestion` — only the main session can prompt.
So when `NON_INTERACTIVE: true` is set and the skill reaches a point where it
would ask, it **stops and returns** instead of guessing:

```
NEEDS_DECISION
skill: <skill name>
issue: <n>
question: <the one-line question, as it would have been asked>
options:
  - <label> — <consequence of choosing it>
  - <label> — <consequence of choosing it>
context: <what the skill already established, so the user can decide without
          re-reading the issue>
```

Rules:

- **Stop after emitting it.** Do not continue past the decision point, do not
  pick a default, do not write any marker block that depended on the answer.
  Work already completed and persisted before the decision point stays — the
  next spawn re-derives state from the issue and resumes there.
- **Same options, same order** as the interactive path. The orchestrator
  presents them verbatim; inventing or reordering options changes what the user
  is choosing between.
- **One decision per return.** If two questions are pending, emit the first.
- `NEEDS_DECISION` is a terminal output, like `STATUS:`. Nothing follows it.

## Pre-supplied answers

The orchestrator re-spawns the same skill with the user's choice supplied:

```
NON_INTERACTIVE: true
DECISION: <skill name> / <question> -> <chosen option label>
```

A skill seeing a `DECISION:` line for a question it is about to ask takes that
answer and proceeds without stopping. Treat it exactly as if the user had picked
that option interactively — including any writes that choice implies.

One further line exists for `improve-issue` alone, relaying an `ExitPlanMode`
rejection the main session obtained on its behalf (`improve-issue/SKILL.md`,
Boot):

```
NON_INTERACTIVE: true
CHANGES: <the user's text, verbatim>
```

`CHANGES:` re-drafts from `/tmp/improve-issue-<n>-spec.md` and halts
`SPEC_PENDING` again. No other skill reads the line. An approval sends no line:
`orchestrate-issue` runs `.claude/scripts/spec-store-write.sh` itself.

## Statuses the orchestrator already understands

These predate this contract and keep their meaning; they are listed so the
orchestrator has one place to look:

| Line | Emitted by | Orchestrator reads it as |
|---|---|---|
| `STATUS: OK ...` | `spec-store-write.sh` | the spec PR merged into `main`, the body mirror and resolution comment are written — the only point at which the spec counts as stored, and the earliest at which `orchestrate-issue` may hand the issue to the `epic-orchestrator` |
| `STATUS: BLOCKED — ...` | `spec-store-write.sh`, `gate-fix`, `improve-issue`, `code-issue`, `review-issue`, `merge-pr` | halt this node, escalate |
| `STATUS: CLEAN` | `gate-fix` | proceed to `gate-commit` |
| `STATUS: PLAN_PENDING` | `gate-fix` | halt this node, surface the Refactor Plan verbatim |
| `STATUS: CHECKPOINT` | `code-issue` | the spawn hit its targeted-test budget, wrote a checkpoint, and left its work uncommitted — run `code-issue` on the section again; counts toward the loop cap |
| `STATUS: LOOP` | `review-issue` | section bounced back — run `code-issue` on it again |
| `STATUS: DONE` | `review-issue` | section approved, or the whole issue complete |
| `STATUS: SPEC_PENDING` | `improve-issue` | the draft at `/tmp/improve-issue-<n>-spec.md` needs interactive approval — `orchestrate-issue` shows it via `ExitPlanMode` in the main session, then stores it with `.claude/scripts/spec-store-write.sh` on approval (branch → PR → merge, see below) or re-spawns `improve-issue` with `CHANGES:` (below); the `epic-orchestrator` never spawns `improve-issue` itself |
| `STATUS: WAVE_DONE waves=<k>` | `epic-orchestrator` | the spawn drove one wave and ended to keep its own context small; `<k>` counts the run's waves so far, and it is the whole return. Nothing to decide — `orchestrate-issue` re-spawns it at once, with no prompt to the user |
| `STATUS: MERGED <pr-url>` | `merge-pr` | the section's PR was merged by this run and cleaned up after; the section is done |
| `STATUS: ALREADY_MERGED <pr-url>` | `merge-pr` | the PR was already merged before the run; the section is done, but this run did not merge it |
| `NEEDS_DECISION` | any skill, non-interactive only | ask the user, re-spawn |

## Spec-store statuses

`.claude/scripts/spec-store-write.sh` never writes to `main` directly: it opens a
`spec/<n>-enriched-spec` branch and a non-draft PR, waits for checks, lands it with
`merge-pr <pr-number>` and only then mirrors the issue body and posts the resolution
comment. Its last line is `STATUS: OK …` or one `BLOCKED` reason. **Nothing downstream
starts before `STATUS: OK`** — `spec-load` reads `main`, so an unmerged spec does not
exist yet.

| `BLOCKED` reason | Meaning | `orchestrate-issue` does |
|---|---|---|
| `issue-unreadable` | the issue could not be fetched | run the script once more; report and stop if it repeats |
| `concurrent-write` | `main`'s copy of the spec changed after it was read — the spec PR is `CONFLICTING`. GitHub's merge check replaces the old sha lock; the same rule applies: re-run from a fresh read | re-spawn `improve-issue` as a re-enrichment, return to the spec loop |
| `spec-pr-open <url>` | a spec PR for this issue is already open; a second is never stacked | report the URL and stop; the user merges (`merge-pr <pr-number>`) or closes it, then relaunches |
| `spec-pr-checks-failing` | a check on the spec PR failed or was cancelled; never merged on red | report and stop; the PR stays open |
| `spec-pr-checks-pending` | the bounded wait (about 10 minutes) ended with checks still running; the PR is left open | report and stop; relaunch once checks finish (the next run reports `spec-pr-open`) |
| `spec-merge-failed` | `merge-pr` refused or `gh pr merge` failed after checks passed | report the line and stop |
| any other | e.g. `merged-section-modified` (merged-section guard), `approved-spec-mismatch`, `spec-write-failed` | report the line and stop |

A `BEHIND` spec PR is updated once by the script (`gh pr update-branch`) and re-waited;
a conflicting update is `concurrent-write`, never resolved. The `epic-orchestrator`
ignores `spec/*` PRs entirely.

## Section-PR update conflicts

The `epic-orchestrator` may run `gh pr update-branch` once on a `BEHIND` approved
section PR. If GitHub reports a conflict it halts with
`STATUS: BLOCKED — update-branch-conflict #<pr> <SEC-ID>` and resolves nothing: a spec
rewrite merged while sections were in flight conflicts with their local checkbox ticks,
and choosing a side is the user's call.

`SPEC_PENDING` is not shaped like `NEEDS_DECISION` — there is no menu of
options to present, only an interactive skill to run.

`STATUS: BLOCKED` always carries a slug naming the cause. `epic-orchestrator`'s own
`stopped-by-user` acknowledges a `DECISION:` that chose a *Stop* / *Abort* option. The triplet's slugs
are defined in their own preflights and halts — the orchestrator routes on the
line, not on the slug, and never on a slug it does not recognise.

`gate`'s `PLAN_PENDING` is deliberately **not** converted into a
`NEEDS_DECISION`. A Refactor Plan is a proposed code change, not a menu — it is
surfaced verbatim and in full for the user to approve or amend, exactly as
`gate/SKILL.md` requires.
