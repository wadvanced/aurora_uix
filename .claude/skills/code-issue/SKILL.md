---
name: code-issue
description: >
  Implement ONE section of an enriched-spec-v2 GitHub issue in aurora_uix, an
  Elixir/Phoenix low-code UI generation library with Ash and Ecto backends. Use
  this skill when the user says "code issue <n>", "code issue <n> <SEC-ID>",
  "implement the section", "code this up", "start coding", "fix the gaps" or
  "address the review findings" on an issue that improve-issue has already
  sectioned — the gaps live in the section's review-table row, not in the issue
  body. Each run delivers exactly one section (Documentation / Schema / Parser /
  UI) on its own branch, ready for its own PR. Always write tests alongside
  implementation. Always run improve-issue first; always run review-issue after.
---

# Skill: code-issue

Implement exactly one section of the enriched spec (v2) that `improve-issue`
stored at `specs/issue-<n>-enriched-spec.md`. The spec is complete by contract — zero open
questions, zero optionality, every symbol grounded. This skill executes it;
it decides nothing.

## Non-negotiables

1. **Obey the spec literally.** The spec is read-only. The
   permitted edits are ticking AC checkboxes in the local working copy (Step 8) and applying a
   **`mechanical`**-class fix per the Step 3/6 defect triage — a correction
   whose one right value is directly readable at its definition site in the
   current repo (a renamed field, a wrong arity, a stale module path), never
   an inferred intent. Every such fix is logged via the self-resolved
   `spec-defect`/`spec-defect-resolved` pair (Step 3) before it is applied.
   Outside that narrow case: never correct an arity, fix an assertion sketch,
   rename anything, or add what seems missing.
2. **NEVER guess.** The spec promises zero required inference. If any step,
   name, shape, or decision is missing, ambiguous, contradicted by the repo,
   or phrased as discovery ("find out whether…", "or", "consider"), that is a
   **spec defect**. Applying a `mechanical` or `oversight` fix under the
   triage below is not a guess — it is reading a fact the repo (or an
   already-citable rule) determines uniquely, the same evidentiary bar
   Step 3's falsification checks already use, and it is always logged as
   such. Anything short of that bar — two plausible fixes, or an answer that
   requires interpreting intent — is `design-gap`: stop. Never substitute a
   default, never widen scope, never work around.
3. **Defect reports carry details only — never solutions.** A defect report
   states: the section and step, what the spec instructs (quoted verbatim),
   what the repo shows instead (file paths, command output), and why the
   instruction cannot be executed as written. It proposes no fix to the spec,
   no fix to the code, and no workaround. The report is raw material for
   analyzing and fixing `improve-issue` itself.
4. **One section per run, top to bottom.** Subsections in written order; steps
   one by one. Nothing outside the section's scope is touched.
5. **Context discipline.** Read only the Section Map, the target section
   block, and `### Out of Scope`. Never read sibling sections' bodies. Fetch
   a linked issue only when the target section cites it.
6. **Readiness is not yours to declare.** This skill never marks a section
   ready, done, or approved — that is `review-issue`'s job. Never add or
   remove the `approved` / `amends-required` labels.
7. **Every halt emits a terminal `STATUS: BLOCKED — <slug>` line**, whether or
   not the run looks orchestrated (`../shared/escalation.md`). Exit means
   exit: after the status line, write nothing and read nothing further. The
   **single exception that still halts** is a `design-gap` spec defect,
   which posts one defect comment **per `design-gap` row found** on the
   issue (Step 3's exhaustive sweep may surface more than one; Step 6's
   reactive mid-implementation check typically finds one) before the status
   line — preflight failures are routing errors, not spec defects, and still
   write nothing. The review-feedback gate in Step 1 is
   the same exception under another name: its writes are
   `address-pr-review`'s — the report, and the replies and resolves that
   skill posts on `REPLY_ONLY` / `OUTDATED` threads — and the halt that
   follows writes nothing more.

   A **second, non-halting exception**: a `mechanical` or `oversight` spec
   defect (Step 3/6 triage) posts its `spec-defect` comment *and* this
   skill's own `spec-defect-resolved` comment, applies the fix, and
   continues — no `STATUS: BLOCKED`. A single run may post several such
   pairs across its dry-run sweep and still finish `STATUS: OK`.
8. **Never write a spec or a body you did not just fetch.** The only spec edit is
   `spec-store <n> tick` (Step 8): a local edit of the working copy in this section's
   checkout, guarded by a checkbox-only diff, that travels to `main` inside this
   section's own PR. Never edit `specs/issue-<n>-enriched-spec.md` directly, and
   never write it to `main`. For the comments this skill
   does write, never append to or write back a scratch file from an earlier
   step or an earlier run: it may hold a different issue's content. Scratch
   paths are namespaced per skill, issue, and section for that reason —
   sections may run in parallel, and a shared `/tmp` name is a cross-issue
   write waiting to happen.
9. **Turn discipline.** Follow `../shared/turn-discipline.md`: batch
   independent tool calls, never poll a background job, one edit per file per
   turn, no narration-only turns.
10. **The project rules bind every line.** `aurora_uix` is a library, not an
    application, and works over two interchangeable backends. Every rule in
    § Project rules below — the backend abstraction boundary, the
    add / do-NOT-add decision for a new `%Field{}` type atom, `dt/1`, no inline
    `class`, both parsers, tests in `test/cases_live/` first — is re-read before
    each subsection. Obeying the spec literally never licenses breaking one:
    an instruction that would is a spec defect (`design-gap`), not an order.

**Gaps resume (review loop).** `review-issue` bounces a section back by
writing **AC failure notes** into its `<!-- review-table #<n> -->` row.
**Preflight row 8 is what detects this** — it is the only place the mode is
resolved, and it is why Step 0 lists the issue's comments.

A gaps resume then runs normally, with two differences: Step 4 reuses the
existing section branch rather than refusing it (recreating it when a revert
removed it), and the failure notes are the work list — each `AC-k: …` note is
completed through that AC's red-test row and implementation subsections, spec
obeyed literally as ever. Steps 7–8 run in full; the new section-log comment
supersedes the old.

Two guards outrank a table row that has gone stale: preflight row 5, where an
open or merged PR wins, and row 8's own staleness check, where a section log
newer than the table means the work is already done and awaiting review.

**Gaps resume (mid-implementation-defect variant).** A section halted by a
spec defect mid-implementation, kept rather than reverted (§ Mid-implementation
defect), has no `review-issue` failure note to resume from — nobody has
reviewed it yet. This skill's own `<!-- code-issue-gap #<n> <SEC-ID> -->`
comment stands in for one: preflight row 8 treats it exactly like a failure
note (its "Remaining work" line is the work list), so the run reuses the
branch instead of halting on `branch-exists`. It is self-clearing once the
section eventually posts a real section log.

