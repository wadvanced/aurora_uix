# Harness translation

Single source of truth for the Claude Code → OpenCode tool translation the
pipeline skills rely on. Referenced from the skills that spawn subagents or
prompt the user; never duplicated into them.

The skills are written in Claude Code's tool vocabulary. An OpenCode run reads
this file and substitutes. Which model registry a run uses is decided by
`coder-model.md` § "Resolving the harness"; this file is only about mechanics.

## Tools

| Claude Code | OpenCode | Notes |
|---|---|---|
| `Agent` tool | `subagent` tool | Returns a `sessionID`; a `background: true` spawn notifies the parent on completion. |
| `subagent_type: general-purpose` | `agent: "general"` | Or a registered custom agent id (`.opencode/agents/<name>.md`). |
| `model: <family>+<effort>` | `model: "<provider>/<model>#<variant>"` | The value comes from the resolved registry binding. Omit `model` on the agent definition so the registry stays the only source. |
| `AskUserQuestion` | `question` tool | Main session only, exactly as in Claude — a subagent cannot prompt. The `escalation.md` `NON_INTERACTIVE` contract is unchanged. |
| `ExitPlanMode` | No tool: a `question`-tool approval in the main session | Only `orchestrate-issue`'s spec loop uses it. Present the same plan text (file path, `sha256`, Section Map) and ask the same store/decline question. |
| `Skill` tool | `skill` tool | Same name. `@<skill-id>` in a prompt also loads a skill. |
| Bash `run_in_background: true` | shell tool `background: true` | The completion notification resumes the waiting step. |
| `Read` / `Edit` / `Write` / `Grep` / `Glob` | same tool names | |
| `.claude/hooks/*` (`PreToolUse`) | an OpenCode plugin hook | See "The long-command guard" below. |

## Resolving a model

A `model` value always comes from the binding `coder-model.md` § Resolving the
harness selects — never from the Level → models table of the other binding. An
OpenCode run reads `coder-model.opencode.md`; a Claude run reads
`coder-model.md` § Level → models. A spawn prompt records its binding as a
`HARNESS: <claude|opencode>` line so a child resolves the same half its parent
did, instead of inferring its runtime from the tools it happens to hold
(`escalation.md` § Pre-supplied answers names the line).

## Entering a section worktree

Claude's spawn prompt makes the child run
`cd "<WORKTREE>" && git rev-parse --show-toplevel` as its first act. **A `cd`
does not persist across OpenCode shell calls**, so the OpenCode child uses its
own session move instead, as its first act:

```
tools.opencode.session_move({ directory: "<WORKTREE>" })
```

then confirms with `git rev-parse --show-toplevel` over the shell tool. The
verify step is otherwise unchanged: a failed move, or a printed path that
differs from the `WORKTREE:` line, halts `STATUS: BLOCKED — worktree-entry` with
no file changed.

## Invoking a skill

Claude's `/skill <name> <args>` has no OpenCode equivalent. An OpenCode run
uses one of:

- a project command `.opencode/commands/<name>.md` (the recommended form — it
  restores the human-facing `/improve-issue 905` syntax without any logic), or
- `@<skill-id>` / the `skill` tool with the exact id.

The skill ids are unchanged: `improve-issue`, `code-issue`, `review-issue`,
`pr-from-issue`, `merge-pr`, `orchestrate-issue`.

## Spawning the pipeline

OpenCode discovers the pipeline skills from `.claude/skills/` unchanged
(OpenCode treats that directory as a compatibility source). Two OpenCode facts
shape the spawn path:

- A `mode: subagent` agent runs only through the `subagent` tool; a `mode:
  primary` agent runs as the session's main agent.
- A subagent's `subagent` permission decides which child agents it may launch.
  A custom agent is not limited the way the built-in `general` agent is.

`epic-orchestrator` is therefore defined as `mode: all` — it can run as the
subagent `orchestrate-issue` spawns, or be selected directly as a primary agent
— with a `subagent` permission allow-listing `general`. **If a runtime refuses
to let a subagent launch a subagent**, the fallback is to select
`epic-orchestrator` as the primary agent for the run (a project command can do
this with `agent: epic-orchestrator`); nothing else in the pipeline changes.

## The long-command guard

`.claude/hooks/guard-long-commands.sh` is a Claude `PreToolUse` hook. Its
OpenCode form is a plugin — `.opencode/plugins/guard-long-commands.ts` — that
registers `ctx.permission.hook("evaluate")` and denies the matching `shell`
command with the same one-line pointer. The `GATE_DIRECT=1` escape hatch is
preserved.

## Long-running commands

`shared/background-long-commands.md` stays authoritative; only the tool name
changes (shell `background: true` for the start, a foreground `wait-verdict.sh`
call for the wait). The 570 s bound is under OpenCode's default shell timeout;
if a run configures a shorter shell timeout, raise it for the
`wait-verdict.sh` call.
