#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Rejects the ways a long command was observed
# being run badly — shell-backgrounded gates, a direct `mix consistency`, an
# unwrapped full suite, and poll loops — and points at the one sanctioned shape:
# start it with `run_in_background`, then one foreground `wait-verdict.sh`.
# A rejection is a message on stderr and exit code 2; everything else exits 0.
#
# A hook cannot tell a pipeline session from a human-directed one, so a command
# containing `GATE_DIRECT=1` is always allowed.
set -uo pipefail

command_text=$(jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0
[ -n "$command_text" ] || exit 0

case "$command_text" in
  *GATE_DIRECT=1* | .claude/scripts/wait-verdict.sh*) exit 0 ;;
esac

reject() {
  echo "$1" >&2
  exit 2
}

matches() {
  printf '%s' "$command_text" | grep -Eq "$1"
}

long_command_pattern='gate\.sh|suite\.sh|spec-store-write\.sh|mix test|mix consistency'
shell_background_pattern='[^&]&[[:space:]]*$'

# a — shell-backgrounded long command
if matches "$long_command_pattern" && { matches 'nohup' || matches "$shell_background_pattern"; }; then
  reject "Do not shell-background this. Pass the plain command to Bash with run_in_background: true, then run .claude/scripts/wait-verdict.sh <gate|suite|spec-<n>> in the foreground."
fi

# b — direct consistency run. Anchored to where a command starts, so a commit
# message or grep that merely mentions `mix consistency` is not rejected.
if matches '(^|[;&|][[:space:]]*)([A-Z_]+=[^[:space:]]*[[:space:]]+)*mix consistency'; then
  reject "Use .claude/scripts/gate.sh (run_in_background: true), then .claude/scripts/wait-verdict.sh gate."
fi

# c — full suite: `mix test` followed by end of command or only by flags
full_suite_pattern='mix test([[:space:]]+-[^[:space:]]*)*[[:space:]]*($|[;&|])'
targeted_pattern='\.exs([:0-9]*)([[:space:]]|$)|[[:space:]]test/|--failed|--stale'
if matches "$full_suite_pattern" && ! matches "$targeted_pattern"; then
  reject "Full suite: use .claude/scripts/suite.sh (run_in_background: true), then .claude/scripts/wait-verdict.sh suite. Targeted runs (a file, --failed) are fine."
fi

# d — poll shapes
if matches '^[[:space:]]*sleep[[:space:]]+[0-9.]+[smhd]?[[:space:]]*(&&[[:space:]]*echo .*)?$' ||
  matches 'pgrep|ps -p' ||
  { matches 'kill -0' && matches 'sleep|while|until'; }; then
  reject "Do not poll. Run .claude/scripts/wait-verdict.sh <gate|suite|spec-<n>> once in the foreground; on STILL_RUNNING run it again."
fi

exit 0