**Amend resume (PR review loop).** A reviewer's feedback on the section's open
PR travels the same channel as a spec defect: `address-pr-review` reports it
on the issue, `improve-issue` rewrites the section — or declines an item on
the record — and posts a `<!-- review-feedback-resolved … -->` comment with
one line per item, and this skill implements what those lines name.
**Preflight row 8 detects this too**, through the amend signal defined there.
The section's PR stays open throughout — that is the expected state, not
`section-in-review` — and Step 4 reuses the branch. The work list is the
resolution lines, not the whole section: each names the ACs and numbered
steps it changed, and those are what get re-implemented, red test first for
every unticked AC. Step 8 then answers and resolves every captured thread.

## Step 0 — Preflight

Read-only, cheap, complete. Check **every** row before reporting any of them
— a preflight that stops at the first failure charges the user one round trip
per defect. Allowed costs: local `git` plumbing, one `gh issue view` per
issue involved (captured to a file, re-grepped from there), one comment
listing for `<n>`, `gh pr list`, and `grep`. Never `mix`, never a source
file, never a sub-skill.

**When the invoking prompt carries a `SECTION_STATE:` block** — only
`epic-orchestrator` ever emits one — skip the fetch below entirely: row 1
passes on the block's say-so, row 5 reads its `PR:` line instead of probing,
and row 8 reads its `Review-table row:` and `Newest section-log:` lines (its own
subsection below). Every row runs in full,
exactly as written below — including the fetch — on any invocation without
that block.

**Only when no `SECTION_STATE:` block was supplied:**

```bash
gh issue view <n> --json body --jq '.body' > /tmp/code-issue-<n>-body.md || {
  echo "⚠️ Could not read issue #<n>. Nothing was run."
  echo "STATUS: BLOCKED — preflight: issue-unreadable"; exit 1
}
[ -s /tmp/code-issue-<n>-body.md ] || {
  echo "⚠️ Issue #<n> returned an empty body. Refusing to guess."
  echo "STATUS: BLOCKED — preflight: issue-unreadable"; exit 1
}
gh api "repos/{owner}/{repo}/issues/<n>/comments" --paginate \
  --jq '.[] | {id, body, created_at, updated_at}' > /tmp/code-issue-<n>-comments.json
```

The comments carry the review table and the section logs — row 8 resolves the
run mode from them. `created_at` / `updated_at` come free in the same call and
row 8 needs both. With `SECTION_STATE:` present, neither file is written here
— row 8's own subsection below reads the block's fields instead, and Step 3's
amend-only thread work (the one later step that genuinely needs comment
bodies, not just their timestamps) fetches
`/tmp/code-issue-<n>-comments.json` itself, lazily, only on an amend-resume run.

1. **Issue readable.** The block above succeeded. **With `SECTION_STATE:`
   present, this row passes without a fetch** — `epic-orchestrator` read the
   issue this same pass to build the block. Slug: `issue-unreadable`.
2. **Enriched spec v2 present.**
   invoke `spec-load <n>`; a `STATUS: BLOCKED — spec-missing` fails this row.
   The spec is **not** in the body — it lives at
   `specs/issue-<n>-enriched-spec.md`, and `/tmp/spec-<n>.md` is what
   `spec-load` writes.
   On miss: `❌ Issue #<n> has no v2 enriched spec. Run /skill improve-issue <n> first.`
   Slug: `enriched-spec-v2-missing`.
3. **Section Map present.**
   `grep -qF '### Section Map' /tmp/spec-<n>.md`.
   Slug: `section-map-missing`.
4. **Target section resolves.**
   - `<SEC-ID>` given as an argument: it must appear as a Section Map row and
     as a `<!-- section:<SEC-ID>:start -->` fence — the same exact marker
     Step 2 extracts with, not a heading prefix. Slug: `section-unknown`.
   - No argument: auto-select the **first** Section Map row (map order is
     execution order) that is not delivered (row 5) and whose dependencies
     are all merged (row 6). If no row qualifies, report why each was skipped.
     Slug: `no-runnable-section`.
5. **Section not already delivered.** Branch names are deterministic and the
   Section Map row carries this section's. `--head` is an exact ref filter:
   ```bash
   gh pr list --head "<branch-from-Section-Map>" --state all \
     --json number,state --jq '.[] | "\(.state) #\(.number)"'
   ```
   **With `SECTION_STATE:` present**, skip the probe: read its `PR:` line instead
   (`<state> #<num>` or `none`) — it names the same branch's PR.

   A `MERGED` hit → the section is done (`section-delivered`). An `OPEN` hit →
   it is in review (`section-in-review`) — a failure **unless** one of two
   holds: the section carries the **amend signal** (row 8), so the open PR is
   exactly where an amend lands and the run proceeds; or the PR carries
   `amends-required` (`gh pr list --head "<branch>" --state open --json
   labels`, or `SECTION_STATE:`'s `PR:` line when present — it already names
   the labels), so Step 1's gate has to look before anyone can say there is
   nothing to code. Label with no signal is a **label-only** pass: preflight
   succeeds so the gate can run, and the run halts there whichever way the
   gate goes.

   **Never probe with `gh pr list --search "… in:title"`.** GitHub's search is
   a stemmed token AND, not a literal match: `(#905 · SCH-1) in:title` drops the
   punctuation and matches any title carrying both `905` and a term stemming to
   `SCH-1` — `SCH-10` and `SCH-11` included. On an issue with ten schema
   sections that reports `SCH-1` as delivered when it is not. Verified against
   this repo; `--head` has no such semantics, and a prefix of a branch name
   matches nothing.
6. **Dependencies merged.** From the target section's `Depends on:` line, each
   dependency resolves to a branch name and gets the same `--head` probe, which
   must show a `MERGED` PR:
   - a sibling id (`SCH-1`, `PAR-2`, …) → its branch is in this issue's Section
     Map;
   - a cross-issue dep (`#<m>·<SEC-ID>`) → one `gh issue view <m>` for that
     issue's Section Map row, then the same probe against its branch;
   - `none` → N/A.
   Any unmerged dependency: `❌ Section <SEC-ID> depends on <dep>, which has no
   merged PR.` Slug: `dependency-unmerged`.
7. **Complexity level resolves.** Read `**Complexity:**` from
   `/tmp/spec-<n>.md` and resolve the coder model by the precedence in
   `../shared/coder-model.md`. A positional argument is a **one-off override** —
   announced, never written back to the issue. An unrecognised value fails
   (`unknown-level`); a v2 spec with **no** `**Complexity:**` line predates this
   contract and fails too (`complexity-missing`) — re-run `improve-issue` rather
   than assuming `normal`, which would silently downgrade a `max` issue.
