#!/usr/bin/env bash
# Runs the FULL `mix test` suite with the same log/verdict shape as gate.sh, so it
# can be started with `run_in_background` and waited on with
# `wait-verdict.sh suite` instead of being polled. Targeted runs stay direct
# (`mix test <file>`, `mix test --failed`) or go through section-test.sh.
#
# Usage: suite.sh [<mix test flags>...]   (a path argument is refused)
#
# Output contract (the only thing ever printed to stdout; also written to
# /tmp/suite-<branch>.verdict, which is deleted at the start of each run):
#   success   -> the log's summary line (`N tests, 0 failures…`), then `EXIT: 0`
#   failure   -> `STAGE: test`, the log's last 60 lines, then `EXIT: <code>`
#   refused   -> `EXIT: 64`  (a path argument was given)
#
# Full output always lands in /tmp/suite-<branch>.log.
#
# The test database is the checkout's private PostgreSQL (scripts/test_pg.sh);
# `mix test` provisions it itself, so nothing is set up here. Migrations are NOT
# run by `mix test` — run `mix ecto.migrate` (MIX_ENV=test) first in a fresh checkout.
set -uo pipefail

export MIX_ENV=test

branch=$(git branch --show-current 2>/dev/null | tr '/' '-')
branch=${branch:-detached}
log="/tmp/suite-${branch}.log"
verdict="/tmp/suite-${branch}.verdict"
rm -f "$verdict"

emit() {
  printf '%s\n' "$1" | tee -a "$verdict"
}

for argument in "$@"; do
  case "$argument" in
    *.exs | *.exs:[0-9]* | test/* | */test/*)
      emit "suite.sh runs the full suite; run a targeted test directly (mix test <file>) or via section-test.sh."
      emit "EXIT: 64"
      exit 64
      ;;
  esac
done

mix test "$@" >"$log" 2>&1
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
  summary=$(grep -E '^[0-9]+ (doctests?, )?[0-9]* ?(properties, )?[0-9]* ?tests?, ' "$log" | tail -n 1)
  [ -n "$summary" ] && emit "$summary"
  emit "EXIT: 0"
else
  emit "STAGE: test"
  emit "$(tail -n 60 "$log")"
  emit "EXIT: ${exit_code}"
fi
exit "$exit_code"
