# improve-issue · defect and feedback comments

Read by `improve-issue` **Inputs** when the issue's comments carry a marker below, and by
**Present** when the run has inputs. The only home of these rules.

## The two inputs

| Input | Marker on the comment | Written by | Content |
|---|---|---|---|
| **defect** | `<!-- spec-defect #<n> <SEC-ID> -->` | `code-issue` | facts about an instruction that could not be executed as written; a `Class:` field; never a fix |
| **feedback** | `<!-- review-feedback #<n> <SEC-ID> -->` | `address-pr-review` | what a PR reviewer asked of that section, one item per review thread |

## Resolved or unresolved

An input is **resolved** when some comment on the issue carries its counterpart, keyed on the
input comment's numeric id:

| Input | Counterpart |
|---|---|
| defect | `<!-- spec-defect-resolved <comment id> -->` |
| feedback | `<!-- review-feedback-resolved <comment id> -->` |

Why: issue comments do not thread. Keyed on `<SEC-ID>`, a second defect on one section reads as
already handled.

- A resolved input is closed history. Never re-open it, re-verify it, or re-ground its section
  because of it. This includes a defect `code-issue` posted and resolved itself in one turn.
- Every unresolved input must be handled in this run.

## Handling a defect

1. Re-ground the named section against the current repo.
2. Rewrite the section so the instruction executes as written. The fix is decided here; where
   the decision is the user's, it is a question (Question rule).
3. Record the defect's `Class:` — `design-gap`, `mechanical` or `oversight`. **Verify** reads it.

## Handling feedback

For each item, do exactly one of:

| Outcome | Condition | Action |
|---|---|---|
| **absorb** | the ask belongs to the section named in the feedback marker, and the spec must honour it | re-ground and rewrite that section |
| **decline** | the spec must not honour it | record the reason |
| **decline, misplaced** | the ask belongs to another section | record where it belongs; the reviewer raises it on that section's PR |

- An item is never routed to another section.
  Why: a section with no open PR has no branch to land the change and no thread to close.
- An item is never dropped silently.
- A question or an ambiguity inside an item is a question (Question rule).

## The resolution comment

One comment per run, drafted by **Present** into `/tmp/improve-issue-<n>-resolution.md`, posted
by the store after the spec is stored. Defect block first, then one block per feedback comment,
blocks separated by one blank line. A kind with no input has no block.

```markdown
<!-- spec-defect-resolved 2481937461 -->
<!-- spec-defect-resolved 2481940022 -->
Spec revised <date>: SCH-1, PAR-2 re-grounded.

<!-- review-feedback-resolved 2481951103 -->
- item 1 → PAR-2: AC-3, AC-4 rewritten; step 6 rewritten
- item 2 → PAR-2: step 4 rewritten
- item 3 → declined: contradicts AC-1 — an association field keeps `html_type: :unimplemented` by design
```

Rules for a feedback block:

1. One line per item. Every item has a line.
   Why: an item with no line leaves the orchestrator halting on `SPEC_PENDING` indefinitely.
2. An absorbed item's line reads `- item k → <SEC-ID>: …`, with the colon directly after the id
   (`PAR-1:` never matches `PAR-10:`), and `<SEC-ID>` is the one in the feedback marker.
3. The line names every AC and every numbered implementation step the item changed. A change
   that touches a step and no AC still names the step.
   Why: these lines are `code-issue`'s amend work list; an unnamed step is never re-coded.
4. A declined item's line reads `- item k → declined: <reason>`.