8. **Run mode resolves.** From `/tmp/code-issue-<n>-comments.json`, take the
   `<!-- review-table #<n> -->` comment and read the `STATE` cell of the target
   section's row. **First match wins:**

   | Table state for the target | Verdict |
   |---|---|
   | any state, amend-signal clause 1 holds, and row 5 found no `OPEN` PR | halt `resolution-misrouted` — a resolution line names a section whose PR did not raise the item (`shared/improve-issue/comment-protocol.md` § Handling feedback forbids it); never code it |
   | any state, and amend-signal clause 1 holds | **amend resume** — proceed; the resolution lines are the work list |
   | any state, the open PR carries `amends-required`, and neither amend-signal clause holds | **label-only** — proceed to Step 1's gate, and no further |
   | no table, no row for it, or `PENDING`, and a `<!-- code-issue-gap #<n> <SEC-ID> -->` comment for this section is newer than the newest `<!-- section-log #<n> <SEC-ID> -->` for it (or no section-log exists) | **gaps resume** — proceed; the gap comment's "Remaining work" line is the work list |
   | no table, no row for it, or `PENDING` | **fresh run** — proceed |
   | failure notes, and the newest `<!-- section-log #<n> <SEC-ID> -->` comment's `created_at` is later than the table comment's `updated_at` | halt `section-awaiting-review` |
   | failure notes | **gaps resume** — proceed; the notes are the work list |
   | `COMPLETED` | halt `section-reviewed` |

   **Amend signal** — what lets row 5 accept an open PR. Either clause:

   1. The newest comment whose body starts with `<!-- review-feedback-resolved`
      and contains a line `- item <k> → <SEC-ID>:` (the colon is the
      delimiter — `PAR-1:` never matches `PAR-10:`) has a `created_at` later
      than the newest `<!-- section-log #<n> <SEC-ID> -->` comment's. The
      spec was rewritten after the section was last coded. This clause is
      **amend resume**. It is read only against an `OPEN` PR: an item is
      resolved into the section whose PR raised it, so a section with no
      open PR can carry no resolution line — one that does is misrouted, and
      row 8 halts on it rather than inventing a branch for it.
   2. The review table holds failure notes for this section and its
      `updated_at` is later than that newest section-log. The amend was
      reviewed and bounced. This clause is an ordinary **gaps resume** that
      happens to land on an open PR.

   Both read from `/tmp/code-issue-<n>-comments.json`; neither reads a label.
   The label only decides whether Step 1 looks for new feedback — and, when
   neither clause holds, whether preflight passes at all (**label-only**).

   *Failure notes* means any state that is neither `COMPLETED` nor `PENDING`
   (`AC-k: …` / `Gate: …`, `<br>`-separated).

   *Code-issue-gap comment* is this skill's own marker, posted for one of two
   reasons: a run halted by a spec defect mid-implementation whose human chose
   **keep** over revert (§ Mid-implementation defect), or a run that exhausted
   its test budget and wrote a checkpoint (§ Checkpoint). Both clear the same
   way, below. It exists because the review
   table cannot yet carry a failure note for a section `review-issue` has
   never seen — without this row, a kept branch would halt every subsequent
   run on `branch-exists` (Step 4) forever, since the table keeps reading
   `PENDING`. The newer-than-the-latest-section-log check is what makes it
   self-clearing: once the section eventually finishes cleanly and posts a
   fresh section log, that log is newer than the gap comment and this row
   stops matching — no explicit "resolved" comment needed, the same technique
   `section-awaiting-review` below already uses.

   `section-awaiting-review` means this section was coded **after** the last
   review — the table is stale, not a work list. Re-running would repeat the
   red/green loop and post a second section log for work already done:
   `❌ Section <SEC-ID> was coded after the last review. 👉 Next: review-issue <n> <SEC-ID>`.

   `section-reviewed` means the section passed review and is waiting to ship.
   Row 5 only sees PRs, so without this row a reviewed-but-unshipped section
   would be silently re-coded:
   `❌ Section <SEC-ID> is reviewed and awaiting its PR. 👉 Next: pr-from-issue <n> <SEC-ID>`.

   Branch presence is **not** checked here — Step 4 handles every combination,
   including a gaps resume whose branch was reverted away.

   **With `SECTION_STATE:` present**, resolve this row from the block instead
   of fetching comments — `epic-orchestrator` only spawns `code-issue` after
   making exactly this determination itself (`epic-orchestrator.md` Classify
   classes `gaps`/`fresh`, `shared/orchestrator/amend-routing.md` rows a/c). Check `PR:` before `Review-table row:`, same
   priority as the native table above (an open, labelled PR always outranks
   what the review table says):

   | `PR:` | `Review-table row:` | Verdict |
   |---|---|---|
   | a `Checkpoint:` line is present | anything | **gaps resume** — the work list is that comment's body, fetched by id with `gh api "repos/{owner}/{repo}/issues/comments/<id>" --jq .body` (the one fetch this mode needs), read together with the failure notes in `Review-table row:` when that row carries any |
   | `OPEN` with `amends-required` | anything but `COMPLETED` | **amend resume** — proceed to Step 3, which itself finds nothing to reply to if this spawn turns out to be an orchestrator amend row 'c' (failure notes, no qualifying resolved comment) rather than row 'a'; either way `Review-table row:`'s failure-note lines, if present, still serve as Step 2's work list |
   | `OPEN` with `amends-required` | `COMPLETED` | **amend resume** — only reachable via amend row 'a'; Step 3 fetches the resolution lines |
   | `none` or `OPEN` (no `amends-required`) | `COMPLETED` | halt `section-reviewed` |
   | `none` or `OPEN` (no `amends-required`) | failure notes | **gaps resume** — the failure-note lines in `Review-table row:` are the work list |
   | `none` | `PENDING` / no row / no table | **fresh run** |

   The two halts the native table carries — `resolution-misrouted` (an amend
   signal fired with no open PR) and `section-awaiting-review` (the
   section-log is newer than the table) — cannot reach an orchestrated spawn:
   the same `PR:` and table facts this row would otherwise re-derive are what
   `epic-orchestrator` read to route here, and its own Classify class `gaps` already
   excludes the `section-awaiting-review` case before it ever spawns for
   "gaps to fix".

**On any failure**, emit the full table — passing rows included, each with
its evidence (`N/A` needs a reason; "did not look" is not one) — then the
status line, then stop:

```
### ❌ Preflight failed — issue #<n> · <SEC-ID>

| Precondition | Verdict | Evidence | Fix |
|---|---|---|---|
| Enriched spec v2 present | ✅ pass | marker found | — |
| Dependencies merged | ❌ fail | PAR-2 has no merged PR | run code-issue <n> PAR-2 first |
| ... every row ... | | | |

STATUS: BLOCKED — preflight: <slug>[, <slug>]
```

**Exit means exit.** After the status line, write nothing — no issue body,
no comment, no label, no file — and read nothing further.

On success, emit one line and continue in the same turn:

```
Level: <level> (<source>) · Coder: <model+effort>
Preflight: 8/8 preconditions pass — target section <SEC-ID> (<fresh run | gaps resume: <k> AC notes | gaps resume: partial work kept | amend resume: <k> items | label-only>).
```

## Step 1 — Review-feedback gate

Skip this step unless preflight row 5 found an `OPEN` PR for this section. When it did, and `gh pr list --head "<branch>" --state open --json labels` shows
`amends-required` among its labels, invoke the `address-pr-review` skill with
`<n> <SEC-ID>` before anything else and branch on its status:

- `STATUS: FEEDBACK_CAPTURED <count>` → stop. The reviewer's asks are now a
  report on the issue that `improve-issue` must absorb before any code is
  written against them. Emit `STATUS: BLOCKED — review-feedback` and nothing
  else — the report was that skill's one write, not this one's.
