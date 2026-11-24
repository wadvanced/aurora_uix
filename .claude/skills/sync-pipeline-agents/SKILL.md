---
name: sync-pipeline-agents
description: >
  Regenerate the issue pipeline's agent definitions — the twelve
  `pipeline-worker-<level>-<group>` agents and the `model:` / `effort:` lines of
  `epic-orchestrator` — from the model registry (`shared/coder-model.md`).
  Run by a user, by hand, after editing the registry: a changed cell, or a new
  model version being adopted. Never invoked by another skill, by an agent, or
  automatically.
disable-model-invocation: true
---

# Skill: sync-pipeline-agents

`../shared/coder-model.md` is the only place a pipeline model, version or effort is
decided. The harness cannot read it: a spawned run takes its exact model and effort
from the agent definition it is spawned as, so each registry cell exists as an agent
in `.claude/agents/`. This skill is the one way those agents are written.

It is deliberately manual. Adopting a model version is a decision a person makes by
editing the registry; a pipeline run that regenerated its own agents would turn a
mismatch — the signal that the registry and the agents disagree — into a silent
rewrite. `orchestrate-issue` only ever **checks**, and halts.

## Steps

1. **Confirm the registry is what the user means to adopt.** Read
   `../shared/coder-model.md` § Level → models and § Model versions and state, in one
   short table, the model ID and effort each of the four groups resolves to at each
   level. Do not edit the registry here — if it is not yet what the user wants, stop
   and say so.

2. **Regenerate.**

   ```bash
   .claude/scripts/pipeline-agents.sh generate
   ```

   Branch on its last line:
   - `STATUS: OK — …` → continue.
   - `STATUS: BLOCKED — registry-unreadable (…)` → report the line and stop. The
     registry has a malformed cell, a family with no Model versions row, or a
     Coordination row that differs across levels; that is fixed in the registry.

3. **Verify.**

   ```bash
   .claude/scripts/pipeline-agents.sh check
   git status --short .claude/agents
   ```

   The check must end `STATUS: OK`. Report the files `git status` lists.

4. **Hand back.** Tell the user which agents changed and that the change is
   uncommitted. Committing follows the usual flow — never commit from this skill
   unasked.

## Forbidden

- Editing a file in `.claude/agents/` by hand to make the check pass. The registry
  is edited; the agents are generated.
- Running `pipeline-agents.sh generate` from any other skill or from an agent.
