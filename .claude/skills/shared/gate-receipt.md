# Gate receipt contract

Single source of truth for the **gate receipt** — the token that lets a later
pipeline step skip a `mix consistency` / `mix test` run that an earlier step already
performed on byte-identical content. Referenced from the skills that emit or
honour it; never duplicated into them.

The receipt exists because `mix consistency` ends in `dialyzer` (~10 min on a first
run) and, on the clean path from code to PR, the gate used to run four times over
the same tree. It is an optimisation with a hard safety property: **it can only
ever skip work whose answer is already known.**

## The tree hash

The receipt is keyed on a **git tree-object hash of the working content**,
computed in a scratch index so the real index is never touched:

```bash
tree_hash() {
  local idx; idx=$(mktemp -u)
  GIT_INDEX_FILE="$idx" git read-tree HEAD >/dev/null 2>&1 &&
  GIT_INDEX_FILE="$idx" git add -A   >/dev/null 2>&1 &&
  GIT_INDEX_FILE="$idx" git write-tree
  local rc=$?
  rm -f "$idx"
  return $rc
}
```

`GIT_INDEX_FILE` must be set on **each** command — it is not inherited from a
bare assignment on `read-tree` alone. Always `rm -f` the temp index.

Two properties are load-bearing. Do not change this command in a way that breaks
either one:

1. **Content-only, and therefore commit-independent.** Committing does not change
   file bytes, so the hash of a dirty tree and the hash after those same edits are
   committed are **identical**. This is what lets one receipt span `review-issue`
   (which leaves the tree dirty) and `gate-commit` (which commits it). Verified:
   the hash of a clean tree equals `git rev-parse 'HEAD^{tree}'`.
2. **Exactly the content the gate reads.** `git add -A` in the scratch index
   honours `.gitignore`, so `_build/` and `deps/` churn does not move the hash,
   while any edit to a tracked file and any new untracked-non-ignored file does.

`mix consistency` and `mix test` are deterministic functions of that content, so on
a hash match a re-run is guaranteed to return the result already recorded. It
yields no new information. That — not "the previous step said it was fine" — is
the entire justification for skipping.

## The receipt line

`review-issue` emits it in its chat output, on a `✅ DONE` verdict and only
when **both** checks are green:

```
**Gate receipt:** tree `<full-40-char-sha>` — consistency ✓, test ✓
```

It is never persisted to the issue — `review-issue`'s persisted ground is the
review table and the completion phrase, nothing else. No retraction is needed:
honouring already requires a byte-equal `tree_hash` at the moment of use, so a
receipt for a tree that has moved on simply stops matching. The caller that
invokes the next step in the same session passes it forward as
`GATE_RECEIPT: <sha>`.

Record the **full** hash. Short forms are for display only.

## Honouring a receipt

A receipt is honoured **only** when the hash it names is byte-equal to
`tree_hash` computed at the moment of use. Anything else — no receipt, a
malformed one, a different hash — means **run the full gate**. There is no third
branch, and a near-miss is a miss.

| Carrier | Passed by → to | Means |
|---|---|---|
| `GATE_RECEIPT: <sha>` | `pr-from-issue` → `do-pr` → `gate` | a full `mix consistency` **and** `mix test` were green on `<sha>` |
| `CONSISTENCY_VERIFIED: <sha>` | `gate` → `gate-commit` | `consistency` alone was green on `<sha>`, in this same turn |
| `.test-receipt.json` | `review-issue` → `do-pr` and `gate` (on disk) | `mix test` (`suite` field) and/or `mix consistency` (`consistency` field) were green on `<sha>` |

The first two are lines in the invoking prompt, matching `escalation.md`'s
`NON_INTERACTIVE: true` convention. The third is a file, described below.

## The suite receipt

`mix test` is the single most expensive step in the pipeline that is **not**
part of `mix consistency` — the suite is several hundred DB-backed tests, and
`consistency` never runs it. `mix consistency` itself ends in `dialyzer` (~10 min on a first run), and
`review-issue` already runs both to completion in its Step 3. The suite receipt
records two independent facts on the same content: *the whole suite was green*
and *`mix consistency` was green.*

It is a gitignored file at the root of the working tree:

```json
{
  "tree": "<full-40-char-sha>",
  "suite": "green",
  "consistency": "green",
  "written_by": "review-issue",
  "issue": 822,
  "written_at": "2026-08-29T14:31:02Z"
}
```

Written **only** by a step that ran both `mix test` and `mix consistency` to
completion and saw them green, and only after every edit to the working tree is
finished — the same rule the prompt-line receipt already follows. Compute
`tree_hash` last; if you edit a file afterwards, recompute and rewrite, or
delete the file.

Never record `"suite": "red"` or `"consistency": "red"`. A receipt exists to let
a later step skip work whose answer is already known to be *green*; a red
result must be acted on where it was found, never carried forward as a token.
The two fields are written together — `review-issue`'s Step 3 gate runs both
commands, so there is no case where this skill knows one and not the other.

**Why a file, and why it needs no retraction.** The prompt-line receipt lives
only in one run's chat output. A file has no such owner — but it needs none,
because **the hash is the invalidation**. A stale receipt does not have to be
deleted; it simply stops matching the moment any tracked file changes. Nothing
has to remember to clean it up.

**What it buys that the prompt-line receipt does not.** It survives the
session: a spec revision by `improve-issue` edits the *issue*, never the repo,
so the tree is byte-identical afterwards and the suite result still holds —
but the chat line is gone. The file survives that, and `do-pr` can still skip
a suite it knows is green.

**Who may honour it.** `do-pr`, for the `suite` field, only on a `GATE_RECEIPT`
miss. `gate`, for the `consistency` field, only when its own Step 0 has no
matching prompt-line `GATE_RECEIPT`. Each skill reads only the field it owns —
`do-pr` never reasons about `consistency`; `gate` never reasons about `suite`.
`review-issue` must **never** read it, for exactly the reason it may not honour
a `GATE_RECEIPT` from `code-issue` — see the independent-verification boundary
below. `code-issue` never writes one: it no longer runs the full suite at all,
and its own `gate.sh` failures are fixed and re-run, never receipted.

## Forbidden

- **Comparing hash prefixes.** Compare the full 40 characters or not at all.
- **Inferring a receipt** from anything other than a literal receipt line: not
  from the completion phrase, not from `✅ No outstanding gaps.`, not from a
  date, not from a green verdict in the transcript.
- **Skipping a gate silently.** Every step that honours a receipt says so in its
  output, naming the short hash it matched. A skipped gate that leaves no trace
  is indistinguishable from a gate that was never wired up.
- **Writing a receipt for a gate you did not run to completion**, or one that was
  red, or one recorded before a later edit to the tree.
- **Recording a suite receipt for a suite you did not run to completion**, or
  one that was red, or one written before a later edit to the tree.
- **Honouring a suite receipt in `review-issue`.** It is the pipeline's only
  independent full-suite run; a reviewer that reads a receipt instead of running
  the suite has verified nothing. The same boundary as below.
- **Receipting across an independent-verification boundary.** Specifically:
  `review-issue` must **never** honour a receipt from `code-issue`. Its Step 1
  exists because "reviews based only on code inspection are unreliable; running
  the gate is the only way to know" — a reviewer that trusts the coder's claim of
  green is not verifying anything. The receipt is only ever valid between steps
  doing *bookkeeping* on an already-reviewed tree.
