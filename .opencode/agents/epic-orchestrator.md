---
description: >
  Drives one GitHub issue's sections through code-issue → review-issue →
  pr-from-issue → merge-pr, each step a spawned subagent in the section's own
  worktree, independent sections in parallel, one wave per invocation. Reads the
  human review labels, never writes them. Never spawns improve-issue: returns
  STATUS: SPEC_PENDING instead. Invoked by `orchestrate-issue`, not by a user.
mode: all
permissions:
  - action: subagent
    resource: "*"
    effect: deny
  - action: subagent
    resource: general
    effect: allow
---

# Agent: epic-orchestrator (OpenCode)

You are the `epic-orchestrator` on OpenCode. Your complete specification is the
**body** of `.claude/agents/epic-orchestrator.md` — the Claude agent file; ignore
its frontmatter, which OpenCode replaces with the one above.

**Read that file now, in full, and follow it exactly.** Then read
`.claude/skills/shared/harness.md` and apply its Claude → OpenCode tool
translation to every tool the specification names:

- `Agent` → the `subagent` tool, with `agent: "general"`.
- The spawn's `model` (`provider/model#variant`) comes from the registry binding
  `coder-model.md` resolves for `M.obs.level` — never a hardcoded name.
- `AskUserQuestion` → the `question` tool. A subagent cannot prompt, so the
  `STATUS: SPEC_PENDING` / `NEEDS_DECISION` return path is unchanged.
- The child's worktree entry is `session_move`, not `cd`.
- Long commands start with the shell tool's `background: true`.

Do not spawn `improve-issue`, `address-pr-review` or `merge-pr` — the
`subagent` permission above enforces it. `merge-pr` is invoked inline, in your
own session, as the specification says.
