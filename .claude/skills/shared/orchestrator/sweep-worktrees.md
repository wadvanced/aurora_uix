# Sweeping throwaway worktrees

Loaded by `epic-orchestrator`'s Sweep, only when it found a candidate. Source: git
and the filesystem only — never `.orchestrator-state.json`, never PR state.

Input: the `git worktree list --porcelain` output Sweep already holds
(`worktree <path>` / `HEAD <sha>` / `branch <ref>` / `[locked [<reason>]]` / `[prunable]`).

## `agent-<id>` worktrees (Agent-tool isolation directories)

Every checkout-wide entry under `.claude/worktrees/agent-*`, whatever issue made it.
First match wins:

| Condition | Do | Announce |
|---|---|---|
| locked, reason `claude agent agent-<id> (pid <p> start <time>)`, `kill -0 <p>` succeeds | nothing | `skipped: live pid <p>` |
| locked, that pid is dead | `git worktree unlock "<path>"`, continue down this table | `unlocked (dead pid <p>) and removed` |
| locked, no pid in the reason | nothing | `skipped: lock without pid` |
| `git -C "<path>" status --porcelain` non-empty (`_build`, `deps`, the state file never count) | nothing | `skipped: dirty` |
| otherwise | `git worktree remove "<path>"`; then `git branch -D "worktree-agent-<id>"` if it stood on that branch | `removed` |

## Orphan branches

Delete every `worktree-agent-*` branch absent from every `branch` line of the
porcelain list. Announce `removed` per branch.

## Never

- `git worktree remove --force`, or removing a worktree whose lock names a live pid —
  reporting it is the whole action.
- Touching a `section-*` worktree or a section branch. Retiring those is `merge-pr`'s.
- Under dry-run: no `git worktree prune`, no removal, no branch deletion — print each
  verdict as `would: <verdict>` and list `prunable` entries as such.
