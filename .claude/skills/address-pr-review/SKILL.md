---
name: address-pr-review
description: >
  Capture the unresolved review threads on a section PR as a `review-feedback`
  report on its issue, so `improve-issue` can turn each one into a spec change
  and `code-issue` can implement and close it. Use this skill when the user
  says "capture PR review", "address PR review", "pick up the review comments",
  or pastes a PR URL/number with reviewer feedback. Also invoked by the
  `epic-orchestrator` agent when a section PR carries `amends-required`, and by
  `code-issue`'s preflight before it codes against an open PR. It reads threads
  and writes comments; it changes no code, resolves no captured thread, and
  proposes no fix.
---

# Skill: address-pr-review

Read every **unresolved** review thread on a section PR and report the ones
that need work as **one `review-feedback` comment on the issue**. That is the
whole job. Three skills, three roles:

| Skill | Role |
|---|---|
| `address-pr-review` | **reports** — what the reviewer said, what the spec says, what the repo shows |
| `improve-issue` | **specifies** — turns each item into a spec change, or a recorded decline, with the user's approval |
| `code-issue` | **solves** — implements the re-specced section, then answers and resolves every captured thread |

This skill therefore never edits a file, never runs the gate, never commits,
never resolves a thread it captured, and never proposes a fix. A review
comment is a fact discovered downstream that the spec must absorb — exactly
the shape of a `spec-defect` — and it travels the same channel. If this skill
decided the fix, spec authority would move to the wrong skill and the human
approval in `improve-issue` would be approving a decision already taken.

Follows `../shared/turn-discipline.md` throughout: batch independent tool
calls, never poll, no narration-only turns.

## Arguments

```
address-pr-review <pr-number | pr-url>   # a specific PR
address-pr-review <n> <SEC-ID>           # the PR for that section, via its Section Map branch
address-pr-review                        # the current branch's PR
```

Idempotent. Every run walks every unresolved thread and captures only the
ones not yet captured; running it twice posts nothing the second time.
Interactive and non-interactive runs behave identically — there is no
decision here to ask anyone about.

## Step 0 — Resolve the PR

- A number or URL → `PR_NUMBER` directly.
- `<n> <SEC-ID>` → invoke `spec-load <n>`, read the section's Section Map row,
  take its `Branch` cell, then `gh pr list --head "<branch>" --state open
  --json number --jq '.[0].number'`. `--head` is an exact ref filter; never a
  title search (`code-issue` preflight row 5 carries the reasoning).
- Nothing → `gh pr view --json number`.

No open PR → stop:

```
⚠️ No open PR found. Pass a PR number or URL.
STATUS: BLOCKED — no-pr
```

Then capture `PR_TITLE`, `PR_BODY`, `HEAD_BRANCH`, and `OWNER/REPO` from
`gh repo view --json owner,name --jq '.owner.login + "/" + .name'`.

## Step 1 — Issue and section

A v2 section PR carries both in its title: `… (#<n> · <SEC-ID>)`. Take
`ISSUE_NUMBER` and `SEC_ID` from there. Cross-check the body's
`Part of #<n>` / `Closes #<n>` line agrees on `<n>`.

Either missing, or the two disagree → stop:

```
⚠️ PR #<PR_NUMBER> does not name an issue and section in its title.
STATUS: BLOCKED — section-unresolvable
```

Never guess the section from the diff. A report filed against the wrong
section sends `improve-issue` to rewrite the wrong text.

## Step 2 — Load the section

Invoke `spec-load <ISSUE_NUMBER> <SEC_ID>` and branch on its status:

- `STATUS: BLOCKED — spec-missing` → stop, `STATUS: BLOCKED — spec-missing`.
- `STATUS: BLOCKED — section-fence-missing` → stop, same slug.
- `STATUS: OK <sha>` → `/tmp/spec-<n>-<SEC-ID>.md` is the section. Read it,
  and only it. The acceptance criteria and implementation steps in it are what
  every thread is quoted against in Step 5. Record `<sha>` — the report names
  it, so the spec version a comment was read against is recoverable.

## Step 3 — Fetch unresolved threads

```bash
gh api graphql -F owner="<OWNER>" -F repo="<REPO>" -F pr=<PR_NUMBER> -f query='
query($owner:String!,$repo:String!,$pr:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first:50) {
            nodes { id databaseId author { login } body path line diffHunk createdAt }
          }
        }
      }
    }
  }
}' > /tmp/address-pr-review-<PR_NUMBER>-threads.json
```

Keep only `isResolved == false`. For each, hold `THREAD_ID`, `PATH`, `LINE`,
`IS_OUTDATED`, the ordered comments, and the first comment's `databaseId`
(the reply target).

**Already captured** — a thread whose **last comment's body contains
`<!-- captured #<n> <SEC-ID> `** is skipped. The marker is the key, never the
author: the reviewer and the `gh` session may be the same GitHub account, so
"last comment is ours" would swallow real feedback. A reviewer who adds a
comment after ours makes the thread new again, and it is captured again as a
fresh item — that is correct, not a duplicate.

Only line-anchored threads are handled. A review's summary body is not a
thread, cannot be resolved, and is deliberately ignored: an actionable ask
belongs on a line.

Zero threads left after filtering → Step 6 with `NO_NEW_FEEDBACK`.

