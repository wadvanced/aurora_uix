---
name: do-pr
description: Create a pull request with proper formatting and pre-merge checks
---

Create a pull request for the current branch. Run every step in order. If a step
fails, stop **this skill** and report to the caller with `STATUS: BLOCKED` — do
NOT proceed to later steps. "Stop" means stop the skill, never end the turn; see
**Returning to the caller** at the end of this file.

Follows `../shared/turn-discipline.md` throughout: batch independent tool
calls, never poll, one edit per file per turn, no narration-only turns.

## 1. Preconditions

- Current branch is not `main`:
  - `git rev-parse --abbrev-ref HEAD` must NOT print `main`. Stop if it does.
  - `pr-from-issue` checks this in its own Step 0 too, before it spends four
    steps getting here. The duplication is deliberate: this skill is also
    invoked directly, so it cannot rely on a caller having checked.

Do NOT require a clean working tree here — Step 2's `gate` commits any remaining
working-tree changes into conventional commits.

## 2. Quality gate

**First, resolve the gate receipt.** Compute `tree_hash` per
`../shared/gate-receipt.md`. If the invoking prompt carries a
`GATE_RECEIPT: <sha>` line and all 40 characters match, then `mix consistency` and
`mix test` were both green on exactly this content and re-running them can only
reproduce that answer. Record this as **receipt hit**; otherwise **receipt miss**
— no receipt, a malformed one, or any difference at all. A near-miss is a miss.

Invoke the `gate` skill via the Skill tool, passing `GATE_RECEIPT: <sha>` through
on a hit and nothing on a miss. If it stops with unresolved errors, do NOT continue — report the errors to the user and stop.

`gate` is invoked on **both** paths, and that is deliberate: `review-issue`
applies its own REVIEWER-FIXED edits and never commits them, so `gate-commit` is
what gets those fixes into the PR. The receipt suppresses the redundant
*verification*, never the commit.

Say which path was taken, on its own line:

```
Gate receipt: hit (tree <short-sha>) — consistency and test skipped, already green on this content.
Gate receipt: miss — running the full gate.
```

## 3. Test

On a **receipt hit**, skip it — `review-issue` ran the full suite on this exact
content and its verdict rules loop on red, so a `✅ DONE` carrying a matching
receipt already means green. Note the deliberate consequence: this removes the
one user-overridable stop below from the receipt path. That is correct, since the
orchestrator drives this skill with `NON_INTERACTIVE: true` and could not answer
the prompt anyway.

On a **receipt miss**, check the suite receipt before spending the suite. Read
`.test-receipt.json` at the root of the working tree and honour it **only** when
all three hold: the file parses, its `tree` is byte-equal to the `tree_hash`
computed in step 2, and its `suite` is `green`. Compare the full 40 characters;
a near-miss is a miss.

```
Suite receipt: hit (tree <short-sha>) — mix test skipped, already green on this content.
Suite receipt: miss — running the full suite.
```

- **Suite receipt hit** → skip `mix test`. Whether `mix consistency` itself ran or was
  skipped was already decided inside `gate` in step 2, against the same file's
  `consistency` field — this skill reads only `suite` and never reasons about
  `consistency` itself.
- **Suite receipt miss or absent** → run `.claude/scripts/suite.sh` per
  `../shared/background-long-commands.md` (`run_in_background`, then one
  foreground `.claude/scripts/wait-verdict.sh suite`); if any error, report the errors and
  ask the user if the task should continue.

The case this catches is a `↩️ RESPEC`: `improve-issue` edits the issue and
never the repo, so the tree is unchanged and the suite result still holds, but
the `review-gaps` block carrying `GATE_RECEIPT` was replaced. Without this
fallback the full suite would be re-run over content already proved green,
purely because a marker block moved.

Never write `.test-receipt.json` from this skill on a receipt hit — you did not
run the suite, and only a step that ran it to completion may record one. On a
genuine miss where you did run the whole suite green, writing one is correct.

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

**A caller may supply the title.** When the invoking prompt carries a
`PR_TITLE: <title>` line, use it **verbatim** and skip the derivation below —
including any punctuation, and without appending or reformatting anything. A
caller that knows the title knows it better than a branch name does:
`pr-from-issue` takes it from the issue's Section Map, where it ends
`(#<n> · <SEC-ID>)` and is what makes a section's PR identifiable.

