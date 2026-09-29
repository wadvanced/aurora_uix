# GitHub issue skills (aurora_uix)

A pipeline that turns a raw GitHub issue into tested, reviewed code. The GitHub
issue is the source of truth throughout — every skill reads its state from the
issue body and from GitHub (PRs, labels), never from chat context, so any step
can be re-run in a fresh session.

## The sectioned model (v2)

`improve-issue` partitions an issue into **sections** — `Documentation`,
`Schema`, `Parser`, `UI` — each self-contained and atomic: merged alone
on top of its dependencies, the app compiles, migrates, boots, and the full
suite stays green.

- Layering is law: Documentation → Schema → Parser → UI. UI depends on
  Parser, Parser depends on Schema, Schema depends on Documentation. A Parser
  section covers exactly one backend (`ash` or `ctx`) per capability, so a
  feature that touches both parsers has two Parser sections.
- Documentation leads structurally. `DOC-1` is one section per issue carrying
  every doc edit it owes, and its PR merges **before** any code section starts.
  The only doc touch outside it is a Schema section's 🔧 → ✅ marker flip.
- Nothing is written to an issue unapproved. `improve-issue` presents the exact
  spec and writes only after a human approves it — every run, re-runs included.
  A non-interactive spawn cannot approve, so it halts with
  `STATUS: SPEC_PENDING` and writes nothing.
- One PR per section. A section may not start until every dependency's PR is
  **merged**. Section status is derived from GitHub (the PR carrying the
  section id), never cached in the issue body.
- There is no sizing, no splitting, no child issues. More work = more sections.
- No open questions: every ambiguity is resolved with the user before the spec
  is written.
- Spec depth is fixed at the `normal` coder, whatever complexity level the run
  is invoked at. A `high` or `max` issue buys a stronger coder, never a
  shallower spec.
- One **complexity level** per issue — `normal` (default), `high`, `max` — set
  by the caller on the first `improve-issue` run and persisted in the spec
  block, so every later step resolves the same models in any session.
  `shared/coder-model.md` is the registry.

## Skills

| Skill | Purpose |
|---|---|
| `spec-load` | Reads an issue's spec — or one section of it — from `specs/issue-<n>-enriched-spec.md` on `main`. The only fence extractor |
| `spec-store` | Stores that spec file through branch → PR → merge (`spec-store-write.sh`) and regenerates the body's Section Map mirror; owns the merged-section guard. Also `tick`: a local checkbox edit in the section worktree |
| `improve-issue` | Partitions and enriches an issue into the sectioned v2 spec; writes only what a human approved, through `spec-store`. **Owns the spec's content** |
| `code-issue` | Implements one section test-first on its own branch. Posts the `section-log` comment |
| `review-issue` | Verifies one section's ACs by evidence, runs the full gate, maintains the review table. **Owns the review table and the completion phrase** |
| `pr-from-issue` | Opens one reviewed section's PR — owns its branch, title and issue reference; delegates the rest to `do-pr` |
| `address-pr-review` | Captures a section PR's unresolved review threads as a `review-feedback` report on the issue — the review-loop twin of `spec-defect`. Changes no code, resolves nothing it captured |
| `merge-pr` | Merges one PR a human labelled `approved` — or one spec PR, which needs no label (see below) — and cleans up after it — refreshes `origin/main` and local `main`, deletes the merged section branch. Reads the review labels, writes none |
| `orchestrate-issue` | Drives an issue's sections end to end, respecting merged-dependency gating; merges an `approved` PR and runs an `amends-required` PR's feedback back through the pipeline |
| `gate` | Runs `gate-fix`, then `gate-commit` if clean |
| `gate-fix` | Runs `mix consistency` and fixes mechanical issues; emits a Refactor Plan for refactor-class issues |
| `gate-commit` | Groups the working tree into conventional commits; refuses unless `mix consistency` is clean |
| `documentation` | Elixir documentation rules |
| `bump-dependencies` | Bumps outdated Hex dependencies, updates `CHANGELOG.md` and closes the `bump`-labelled issues it resolves |

