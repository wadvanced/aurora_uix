import { Plugin } from "@opencode/plugin"

// OpenCode form of `.claude/hooks/guard-long-commands.sh` (a Claude PreToolUse
// hook on Bash). Rejects the ways a long command was observed being run badly —
// shell-backgrounded gates, a direct `mix consistency`, an unwrapped full suite,
// and poll shapes — and points at the one sanctioned shape: start it with the
// shell tool's `background: true`, then one foreground `wait-verdict.sh`.
//
// A plugin cannot tell a pipeline session from a human-directed one, so a
// command containing `GATE_DIRECT=1` is always allowed.

const LONG_COMMAND = /gate\.sh|suite\.sh|spec-store-write\.sh|mix test|mix consistency/
const SHELL_BACKGROUND = /[^&]&\s*$/m

/**
 * Returns a rejection message for a command that must not be run as written,
 * or `undefined` when the command is fine.
 */
function rejection(command: string): string | undefined {
  if (command.includes("GATE_DIRECT=1") || command.includes(".claude/scripts/wait-verdict.sh")) {
    return undefined
  }

  const matches = (pattern: RegExp) => pattern.test(command)
  const targeted = () => /\.exs([:0-9]*)(\s|$)/m.test(command) || /\stest\/|--failed|--stale/.test(command)

  if (matches(LONG_COMMAND) && (matches(/nohup/) || matches(SHELL_BACKGROUND))) {
    return "Do not shell-background this. Pass the plain command to the shell tool with background: true, then run .claude/scripts/wait-verdict.sh <gate|suite|spec-<n>> in the foreground."
  }

  if (matches(/(^|[;&|]\s*)([A-Z_]+=\S*\s+)*mix consistency/m)) {
    return "Use .claude/scripts/gate.sh (background: true), then .claude/scripts/wait-verdict.sh gate."
  }

  if (matches(/mix test(\s+-[^\s]*)*\s*($|[;&|])/m) && !targeted()) {
    return "Full suite: use .claude/scripts/suite.sh (background: true), then .claude/scripts/wait-verdict.sh suite. Targeted runs (a file, --failed) are fine."
  }

  if (
    matches(/^\s*sleep\s+[0-9.]+[smhd]?\s*(&&\s*echo .*)?$/m) ||
    matches(/pgrep|ps -p/) ||
    (matches(/kill -0/) && matches(/sleep|while|until/))
  ) {
    return "Do not poll. Run .claude/scripts/wait-verdict.sh <gate|suite|spec-<n>> once in the foreground; on STILL_RUNNING run it again."
  }

  return undefined
}

export default Plugin.define({
  id: "aurora-uix.guard-long-commands",
  async setup(ctx) {
    await ctx.permission.hook("evaluate", (event) => {
      if (event.action !== "shell") return

      for (const command of event.resources) {
        const message = rejection(command)
        if (!message) continue

        event.effect = "deny"
        event.message = message
        return
      }
    })
  },
})
