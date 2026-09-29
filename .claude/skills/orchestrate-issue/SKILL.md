---
name: orchestrate-issue
description: >
  Drive a GitHub issue's sections through the whole pipeline unattended,
  running independent sections in parallel, until every section is merged. Use
  when the user says "orchestrate this issue", "run the whole pipeline", "take
  this issue to PRs", or "drive issue N end to end". Stops only at genuine
  judgement calls — including the one no subagent can clear: approving a spec.
  Acts on the human review labels without ever writing one: `approved` merges
  the section PR and cleans up after it, `amends-required` runs the feedback
  back through the pipeline.
---

# Skill: orchestrate-issue

Thin launcher around the `epic-orchestrator` agent. The agent drives sections;
this skill exists for three reasons only:

1. **To resolve models.** An agent cannot pick its own model, so this skill
   reads the registry and passes the resolved family as a spawn-time `model`
   override — Coordination for the `epic-orchestrator`, Spec/Review for
   `improve-issue`.
2. **To ask the user.** A subagent cannot call `AskUserQuestion`. The agent
   returns `NEEDS_DECISION` and terminates; this skill — running in the main
   session, where prompting works — surfaces the question and re-spawns.
3. **To approve the spec.** A subagent cannot call `ExitPlanMode` either, so
   `improve-issue` — always spawned at the Spec/Review model, never run at
   this session's — halts at `STATUS: SPEC_PENDING` with the drafted spec in
   `/tmp/improve-issue-<n>-spec.md` (`improve-issue/SKILL.md`, Present and Settle). This
   skill presents that file's identity and Section Map — never its full text
   — for approval here, where `ExitPlanMode` works, then stores the approved
   bytes with one call to `.claude/scripts/spec-store-write.sh` — a write that
   involves no judgement needs no model, so it is not a spawn. `main` takes no
   direct commits, so the script stores through a spec PR (branch
   `spec/<n>-enriched-spec` → checks → `merge-pr <pr-number>`); the spec is stored
   only when that PR has merged.

This skill implements **no** pipeline or section-state logic. If you find
yourself reasoning about marker blocks or Section Map rows here, that belongs
in the agent. The one thing it does with a spec is present its identity and
relay the verdict — it never reads the spec body, drafts or edits one, and
persists it only by running the store script once, after approval.

Follows `../shared/turn-discipline.md` throughout: never poll a spawned task,
no narration-only turns.

## Arguments

```
/orchestrate-issue <n>                 drive issue <n>'s sections to PR(s)
/orchestrate-issue <n> <level>         normal|high|max — used only if this
                                        issue has no spec yet, passed through
                                        to the first improve-issue spawn
/orchestrate-issue <n> --dry-run       print the derived per-section state and
                                        the step(s) that would run next, then
                                        stop — spawns nothing
```

`<level>` matters only on an issue's first enrichment — every later step reads
the persisted `**Complexity:**` line instead. On a re-enrichment (e.g. a
spec-defect repair) this skill omits it, so `improve-issue` reuses the
persisted level rather than resetting it.

## Steps

1. **Resolve Coordination's model.** Read `.claude/skills/shared/coder-model.md`
   and resolve the Coordination family — it is pinned at every complexity
   level, but still resolved through the registry, never hardcoded.

2. **Spawn** the `epic-orchestrator` agent with the issue number, passing the
   resolved model as the `Agent` call's `model` and `--dry-run` through in the
   prompt when given.

3. **Patch the task id into the state file.** Same mechanism as before: the
   `Agent` call returns the agent's id once the spawn is accepted; the agent
   itself cannot know it and writes `"task_id": null`.

   A fixed-count `sleep`-and-poll loop burns a turn per retry. Instead, run
   this single command via Bash's `run_in_background` and end the turn — the
   completion notification resumes this step:

   ```bash
   until [ -f .orchestrator-state.json ]; do sleep 0.5; done
   tmp=$(mktemp) &&
     python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));d["task_id"]=sys.argv[2];json.dump(d,open(sys.argv[3],"w"),indent=2)' \
       .orchestrator-state.json "<agent-id>" "$tmp" &&
     mv -f "$tmp" .orchestrator-state.json
   ```

   Patch only this field. Give the command a short timeout (the file always
   appears within seconds of a successful spawn); a timeout means the file
   never appeared — carry on, a missing `task_id` costs a slower recovery,
   never a wrong one. A `--dry-run` writes no file at all. Do not re-patch on
   a re-spawn unless the id actually changed — and never on a `WAVE_DONE`
   re-spawn, whose id always differs: a wave is minutes long, the agent rewrites
   the file on every transition anyway, and a run whose owner died mid-wave is
   recovered by re-launching, not by reattaching
   (`shared/orchestrator/state-file.md` § Recovery). An `improve-issue` spawn is not
   the orchestrator and never touches this field.