- `STATUS: BLOCKED — <slug>` → stop and propagate the line.
- `STATUS: NO_NEW_FEEDBACK` → every unresolved thread was answered there or
  is already in a report. **Amend or gaps resume** → continue in the same
  turn; that report's resolution lines are this run's work list.
  **Label-only** → halt `STATUS: BLOCKED — section-in-review`: the label is
  on, but nothing on the PR is waiting for code from this run.

This is why a manual `code-issue` run cannot skip the capture an orchestrated
one performs. The label only decides whether to look; `address-pr-review`
alone decides what it finds.

## Step 2 — Extract the section (mechanical)

Extract the section **to its own file** by its fence, then read that file.
Substitute the literal `<SEC-ID>`; the single quotes keep the shell away from
the `!` in the marker:

```bash
spec-load <n> <SEC-ID>     # writes /tmp/spec-<n>-<SEC-ID>.md
```

The instructions in that file are `main`'s; its AC checkboxes are `main`'s unioned with the
ticks already in this checkout's working copy of the spec (`spec-load` § Two sources, one rule).
A `NOTICE: spec-drift` line means the spec was rewritten after this branch was cut: code against
the file as extracted, mention the notice in the summary, and let the orchestrator's
`gh pr update-branch` surface the conflict.

An **empty** result means the spec has no fence for this section — it predates
the fence contract. Halt: `STATUS: BLOCKED — section-fence-missing`, re-run
`improve-issue`. Never fall back to a heading- or `---`-bounded guess: a
heading bound prefix-matches `SCH-1` against `SCH-10`, and a `---` bound runs
into whatever follows.

Then keep in working memory:

1. The target section's **Section Map row** — branch name and PR title.
2. `/tmp/spec-<n>-<SEC-ID>.md` — the whole instruction set for the run.
3. `### Out of Scope` — the boundary you must not cross.

**Read the section file, never the whole spec.** `/tmp/spec-<n>.md` exists for
`grep`/`awk` on the map and the level only; reading it wholesale pulls every
sibling section into context, which is what non-negotiable 5 forbids and what
the fence exists to make avoidable.

## Step 3 — Dry-run (read-only implementability gate)

This gate answers two questions, in order. First: **do the spec's facts hold
against the repo?** Second: **can I fully understand the spec?** — a spec can
be factually perfect and still demand interpretation this skill is forbidden
to supply.

**Part 1 — falsification.** Before creating a branch or writing a single
line, walk the entire section and prove it can be implemented exactly as
written. **Check every item before reporting any of them** — a dry-run that
stops at the first failure charges the user (and `improve-issue`) one round
trip per defect, the same reasoning Step 0's preflight already applies.

Build one **inventory table** first, enumerating every checkable item across
the *whole* section — never just up to the first problem found — one row
each for:

- every `existing` symbol cited (function+arity, action, `define`, component
  attr, selector/`data-*` attr, DSL option, route, doc `§` anchor),
- every `new` symbol the section introduces,
- every red-test row's placement target,
- every prescribed documentation edit (`DOC-1`: each `#####` file block, the CHANGELOG entry),
- every migration and snapshot the section references,
- for a new `%Field{}` type atom: every row of the section's `##### Type-atom audit` — re-run its
  sibling-atom `rg` and confirm every hit has a row.

Then verify each row independently against the repo and record a pass/fail
verdict — a fail on one row never skips the rows after it:

- **`existing` row:** open where the symbol is defined and confirm it
  matches the spec's citation. Fail slug: `stale-grounding` if the citation
  itself no longer matches (see below), otherwise the fact goes to triage.
- **`new` row:** re-run the spec's own recorded search terms; a hit is
  **stale grounding** — the world moved under the spec (slug
  `stale-grounding`). Never substitute the existing symbol for the
  prescribed new one — that is a coding-time judgment, i.e. a guess.
- **Red-test placement row:** `amend` — the named test exists in the named
  file; `add to` — the file exists; `new file` — the file does not exist.
- **Documentation row:** for `DOC-1`, the text each `#####` block says to
  change is present, verbatim, in the current doc, and the CHANGELOG section it
  inserts under exists. Other sections prescribe none.
- **Every row, additionally:** the instruction must be executable with zero
  inference — no "or", no "consider", no discovery, no missing param shape,
  no unlisted caller on a contract change — and free of internal
  contradiction — a row whose assertion sketch disagrees with the named
  source it instructs to copy from (or any two spec statements that disagree
  with each other) fails (slug `internal-contradiction`) — a copy-instruction
  never silently overrides its own sketch.

Emit the completed inventory table in chat — it is the exhaustiveness proof,
same role as Part 2's execution checklist. Only once every row has a verdict
does triage run over the failing ones.

**Triage** — classify every failing row into exactly one of:

- **`mechanical`** — the one correct value is directly readable at its
  definition site in the current repo (a renamed field, a wrong arity, a
  wrong module path/alias, a stale symbol name). No interpretation of
  intent required.
- **`oversight`** — the spec is silent on a case, but an existing, citable
  rule already determines the answer without inference: a documented
  AGENTS.md convention, a house convention (`../shared/house-conventions.md`), an
  existing pattern already used in the same module, or an existing `%Field{}` rule. The citation is mandatory in
  the log entry — "seemed reasonable" is not a citation and disqualifies the
  row from this class.
- **`design-gap`** — everything else: genuinely plausible alternative fixes,
  an approach that conflicts with an architectural rule (the backend abstraction
  boundary, transport-only writes, both-backends parity in AGENTS.md), or a comprehension failure (Part
  2, slug `not-understandable`). Always bounces.

**Process every failing row before emitting any status line — a `design-gap`
row is never, by itself, a stopping point.** Walk the failing rows in table
order; for each one, apply its fix (if `mechanical`/`oversight`) or collect
its report (if `design-gap`), then move to the next row. Never emit
`STATUS: BLOCKED` on the first `design-gap` row encountered — that charges
the user one round trip per defect, exactly what the inventory-first
ordering above exists to prevent. Only after the last row has been fixed or
reported does this gate close, per the two outcomes below.

For each failing row, post the details-only report (non-negotiable 3) as an
issue comment, with a mandatory `Class:` line, so `improve-issue` can ingest
whatever is still unresolved:

```bash
gh issue comment <n> --body-file <the report below>
```

```
<!-- spec-defect #<n> <SEC-ID> -->
### 🛑 Spec defect — issue #<n> · <SEC-ID>

- **Where:** <subsection / step / red-test row>
- **Class:** mechanical|oversight|design-gap
- **Spec says:** "<verbatim quote>"
- **Repo shows:** <file:anchor / command + output>
- **Why it cannot be executed as written:** <one or two sentences of fact>
```

Then branch on that row's class and continue to the next row — neither
branch emits a status line by itself:

