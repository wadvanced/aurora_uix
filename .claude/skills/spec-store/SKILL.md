---
name: spec-store
description: >
  Store an issue's enriched spec (branch, pull request, merge) in its
  version-controlled spec file, or tick acceptance-criteria checkboxes inside the
  local working copy of it. Invoked as a sub-skill by `improve-issue` (whole-spec
  writes), `code-issue` and `review-issue` (checkbox ticks) — never directly by a
  user. It is the only place that writes a spec, and the only place that
  regenerates the issue body's Section Map mirror.
---

# Skill: spec-store

Persist the enriched spec for issue `<n>` to `specs/issue-<n>-enriched-spec.md`, and regenerate
the pointer plus Section Map mirror in the issue body.

**Nothing here ever writes to `main` directly.** aurora_uix's ruleset requires a pull request and
a green `Build and test (1.19.4-otp-28, 28.2)`. A spec is stored by branch → PR → merge, and it
is not stored until that PR has merged, because `spec-load` reads `main`.

Two modes, with different owners and different reach:

| Mode | Invoked by | Writes | Reaches `main` through |
|---|---|---|---|
| `write` | `improve-issue` (and `orchestrate-issue`'s approved branch) | the whole spec file, then the body mirror | its own spec PR, merged by `merge-pr` |
| `tick` | `code-issue`, `review-issue` (section mode) | AC checkbox characters inside one section, **in the current checkout** | the section's own code PR, committed by `gate-commit` |

Follows `../shared/turn-discipline.md`: one edit per file per turn, never
re-read a file this turn's write just changed, no narration-only turns.

## Arguments

```
spec-store <n> write <local-spec-file> [<resolution-file>]
spec-store <n> tick <SEC-ID> <AC-1,AC-3,AC-7>
```

## What this skill must never touch

The spec file and the body's `<!-- enriched-spec:start v2 -->` block, and
nothing else. The review table, the section log, `spec-defect` comments, the
`Issue is completed and ready to be closed.` phrase and every label stay with
their existing owners (`../README.md` § Marker blocks). A write here that
touched any of them would give two skills authority over one record.

---

## Mode `write`

A shell script cannot invoke a skill, and `merge-pr` is the single merge authority, so the merge
sits **between two invocations** of one script:

1. **Write phase.** Run in the background per `../shared/background-long-commands.md`
   (`run_in_background`, then foreground `.claude/scripts/wait-verdict.sh spec-<n>` — the checks
   wait alone can outlast one foreground call):

   ```bash
   .claude/scripts/spec-store-write.sh <n> <local-spec-file> [--resolution <resolution-file>]
   ```

   It reads the current file from `main`, runs the merged-section guard, creates the branch
   `spec/<n>-enriched-spec` from the `origin/main` tip, commits the file to it, opens a
   **non-draft** PR titled `docs(spec): enriched spec for issue #<n>`, and waits (bounded, about
   ten minutes) for the checks. If the PR is merely `BEHIND` it runs `gh pr update-branch` once.
   A docs-only PR runs the light CI path, so the wait is normally about a minute.

2. **Merge.** On `STATUS: OK-PR-READY <pr>`, invoke the `merge-pr` skill in direct mode:
   `merge-pr <pr>`. `merge-pr` recognises a spec PR by its fixed head, title and sole file, and
   needs no `approved` label for it; every other row still applies.

3. **Finish phase.** Only after `merge-pr` reports `STATUS: MERGED <url>` (or `ALREADY_MERGED`):

   ```bash
   .claude/scripts/spec-store-write.sh <n> --finish <pr> [--resolution <resolution-file>]
   ```

   It confirms the PR merged, refreshes local `main`, regenerates the issue-body mirror and posts
   the resolution comment, in that order, and ends `STATUS: OK <merge-commit-sha>`.

`--resolution <file>` names a comment `improve-issue` drafted before approval, posted once the
spec is stored (skipped when the file is absent or empty, or an identical comment is already on
the issue). The script also takes `--sha256 <hex>` on the write phase (refuse unless the file
hashes to the approved value); only the orchestrated path passes it.

**Only `STATUS: OK <sha>` means the spec is stored.** `STATUS: OK-PR-READY` is exit 0 too and is
not done: never continue to coding, and never regenerate the mirror or post the resolution
comment yourself, on it. When the file already equals `main`'s copy, the write phase repairs the
mirror and prints `STATUS: OK <sha>` directly; skip steps 2 and 3.

**Merged-section guard.** A section whose PR is merged is history: the spec it
records is what a shipped PR was built against. Altering or deleting it
destroys that record silently. The script compares each section's fenced content old vs new,
probes only the ones that differ, and on any merged hit halts with
`STATUS: BLOCKED — merged-section-modified`, writing nothing. The remedy is a
decision, not a workaround: revert the edit to that section, or take it to the
user as a deliberate amendment of shipped history. Never write over it.

**Concurrency.** The optimistic lock is GitHub's. If `main`'s copy of the file changed after the
write phase read it, the PR is `CONFLICTING`: the script closes it, deletes the branch and
returns `STATUS: BLOCKED — concurrent-write`. Re-run from a fresh `spec-load`; never resolve the
conflict by hand and never re-push over it.

**One open spec PR per issue.** A second write while one is open returns
`STATUS: BLOCKED — spec-pr-open <url>`. Merge or close that PR first (a human decision); never
stack a second.

**The file lands before the mirror, deliberately.** If the mirror write fails,
the spec is still stored and `--finish` can be re-run to repair the mirror. The reverse order
would leave a body advertising a spec that does not exist.

**Re-enrichment while sections are in flight.** A spec rewrite that merges while section branches
are open makes their local ticks conflict with it. Say so to the user when `improve-issue` stores
a re-enrichment and any Section Map row has an open PR or a live worktree; the orchestrator halts
on the resulting conflict instead of resolving it.

---

## Mode `tick`

Flip `- [ ] AC-k` → `- [x] AC-k` for the named ACs, inside the named section
only, **as a local edit of the working copy in the current checkout**: no API call, no branch, no
PR. The section is being coded or reviewed in its own worktree (work is handed between skills
uncommitted); the tick then travels to `main` inside that section's code PR, committed by the
normal `gate-commit` flow. Callers batch: one `tick` per section per skill, never one per AC.

```bash
WC="$(git rev-parse --show-toplevel)/specs/issue-<n>-enriched-spec.md"
CUR=/tmp/spec-store-<n>-<SEC-ID>-before.md
EDIT=/tmp/spec-store-<n>-<SEC-ID>-edit.md

[ -s "$WC" ] || { echo "STATUS: BLOCKED — spec-missing"; exit 1; }
cp "$WC" "$CUR"
cp "$WC" "$EDIT"

# edit "$EDIT": within the <SEC-ID> fence only, `- [ ] AC-k` → `- [x] AC-k`
# for each AC on the list

diff "$CUR" "$EDIT"   # expect ONLY checkbox flips, all inside the fence
```

Anything else in that diff — a line outside the named fence, a changed character other than the
`[ ]` → `[x]` flip — means the spec was touched: **stop and fix the copy before writing.** An AC id
that does not exist in the fence is `STATUS: BLOCKED — spec-tick-failed`. An AC already ticked is
left as it is. Only when the diff is clean, one write puts the edited copy back:

```bash
cp "$EDIT" "$WC"
```

Then `STATUS: OK ticked <k>` with `<k>` the number of boxes flipped. An empty AC list means **no
edit at all**.

- The working copy is the file `spec-load` overlays ticks from; there is no second copy to keep
  in step and no sha to carry.
- The mirror is not regenerated by `tick`: checkbox state lives in the file, and the mirror
  carries only the Section Map.
- `tick` never commits. The edit stays in the working tree until `gate-commit` commits it with
  the section's other changes.
- Closing-mode `review-issue` runs after every section merged, in the orchestrator's own checkout
  with no section branch, and does **not** tick: it reports unticked ACs and leaves them. A tick
  on a merged section would be a spec change the merged-section guard refuses.

---

## Return

One terminal `STATUS:` line.

| Status | Meaning |
|---|---|
| `STATUS: OK <sha>` | `write`: the spec PR merged, `main` refreshed, mirror regenerated, resolution comment posted (or the spec was identical; the mirror was repaired) |
| `STATUS: OK-PR-READY <pr>` | `write` phase 1 only, exit 0: PR open and green — **not stored**; invoke `merge-pr <pr>` then `--finish` |
| `STATUS: OK ticked <k>` | `tick`: `<k>` checkboxes flipped in the working copy; nothing committed |
| `STATUS: BLOCKED — merged-section-modified` | a changed section's PR is merged; nothing written |
| `STATUS: BLOCKED — concurrent-write` | `main`'s copy changed since it was read (spec PR `CONFLICTING`; closed, branch deleted); re-run from a fresh `spec-load` |
| `STATUS: BLOCKED — spec-pr-open <url>` | an open spec PR for this issue already exists; nothing written |
| `STATUS: BLOCKED — spec-pr-checks-failing <url>` | a check on the spec PR failed or was cancelled; PR left open |
| `STATUS: BLOCKED — spec-pr-checks-pending <url>` | checks did not finish inside the wait budget; PR left open — `merge-pr <pr>` then `--finish` once they do |
| `STATUS: BLOCKED — spec-merge-failed` | the PR was still `BEHIND` after the one `update-branch`, or `--finish` found it not merged; PR left open |
| `STATUS: BLOCKED — spec-missing` | `tick` found no spec file in the checkout |
| `STATUS: BLOCKED — spec-tick-failed` | `tick` was given an AC id or section fence that does not exist |
| `STATUS: BLOCKED — issue-unreadable` | spec merged, mirror (or resolution comment) not; re-run `--finish` to repair |
| `STATUS: BLOCKED — approved-spec-mismatch` | `--sha256` did not match the file; nothing written (orchestrated path only) |
| `STATUS: BLOCKED — spec-write-failed` | any other failure, or an unusable input; nothing written |

`merge-pr`'s own refusals during step 2 (`not-approved` for a PR that fails the spec-PR
recognition, `checks-failing`, `not-mergeable`, …) are relayed as that skill's terminal line; the
spec is then not stored.

## Forbidden

- Writing anything to `main` directly — no Contents API write aimed at `main`, no push to it.
- Writing the spec into the issue body. The body carries the mirror only.
- Writing from a file this run did not just build or just fetch.
- Merging the spec PR any other way than `merge-pr`.
- Continuing to coding on anything but `STATUS: OK <sha>`.
- Editing the spec file in `tick` outside the named section's fence, or ticking on a checkout
  whose branch is not the section's own.
- Any edit outside the spec file and the body's `enriched-spec` block.
- Being invoked by anything other than `improve-issue` / `orchestrate-issue` (`write`), or
  `code-issue` / `review-issue` in section mode (`tick`).
