#!/usr/bin/env bash
# Runs a targeted `mix test` for `code-issue` and counts it against a per-spawn
# budget, so a long debugging session ends in a checkpoint instead of growing to
# 500k of context. A spawn cannot see its own context size; it can be made to
# run every targeted test through here, and this script counts them.
#
# Usage: section-test.sh [--reset] [<mix test args>...]
#   --reset alone   deletes the counter                 -> `BUDGET: 0/<budget>` only, exit code 0
#   --reset + args  deletes the counter, then runs the tests below
#   no arguments    refuses: the full suite is not a targeted run
#
# Output contract (mix's own output is streamed unchanged; the LAST TWO lines are):
#   under budget  -> `BUDGET: <k>/<budget>`,                                              `EXIT: <mix exit code>`
#   at/over it    -> `BUDGET: EXHAUSTED — checkpoint now (code-issue Step 6 § Checkpoint)`, `EXIT: <mix exit code>`
#   refused       -> `EXIT: 64`
#
# The budget is counted per branch in /tmp/section-budget-<branch, / -> ->; it is
# reset by `code-issue` at the start of each spawn, so a re-spawn gets a fresh one.
set -uo pipefail

# The only place the number lives; tune it when a measurement says so.
budget=6

export MIX_ENV=test

branch=$(git branch --show-current 2>/dev/null | tr '/' '-')
branch=${branch:-detached}
counter="/tmp/section-budget-${branch}"

reset_requested=false
if [ "${1:-}" = "--reset" ]; then
  reset_requested=true
  shift
  rm -f "$counter"
fi

if [ "$#" -eq 0 ]; then
  if [ "$reset_requested" = true ]; then
    echo "BUDGET: 0/${budget}"
    exit 0
  fi
  echo "section-test.sh runs a targeted test: pass a file, file:line, or other mix test args."
  echo "EXIT: 64"
  exit 64
fi

mix test "$@"
exit_code=$?

runs=$(cat "$counter" 2>/dev/null || echo 0)
case "$runs" in
  '' | *[!0-9]*) runs=0 ;;
esac
runs=$((runs + 1))
echo "$runs" >"$counter"

if [ "$runs" -ge "$budget" ]; then
  echo "BUDGET: EXHAUSTED — checkpoint now (code-issue Step 6 § Checkpoint)"
else
  echo "BUDGET: ${runs}/${budget}"
fi
echo "EXIT: ${exit_code}"
exit "$exit_code"