- **`mechanical` / `oversight`** — apply the fix (non-negotiable 1), then
  immediately post this skill's own resolution comment for the `spec-defect`
  comment just posted:

  ```markdown
  <!-- spec-defect-resolved <id-of-the-comment-just-posted> -->
  ### ✅ Spec defect self-resolved — issue #<n> · <SEC-ID>

  - **Class:** mechanical|oversight
  - **Fix applied:** <one or two sentences, the fact-based correction>
  - **Cited by:** <definition site / AGENTS.md rule / existing pattern this fix is grounded in>
  ```

  No `STATUS: BLOCKED`, no user prompt — continue to the next row in the
  same turn regardless of how many `design-gap` rows have already been
  collected below.

- **`design-gap`** — no code was written for this row, nothing needs
  reverting. The report just posted **is** the record; keep its id for
  independent resolution and continue to the next row without emitting
  anything further here.

**Closing the gate**, once every failing row has a fix or a posted report:

- **No `design-gap` rows** — every failure was `mechanical`/`oversight` and
  self-resolved. Continue straight into Part 2 in the same turn; a single
  dry-run may have posted several self-resolved pairs along the way.
- **One or more `design-gap` rows** — emit every such report in chat (all of
  them, not just the last), then exactly one closing status line naming
  every collected slug:

  ```
  STATUS: BLOCKED — spec-defect: <slug>[, <slug>...]
  ```

  The marker line on each comment is mandatory — `improve-issue` greps for
  it. Each comment is a permitted write on a halt (non-negotiable 7);
  `improve-issue` should not learn about them one round trip at a time. After
  the last comment and the status line, nothing else.

**Part 2 — comprehension walk.** With the facts proven, restate the section
as a compact **execution checklist**: one line per numbered implementation
step and per red-test row, in your own words, each answering — which file I
open, what exact change I make, what I run, what outcome I expect. Producing
the line from the spec text alone, with zero inference, is the proof of
understanding; a step you cannot restate that way IS the failure, whatever
Part 1 said. Report it with the same details-only protocol, slug
`not-understandable`, with one strict addition: quote the instruction and
state **what cannot be determined** — never propose an intended meaning
(that would be a guess).

This gate is what makes re-runs safe: after `improve-issue` rewrites the
spec, invoking code-issue again starts from a clean tree because defects are
caught before any code exists.

On success, emit `Dry-run: section implementable — understood.` followed by
the execution checklist, and continue in the same turn. The checklist is the
work order Step 6 executes.

## Step 4 — Branch

```bash
git fetch origin
```

The branch name comes verbatim from the Section Map — never invented. What
happens next depends on the run mode from preflight row 8 and on whether the
branch exists locally or on origin:

| Mode | Branch exists | Action |
|---|---|---|
| fresh run | no | `git checkout -b <branch> origin/main` |
| fresh run | yes | halt `STATUS: BLOCKED — branch-exists` |
| gaps resume | yes | `git checkout <branch>` |
| gaps resume | no | `git checkout -b <branch> origin/main` |
| amend resume | yes | `git checkout <branch>` |
| amend resume | no | halt `STATUS: BLOCKED — branch-missing` |

**fresh run + branch exists** is leftover state from a previous run — a
human's to resolve, not this skill's to reuse or delete.

**gaps resume + branch exists** is the ordinary review loop: the prior work is
the point, and the failure notes say what is still missing.

**gaps resume + no branch** is reached legitimately. Step 6's
mid-implementation defect offers *revert*, which deletes the branch to restore
the clean-tree guarantee; the review table still carries the notes afterwards.
Recreate the branch from `origin/main` and keep the notes as the work list —
nothing is lost, because the spec and the notes both live on the issue.

**amend resume + no branch** is corruption, not a revert: an open PR points at
that branch. It is a human's to explain, never this skill's to recreate under
a PR that would then show a diff against nothing.

## Step 5 — Documentation is DOC-1's work

Every documentation edit an issue owes, and its CHANGELOG entry, lives in one section. What this
step does depends on which section this run targets:

| Target | Action |
|---|---|
| `DOC-1` | Its `#### Implementation details` **are** the doc edits, one `#####` block per file. Apply them verbatim — that is the whole of this section's work. No Red/Green loop follows. The CHANGELOG entry goes under the current unreleased version with **no issue-link suffix** (house convention H-4); prescribed text that carries one is an `oversight` defect citing H-4 — strip the suffix, log the pair. |
| Any other section | Nothing to apply. Editing `CHANGELOG.md`, `README.md` or a file under `guides/` is out of scope: a documentation change this section turns out to need is a spec defect (Step 6), never a drive-by edit. `@moduledoc` / `@doc` text on the modules this section edits **is** its own work — `doctor` gates it. |

`DOC-1` merges before any code section starts, so a code section reads the
documentation as already correct.

The dry-run already proved `DOC-1`'s edits apply. If one no longer does, the
doc changed under the run — treat it as a mid-implementation defect (Step 6).

## Step 6 — Implement, subsection by subsection

Follow `#### Implementation details` in written order — the v2 templates fix
it as the TDD order: acceptance criteria → test ports → red tests →
implementation subsections → green tests. `§ Project rules` below applies to every
subsection.

**Test budget.** Under `NON_INTERACTIVE: true`, run
`.claude/scripts/section-test.sh --reset` once, before the first test of this
step, and run **every** targeted test of this step through
`.claude/scripts/section-test.sh <file>[:<line>]` instead of bare `mix test`.
The script counts the runs and prints `BUDGET: <k>/<budget>` as its second-to-last
line; on `BUDGET: EXHAUSTED` follow § Checkpoint. A human-run `code-issue` may
use either — the budget applies only when the script is used.

### Red → Green → Refactor (per red-test row)

For each row of the `##### Red tests` table, in order:

1. **Red.** Honor the row exactly: `Placement` (`amend` the named test /
   `add to` the named file / `new file`), `Setup` (fixtures, factory calls,
   actor, mount path), test file, test name, assertion sketch, and the
   assertion API the row's mount type dictates. Run it in isolation:
   ```bash
   .claude/scripts/section-test.sh <file>:<line> 2>&1 | tee /tmp/code-issue-<n>-<SEC-ID>-red.log
   ```
   The failure must be genuine: `UndefinedFunctionError`, `CompileError`
   (module/function not yet defined), `KeyError`/`MatchError` on a field the
   implementation will introduce, or an `assert` mismatch where the LHS is
   the port's actual return. A syntax or setup error is **not** a valid red —
   fix the test and re-run. Record the row's red evidence (file:line + one
   failure excerpt) for the section log.
2. **Green.** Write the smallest implementation that satisfies the spec's
   declared shapes exactly — no extra return fields, no over-engineering.
   Re-run the targeted test to green; record the evidence.
3. **Refactor** only while green; re-run the targeted test after each step.
4. `mix format` to keep the diff clean. Defer `mix credo --strict` and `mix dialyzer` to
   Step 7 — a per-AC dialyzer run would dominate the runtime.

Test names describe observable behavior — never the issue, an AC id, or a
section id, in names, `describe` labels, or comments. The AC↔test mapping
lives in the section log only.

### Sections with an empty red-tests table

