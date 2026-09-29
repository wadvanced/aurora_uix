# Provisioning a section worktree

Loaded by `epic-orchestrator`'s Provision, only when the batch holds a section spawn.

One worktree per section, from its first spawn until `merge-pr` retires it. Path:
`.claude/worktrees/section-<n>-<sec>`, `<sec>` lowercased (`PAR-7` → `par-7`). Gitignored.
Parallel sections must never share a database or a port, which is why each gets its own
checkout and, through `scripts/test_pg.sh`, its own PostgreSQL instance.

**One section at a time** — create, then copy, as one unit. Spawns are batched;
provisioning is not. **Idempotent** — a path already in `git worktree list` is skipped
whole, keeping its `_build`.

## 1. Create

```bash
WT=".claude/worktrees/section-<n>-<sec>"
git fetch origin --quiet
if git rev-parse --verify --quiet "refs/heads/<branch>"; then
  git worktree add "$WT" "<branch>"                              # local branch
elif git rev-parse --verify --quiet "refs/remotes/origin/<branch>"; then
  git worktree add --track -b "<branch>" "$WT" "origin/<branch>" # origin only
else
  git worktree add --detach "$WT" origin/main                    # no branch yet
fi
```

| Case | Why |
|---|---|
| detached when no branch exists | `code-issue` owns branch creation, including its `fresh run + branch exists` halt |
| on the branch when one exists | `pr-from-issue` never checks out; it asserts the current branch equals the Section Map's `Branch` cell |

`git worktree add` refuses a branch another worktree holds → set the row's
`note: blocked: branch-checked-out-elsewhere` naming the holder from
`git worktree list --porcelain`, drop the section from `M.batch`, carry on with the rest.

## 2. Copy

```bash
cp -R _build "$WT/_build"                       # skip when the source is missing
cp -R deps "$WT/deps"                           # skip when the source is missing
```

Nothing else is copied and nothing is rewritten. Everything that must differ per
checkout is derived from the worktree itself, so no allocation or ledger exists:

| What | Derived how |
|---|---|
| Test database server | the worktree's private PostgreSQL instance under `/tmp/aurora_uix_pg/` (override `AURORA_UIX_TEST_PG`), created by `scripts/test_pg.sh ensure` on the first `mix test`; a Unix socket, no TCP port |
| Wallaby `base_url` and endpoint port | derived per checkout by the test config, so two worktrees running `mix test` never collide on `4001` |

The instance lifecycle is `scripts/test_pg.sh` (`ensure`, `status`, `psql`, `stop`,
`destroy`, `sweep`, `stop-idle`, `destroy-all`); this agent never calls it — `mix test`
does. It is skipped on CI. Releasing needs no bookkeeping: `merge-pr` retires the
worktree and runs `scripts/test_pg.sh sweep`.

Announce per section: `<SEC-ID> — worktree .claude/worktrees/section-<n>-<sec>`

## Never

- `--force`; creating a section branch; sharing a worktree or a branch between sections.
- A worktree for anything that is not a section — `address-pr-review`, `merge-pr` and
  closing-mode `review-issue` run in this agent's own checkout.
- Setting `AURORA_UIX_TEST_PG` or a port override for a section, or rewriting test
  config in the copy — the derivation is the isolation.
- Copying `_build` into a worktree that already has one.
- Retiring a worktree, here or anywhere in this agent, before its PR merges.
