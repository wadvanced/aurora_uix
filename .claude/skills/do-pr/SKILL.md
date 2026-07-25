---
name: do-pr
description: Create a pull request with proper formatting and pre-merge checks
---

Create a pull request for the current branch. Run every step in order. If a step fails, stop and report — do NOT proceed to later steps.

## 1. Preconditions

- Current branch is not `main`:
  - `git rev-parse --abbrev-ref HEAD` must NOT print `main`. Stop if it does.

Do NOT require a clean working tree here — Step 2's `gate` commits any remaining
working-tree changes into conventional commits.

## 2. Quality gate

Invoke the `gate` skill via the Skill tool. If it stops with unresolved errors, do NOT continue — report the errors to the user and stop.

## 3. Test 

Run 'mix test' if any error, report the errors and ask the user if the task should continue

## 4. Push

Push is **mandatory on every invocation**, including re-runs where the PR already
exists — the PR description is built from local commits, so origin must carry them
first.

```
git push -u origin <current-branch>
```

Then confirm the branch is fully pushed — these two SHAs must be equal:

```
git rev-parse HEAD
git rev-parse origin/<current-branch>
```

If push fails or the SHAs differ, stop and report. Never use `--force` or
`--no-verify`.

## 5. Build the PR title

Apply these rules to the current branch name:

1. Strip any leading `<username>/` or `<username>-` prefix (everything up to and including the first `/` or `-`).
2. If the next segment is purely numeric (an issue number, e.g. `365/…`), strip it too — including its trailing `/` or `-`.
3. Take the first remaining token (split on `-` or `_`). If it matches one of `feat|fix|build|refactor|docs|chore|test|perf`, use it as `<type>` and remove it. Otherwise default `<type>` to `feat`.
4. Replace remaining `-` and `_` with spaces. This is `<description>`.
5. Final title: `<type>: <description>`.

Examples:
- `federico/365/name-fields-components` → `feat: name fields components`
- `federico/338/refactor-rename-table` → `refactor: rename table`
- `federico/implement_user_profile` → `feat: implement user profile`
- `federicoalcantara-fix-login-bug` → `fix: login bug`
- `federico/refactor_auth` → `refactor: auth`

## 6. Build the PR body

Write a **prose Summary that describes the change — not the commit log.** Do NOT
copy commit subjects verbatim; a reviewer who has not seen the commits must be
able to understand the PR from the body alone.

**Gather context from the diff, not just the subjects:**

- `git log main..HEAD --pretty=format:"%s"` — commit subjects, for orientation only.
- `git diff main...HEAD --stat` — files touched and overall scope.
- Read the actual diff for the substantive changes whenever the subjects are terse
  (e.g. `ai: update skill files` tells a reviewer nothing).

**Write the Summary as 3–6 bullets:**

- Each bullet states *what* changed and, where non-obvious, *why*.
- **Group related commits into a single bullet.** Do NOT emit one bullet per
  commit.
- Reference concrete artifacts — module, file, field, and function names in
  backticks — so each bullet is self-explanatory.

Good vs. bad bullets:

```
❌ - ai: update do-pr and pr-from-issue skill files
✅ - Rewrites `do-pr` Step 6 so PR summaries are prose derived from the diff
     instead of copied commit subjects, and drops the boilerplate Test plan section
```

**Wrap the generated content in the managed-region markers.** These two visible
blockquote lines delimit the block `do-pr` owns; reviewers add their own notes
*outside* them and a later re-run refreshes only what is *between* them (see
Step 7). Compose the whole block into a body file (`git status` is clean, so use
the scratchpad or a temp file):

```
> 🤖 **GENERATED-DESCRIPTION:START** — auto-generated; edit above or below, never inside.

## Summary
- <prose bullet 1>
- <prose bullet 2>
- ...

> 🤖 **GENERATED-DESCRIPTION:END**
```

**Optional issue reference.** If a caller (e.g. the `pr-from-issue` skill) invokes
this skill with an issue number `<n>`, add a blank line and `Closes #<n>` **inside
the block**, right before the `GENERATED-DESCRIPTION:END` marker. When no issue
number is passed, do not add a `Closes` line.

## 7. Create or update the PR

**Sync guard (both paths).** The PR body describes local commits, so the branch
must be fully pushed before it is written. Run `git push -u origin
<current-branch>`, then verify `git rev-parse HEAD` equals `git rev-parse
origin/<current-branch>`. If they differ, stop — do NOT create or update the PR.

Check whether the branch already has a PR: `gh pr view --json url`.

### No PR yet — create

The body is the marker-wrapped block from Step 6 (the whole body file). Then:

```
gh pr create --base main --title "<title>" --body-file <body-file>
```

Print the PR URL returned by `gh`.

### PR already exists — refresh in place

Refresh **only the text between the markers**, preserving everything a reviewer
wrote above `GENERATED-DESCRIPTION:START` or below `GENERATED-DESCRIPTION:END`.

1. Fetch the live body (strip the CRLF that `gh` injects):
   ```
   gh pr view --json body --jq .body | tr -d '\r' > live_body
   ```
2. **Both markers must be present.** If either is missing, do NOT touch the body
   — report the PR URL and that the description was left unchanged, then stop:
   ```
   grep -qF 'GENERATED-DESCRIPTION:START' live_body \
     && grep -qF 'GENERATED-DESCRIPTION:END' live_body
   ```
3. Carve out the reviewer-owned regions verbatim:
   ```
   awk '/GENERATED-DESCRIPTION:START/{exit} {print}' live_body > prefix   # before START
   awk 'p{print} /GENERATED-DESCRIPTION:END/{p=1}'   live_body > suffix   # after END
   ```
4. Rebuild the managed block via Step 6 into `block` (fresh Summary from the
   current commits, wrapped in both markers).
5. Reassemble and update:
   ```
   cat prefix block suffix > new_body
   gh pr edit --body-file new_body
   ```
   Report "description refreshed" and print the PR URL.

## Forbidden

- `git push --force` / `--force-with-lease`
- `--no-verify` on any git command
- Amending an already-pushed commit
- Creating a PR while preconditions or precommit fail
- Modifying the PR body when either `GENERATED-DESCRIPTION` marker is absent
- Altering any content outside the `GENERATED-DESCRIPTION` markers, or the PR title
- Creating or updating a PR description while local `HEAD` is ahead of
  `origin/<current-branch>` (unpushed commits)

