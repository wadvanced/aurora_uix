# Retiring a section worktree

Single source of truth for removing a section worktree and destroying the
private test PostgreSQL instances that worktrees leave behind. Referenced from
`merge-pr` (`../merge-pr/SKILL.md` Step 2 step 4), its only caller; never
duplicated into it. `epic-orchestrator` retires a section worktree only by
invoking `merge-pr`.

This is the mechanism only — removing a worktree and sweeping instances.
Deciding *when* a worktree is due for retirement, and *finding* its path, are
the caller's job: `merge-pr` locates it by matching
`git worktree list --porcelain`'s `branch refs/heads/<branch>` against the PR
it just confirmed `MERGED`. It retires only **after** a merge is confirmed,
never before — that invariant is the caller's to keep, not this doc's to
enforce.

Section worktrees live at `.claude/worktrees/section-<n>-<sec>` inside the main
checkout (gitignored), so they are found from `git worktree list` and never by
guessing a path. A spec PR (`spec/<n>-enriched-spec`) has no worktree; for it
the removal below is a no-op and only the sweep runs.

```bash
if [ -d "$WT" ]; then
  git worktree remove "$WT"        # never --force
fi
scripts/test_pg.sh sweep           # from any checkout; destroys instances whose checkout is gone
```

- **The test database is not on the shared server.** Every checkout tests
  against its own disposable PostgreSQL instance under `/tmp/aurora_uix_pg/`
  (override `AURORA_UIX_TEST_PG`; `scripts/test_pg.sh`, started by the test
  config on the first `mix test`; never on CI). Each instance records the
  checkout path it belongs to; `sweep` stops and `rm -rf`s every instance whose
  recorded checkout no longer exists. No `DROP DATABASE`, nothing to `cd` into,
  nothing that can be skipped by a crash — a worktree removed by hand or pruned
  by `git worktree prune` is caught the same way on the next sweep.
- **Remove first, sweep after.** The sweep only destroys an instance whose
  checkout is gone, so the order is what makes the removal's instance eligible.
- **The sweep is idempotent and runs from anywhere.** Run it after every
  removal, and again whenever leftovers are suspected; an instance whose
  checkout still exists is reported as `kept` and left alone.
- **A missing `$WT` is a no-op for the removal, not for the sweep.** No
  worktree ever existed for this branch, or a previous run already retired
  it — either way the sweep still runs, because an instance may outlive the
  worktree that created it.
- **A refused removal is reported and skipped, never forced.** `git worktree
  remove` refuses a dirty tree or a lock naming a live pid; the caller reports
  the path and moves on. `--force` can discard uncommitted work sitting in
  that worktree — never used here. The sweep still runs and keeps that
  worktree's instance, since its checkout is still on disk.