`.claude/agents/epic-orchestrator.md` is the agent `orchestrate-issue` spawns to
drive one wave of sections through code → review → PR → merge. Its helpers are
`.claude/scripts/` (`gate.sh`, `suite.sh`, `section-test.sh`, `wait-verdict.sh`,
`spec-store-write.sh`) and the `.claude/hooks/guard-long-commands.sh` hook, which
rejects backgrounded gates, direct `mix consistency` runs and poll loops.
`scripts/test_pg.sh` gives each checkout its own test PostgreSQL instance.

`shared/` is not a skill. It holds `house-conventions.md`, `escalation.md`,
`gate-receipt.md`, `background-long-commands.md`, `turn-discipline.md`, and
`coder-model.md` — the model registry: one complexity level maps to a set of
four models, one per skill group (Coordination, Spec/Review, Coder, Ship).

## The pipeline

```
/skill improve-issue <n> [level]    # writes the sectioned v2 spec; sets the complexity level
/skill code-issue <n> <SEC-ID>      # implements one section (docs first, red tests, code, green)
/skill review-issue <n> <SEC-ID>    # reviews that section
/skill pr-from-issue <n> <SEC-ID>   # opens the section's PR
                                    # — a human reviews it and labels it `approved` —
/skill merge-pr <n> <SEC-ID>        # merges it and cleans up; also takes a bare PR number
```

The label between the last two lines is the only step no skill performs. Every
other transition is derived from GitHub, so the pipeline never has to ask
whether something happened — it looks.

A section's PR references the issue as `Part of #<n> · <SEC-ID>`, never
`Closes`, until `review-issue` has written the completion phrase — otherwise the
first section to merge would close an issue whose remaining sections are not
written yet.

`[level]` is `normal` (default), `high`, or `max`, and is needed only on the
first `improve-issue` run — the later steps read it from the spec block. Passing
it to `code-issue` or `review-issue` is a one-off override, never written back.

Repeat per section, in Section Map order. Sections with no dependency between
them may run in parallel; a section starts only when its dependencies are
merged.

## The review loop

A reviewer who wants changes labels the section's PR `amends-required` — a
human-only label (`shared/house-conventions.md` H-6). From there:

```
/skill address-pr-review <n> <SEC-ID>   # reports the threads on the issue; changes nothing
/skill improve-issue <n>                # absorbs each item into the spec, or declines it on the record
/skill code-issue <n> <SEC-ID>          # amend resume: implements the resolution lines, answers and resolves the threads
/skill review-issue <n> <SEC-ID>        # re-verifies on the open PR
/skill pr-from-issue <n> <SEC-ID>       # refreshes the same PR
```

The reviewer then removes `amends-required` and adds `approved` — both human
acts — and `merge-pr` lands it. `merge-pr` refuses a PR that carries
`amends-required`, even if `approved` is also present; that is how a reviewer
re-blocks a PR they had already approved. (aurora_uix has no `approval-check.yml`;
the rule is enforced by the skill, not by a required check.)

