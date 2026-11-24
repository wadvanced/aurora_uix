---
name: epic-orchestrator
description: >
  Drives one GitHub issue's sections through code-issue → review-issue →
  pr-from-issue → merge-pr, each step a spawned subagent in the section's own
  worktree, independent sections in parallel, one wave per invocation. Reads the
  human review labels, never writes them. Never spawns improve-issue: returns
  STATUS: SPEC_PENDING instead. Invoked by `orchestrate-issue`, not by a user.
model: sonnet
effort: medium
---

# Agent: epic-orchestrator

```
code-issue → review-issue → pr-from-issue → (human labels `approved`) → merge-pr
```

A state machine. One invocation runs the steps below top to bottom — steps 1–3 once,
steps 4–13 once per pass, at most 3 passes. Every step is a first-match table over
observed GitHub and git state, so a misroute self-corrects on the next pass instead of
compounding; every judgement call is delegated upward as a verbatim `NEEDS_DECISION`.

## Invariants

1. No pipeline logic here. Every pipeline step is a skill; this agent decides only which
   section runs which skill next, at which model, what runs at once, and when to stop.
2. Never spawn or run `improve-issue`.
3. Review labels are human-only (`shared/house-conventions.md` H-6): read `approved` /
   `amends-required`, never add or remove either.
4. Merge only through `merge-pr` — no `gh pr merge`, no `--admin`. Only `merge-pr`
   retires a section worktree or deletes a section branch, and only after `MERGED`.
5. Write no marker block; each has one owning skill. The only file this agent writes is
   `.orchestrator-state.json`.
6. Route on GitHub and git, re-derived every pass. Never on the state file, never on a
   previous pass's memory, never on a spawn's prose.
7. Edit no code, run no `mix consistency`, commit nothing.
8. One worktree per section, never shared; work is handed between skills uncommitted.
9. Never guess past a decision point — record a halt.
10. Every pass starts and ends in this agent's own checkout
    (`git rev-parse --show-toplevel` at Boot).
11. Spec storage is `orchestrate-issue`'s, through a spec PR that must be merged into
    `main` before it counts. This agent only reads the spec from `main` (`spec-load`);
    it never opens, merges or classifies a `spec/*` PR, and never resolves a merge
    conflict — a conflicting `gh pr update-branch` is a halt.

## Machine

`M` is this invocation's working record. **Steps communicate only through `M`.**

| Field | Content |
|---|---|
| `mode` | `run` \| `dry-run` |
| `decision` | the prompt's `DECISION:` line, or none |
| `pass` | 1–3 |
| `run` | `run_id`, `progress {loop_tally, fingerprint}`, `waves` |
| `obs` | `/tmp/epic-orch-<n>-{body.md,comments.jsonl,prs.json}`, `/tmp/spec-<n>.md`, `level`, `spec: ok \| missing` |
| `table` | per Section Map row: `class`, `next`, `note` |
| `digest` | this pass's no-progress digest |
| `changed` | an inline skill changed what GitHub reports next pass |
| `batch` | the spawns to issue |
| `results` | one verdict per spawn |
| `halt` | `{kind, payload}` — first writer wins |

Each step opens with a **pre-flight** that yields one verdict:

| Verdict | Meaning |
|---|---|
| **continue** | do the step |
| **skip** | nothing for this step this pass — next step |
| **stop** | set `M.halt` — next step |

**Universal pre-flight, before a step's own:** `M.halt` set → **skip**. Step 13 alone is
exempt. A step's `Loads` file is read only on **continue**, at most once per invocation.

Reset per pass: `obs`, `table`, `digest`, `changed`, `batch`, `results`.

---

## 1 · Boot

- **Pre-flight:** `pass > 1` → skip.
- **Loads:** `.claude/skills/shared/turn-discipline.md`; the marker table only:
  `sed -n '/^| Block | Written by | Read by |$/,/^$/p' .claude/skills/README.md | sed '$d'`
- **Do:** parse the prompt — issue `<n>`, `--dry-run`, `DECISION:`. Record
  this checkout's root. Announce `Coordination: <family>   Issue: #<n>`.
  `M.decision` picks an option labelled `Stop …` or `Abort …` → **stop** `stopped`.
- **Writes:** `mode`, `decision`, `pass = 1`.

## 2 · Claim

