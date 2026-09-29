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

Follows `../shared/turn-discipline.md` throughout: never poll a backgrounded
`gate.sh`/`mix test` run, no narration-only turns.

## Steps

0. **Check for a gate receipt.** If the invoking prompt carries a
   `GATE_RECEIPT: <sha>` line, compute `tree_hash` per
   `../shared/gate-receipt.md` and compare all 40 characters. On an exact match,
   `mix consistency` was already green on this exact content, so **skip `gate-fix`
   entirely** — say so, then go straight to `gate-commit`, passing
   `CONSISTENCY_VERIFIED: <sha>`:

   ```
   Honouring GATE_RECEIPT for tree <short-sha> — skipping gate-fix.
   ```

   **No prompt-line receipt, or a mismatch?** Before falling through, check the
   on-disk `.test-receipt.json` at the root of the working tree per
   `../shared/gate-receipt.md`. Honour it only when all three hold: it parses,
   its `tree` is byte-equal (all 40 characters) to `tree_hash`, and its
   `consistency` field is `green`. On a hit, skip `gate-fix` exactly as above,
   passing `CONSISTENCY_VERIFIED: <sha>`:

   ```
   Honouring .test-receipt.json (consistency: green) for tree <short-sha> — skipping gate-fix.
   ```

   Anything else — no file, a malformed one, a different hash, or a `consistency`
   field that is absent or not `green` — falls through to step 1 and runs the
   full fixer. A near-miss is a miss, for either receipt.

   Note what this path gives up: `gate-fix` is the only step that *edits* code to
   clear the gate. Skipping it is sound precisely because a receipt — either
   kind — asserts there is nothing to clear.

1. Invoke the `gate-fix` skill.
2. Read its terminal `STATUS:` line.
3. Branch:
   - **`CLEAN`** → invoke the `gate-commit` skill **immediately, in the same
     turn**, passing `CONSISTENCY_VERIFIED: <sha>` where `<sha>` is `tree_hash`
     computed now. `gate-fix` has just run `mix consistency` to green on this exact
     content, so the committer's own gate would be a second identical run;
     the receipt is what tells it to trust this turn's result.
     `gate-fix` returning `CLEAN` is a handoff, not a stopping point —
     never end the turn or wait for the user between the two sub-skills.
   - **`PLAN_PENDING`** → stop. The fixer's Refactor Plan IS the proposed
     coding change. Surface it to the user **verbatim and in full** (do not
     summarize, reorder, or trim) and wait for them to approve or amend it
     before any code is written. Do **not** invoke the committer. Re-running
     `gate` after the user resolves the plan re-enters the fixer cleanly.
   - **`BLOCKED`** → stop and report what the fixer left behind. Do **not**
     invoke the committer.

## Returning to the caller

This skill may be invoked directly by the user, or by another skill (`do-pr`).
When a skill invoked it, `gate-commit` finishing is a **handoff, not a
conclusion** — report what was committed and continue in the **same turn** with
whatever step the caller has next. Do not end your turn and do not wait for the
user. Only the outermost skill in the chain decides when the turn is over.

The deliberate stops are `PLAN_PENDING` (the user approves the Refactor Plan)
and `BLOCKED`. Those two end the chain; the `CLEAN` path never does.

## Running non-interactively

When the invoking prompt carries `NON_INTERACTIVE: true` (see
`../shared/escalation.md`), the branches above are unchanged. `PLAN_PENDING` is
deliberately **not** converted into a `NEEDS_DECISION`: a Refactor Plan is a
proposed code change, not a menu of options, so it is returned verbatim and in
full for the caller to surface to the user. Never approve your own Refactor
Plan because no user was there to approve it.

## Forbidden

- Ending the turn after `gate-commit` succeeds, instead of returning to the caller.
- Invoking `gate-commit` when the fixer did not return `CLEAN`, **except** on the
  step 0 receipt path, where the receipt stands in for that `CLEAN`.
- Honouring a `GATE_RECEIPT` or a `.test-receipt.json` `consistency` field whose
  hash does not match the current tree, or matching it on a prefix rather than
  all 40 characters.
- Honouring a `.test-receipt.json` whose `consistency` field is absent or not
  `green`.
- Passing `CONSISTENCY_VERIFIED` to the committer on any path where `mix consistency`
  was not just proven green for that exact hash.
- Editing code or committing directly from this skill — all work happens in
  the two sub-skills.