## Step 4 — Sort each thread

Exactly one of three:

| Sort | When | Now |
|---|---|---|
| `REPLY_ONLY` | a question answerable from the section, a clarification, a thank-you, an observation that asks for nothing | answer it, resolve the thread |
| `OUTDATED` | `isOutdated == true` **and** the current diff at that path visibly already does what was asked | reply naming the change, resolve the thread |
| `CAPTURE` | everything else — a requested change, a disagreement with an AC, a scope question, an ambiguity, anything you are not certain is `REPLY_ONLY` | item in the report |

Out-of-scope and ambiguous asks are `CAPTURE`, not a judgement call here.
`improve-issue` has the whole spec, the codebase, and a user to ask; this
skill has one section and no user. When in doubt, capture.

Reply and resolve use the same two calls throughout:

```bash
gh api -X POST \
  "repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments/<FIRST_COMMENT_DB_ID>/replies" \
  -f body="<reply>"

gh api graphql -f query='
mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ id isResolved } } }' \
  -f id="<THREAD_ID>"
```

Never resolve before replying. Never resolve a `CAPTURE` thread — that is
`code-issue`'s act, after the work exists.

## Step 5 — Post the report

No `CAPTURE` threads → skip to Step 6.

Otherwise, **one** comment on the issue. Details only: what the reviewer
said, what the spec says, what the repo shows. **No proposed fix, no
suggested wording, no "we should".** The report is raw material for
`improve-issue`; a proposal in it pre-empts the decision that skill makes with
the user.

```markdown
<!-- review-feedback #<n> <SEC-ID> -->
### 🔁 PR review feedback — issue #<n> · <SEC-ID> · PR #<PR_NUMBER> · spec <sha>

| # | Thread | Path:Line | Reviewer | Touches |
|---|---|---|---|---|
| 1 | <THREAD_ID> | lib/foo.ex:42 | @alice | AC-3 |
| 2 | <THREAD_ID> | lib/bar.ex:10 | @bob | step 6 |
| 3 | <THREAD_ID> | (unanchored) | @carol | — |

#### 1 · <THREAD_ID>
- **Reviewer says:** "<verbatim quote — the whole ask, not a paraphrase>"
- **Spec says:** "<verbatim AC or step text>" (AC-3)
- **Repo shows:** <file:anchor, or command + output>
- **Conflict:** <one or two sentences of fact>

#### 2 · <THREAD_ID>
…
```

`Touches` names the AC or numbered step the comment bears on; `—` when it
bears on none (a scope question, a request for something the section does
not describe). `Spec says` quotes the section file from Step 2, never memory.

```bash
gh issue comment <n> --body-file /tmp/address-pr-review-<PR_NUMBER>-report.md
```

Then reply on every captured thread, so the reviewer sees it was seen and so
Step 3 skips it next time:

```
<!-- captured #<n> <SEC-ID> item-<k> -->
Captured as item <k> of the review-feedback report on #<n>. It will be
answered through the spec and closed by the change that implements it.
```

**Leave the thread open.** It closes when `code-issue` has done the work.

## Step 6 — Report

```
### Address-PR-Review · PR #<PR_NUMBER> → issue #<n> · <SEC-ID>

Answered and resolved: <count> (REPLY_ONLY <a>, OUTDATED <b>)
Captured:              <count> → review-feedback comment <url>
Skipped (captured earlier): <count>
```

Then exactly one terminal line:

| Status | Meaning |
|---|---|
| `STATUS: FEEDBACK_CAPTURED <count>` | a report was posted; the section's spec now needs `improve-issue` |
| `STATUS: NO_NEW_FEEDBACK` | nothing to capture — every unresolved thread was answered here or captured earlier |
| `STATUS: BLOCKED — <slug>` | `no-pr`, `section-unresolvable`, `spec-missing`, `section-fence-missing` |

`FEEDBACK_CAPTURED` is read by the orchestrator the way a `spec-defect`
comment is: the next pass reports `SPEC_PENDING`, and `improve-issue` runs
interactively to absorb it.

## What happens next (not this skill's job)

- `improve-issue <n>` ingests the report, rewrites the section — or declines
  an item with a reason — and posts `<!-- review-feedback-resolved <comment-id> -->`
  with one line per item.
- `code-issue <n> <SEC-ID>` resumes on the section's branch, implements what
  the resolution lines name, replies on each captured thread — the commit
  for a solved item, the reason for a declined one — and resolves them all.
- The reviewer re-reviews and removes `amends-required` — a human act, never
  a skill's (`../shared/house-conventions.md` H-6).

## Forbidden

- Editing any file, running `mix format`, `mix consistency`, or `mix test`,
  staging, committing, or pushing.
- Resolving a `CAPTURE` thread, or replying to it with anything but the
  captured marker.
- Proposing a fix, a rewording, or a scope decision in the report or in a
  reply. Facts only.
- Capturing from a paraphrase. `Reviewer says` and `Spec says` are verbatim.
- Guessing the section when the PR title does not name it.
- Reading the spec from the issue body or any ref but `main` — `spec-load`
  owns that.
- Adding, removing, or reading meaning into `approved` / `amends-required`.
  The label is the orchestrator's trigger to call this skill; it is not
  feedback, and its absence is not permission to skip a thread.
