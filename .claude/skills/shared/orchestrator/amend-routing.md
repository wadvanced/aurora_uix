# Routing a section whose PR carries `amends-required`

Loaded by `epic-orchestrator`'s Inline, only for a row with `next: probe`.

## 1. Probe

Run `address-pr-review <n> <SEC-ID>` through the Skill tool, in this agent's own
checkout.

| Returned | Row becomes | `M.changed` |
|---|---|---|
| `FEEDBACK_CAPTURED` | `next: —`, `note: feedback captured` | `true` — the next pass observes the new report |
| `NO_NEW_FEEDBACK` | per § 2 | unchanged |
| `BLOCKED — <slug>` | `next: —`, `note: blocked: <slug>` | unchanged |

## 2. Amend rows — only after `NO_NEW_FEEDBACK`

Sources: `M.obs`'s comments and PR files, plus two local git reads for row d. First
match wins.

| | Condition | `next` |
|---|---|---|
| a | the newest `<!-- review-feedback-resolved` comment containing a line `- item <k> → <SEC-ID>:` is newer than the newest `<!-- section-log #<n> <SEC-ID> -->` comment | `code-issue` — amend resume |
| b | the newest section-log is newer than the review-table comment's `updated_at` | `review-issue` |
| c | the review-table row carries failure notes | `code-issue` — gaps |
| d | the row reads `COMPLETED`, a resolution line for this section exists, and **either** `git rev-parse "<branch>"` ≠ the PR file's `headRefOid` for the branch's `OPEN` row **or** `git -C ".claude/worktrees/section-<n>-<sec>" status --porcelain` is non-empty | `pr-from-issue` |
| e | otherwise — tip equals head **and** the worktree is clean or gone | `—`, `note: awaiting re-review` |

Row d always tests both arms.

These rows are what lets `code-issue`, `review-issue` and `pr-from-issue` skip their own
PR probe under `SECTION_STATE:`; they restate the PR state handed down, they never
derive a second opinion of it.