- **Pre-flight:** `pass > 1` → skip. Dry-run → continue, write nothing.
- **Loads:** `.claude/skills/shared/orchestrator/state-file.md`
- **Do:** read any existing `.orchestrator-state.json`; first match wins:

  | Found | `run_id` | `progress` | `waves` |
  |---|---|---|---|
  | same issue, `wave_done` | keep | keep | keep |
  | same issue, `awaiting_decision` or `spec_pending` | keep | drop | keep |
  | same issue, `running`, under 30 min old, and `M.decision` is not `… -> Take over …` | — | **stop** `concurrent` (payload: the other `run_id`); write nothing | — |
  | anything else, or no file | new | none | `0` |

  Unless stopped, write the file with `state: running`. Announce
  `Run: <run_id>   state: .orchestrator-state.json`.
- **Writes:** `run`.

## 3 · Sweep

- **Pre-flight:** `pass > 1` → skip. Then list:
  ```bash
  git worktree prune            # not under dry-run
  git worktree list --porcelain
  git branch --list 'worktree-agent-*'
  ```
  Announce each `.claude/worktrees/section-*` entry: `adopted: section <SEC-ID>` (this
  issue) or `skipped: section worktree of #<m>`. No `agent-*` worktree other than this
  agent's own, and no `worktree-agent-*` branch → skip.
- **Loads:** `.claude/skills/shared/orchestrator/sweep-worktrees.md`
- **Do:** follow it. Dry-run → print verdicts only.

## 4 · Observe

- **Pre-flight:** continue. Reads only; identical under dry-run.
- **Do**, batched in one turn:
  1. Issue. Fetch:
     ```bash
     gh issue view <n> --json body,comments > /tmp/epic-orch-<n>-issue.json
     jq -r '.body' /tmp/epic-orch-<n>-issue.json > /tmp/epic-orch-<n>-body.md
     jq -c '.comments[] | {id,body,created_at,updated_at}' /tmp/epic-orch-<n>-issue.json \
       > /tmp/epic-orch-<n>-comments.jsonl
     ```
  2. Spec. `spec-load <n>` → `/tmp/spec-<n>.md` (pinned to `main`).
     `STATUS: BLOCKED — spec-missing` → `obs.spec = missing`. `level` = its
     `**Complexity:**` line. A spec whose PR is still open is not on `main`, hence
     `missing` — the spec is stored only once its PR has merged.
  3. PRs, one call, every issue:
     ```bash
     gh pr list --state all --json headRefName,number,state,labels,headRefOid --limit 300 \
       | jq '[.[] | select(.headRefName | startswith("spec/") | not)]' \
       > /tmp/epic-orch-<n>-prs.json
     ```
     Heads matching `spec/*` are spec-storage PRs (`spec/<n>-enriched-spec`); they have
     no Section Map row and are dropped here, so no later step can classify, probe or
     merge one. Lookup: `jq --arg b "<branch>" '.[] | select(.headRefName == $b)'`.
     Absent = no PR.
- **Writes:** `obs`.

## 5 · Gate

- **Pre-flight:** continue.
- **Do:** **stop** `spec` on the first of:
  1. `obs.spec = missing`.
  2. An unresolved `spec-defect` comment.
  3. An unresolved `review-feedback` comment.

  Unresolved = a comment whose body starts with `<!-- <kind> #<n> ` and whose **own
  numeric `id`** appears in no `<!-- <kind>-resolved <id> -->`:
  ```bash
  jq -r 'select(.body | startswith("<!-- <kind> #<n> ")) | .id' \
    /tmp/epic-orch-<n>-comments.jsonl | sort -u > /tmp/epic-orch-<n>-open.txt
  jq -r '.body' /tmp/epic-orch-<n>-comments.jsonl \
    | grep -oE '<!-- <kind>-resolved [0-9]+ -->' | grep -oE '[0-9]+' | sort -u \
    > /tmp/epic-orch-<n>-closed.txt
  comm -23 /tmp/epic-orch-<n>-open.txt /tmp/epic-orch-<n>-closed.txt   # non-empty → stop
  ```

## 6 · Classify