4. **Read its terminal output** and branch:

   - **`NEEDS_DECISION`** → present it with `AskUserQuestion`, question and
     options **verbatim and in the order given**. Then go to step 6 — with
     one exception: the agent's **review pause**
     (question `Waiting on a review label — re-check GitHub?`,
     `epic-orchestrator.md` Settle, last row) answered *Stop*. Report the per-section
     context and stop without a re-spawn: the agent already wrote
     `awaiting_decision` to the state file, and a re-spawn whose only job is to
     exit is waste. *Continue* re-spawns
     as any other answer does; the agent re-derives from GitHub and either
     advances or asks again.
   - **`STATUS: WAVE_DONE`** → the agent ended a wave on purpose, to keep its own
     context small (`epic-orchestrator.md` Settle, the `wave_done` rows). Nothing to ask, show or
     report: go straight to step 6. Never stop on it, and never narrate it. A run
     that makes no progress is stopped by the agent's own no-progress cap
     (`NEEDS_DECISION`), not here.
   - **`STATUS: SPEC_PENDING`** → do **not** re-spawn the agent yet. Run the
     **spec loop** (step 5) to completion, then go to step 6.

     **Cap:** if the very next agent spawn reports `SPEC_PENDING` again for
     the same reason (no spec still, the same unresolved defect, or the same
     unresolved review-feedback report), stop —
     the user already declined once in this session. Report it and do not
     loop.
   - **`STATUS: PLAN_PENDING`** → surface the Refactor Plan **verbatim and in
     full**. Stop the whole run. A Refactor Plan needs the same kind of
     interactive approval a spec does, and nothing downstream can act on it
     non-interactively.
   - **`STATUS: BLOCKED — …`** → report the reason and stop the whole run.
     `stopped-by-user` is the agent acknowledging a *Stop* / *Abort* answer
     it was re-spawned with.
   - **completion** → report per section: which step ran last, its verdict,
     and its PR URL where one exists (or "waiting on <dep>" / "awaiting review
     label" / "approved, awaiting checks" / "awaiting re-review" for sections
     not yet reachable). Stop.

5. **Spec loop** — `improve-issue` drafts at Spec/Review; this session
   approves and stores.

   a. **Resolve Spec/Review's model** from the registry at the run's level —
      read `level` from `.orchestrator-state.json` (the agent wrote it this
      pass; it is the positional `<level>` on a fresh issue, else the
      persisted `**Complexity:**`). Carry that same `model` on every
      `improve-issue` spawn in this loop.
   b. **Spawn** `improve-issue <n>` as an `Agent` at that model, prompt
      carrying `NON_INTERACTIVE: true`, plus `<level>` only if this issue has
      no `enriched-spec:start v2` block yet (a fresh spec) — omit it on a
      re-enrichment so the persisted level survives.
   c. **Read its terminal output** and branch:
      - **`NEEDS_DECISION`** → `AskUserQuestion`, verbatim and in order, then
        re-spawn `improve-issue` with the answer as a `DECISION:` line
        (`shared/escalation.md`) and return to c.
      - **`STATUS: BLOCKED — …`** → report the reason and stop the whole run.
      - **`STATUS: SPEC_PENDING`** → the draft is complete at
        `/tmp/improve-issue-<n>-spec.md`. Do **not** read or emit the file's
        contents into this session — 94 KB of spec prose sitting in a
        long-lived root session costs every later relay turn, not just this
        one. Compute its identity and structure instead, which is what
        approval actually needs:

        ```bash
        sha256=$(shasum -a 256 /tmp/improve-issue-<n>-spec.md | cut -d' ' -f1)
        awk '/^### Section Map$/{f=1;next} f&&/^\|---/{next} f&&/^\|/{print} f&&!/^\|/{exit}' \
          /tmp/improve-issue-<n>-spec.md
        ```

        Show the human the file path, that `sha256`, the Section Map table
        just extracted, and — when the spawn emitted them — its reading aids
        verbatim: the per-section change list and the feedback item lines
        (a concise diff against the previous version; never the spec body). Call
        `ExitPlanMode` with that text as the plan, prefixed by `Store this
        enriched spec for issue #<n>.` **If this is a re-enrichment while
        sections are in flight** — `.orchestrator-state.json` lists any section
        `in_progress` or `in_review`, or the issue already has open section PRs —
        put a visible warning at the top of the plan: sections are running on
        the spec being replaced, and merging the new one may conflict with
        their local checkbox ticks (the orchestrator then halts on a
        conflicting `gh pr update-branch` and resolves nothing). The user
        decides whether to approve now or wait. A reviewer who wants the exact bytes
        reads `/tmp/improve-issue-<n>-spec.md` directly — this session was
        never where that review happened, and approving here never required
        having read it. Then:
        - **Approved** → one Bash call, with the `sha256` shown above:

          ```bash
          .claude/scripts/spec-store-write.sh <n> /tmp/improve-issue-<n>-spec.md \
            --sha256 <hex> --resolution /tmp/improve-issue-<n>-resolution.md
          ```

          The script verifies the bytes, opens the spec PR, waits for its checks
          (bounded, about 10 minutes), merges it through `merge-pr <pr-number>`,
          refreshes local `main`, and **only then** regenerates the body mirror
          and posts the resolution comment `improve-issue` drafted (skipped when
          that file is absent or empty). Run it in the foreground; it is
          bounded and does its own waiting. Branch on its last line, per
          `shared/escalation.md` § Spec-store statuses:
          `STATUS: OK …` → the spec is on `main`; the loop is done;
          `STATUS: BLOCKED — issue-unreadable` → run the same command once
          more, then report and stop the whole run if it repeats;
          `STATUS: BLOCKED — concurrent-write` → re-spawn `improve-issue` as a
          re-enrichment (no approval line, same model,
          `NON_INTERACTIVE: true`) and return to c;
          `STATUS: BLOCKED — spec-pr-open <url>`,
          `spec-pr-checks-failing`, `spec-pr-checks-pending` (PR left open) or
          `spec-merge-failed` → report the line and the PR, and stop the whole
          run; the spec is **not** stored, so step 6 never runs and nothing is
          coded; any other `BLOCKED` → report the line and stop the whole run.
          **Never proceed to coding — no re-spawn of the agent — before
          `STATUS: OK`.**
        - **Rejected with changes** → re-spawn `improve-issue` with the
          user's text verbatim under a `CHANGES:` line (same model,
          `NON_INTERACTIVE: true`); it re-drafts, re-runs its Check and Verify steps on the
          sections the change touched, and halts `SPEC_PENDING` again. Return
          to c. Approval is never inherited from the version before.
        - **Rejected, nothing supplied** → the loop is done, nothing written;
          step 4's cap applies to the next agent spawn.

