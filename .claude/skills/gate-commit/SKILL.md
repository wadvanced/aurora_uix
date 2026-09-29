---
name: gate-commit
description: Group the working tree into conventional commits and commit them. Refuses to run unless `mix consistency` is currently clean.
---

Group the staged changes into conventional commits. This skill is gated: it
will not commit unless `mix consistency` currently passes.

Follows `../shared/turn-discipline.md` throughout: batch independent tool
calls, never poll, no narration-only turns.

## 1. Gate

This skill does not commit onto a red tree. There are two ways to establish that
it is green, and the receipt path exists only because `gate` has *just* run the
identical command.

**Receipt path.** If the invoking prompt carries a `CONSISTENCY_VERIFIED: <sha>`
line, compute `tree_hash` per `../shared/gate-receipt.md` and compare all 40
characters. On an exact match, skip `mix consistency` and say so:

```
Trusting CONSISTENCY_VERIFIED receipt for tree <short-sha> — skipping mix consistency.
```

Then go to step 2. Anything less than an exact match — no receipt line, a
malformed one, a different hash — falls through to the full run below. A
near-miss is a miss.

**Full path.** Otherwise — and this is always the case when a user invokes this
skill directly — run:

```
.claude/scripts/gate.sh
```

Run it per `../shared/background-long-commands.md` — `run_in_background`, then
one foreground `.claude/scripts/wait-verdict.sh gate`. A verdict of
`SKIPPED: docs/spec-only changes` then `EXIT: 0` is a pass.

If exit code is non-zero, abort with:

> `mix consistency` is failing. Run the `gate` skill (or `gate-fix`
> directly) before committing.

Do not stage, do not commit, do not retry.

The refusal guarantee in this skill's description is unchanged: invoked on its
own, with no receipt, it still runs the gate and still refuses on red.

## 2. Grouping rules

A **group** is a set of changed files that share one intent and become exactly
**one** commit. Assign every changed file to a group using the table below,
**first match wins** (check rows top to bottom). Each group is one commit whose
type is the `Type` column.

| # | A file belongs here when… | Type | Message shape |
|---|---|---|---|
| 1 | it is under `.claude/` (skills, agents, scripts, hooks, settings) | `chore` | `chore: <what changed>` |
| 2 | it is CI config (`.github/workflows/**`, CI/lint config) | `ci` | `ci: <what changed>` |
| 3 | it is build/dependency config (`mix.exs`, `mix.lock`, `.tool-versions`, asset build config) | `build` | `build: <what changed>` |
| 4 | it is a `.pot` gettext template (`priv/gettext/*.pot`) | `chore` | `chore: <what changed>` |
| 5 | it is a test file (`test/**`, `*_test.exs`) | `test` | `test: <details>` or scoped `test(feat): …`, `test(chore): …` |
| 6 | it was changed **only** by `mix format` | `chore` | `chore: format` |
| 7 | it was changed **only** by the `documentation` skill | `docs` | `docs: <scope>` |
| 8 | it is `CHANGELOG.md`, or a guide/README that documents the change | `docs` | `docs: <scope>` |
| 9 | it adds new user-facing behavior | `feat` | `feat: <why>` |
| 10 | it fixes a bug | `fix` | `fix: <why>` |
| 11 | it improves performance without changing behavior | `perf` | `perf: <why>` |
| 12 | it restructures code without changing behavior | `refactor` | `refactor: <why>` |
| 13 | it changes only formatting/whitespace/style, no code meaning | `style` | `style: <what changed>` |
| 14 | it is other maintenance/tooling (not covered above) | `chore` | `chore: <what changed>` |
| 15 | none of the above, or a file could plausibly fit two groups | — | **STOP and ask the user how to split.** |

Rules that override the table:

- Test files (row 5) are **never** grouped with non-test files. They may form a
  single `test:` group or several scoped ones (`test(feat):`, `test(chore):`).
- A regenerated artifact (`priv/static/classes.js`, generated stylesheet inputs)
  travels with the change that caused it, not in a group of its own.
- `specs/issue-<n>-enriched-spec.md` carrying only `- [ ]` → `- [x]` flips
  (a `spec-store tick`) travels in the section's own code commit group — it is
  part of the section's change, not a separate intent.
- When in doubt between two groups, do not guess — use row 15 and ask.

## 3. Stage and commit

For each group:

1. `git add <specific file>` — explicitly, one file at a time. Never
   `git add -A` / `git add .`.
2. Commit with a conventional message that describes the *why*, not the
   *what*. Pass the message via HEREDOC to preserve formatting.

If there is nothing to commit after the gate passes, report that in a short note
and return to the caller.

Every commit message ends with the `Co-Authored-By` trailer the harness
specifies (never invent one).

## Returning to the caller

This skill is normally invoked by another skill (`gate`), never on its own. The
closing report — commits created, or nothing to commit — is a **handoff, not a
conclusion**. Emit it and continue in the **same turn** with whatever step the
caller has next. Do not end your turn and do not wait for the user. Only the
outermost skill in the chain decides when the turn is over.

The one deliberate stop is row 15 of the grouping table: an unassignable or
ambiguous file requires the user's decision, so ask and wait. Every other path
returns.

## Forbidden

- Ending the turn after committing instead of returning to the caller.
- `--no-verify` on any git command.
- `git push --force` (this skill does not push).
- `git add -A` / `git add .`.
- Amending an existing commit.
- Committing while `mix consistency` is failing.
- Honouring a `CONSISTENCY_VERIFIED` receipt whose hash does not match the current
  tree, or matching it on a prefix rather than all 40 characters.
- Skipping `mix consistency` on anything other than an exact receipt match — a
  caller's assurance in prose is not a receipt.
