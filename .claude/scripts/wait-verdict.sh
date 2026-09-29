#!/usr/bin/env bash
# The one sanctioned wait for a backgrounded `gate.sh`, `suite.sh` or
# `spec-store-write.sh`. Start the command with Bash's `run_in_background`, then
# call this ONCE in the foreground: it blocks until the command's verdict file
# ends in an `EXIT:` line, prints the verdict, and returns. On timeout it prints
# `STILL_RUNNING` — call it again.
#
# Usage: wait-verdict.sh <gate|suite|spec-<issue-number>> [timeout-seconds=570]
#   570 s stays under the Bash tool's 600 s ceiling.
#   gate / suite  -> /tmp/<kind>-<branch>.verdict   (branch of the current checkout)
#   spec-<n>      -> /tmp/spec-<n>.verdict          (written by spec-store-write.sh <n> …)
#
# Output contract: the verdict file's contents (last line `EXIT: <code>`), or the
# single line `STILL_RUNNING`. Exit code 0 in both cases; 64 on a bad argument.
set -uo pipefail

kind="${1:-}"
timeout_seconds="${2:-570}"

case "$kind" in
  gate | suite)
    branch=$(git branch --show-current 2>/dev/null | tr '/' '-')
    branch=${branch:-detached}
    verdict="/tmp/${kind}-${branch}.verdict"
    ;;
  spec-[0-9]*)
    case "${kind#spec-}" in
      *[!0-9]*)
        echo "usage: wait-verdict.sh <gate|suite|spec-<issue-number>> [timeout-seconds]"
        exit 64
        ;;
    esac
    verdict="/tmp/${kind}.verdict"
    ;;
  *)
    echo "usage: wait-verdict.sh <gate|suite|spec-<issue-number>> [timeout-seconds]"
    exit 64
    ;;
esac

case "$timeout_seconds" in
  '' | *[!0-9]*)
    echo "usage: wait-verdict.sh <gate|suite|spec-<issue-number>> [timeout-seconds]"
    exit 64
    ;;
esac

waited=0
while [ "$waited" -lt "$timeout_seconds" ]; do
  if [ -f "$verdict" ] && tail -n 1 "$verdict" | grep -q '^EXIT:'; then
    cat "$verdict"
    exit 0
  fi
  sleep 5
  waited=$((waited + 5))
done

echo "STILL_RUNNING"
exit 0
