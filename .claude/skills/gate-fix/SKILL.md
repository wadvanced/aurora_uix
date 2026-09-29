---
name: gate-fix
description: Run `mix consistency` and fix issues. Mechanical issues are fixed in place; refactor-class issues produce a plan for user approval instead of being attempted.
---

Run `mix consistency` and resolve issues until it passes, OR until the only
remaining issues require a refactor — in which case emit a Refactor Plan and
stop.

Follows `../shared/turn-discipline.md` throughout: never poll a backgrounded
`gate.sh` run, no narration-only turns.

## Background

The `consistency` alias in `mix.exs` is fail-fast and runs in this fixed order:

```
auix.gen.tailwind_classes → format → compile --warnings-as-errors → credo --strict → dialyzer → doctor
```

Only the FIRST failing stage is visible per run. Fix that stage, re-run, repeat.

## Terminal status

This skill always **returns** exactly one of these statuses to its caller,
printed on its own line so the orchestrator can branch on it:

- `STATUS: CLEAN` — `mix consistency` exited 0.
- `STATUS: PLAN_PENDING` — every mechanical issue you could fix is fixed, but
  one or more refactor-class issues remain. A **Refactor Plan** section was
  printed for the user to approve.
- `STATUS: BLOCKED` — 3-iteration cap reached or an unrecoverable failure.

## 1. Run

```
.claude/scripts/gate.sh
```

Run it per `../shared/background-long-commands.md` — `run_in_background`, then
one foreground `.claude/scripts/wait-verdict.sh gate`. It runs the `consistency`
stages one `mix` invocation each, fail-fast, and prints only the failing stage's
last 40 log lines (the full log is `/tmp/gate-<branch>.log`).

If the verdict is `EXIT: 0` — including `SKIPPED: docs/spec-only changes` (a
diff made only of documentation, images and specs cannot change any stage) —
print `STATUS: CLEAN` and return.

## 2. Identify the failing stage

`gate.sh` prints `STAGE: <name>` on the failure — read that line rather than
scanning output. It is one of:

`auix.gen.tailwind_classes` · `format` · `compile --warnings-as-errors` · `credo --strict` · `dialyzer` · `doctor`

## 3. Stage-keyed action table

Apply the action for the failing stage. Then go back to step 1.

| Failing stage | Mechanical action | Refactor-class fallback |
|---|---|---|
| `auix.gen.tailwind_classes` | The task rescans `lib/` for `hero-*` icon names and regenerates `priv/static/classes.js`. Re-run `mix auix.gen.tailwind_classes` and keep the regenerated file in the working tree so `gate-commit` picks it up. (It has nothing to do with `auix-*` theme classes — those live in `templates/basic/themes/base.ex`.) | If the task itself crashes or the icon name it rejects needs a design change → record in Refactor Plan. |
| `format` | Run `mix format`. | n/a |
| `compile --warnings-as-errors` | If every warning is one of {unused variable, unused alias, unused import, unused module attribute} → fix mechanically (prefix unused vars with `_`, delete unused aliases/imports). | Any other warning → record in Refactor Plan; never modify logic to silence a warning. |
| `credo --strict` | Only act if `credo` exited non-zero (TODOs are non-failing — ignore). If every breaking issue is one of {trailing whitespace, large numbers without underscores, alias ordering, missing alias at the top, module attribute ordering, missing @spec} → fix mechanically. | Otherwise → record in Refactor Plan. |
| `doctor` | For each module flagged with low coverage, invoke the `documentation` skill on that file. | If coverage gap requires API/behavior changes → record in Refactor Plan. |
| `dialyzer` | n/a | All Dialyzer findings → record in Refactor Plan. Never invent or weaken `@spec` to silence Dialyzer. |

After applying the mechanical action for a stage, go back to step 1.

When the *currently failing* stage yields only refactor-class issues, stop
the loop immediately and go to step 5 — do **not** keep re-running
`gate.sh` hoping a later stage surfaces. The pipeline is fail-fast
and the same stage will keep failing until the user resolves the plan.
Continue collecting issues across re-runs only when a previous run *did*
make mechanical progress and the next run reveals new refactor-class
findings in a different stage.

## 4. Iteration cap

If `gate.sh` has been run 3 times without reaching exit 0:

- If any refactor-class issues were collected → go to step 5 and emit
  `STATUS: PLAN_PENDING`.
- Otherwise → print `STATUS: BLOCKED` with what is left.

## 5. Refactor Plan output

The Refactor Plan IS the proposed coding change. Write it as if the user
will hand it to another engineer (or to `code-issue`) to execute — concrete
enough to act on, not a summary.

When refactor-class issues remain, end with:

```
## Refactor Plan

### <file>:<line> — <short title>
**Stage:** <stage name>
**Tool output (gate.sh's last-40-line excerpt for this stage):**
<paste what gate.sh printed>

**Root cause:** <1-2 sentences naming the underlying design/code issue,
not just the symptom>

**Proposed refactor:**
- <step 1: concrete code change — module/function, what to add/remove/rename>
- <step 2: ...>
- <step N: ...>

**Files touched:** <list of file paths, including new files>
**Tests to add or update:** <test files + what they assert>
**Risk/scope:** <e.g. "public API", "Ash policy", "DB migration", "test-only">
**Out of scope (intentionally not changed):** <anything the reader might
expect to be touched but won't be>

### ... (one block per finding)

STATUS: PLAN_PENDING
```

Do not edit code to implement the plan — that is the user's call. After the
user acts on the plan, re-running this skill picks up cleanly.

## Returning to the caller

This skill is normally invoked by another skill (`gate`), never on its own. The
`STATUS:` line is a **handoff, not a conclusion** — print it and continue in the
**same turn** with whatever step the caller has next. Do not end your turn and
do not wait for the user, on any of the three statuses. Only the outermost skill
in the chain decides when the turn is over.

`STATUS: PLAN_PENDING` is the one exception the caller itself handles: `gate`
stops there so the user can approve the Refactor Plan. That stop belongs to
`gate`, not to this skill — still return the status rather than ending the turn
yourself.

## Forbidden

- Ending the turn after printing a `STATUS:` line instead of returning to the caller.
- Running `mix consistency` directly, or backgrounding/polling `gate.sh` outside
  `../shared/background-long-commands.md`.
- Modifying code logic to silence a warning.
- Inventing or relaxing `@spec` to silence Dialyzer.
- Emitting `STATUS: CLEAN` while any stage still fails.
- Emitting a Refactor Plan whose body is only a one-line summary.
- Exiting with `STATUS: BLOCKED` when refactor-class issues were collected
  during the run.
