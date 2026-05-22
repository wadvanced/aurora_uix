---
name: gate
description: Ensure proper lints and documentation rules, then commit. Orchestrates `gate-fix` and `gate-commit`.
---

Thin orchestrator around two sub-skills:

1. `gate-fix` — runs `mix consistency` and fixes issues. Ends with one of
   three statuses on a line by itself: `STATUS: CLEAN`,
   `STATUS: PLAN_PENDING`, or `STATUS: BLOCKED`.
2. `gate-commit` — groups the working tree into conventional commits.
   Only invoked when the fixer reports `CLEAN`.

## Steps

1. Invoke the `gate-fix` skill.
2. Read its terminal `STATUS:` line.
3. Branch:
   - **`CLEAN`** → invoke the `gate-commit` skill. Done.
   - **`PLAN_PENDING`** → stop. The fixer's Refactor Plan IS the proposed
     coding change. Surface it to the user **verbatim and in full** (do not
     summarize, reorder, or trim) and wait for them to approve or amend it
     before any code is written. Do **not** invoke the committer. Re-running
     `gate` after the user resolves the plan re-enters the fixer cleanly.
   - **`BLOCKED`** → stop and report what the fixer left behind. Do **not**
     invoke the committer.

## Forbidden

- Invoking `gate-commit` when the fixer did not return `CLEAN`.
- Editing code or committing directly from this skill — all work happens in
  the two sub-skills.