Documentation sections, and any section whose ACs all carry a
`(visual|mechanical|manual — no red test; verified by …)` marker, have no
Red/Green loop. Follow the section's numbered implementation subsections
(the per-file doc blocks, Schemas, Parser changes, Modules & components, …) in order.
A `mechanical` AC runs its own stated check (e.g. the AC's grep) and records
the output for the section log.

### Mid-implementation defect (rare — the dry-run should have caught it)

If reality still diverges from the spec while coding — a name that does not
resolve, an unlisted caller breaking on a contract change, a missing shape,
an internal contradiction surfacing only at run time — run the **same
triage as Step 3** (`mechanical` / `oversight` / `design-gap`) before
deciding what to do.

**`mechanical` / `oversight`** — apply the fix, post the `spec-defect` +
`spec-defect-resolved` pair exactly as in Step 3, and keep implementing the
section. No halt, no revert question — the same non-halting exception
(non-negotiable 7) applies mid-implementation as it does during dry-run.

**`design-gap`** — stop immediately. Do not finish the rest of the section:
partial work on a defective spec is rework. Post and emit the details-only
defect report exactly as in Step 3
(same `<!-- spec-defect #<n> <SEC-ID> -->` comment, same status line), and
additionally **ask the user whether the partial work on the branch should be
reverted**:

- **revert** — delete the branch; the clean-tree reentrancy guarantee is
  restored and the re-run after the spec fix starts fresh;
- **keep** — the branch stays. Post one comment, this skill's own marker, so
  the next run resolves as **gaps resume** (Step 8) instead of re-halting on
  `branch-exists` (Step 4): no review cycle ever ran on this section, so the
  review table still shows `PENDING` and has no failure note to resume from.

  ```markdown
  <!-- code-issue-gap #<n> <SEC-ID> -->
  ### 🔧 Partial work kept — issue #<n> · <SEC-ID>

  Branch `<branch>` carries partial work from a run halted by the
  `<!-- spec-defect #<n> <SEC-ID> -->` comment above. Kept per explicit user
  decision rather than reverted.

  **Remaining work:** <one-line summary of what the defect blocks, and what
  is already done and must not be redone>
  ```

Never decide alone. In a non-interactive spawn, report the defect and the
revert question verbatim, leave the branch untouched **and post no marker
comment** — the keep/revert decision has not been made, so a later run must
still ask — and end with `STATUS: BLOCKED — spec-defect: <slug>`.

### Checkpoint

On a `BUDGET: EXHAUSTED` line from `section-test.sh` (§ Test budget), finish the
current edit, run nothing more, and:

1. leave all work **uncommitted** in the worktree;
2. tick nothing, post no section log;
3. post one comment —

   ```markdown
   <!-- code-issue-gap #<n> <SEC-ID> -->
   ### ⏸ Checkpoint — issue #<n> · <SEC-ID>

   **Done:** <AC ids green, files written>
   **Failing now:** <test file:line — one-line failure>
   **Ruled out:** <what was tried and did not work, one line each>
   **Remaining work:** <what the next spawn does first, and what it must not redo>
   ```

4. end with `STATUS: CHECKPOINT`.

The orchestrator re-spawns `code-issue` on the same worktree; the next spawn
resolves as **gaps resume** (Step 0 row 8) and reads this comment as its work list.

### Rules beyond AGENTS.md

Everything in AGENTS.md applies; `§ Project rules` below restates the ones this skill enforces
while coding. Additionally:

- **Never run `mix gettext.extract` / `gettext.merge`** to "finish" a string: user-visible strings
  go through `dt/1`; extraction into `priv/gettext/*.pot` is not this section's work and rewrites
  files across worktrees.
- **Seed test data through `test/support/helper.ex`** (`create_sample_products/2`,
  `delete_all_inventory_data/0`, …) and the guide schemas — never hand-rolled structs, never mocks.
- The spec-is-read-only rule (non-negotiable 1) extends to the section log
  and every marker block: this skill writes only what Step 8 lists.

## Step 7 — Section quality gate

1. When the section adds an `auix-*` rule to `templates/basic/themes/base.ex`, run
   `mix auix.gen.stylesheet` and `mix auix.gen.tailwind_classes`, and keep whichever regenerated
   file `git status` shows as tracked. A Schema section runs `mix ecto.migrate` first: `mix test`
   does not run migrations.
2. `mix format` — no diff remains.
3. **Targeted tests only:** run every test file named in the section's
   red-tests table, plus any other test file this run touched:
   ```bash
   .claude/scripts/section-test.sh <each such file>
   ```
   Under `NON_INTERACTIVE: true` this run, and every re-run after a fix, goes
   through `section-test.sh` like Step 6's (§ Test budget) — a debugging loop
   that starts here is counted too, and `BUDGET: EXHAUSTED` means § Checkpoint.
   A human-run `code-issue` may use bare `mix test`.
   Do **not** run the full suite. The section's green-tests row "`mix test` —
   full suite green" is `review-issue`'s to run: it executes the suite
   immediately after this skill and may not trust any receipt from it, so a
   full run here is the same ~1,700 tests twice for one answer.
4. **Mechanical fixes, direct and targeted — not a `gate.sh` loop.** Settle
   formatting and credo issues on this run's touched files directly: `mix
   format`, then `mix credo --strict <each touched file>` (never a bare `mix
   credo --strict`, which re-checks the whole codebase for a change scoped to
   a handful of files). Only once this settles, run
   `.claude/scripts/gate.sh` as the section's **one** authoritative check, per
   `../shared/background-long-commands.md` (`run_in_background`, then one
   foreground `.claude/scripts/wait-verdict.sh gate`) — fix whatever it reports
   (dialyzer specs, `doctor` doc-coverage warnings, anything the targeted pass above missed)
   and do not hand off red. (`gate.sh` may instead print
   `SKIPPED: docs/spec-only changes` and exit 0 for a documentation-only section — that is
   not a broken run, it means there was nothing to check.) If it turns up
   something new, fix it — directly
   by file when it's format/credo, otherwise per its own report — and run
   `gate.sh` again (same backgrounding); that is the exception, not the loop,
   since the targeted pass above exists precisely to make this the only time
   it runs. A failure that needs design judgment to fix is a defect to report
   (Step 6's protocol), never something to improvise around.
5. Self-check — every box ticked before Step 8; an unticked box is blocking:

```
- [ ] Every red-test row has red AND green evidence (or the section's table is empty)
- [ ] Every AC in the section is implemented
- [ ] DOC-1: every prescribed edit applied verbatim, the CHANGELOG entry carries no issue
      link. Any other section: no documentation file (`CHANGELOG.md`, `README.md`,
      `guides/`) touched
- [ ] Backend boundary intact: no `Ecto.Association.*` / `Ecto.Embedded` outside
      `integration/ctx/`, no `Ash.Resource.*` outside `integration/ash/`
- [ ] New `%Field{}` type atom: every row of the type-atom audit acted on as its verdict says
- [ ] Both backends covered by tests where the section touches a parser, or the spec's stated
      reason honoured
- [ ] Every new `test/cases_live/` route registered in `test/support/app_web/routes.ex`
- [ ] No inline `class=`; new `auix-*` rules in `themes/base.ex` with the stylesheet regenerated;
      every user-visible string through `dt/1`
- [ ] No file outside the section's scope was touched; Out of Scope respected
- [ ] Targeted `mix test` green for every file above; `gate.sh` (`mix consistency`) clean
- [ ] Zero guesses made — every decision taken is either written in the spec
      or logged as a self-resolved `mechanical`/`oversight` defect
```

## Step 8 — Write back and report

1. **Tick AC checkboxes** — every AC implemented in this run, including
   visual/mechanical/manual ones (their verification is `review-issue`'s and
   the human's). This is the only edit ever made to the spec, and it is **local**:

   Invoke `spec-store <n> tick <SEC-ID> <AC-1,AC-4,…>` — one call carrying
   **every** AC ticked in this run, never one call per AC. `spec-store` edits a copy of this
   checkout's `specs/issue-<n>-enriched-spec.md`, flips only those checkbox characters inside
   that section's fence, runs the "diff shows only checkbox flips" guard, and writes the copy
   back. There is no API call, no PR and no `main` write: the tick stays in the working tree,
   uncommitted like the rest of this run's work, and `gate-commit` commits it with the section
   so it reaches `main` inside this section's own PR. An empty AC list means no call at all.

   Branch on its terminal `STATUS:` line: `STATUS: OK ticked <k>` continues;
   `STATUS: BLOCKED — spec-missing` (no spec file in this checkout) or
   `spec-tick-failed` (an AC id or fence that does not exist) → stop and report it verbatim.
   Never edit the spec file directly, and never write the issue body: the body carries only a
   regenerated Section Map mirror and no checkboxes.


2. **Post the section log** as an issue comment — the audit trail
   `review-issue` reads to validate that each test was actually implemented,
   and was red before the implementation existed, without re-deriving:

   ```markdown
   <!-- section-log #<n> <SEC-ID> -->
   ## Section log · #<n> · <SEC-ID>

   Branch: `<branch>`

   | AC | Test file:line | Test | Red evidence | Green result |
   |---|---|---|---|---|
   | AC-1 | test/.../x_test.exs:42 | new | ** (UndefinedFunctionError) ... | 1 test, 0 failures |
   | AC-2 | test/.../x_test.exs:12 | amended | assert mismatch on {:error, _} | 1 test, 0 failures |
   | AC-3 | — | no test — manual | — | verified by <means from the AC marker> |
   ```

   `Test` is one of `new` / `amended` / `no test — <visual|mechanical|manual>`.
   A `mechanical` row's Green result is its check's actual output.

3. **Answer the review threads** — amend resume only. `/tmp/code-issue-<n>-comments.json`
   may not exist yet — preflight skipped writing it under `SECTION_STATE:` (Step 0). If
   the file is missing, fetch it now with the same `gh api` call Step 0 would otherwise
   have run; this is the one point in an amend-resume run that genuinely needs comment
   bodies, not just the timestamps `SECTION_STATE:` already carried. From
   `/tmp/code-issue-<n>-comments.json`, take every
   `<!-- review-feedback #<n> <SEC-ID> -->` comment whose id appears in a
   `<!-- review-feedback-resolved <id> -->` marker, and pair each of its items
   with that resolution comment's `- item <k> → …` line. Re-run the thread
   query from `address-pr-review` Step 3 for the thread ids in the report's
   table; for every item whose thread is still `isResolved == false` (one the
   reviewer already closed is left alone), reply, then resolve:

   - solved (`- item k → <SEC-ID>: …`) → `Addressed in <sha> — <one sentence naming what changed>.`
   - declined (`- item k → declined: <reason>`) → the reason, verbatim from the line.

   ```bash
   gh api -X POST \
     "repos/<OWNER>/<REPO>/pulls/<PR>/comments/<FIRST_COMMENT_DB_ID>/replies" -f body="<reply>"
   gh api graphql -f query='
   mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ id isResolved } } }' \
     -f id="<THREAD_ID>"
   ```

   Never resolve before replying; **resolve every one, declined included** —
   an answered thread is a closed thread, and reopening it is the reviewer's
   move. `<sha>` is this branch's head; `pr-from-issue` pushes it after
   review. This runs before `review-issue` verifies the work, deliberately: a
   gap found in review is fixed on the same branch, and the reviewer
   re-reviews with `amends-required` still on.

4. **Implementation Summary** in chat:

   ```
   ### Implementation Summary · #<n> · <SEC-ID>

   **Branch:** <branch> (PR title per Section Map: "<title>")
   **Files created/modified:**
   - `lib/...` — <what changed>
   **Docs applied:** <DOC-1's prescribed edits, CHANGELOG entry included ·
   "none — documentation is DOC-1's">
   **Tests run (targeted):** <files> — green
   **Pending human verification:** <the visual/manual ACs and their stated means, or "none">
   **Review threads answered:** <k solved, j declined — all resolved | n/a>

   👉 Next: review-issue <n> <SEC-ID>  (Spec/Review: <model+effort>)
   ```

   Spec defects never appear in a summary — a real one blocked the run at
   Step 3 or Step 6. PR creation is `pr-from-issue`'s job, after review.

## Project rules

`aurora_uix` is a **low-code UI generation library**, not an application. It generates LiveView
index/form/show UIs from resource metadata, over **two interchangeable backends**: Ash and Ecto
(via `aurora_ctx`). Re-read before each subsection. `AGENTS.md` is canonical; this restates what
this skill enforces while coding.

- **Backend abstraction boundary** (the single most important rule):
  - `Ecto.Association.*` / `Ecto.Embedded` may be referenced **only** in
    `lib/aurora_uix/integration/ctx/`.
  - `Ash.Resource.*` may be referenced **only** in `lib/aurora_uix/integration/ash/`.
  - Both parsers normalize into a common `%Aurora.Uix.Field{}` shape (`type`, `html_type`,
    `data`). Everything downstream — layout, renderers, generators, handlers — consumes the
    normalized atoms and must stay backend-agnostic.
  - A feature is not complete until **both** parsers support it.
- **Adding a new field type atom**: audit every downstream consumer that pattern-matches on the
  existing atoms. Grep for a sibling atom (e.g. `:one_to_many_association`) and make an
  add / do-NOT-add decision for each hit, with a justification — the spec's `##### Type-atom audit`
  carries it; execute it, and log an `oversight`/`design-gap` defect for a hit it does not cover.
  Silent omission is the dominant failure mode: a missing entry in `filter_preloads/1` or
  `replace_related_field_data/2` fails far from the change.
- **The library is transport-only for writes.** It renders input names and forwards params
  untouched; it never builds a changeset. `cast_assoc` / `cast_embed` / `manage_relationship`
  live only in `lib/aurora_uix/guides/` (demo host code).
- **Renderers**:
  - Implement the `Aurora.Uix.Renderer` behaviour (`render/1`).
  - Field renderers live in `templates/basic/renderers/fields/`. The module is
    `…Renderers.OneToMany`, **not** `…Renderers.Fields.OneToMany`, despite the path.
  - Prefer swapping `auix` keys (`:layout_tree`, `:resource_name`, `:form`, `:entity`) and
    delegating to `Renderer.render_inner_elements/1` over hand-writing child markup — that keeps
    renderer overrides, sections and groups working.
  - Dispatch is added in `templates/basic/renderers/default_renderer.ex`. Keep aliases
    alphabetical (credo enforces this).
- **Styling**: no inline `class=`. New `auix-*` classes go in `templates/basic/themes/base.ex`
  as a `rule/1` clause; regenerate with `mix auix.gen.stylesheet` and
  `mix auix.gen.tailwind_classes`.
- **LiveView**:
  - Use `<.icon name="hero-...">`, `<.input>` and the other components from
    `templates/basic/components/core_components.ex`. Never use `Heroicons` directly.
  - Use streams for collections; track counts/empty-state in separate assigns (streams are not
    enumerable).
  - Avoid LiveComponents unless there is a specific, strong need.
  - No raw `<script>` tags. Colocated hooks only (`:type={Phoenix.LiveView.ColocatedHook}`, name
    starts with `.`, unique DOM `id`).
  - Use `<.link navigate>` / `push_navigate` — never deprecated `live_redirect`.
- **Localization**: user-visible strings go through `dt/1` (`use Aurora.Uix.Gettext`). Templates
  are extracted to `priv/gettext/*.pot`; this project ships no per-locale translations.
- **Documentation** (enforced by `doctor` in `mix consistency`): `@moduledoc` with
  `## Key Features` / `## Key Constraints`; `@doc` + `@spec` on public functions — first clause
  only; `@spec` on private functions too. See the `documentation` skill.
- **Elixir gotchas**: lists do not support `mylist[i]` (use `Enum.at/2` or pattern match); block
  expressions must rebind (`socket = if ... do ... end`); never `String.to_atom/1` on user input;
  never nest multiple modules in one file; predicate functions end with `?`.
- **Tests**: `use Aurora.UixWeb.Test.UICase, :phoenix_case` and
  `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`. There is no `FeatureCase` and no
  factory. No mocks. No `Process.sleep/1` — use `start_supervised!/1`, `_ = :sys.get_state(pid)`,
  or `Process.monitor/1` + `assert_receive {:DOWN, ...}`.

### Reusable patterns

**Parser clause — normalize a backend construct into `%Field{}`.** Both parsers map a native
struct to a common atom + `data` map. Clause order matters: the specific clause must precede the
catch-all, and in `ash/fields_parser.ex` several functions have **no** catch-all, so a missing
clause raises `FunctionClauseError` at blueprint-compile time rather than degrading.

```elixir
# lib/aurora_uix/integration/ctx/fields_parser.ex   (Ecto)
defp field_type(_attrs, %{ecto_type: %AssociationHas{cardinality: :one}}),
  do: :one_to_one_association

# lib/aurora_uix/integration/ash/fields_parser.ex   (Ash — fully qualified;
# this file deliberately keeps no relationship aliases)
defp field_type(nil, %Ash.Resource.Relationships.HasOne{}),
  do: :one_to_one_association

defp field_data(_attrs, %Ash.Resource.Relationships.HasOne{
       destination_attribute: related_key,
       destination: related_schema,
       source_attribute: owner_key
     }),
     do: %{owner_key: owner_key, related: related_schema, related_key: related_key}
```

**Field renderer — delegate to the engine, don't hand-write child markup.**

```elixir
def render(%{field: %{data: %{resource: resource_name}} = field,
             auix: %{layout_type: :form}} = assigns) do
  assigns =
    assigns
    |> BasicHelpers.assign_auix(:layout_tree, BasicHelpers.get_layout(assigns, resource_name, :form))
    |> BasicHelpers.assign_auix(:resource_name, resource_name)

  ~H"""
  <div class="auix-one-to-one-container">
    <.inputs_for :let={child_form} field={@auix.form[@field.key]}>
      <Renderer.render_inner_elements auix={Map.put(@auix, :form, child_form)} />
    </.inputs_for>
  </div>
  """
end
```

(The `class=` above is theme-owned: the `auix-*` rule exists in `themes/base.ex`.)

**Migrations.** Two separate paths, by guide backend (`mix ash.codegen` exists via the `ash` dep
but covers only the Ash resources; it is not the path for the Ecto guide schemas).

```bash
# Ecto guide schemas (lib/aurora_uix/guides/inventory/) — hand-written migrations
mix ecto.gen.migration create_<name>_table

# Ash guide resources (lib/aurora_uix/guides/blog/) — generated
mix ash_postgres.generate_migrations --name <name>
# commit BOTH the migration and the priv/resource_snapshots/ snapshot
```

`mix test` does **not** run migrations. Run `mix ecto.migrate` (the test/demo database) or
DB-backed tests fail with a confusing `relation "…" does not exist`.

### Test patterns

**Prefer `Phoenix.LiveViewTest` for all UI tests** — faster, no browser driver, covers the vast
majority of LiveView interactions. Use `has_element?/2` and `element/2`; never assert on raw HTML.

| Directory | Covers | DB? |
|---|---|---|
| `test/cases/integration/{ash,ctx}/` | parser output for one backend | no |
| `test/cases/integration/fields_parser_validations_test.exs` | shared golden `%Field{}` metadata | no |
| `test/cases/` | resource metadata, layout/blueprint generation | no |
| `test/cases_live/` | rendered LiveView behaviour (**the default for UI work**) | yes |
| `test/browser_cases/` | Wallaby — last resort only | yes |
| `test/doctests/` | doctests | no |

Parser tests are pure compile-time introspection — run them first as the fast feedback loop.

```elixir
# test/cases/integration/ctx/fields_parser_test.exs — fixtures are schemas
# declared inside the test module; no database involved.
test "Validate association_parser" do
  validations = Validations.get(:with_associations)

  parsed_schema =
    AllTypes
    |> Ctx.FieldsParser.parse_fields(:all_types)
    |> then(&Ctx.FieldsParser.parse_associations(AllTypes, :all_types, %{}, &1))
    |> Map.new(&{&1.key, &1})

  assert Validations.compare_maps(validations, parsed_schema) == []
end

# test/cases_live/ — declare metadata + layout, then drive the generated UI.
defmodule Aurora.UixWeb.Test.MyFeatureTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    edit_layout :product do
      stacked([:reference, :name])
    end
  end

  test "renders the field", %{conn: conn} do
    delete_all_inventory_data()
    {:ok, view, _html} = live(conn, "/my-feature/products/new")
    assert has_element?(view, "input[name='product[reference]']")
  end
end
```

**Every route used by a `test/cases_live/` test must be registered in
`test/support/app_web/routes.ex`** via `RoutesHelper.register_crud/2` — otherwise the test 404s.
Do **not** extend `register_product_crud/2`; it hardcodes three modules and is called from ~20
sites.

Assert on stable selectors — `input[name='parent[child][field]']`, container ids,
`has_element?/2`. Never assert on raw HTML strings, and avoid `auix-field-*` ids: they embed a
global counter and are not stable across test ordering.

**Wallaby (`test/browser_cases/`) is a last resort.** Only when LiveViewTest is genuinely
insufficient — file downloads, native dialogs, multi-tab. Document **why** in a comment above the
test.