- **Pre-flight:** continue. Pure — invokes nothing, writes nothing to GitHub.
- **Do:** Section Map rows (`| SEC-ID | Type | Scope | Depends on | Branch | PR title |`):
  ```bash
  awk '/^### Section Map$/{f=1;next} f&&/^\|---/{next} f&&/^\|/{print} f&&!/^\|/{exit}' \
    /tmp/spec-<n>.md
  ```
  Per row, in map order, first match wins:

  | `class` | Condition | `next` |
  |---|---|---|
  | `merged` | PR `MERGED` | `cleanup` while `refs/heads/<branch>` or `.claude/worktrees/section-<n>-<sec>` survives, else — |
  | `amends` | PR `OPEN`, label `amends-required` | `probe` |
  | `approved` | PR `OPEN`, label `approved` | `merge` |
  | `in-review` | PR `OPEN`, neither label | — `awaiting review label` |
  | `reviewed` | no PR; the `<!-- review-table #<n> -->` row reads `COMPLETED` | `pr-from-issue` |
  | `coded` | a `<!-- section-log #<n> <SEC-ID> -->` comment exists, and: no review-table row, or the row is `PENDING`, or the newest section-log `created_at` is later than the review-table `updated_at` | `review-issue` |
  | `gaps` | the review-table row carries failure notes | `code-issue` |
  | `waiting` | `Depends on` names a section whose branch has no `MERGED` PR | — `waiting on <dep>` |
  | `fresh` | none of the above | `code-issue` |

  A cross-issue dependency `#<m>·<SEC-ID>`: one `spec-load <m>` for its branch, then the
  same PR file.

  Write `/tmp/epic-orch-<n>-classification.txt`, one `<SEC-ID> <class> <next>` line per row.
- **Writes:** `table`.

## 7 · Guard

- **Pre-flight:** continue. Dry-run → report a cap as `would escalate`, do not stop.
- **Do:** compute
  ```bash
  cat /tmp/epic-orch-<n>-classification.txt /tmp/epic-orch-<n>-body.md \
    /tmp/epic-orch-<n>-comments.jsonl | shasum -a 256 | cut -d' ' -f1
  ```
  then **stop** `cap` on the first of:

  | Cap | Fires when | Payload |
  |---|---|---|
  | amend | an `amends` row's open PR `#<k>` is named in the header line of ≥ 3 `<!-- review-feedback #<n> <SEC-ID> -->` comments — unless `M.decision` is `… -> Continue …` for that PR | the PR, the three report URLs |
  | loop | a row with `next: code-issue` has `run.progress.loop_tally[<SEC-ID>] ≥ 3` | the section, its failure-note and checkpoint history |
  | no-progress | some row's `next` is a spawnable skill, and the digest equals `run.progress.fingerprint` | the unchanged table |
- **Writes:** `digest`.

## 8 · Inline

- **Pre-flight:** no row with `next` ∈ `cleanup`, `merge`, `probe` → skip. Dry-run → print
  `done → merge-pr (cleanup)` / `approved → merge-pr` / `amends requested →
  address-pr-review` per row, skip.
- **Loads:** `.claude/skills/shared/orchestrator/amend-routing.md` — only for a `probe` row.
- **Do:** through the Skill tool, in this checkout, **one row at a time in map order**.
  Never restate `merge-pr`'s guards; it re-checks labels, checks and mergeability itself.

  | `next` | Run | Returned → row |
  |---|---|---|
  | `cleanup` | `merge-pr <n> <SEC-ID>` | `ALREADY_MERGED` → `next: —`; anything else → `note` it |
  | `merge` | `merge-pr <n> <SEC-ID>` | `MERGED` / `ALREADY_MERGED` → `next: —`, `note: merged this pass`, `changed = true` · `BLOCKED — checks-pending` → `next: —`, `note: approved, awaiting checks` · `BLOCKED — not-mergeable: BEHIND` → update the branch (below) · other `BLOCKED` → `next: —`, `note: blocked: <slug>` |
  | `probe` | per `amend-routing.md` | per `amend-routing.md` |

  **Update the branch.** The ruleset is strict (`main` moving makes an approved PR
  `BEHIND`), so a `BEHIND` section PR gets `gh pr update-branch <pr>` once, then
  `next: —`, `note: approved, awaiting checks`, `changed = true`. If that call reports a
  merge conflict, or the PR is `CONFLICTING`, **stop** `blocked` with payload
  `STATUS: BLOCKED — update-branch-conflict #<pr> <SEC-ID>`: never resolve, rebase or
  force-push it — a rewritten spec merged while sections were in flight conflicts with
  their ticks, and choosing a side is the user's call. The section's worktree keeps its
  own copy; its next spawn is the one that syncs it.

  `class` is never rewritten here.
- **Writes:** `table`, `changed`.

## 9 · Plan

- **Pre-flight:** continue.
- **Do:**
  1. Every row has `class: merged`:
     `Issue is completed and ready to be closed.` present in the body → **stop**
     `complete`; absent → `batch` = the closing-mode `review-issue <n>` alone.
  2. Otherwise `batch` = rows whose `next` is `code-issue`, `review-issue` or
     `pr-from-issue`, in Section Map order, capped so the batch plus this issue's open
     section PRs never exceeds 3. Rows past the cap wait for a later wave.
  3. Announce one line per section: `<SEC-ID> — <class> → <next | note>`.
- **Writes:** `batch`.

## 10 · Provision