Otherwise apply these rules to the current branch name:

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
  (e.g. `chore: update skill files` tells a reviewer nothing).

**Write the Summary as 3–6 bullets:**

- Each bullet states *what* changed and, where non-obvious, *why*.
- **Group related commits into a single bullet.** Do NOT emit one bullet per
  commit.
- Reference concrete artifacts — module, file, field, and function names in
  backticks — so each bullet is self-explanatory.

Good vs. bad bullets:

```
❌ - chore: update do-pr and pr-from-issue skill files
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

**Optional issue reference.** Add a blank line and one reference line **inside
the block**, right before the `GENERATED-DESCRIPTION:END` marker. First match
wins:

1. An `ISSUE_REF: <text>` line in the invoking prompt → use `<text>` **verbatim**.
   The caller has decided what this PR does to the issue; never rewrite it into
   a `Closes` and never add one alongside it. `pr-from-issue` sends
   `Part of #<n> · <SEC-ID>` for a PR that ships one section of several, and
   `Closes #<n>` only once `review-issue` has declared the issue complete —
   turning the former into the latter would close an issue with sections still
   unwritten.
2. A bare issue number `<n>` and no `ISSUE_REF:` → `Closes #<n>`.
3. Neither → no reference line.

**Attribution.** After the `GENERATED-DESCRIPTION:END` marker (outside the
managed block, so a refresh preserves it), end the body with the pull-request
attribution line the harness specifies for this session, when it specifies one
(`🤖 Generated with [Claude Code](https://claude.com/claude-code)`). Add it once,
on creation; never duplicate it on a refresh.

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

Print the PR URL returned by `gh`, then the terminal status on its own line:

```
STATUS: PR_READY <pr-url>
```

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
   Report "description refreshed" and print the PR URL, then the terminal status
   on its own line:
   ```
   STATUS: PR_REFRESHED <pr-url>
   ```

## Terminal status

This skill always **returns** exactly one of these statuses to its caller,
printed on its own line so an orchestrator can branch on it:

- `STATUS: PR_READY <pr-url>` — a new PR was created.
- `STATUS: PR_REFRESHED <pr-url>` — an existing PR's managed block was refreshed,
  or the body was deliberately left untouched because a marker was missing.
- `STATUS: BLOCKED — <reason>` — a step failed (preconditions, `gate`, `mix test`,
  push, or the sync guard) and no PR was created or updated.

## Returning to the caller

This skill may be invoked directly by the user, or by another skill
(`pr-from-issue`). When a skill invoked it, the PR URL and `STATUS:` line are a
**handoff, not a conclusion** — emit them and continue in the **same turn** with
whatever step the caller has next. Do not end your turn and do not wait for the
user. Only the outermost skill in the chain decides when the turn is over.

The one deliberate stop is Step 3 on a receipt miss: a red `mix test` requires
the user's decision, so ask and wait. On a receipt hit Step 3 does not run, so
this skill has no interactive stop of its own.

## Forbidden

- Ending the turn after printing the PR URL, instead of returning to the caller.

- `git push --force` / `--force-with-lease`
- `--no-verify` on any git command
- Amending an already-pushed commit
- Creating a PR while preconditions or `mix consistency` fail
- Honouring a `GATE_RECEIPT` whose hash does not match the tree in front of you,
  or matching it on a prefix rather than all 40 characters
- Inferring a receipt from anything but a literal `GATE_RECEIPT:` line — an
  issue's completion phrase, a caller's assurance, and a green transcript are all
  not receipts
- Skipping the `gate` skill itself on a receipt hit. The receipt suppresses
  verification, never `gate-commit` — skipping it would drop the reviewer's own
  fixes out of the PR
- Reporting a run as gated when it took the receipt path, or taking either path
  without saying which
- Modifying the PR body when either `GENERATED-DESCRIPTION` marker is absent
- Altering any content outside the `GENERATED-DESCRIPTION` markers, or the PR title
- Rewriting a supplied `PR_TITLE:` or `ISSUE_REF:` — reformatting the title,
  appending to it, or promoting a `Part of` reference into a `Closes`. A caller
  that supplies either has decided it; silently "improving" an `ISSUE_REF` can
  close an issue whose remaining sections are not written yet
- Creating or updating a PR description while local `HEAD` is ahead of
  `origin/<current-branch>` (unpushed commits)
