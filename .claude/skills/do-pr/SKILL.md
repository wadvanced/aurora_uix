---
name: do-pr
description: Create a pull request with proper formatting and pre-merge checks
---

Create a pull request for the current branch. Run every step in order. If a step fails, stop and report — do NOT proceed to later steps.

## 1. Preconditions

Run all three checks. Stop and report if any fails.

- Current branch is not `main`:
  - `git rev-parse --abbrev-ref HEAD` must NOT print `main`.
- Chromedriver is in headless mode:
  - `grep -n "headless: true" config/test.exs` must succeed (exit 0).
- All changes are committed:
  - `git status --porcelain` must print nothing.

## 2. Quality gate

Invoke the `gate` skill via the Skill tool. If it stops with unresolved errors, do NOT continue — report the errors to the user and stop.

## 3. Test 

Run 'mix test' if any error, report the errors and ask the user if the task should continue

## 4. Push

```
git push -u origin <current-branch>
```

If push fails, stop and report. Never use `--force` or `--no-verify`.

## 5. Build the PR title

Apply these rules to the current branch name:

1. Strip any leading `<username>/` or `<username>-` prefix (everything up to and including the first `/` or `-`).
2. Take the first remaining token (split on `-` or `_`). If it matches one of `feat|fix|build|refactor|docs|chore|test|perf`, use it as `<type>` and remove it. Otherwise default `<type>` to `feat`.
3. Replace remaining `-` and `_` with spaces. This is `<description>`.
4. Final title: `<type>: <description>`.

Examples:
- `federico/implement_user_profile` → `feat: implement user profile`
- `federicoalcantara-fix-login-bug` → `fix: login bug`
- `federico/refactor_auth` → `refactor: auth`

## 6. Build the PR body

Use this exact template, filled from `git log main..HEAD --pretty=format:"%s"`:

```
## Summary
- <commit subject 1>
- <commit subject 2>
- ...

## Test plan
- [ ] mix consistency
- [ ] mix test
```

One bullet per commit (subject line only, no body).

## 7. Create the PR

```
gh pr create --base main --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

Print the PR URL returned by `gh`.

## Forbidden

- `git push --force` / `--force-with-lease`
- `--no-verify` on any git command
- Amending an already-pushed commit
- Creating a PR while preconditions or precommit fail
