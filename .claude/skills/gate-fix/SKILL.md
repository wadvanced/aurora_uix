---
name: gate-fix
description: Run `mix consistency` and fix issues. Mechanical issues are fixed in place; refactor-class issues produce a plan for user approval instead of being attempted.
---

Run `mix consistency` and resolve issues until it passes, OR until the only
remaining issues require a refactor — in which case emit a Refactor Plan and
stop.

## Background

The `precommit` alias in `mix.exs` is fail-fast and runs in this fixed order:

```
deps.unlock --unused → format → compile --warnings-as-errors → docs → credo --strict → doctor → dialyzer
```

Only the FIRST failing stage is visible per run. Fix that stage, re-run, repeat.

## Terminal status

This skill always ends with exactly one of these statuses, printed on its own
line so the orchestrator can branch on it:

- `STATUS: CLEAN` — `mix consistency` exited 0.
- `STATUS: PLAN_PENDING` — every mechanical issue you could fix is fixed, but
  one or more refactor-class issues remain. A **Refactor Plan** section was
  printed for the user to approve.
- `STATUS: BLOCKED` — 3-iteration cap reached or an unrecoverable failure.

## 1. Run

```
mix consistency
```

If exit code is 0, print `STATUS: CLEAN` and return.

## 2. Identify the failing stage

Read the output and find the last stage that ran. It is one of:

`deps.unlock --unused` · `format` · `compile --warnings-as-errors` · `docs` · `credo --strict` · `doctor` · `dialyzer`

## 3. Stage-keyed action table

Apply the action for the failing stage. Then go back to step 1.

| Failing stage | Mechanical action | Refactor-class fallback |
|---|---|---|
| `deps.unlock --unused` | Run `mix deps.unlock --unused`. | n/a |
| `format` | Run `mix format`. | n/a |
| `compile --warnings-as-errors` | If every warning is one of {unused variable, unused alias, unused import, unused module attribute} → fix mechanically (prefix unused vars with `_`, delete unused aliases/imports). | Any other warning → record in Refactor Plan; never modify logic to silence a warning. |
| `docs` | For each file in the ex_doc warnings, invoke the `documentation` skill on that file. | If a file's docs require non-trivial restructuring beyond what `documentation` produces → record in Refactor Plan. |
| `credo --strict` | Only act if `credo` exited non-zero (TODOs are non-failing — ignore). If every breaking issue is one of {trailing whitespace, large numbers without underscores, alias ordering, missing alias at the top, module attribute ordering, missing @spec} → fix mechanically. | Otherwise → record in Refactor Plan. |
| `doctor` | For each module flagged with low coverage, invoke the `documentation` skill on that file. | If coverage gap requires API/behavior changes → record in Refactor Plan. |
| `dialyzer` | n/a | All Dialyzer findings → record in Refactor Plan. Never invent or weaken `@spec` to silence Dialyzer. |

After applying the mechanical action for a stage, go back to step 1.

When the *currently failing* stage yields only refactor-class issues, stop
the loop immediately and go to step 5 — do **not** keep re-running
`mix consistency` hoping a later stage surfaces. The pipeline is fail-fast
and the same stage will keep failing until the user resolves the plan.
Continue collecting issues across re-runs only when a previous run *did*
make mechanical progress and the next run reveals new refactor-class
findings in a different stage.

## 4. Iteration cap

If `mix consistency` has been run 3 times without reaching exit 0:

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
**Tool output (verbatim):**
<paste exactly what the tool printed>

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

## Forbidden

- Modifying code logic to silence a warning.
- Inventing or relaxing `@spec` to silence Dialyzer.
- Emitting `STATUS: CLEAN` while any stage still fails.
- Emitting a Refactor Plan whose body is only a one-line summary.
- Exiting with `STATUS: BLOCKED` when refactor-class issues were collected
  during the run.