`orchestrate-issue` runs this unattended, stopping only for the `improve-issue`
approval; while every section is waiting on something outside the run (a review
label, CI checks, a re-review, a dependency) it pauses with a Continue / Stop
question rather than ending. It never asks whether a PR was merged — merge state
is derived from `gh pr list`, and a merge the run performs is an act, not a
question. Each **section** gets one git worktree, provisioned with its own private test
PostgreSQL instance (`scripts/test_pg.sh`) and its own endpoint port, and it lives until that section's PR
merges — the section's steps hand uncommitted work to one another through that
tree, so retiring it between them would strand the work. `merge-pr` retires the
worktree and deletes the section's local branch together, as its own
after-merge cleanup, once the PR is confirmed merged — so a human who merges
outside the pipeline (standalone `merge-pr`, or a merge done on GitHub's UI)
still gets both, not just the branch. The
thread is answered by the spec and closed by the code:
`address-pr-review` resolves nothing it captured; `code-issue` resolves every
captured thread — implemented or declined — once the work exists. An item is
absorbed into the section whose PR raised it or declined on the record; it
never moves to a sibling, because sections are atomic.

## Marker blocks

**The spec is a file, not a body.** It lives at
`specs/issue-<n>-enriched-spec.md`, version-controlled, because a real spec
outgrows what a GitHub issue body accepts. Two
sub-skills own the transport, and nothing else may bypass them:
`spec-load` reads (always from `main`), `spec-store` writes.

| Block | Written by | Read by |
|---|---|---|
| `specs/issue-<n>-enriched-spec.md` — the spec itself, sections and ACs | `spec-store` (owner) — on behalf of `improve-issue` (whole spec, through a spec PR) and `code-issue` / `review-issue` (AC ticks, local edit in the section worktree) | `spec-load`, and through it every pipeline skill |
| `enriched-spec` (v2) body block — pointer + Section Map **mirror** | `spec-store` (owner), regenerated on every write | **nobody.** The mirror is for humans scanning GitHub; a skill that read it could act on a hand-edit |
| `**Complexity:** <level>` (in the spec file) | `improve-issue` (owner) | `code-issue`, `review-issue`, `pr-from-issue`, `epic-orchestrator` |
| `<!-- section:<SEC-ID>:start/end -->` fences (in the spec file) | `improve-issue` (owner) | `spec-load` — the single canonical extractor |
| `<!-- section-log #<n> <SEC-ID> -->` comment | `code-issue` | `review-issue` |
| `<!-- spec-defect #<n> <SEC-ID> -->` comment | `code-issue` | `improve-issue` |
| `<!-- code-issue-gap #<n> <SEC-ID> -->` comment | `code-issue` (owner) — posted on a mid-implementation-defect **keep** decision, and as a checkpoint when a spawn exhausts its targeted-test budget | `code-issue` itself, on the next run (preflight row 8) |
| `<!-- review-feedback #<n> <SEC-ID> -->` comment | `address-pr-review` | `improve-issue`, `code-issue` (thread ids to answer), `epic-orchestrator` |
| `<!-- review-feedback-resolved <id> -->` comment, one `- item k → …` line per item | `improve-issue` | `code-issue` (amend work list, replies), `epic-orchestrator` (`shared/orchestrator/amend-routing.md`) |
| `<!-- review-table #<n> -->` comment (one per issue, edited in place) | `review-issue` (owner) | `code-issue` (gaps resume), `pr-from-issue`, `orchestrate-issue` |
| `Issue is completed and ready to be closed.` (body phrase) | `review-issue` (owner) | `pr-from-issue` (decides `Closes` vs `Part of`), `orchestrate-issue` |

`code-issue` may edit exactly one thing in the spec: the AC checkboxes of the
section it implements; `review-issue` may additionally tick a checkbox it has
proven met. Both go through `spec-store <n> tick`, which is a **local edit** of
the spec file in the section's worktree — no API call, no PR — and permits only
`- [ ]` → `- [x]` flips inside that section's fence. The tick reaches `main` in
the section's own code PR, committed by `gate-commit`. `spec-load` reads `main`
for structure and overlays only the working copy's ticks for the section in
hand. Closing-mode `review-issue` does not tick (the sections are merged and
the merged-section guard would refuse). Everything else belongs to
`improve-issue`. A section whose PR is merged is history — never rewritten.

**Nothing is ever written to `main` directly.** aurora_uix's ruleset requires a
pull request and the status check `Build and test (1.19.4-otp-28, 28.2)`, so a
spec is stored by `spec-store-write.sh` in two phases: it creates branch
`spec/<n>-enriched-spec`, opens a non-draft PR, waits for checks (the light CI
run for spec-only PRs takes about a minute) and prints `STATUS: OK-PR-READY <pr>`;
the caller then runs `merge-pr <pr>`; then `spec-store-write.sh <n> --finish <pr>`
refreshes local `main`, regenerates the mirror and posts the resolution comment.
Only its `STATUS: OK <sha>` means the spec is stored. Terminal statuses are
listed in `shared/escalation.md`.

### Spec PR convention

`merge-pr` skips its `approved`-label check (Step 0 row 5) for a **spec PR**,
recognised by **all** of:

- head branch matches `^spec/[0-9]+-enriched-spec$`,
- title starts with `docs(spec): enriched spec for issue #`,
- every file in the PR is exactly `specs/issue-<n>-enriched-spec.md`, with the
  same `<n>` as the branch.

If any condition fails the PR is an ordinary PR and needs `approved`. Every
other row still applies (not draft, base `main`, no `amends-required`, checks
green or skipped, mergeable). `merge-pr` still never writes `approved` or
`amends-required` (H-6). The orchestrator ignores `spec/*` heads when it
classifies PRs. If an `approval-check.yml` is ever added it needs the same
exemption and must not be a required check without it.