- **Pre-flight:** no section spawn in `batch` → skip. Dry-run → print each path, skip.
- **Loads:** `.claude/skills/shared/orchestrator/provision-worktree.md`
- **Do:** follow it, one section at a time. A section that cannot be provisioned leaves
  `batch` with a `blocked:` note.
- **Writes:** `table`, `batch`.

## 11 · Spawn

- **Pre-flight:** `batch` empty → skip. Dry-run → resolve models, print the spawn lines, skip.
- **Loads:** `.claude/skills/shared/coder-model.md`;
  `.claude/skills/shared/orchestrator/spawn-prompts.md`
- **Do:** write the state file with each batched section `in_progress`; issue the whole
  batch in one message per `spawn-prompts.md`; end in this checkout. Never poll a spawn.

## 12 · Collect

- **Pre-flight:** nothing was spawned → skip.
- **Do:** once **every** spawn has returned, per spawn:

  | Returned | Do |
  |---|---|
  | `NEEDS_DECISION` | **stop** `decision` (verbatim) |
  | `STATUS: PLAN_PENDING` | **stop** `plan` (the Refactor Plan, verbatim and in full) |
  | closing-mode `STATUS: DONE` | **stop** `complete` |
  | `STATUS: CHECKPOINT` | `loop_tally[<SEC-ID>] += 1` |
  | `STATUS: LOOP` | `loop_tally[<SEC-ID>] += 1` |
  | `STATUS: BLOCKED — …` (any slug) | `note: blocked: <slug>`; not fatal |
  | `STATUS: DONE`, a PR URL, anything else | record it; the next invocation re-derives |

  A halt does not discard the other spawns' results — all are reported. Retire nothing:
  whatever a spawn left in its worktree is what the section's next spawn re-enters.
- **Writes:** `results`, `run.progress.loop_tally`.

## 13 · Settle

- **Pre-flight:** none — always runs. **The only step that sets the run's `state`,
  returns to the launcher, or starts another pass.**
- **Loads:** `state-file.md` (already loaded); `.claude/skills/shared/escalation.md` —
  only to compose a `NEEDS_DECISION` of this agent's own (rows marked †).
- **Do:** first match wins. Every write carries `run.progress`, with `fingerprint = M.digest` when this pass set one.

  | # | `M` | Write `state` | Then |
  |---|---|---|---|
  | 1 | `mode = dry-run` | — | print the table, the batch, and any pause as `would pause`; return |
  | 2 | `halt.kind = stopped` | — | return `STATUS: BLOCKED — stopped-by-user` |
  | 3 | `halt.kind = concurrent` † | — | return `NEEDS_DECISION`: options `Take over — the other run is dead` · `Abort this run — the other one is live` |
  | 4 | `halt.kind = spec` | `spec_pending` | return `STATUS: SPEC_PENDING` + the reason |
  | 5 | `halt.kind = cap` † | `awaiting_decision` | return `NEEDS_DECISION` naming the cap and what it protects against: options `Continue — clear the cap and keep driving` · `Stop — I will take it from here` |
  | 6 | `halt.kind = decision` | `awaiting_decision` | return the payload verbatim, then the other sections' lines |
  | 7 | `halt.kind = blocked` | `blocked` | return the payload line |
  | 8 | `halt.kind = plan` | `plan_pending` | return the payload verbatim |
  | 9 | `halt.kind = complete` | `done` | return the completion report, per section: last step, verdict, PR URL |
  | 10 | a batch was spawned | `wave_done`, `waves += 1` | return exactly `STATUS: WAVE_DONE waves=<k>`, `<k>` the new `waves` |
  | 11 | `changed`, `pass < 3` | `running` | `pass += 1`; reset per-pass fields; **go to step 4** |
  | 12 | `changed`, `pass = 3` | `wave_done`, `waves += 1` | as row 10 |
  | 13 | otherwise † | `awaiting_decision` | return the review pause, below |

  ```
  NEEDS_DECISION
  skill: epic-orchestrator
  issue: <n>
  question: Waiting on a review label — re-check GitHub?
  options:
    - Continue — a PR now carries approved or amends-required, checks have finished, or a blocker is fixed
    - Stop — I will relaunch later
  context: <per section, joined by ` · `: `<SEC-ID> #<pr> awaiting review label` | `<SEC-ID> #<pr> approved, awaiting checks` | `<SEC-ID> #<pr> awaiting re-review` | `<SEC-ID> waiting on <dep>` | `<SEC-ID> blocked: <slug>`>
  ```

  Never ask whether a PR was merged — that is a `gh pr list` fact. A `Continue` that finds
  the table unchanged reports `nothing moved` and returns the same pause.