6. **Re-spawn** the agent — with the user's answer
   appended as a `DECISION:` line (`shared/escalation.md`) after a
   `NEEDS_DECISION`, or with nothing new after the spec loop or a
   `WAVE_DONE` (the agent re-derives everything from the issue), then return
   to step 4.

   **Carry the same `model` on every re-spawn.**

Loop steps 4 and 6 until the agent completes, blocks, or the user stops it. A
run of `WAVE_DONE` re-spawns is the normal shape of a long issue, one per wave
of section spawns.

## What this skill does not do

- **It does not replace the manual pipeline.** `/skill improve-issue <n>` and
  friends work exactly as before, at any section, in either direction, at any
  point.
- **It does not merge directly, and it never writes a review label.** The
  merge belongs to the agent's Inline step (`next: merge`), which invokes `merge-pr`; this
  skill neither calls `gh pr merge` nor touches `approved` /
  `amends-required`. A section rests at PR opened and awaiting a review label
  — or, when a reviewer labels the PR `amends-required`, at awaiting re-review
  once the agent has run `address-pr-review`, this skill has taken the
  resulting `SPEC_PENDING` through the spec loop, and the section has gone
  back through `code-issue` → `review-issue` → `pr-from-issue`. When every
  section is waiting on something outside the run like that, the run **pauses**
  rather than ending — an ordinary `NEEDS_DECISION` (Continue / Stop), handled
  in step 4 like any other, not a new state or status.

  **It never asks whether a PR was merged.** Merge state is derived from
  `gh pr list`, and a merge the run itself performs is an act, not a question.
  The pause waits on the one thing no probe can supply: a human's label.
- **It does not write to issues directly.** The one file it touches is
  `.orchestrator-state.json`, and only its `task_id` field — everything else
  is written by `improve-issue` (which this skill spawns and approves for,
  never bypasses), by the pipeline skills the agent spawns, or by the store
  script run once after approval. The spec file is never edited here: what
  `ExitPlanMode` showed is what the script writes, and the sha is how it knows.

## Finding a run you lost track of

Read `.orchestrator-state.json` at the root of the working tree: it names the
issue, the level, every section's state, the run's own `state`, and
`last_updated`. The reading table is in
`.claude/skills/shared/orchestrator/state-file.md` under **Recovery**.

Re-launching is always safe. The agent re-derives every routing decision from
the issue, so `/orchestrate-issue <n>` resumes wherever the sections actually
stand rather than replaying a session.

## Forbidden

- Running a pipeline skill inline in this session instead of spawning it —
  `improve-issue` included. It is spawned at Spec/Review; only its
  `ExitPlanMode` approval happens here. Running it at this session's model
  would silently replace the registry's choice with whatever the user
  happens to be chatting on.
- Editing `/tmp/improve-issue-<n>-spec.md` or calling the `spec-store` skill
  from this session. The one write it makes is running
  `.claude/scripts/spec-store-write.sh`, once, only after `ExitPlanMode`
  approval, with the sha it showed.
- Writing to `main` in any way, or merging a spec PR by hand (`gh pr merge`); the
  script lands it through `merge-pr`.
- Continuing to coding (re-spawning the agent) on anything but `STATUS: OK` from the
  store script.
- Resolving a conflicting `gh pr update-branch`, here or in the agent.
- Answering a `NEEDS_DECISION` on the user's behalf, including "the default is
  obvious".
- Continuing after `PLAN_PENDING` or `BLOCKED`.
