# Spawn prompts

Loaded by `epic-orchestrator`'s Spawn, only on a non-empty batch.

Every spawn: `subagent_type: general-purpose`, **no `isolation`**, `model` from
`coder-model.md` at `M.obs.level` — `code-issue` → Coder, `review-issue` → Spec/Review,
`pr-from-issue` → the pinned Ship family (never the issue's level). Never hardcode a
model, never write one onto a GitHub issue.

All `Agent` calls of the batch go in **one message**. This agent never changes its own
directory to spawn a section — it stays in its own checkout for every tool call, Provision
through Collect. Working directory is shared, sequential state; a `cd` here would steer
whichever spawn fires next, not the section it was meant for, and a batch spawns several
sections' `Agent` calls together. Instead, each section spawn's own prompt carries a
`WORKTREE:` line, and the spawned agent enters that worktree itself, as its own first
action, before it does anything else — see the verify step below.

Announce per spawn: `<SEC-ID> → <skill> @ <model>`

## Section spawn — `code-issue`, `review-issue <n> <SEC-ID>`, `pr-from-issue`

```
NON_INTERACTIVE: true
WORKTREE: <abs>/.claude/worktrees/section-<n>-<sec>
SECTION_STATE:
Section Map row: <the row, verbatim>
Complexity: <level>
PR: <state> #<num> (labels: <l1,l2,...>) | none
Review-table row: <raw STATE cell text> | no row | no table
Newest section-log: <comment id> <ISO 8601 created_at> | none
Checkpoint: <comment id>
First, run `cd "<WORKTREE path above>" && git rev-parse --show-toplevel` and confirm the
second line prints exactly the `WORKTREE:` path above. If the `cd` fails or the printed
path differs, stop immediately and return `STATUS: BLOCKED — worktree-entry`, changing no
files.
Then invoke the `<skill>` skill for issue <n> section <SEC-ID>.
Return the skill's terminal STATUS / verdict line, and nothing else of length.
```

| Field | Source |
|---|---|
| Section Map row, Complexity | `M.obs` spec file |
| PR | `M.obs` PR file, the row for this branch |
| Review-table row, Newest section-log (`id` and `created_at`) | `M.obs` comments file |
| Checkpoint (`id`) | `M.obs` comments file — only for `code-issue`, and only when the newest comment whose body starts with `<!-- code-issue-gap #<n> <SEC-ID> -->` has a `created_at` later than the newest section-log's (or no section-log exists); omitted otherwise |

The block restates facts already in `M`; each skill's own Step 0 says which of its
fetches the block lets it skip. **The verify line is never abbreviated away.**

## Closing-mode spawn — `review-issue <n>`, no `<SEC-ID>`

```
NON_INTERACTIVE: true
Invoke the `review-issue` skill for issue <n>.
Return the skill's terminal STATUS / verdict line, and nothing else of length.
```

No worktree, no `WORKTREE:` line, no preamble. Issued from this agent's own checkout —
which it never leaves. Guard first:

```bash
git rev-parse --abbrev-ref HEAD                 # must be main
git status --porcelain --untracked-files=no     # must be empty
```

Either failing → spawn nothing; row `note: blocked: checkout-not-on-main`, naming the
branch or the modified files.

## Fallback

A subagent reporting it cannot invoke the `Skill` tool: re-spawn with `Read
.claude/skills/<skill>/SKILL.md and follow it exactly for issue <n>[ section <SEC-ID>].`
— after the same verify.

## Never

- A section spawn without its `WORKTREE:` line, or whose grandchild does not `cd` into it
  and verify before invoking the skill.
- This agent itself `cd`-ing anywhere to spawn a section — the spawned agent enters its
  own worktree; this agent's own checkout never moves.
- `improve-issue`, `address-pr-review` or `merge-pr` in the batch.
