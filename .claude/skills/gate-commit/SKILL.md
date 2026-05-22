---
name: gate-commit
description: Group the working tree into conventional commits and commit them. Refuses to run unless `mix consistency` is currently clean.
---

Group the staged changes into conventional commits. This skill is gated: it
will not commit unless `mix consistency` currently passes.

## 1. Gate

Run:

```
mix consistency
```

If exit code is non-zero, abort with:

> `mix consistency` is failing. Run the `gate` skill (or `gate-fix`
> directly) before committing.

Do not stage, do not commit, do not retry.

## 2. Grouping rules

Group the working tree into conventional commits using these rules:

- One commit per intent group: `feat:`, `fix:`, `refactor:`, `docs:`,
  `test:`, `chore:`.
- Files changed only by `mix format` → single `chore: format` commit.
- Files changed only by the `documentation` skill → single `docs: <scope>`
  commit.
- All other groupings → STOP and ask the user how to split.

## 3. Stage and commit

For each group:

1. `git add <specific file>` — explicitly, one file at a time. Never
   `git add -A` / `git add .`.
2. Commit with a conventional message that describes the *why*, not the
   *what*. Pass the message via HEREDOC to preserve formatting.

If there is nothing to commit after the gate passes, exit cleanly with a
short note.

## Forbidden

- `--no-verify` on any git command.
- `git push --force` (this skill does not push).
- `git add -A` / `git add .`.
- Amending an existing commit.
- Committing while `mix consistency` is failing.
