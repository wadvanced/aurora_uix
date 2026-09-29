#!/usr/bin/env bash
# Runs the same stages as mix.exs's `consistency` alias, one `mix` invocation per
# stage, so a failure is reported as its own STAGE with only that stage's last
# 40 log lines — not the full `mix consistency` output. The environment is left
# at Mix's default (:dev), exactly as `mix consistency` and CI run it.
#
# Output contract (the only thing ever printed to stdout):
#   success                 -> `EXIT: 0`
#   failure                 -> `STAGE: <name>`, then the log's last 40 lines, then `EXIT: <code>`
#   docs/spec-only changes  -> `SKIPPED: docs/spec-only changes`, then `EXIT: 0`
#
# Full stage-by-stage output always lands in /tmp/gate-<branch>.log. Everything
# printed to stdout is also written to /tmp/gate-<branch>.verdict, which
# `wait-verdict.sh gate` blocks on; the verdict is deleted at the start of each
# run, so its existence with a last line of `EXIT: <code>` means this run ended.
set -uo pipefail

branch=$(git branch --show-current 2>/dev/null | tr '/' '-')
branch=${branch:-detached}
log="/tmp/gate-${branch}.log"
verdict="/tmp/gate-${branch}.verdict"
: >"$log"
rm -f "$verdict"

# Prints to stdout and appends to the verdict file, so a waiter sees the same lines.
emit() {
  printf '%s\n' "$1" | tee -a "$verdict"
}

# A diff made only of documentation, images and specs cannot change any
# consistency stage's outcome relative to origin/main, which is always green
# (merge-pr only ever merges a gated PR). The exemption set is the one CI's
# `code` filter uses (.github/workflows/ci.yml): everything else, including
# `.claude/**` scripts, still runs the full gate. Three separate git calls
# rather than parsing `--porcelain`, which mishandles renames.
changed_files=$(
  {
    git diff --name-only origin/main...HEAD 2>/dev/null
    git diff --name-only HEAD 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | sort -u
)
if ! printf '%s\n' "$changed_files" |
  grep -vE '(^|/)[^/]+\.md$|(^|/)LICENSE$|\.(png|jpe?g|gif|svg)$|^specs/|^$' |
  grep -q .; then
  emit "SKIPPED: docs/spec-only changes"
  emit "EXIT: 0"
  exit 0
fi

# Keep in sync with the `consistency` alias in mix.exs.
stage_names=(
  "auix.gen.tailwind_classes"
  "format"
  "compile --warnings-as-errors"
  "credo --strict"
  "dialyzer"
  "doctor"
)
stage_cmds=(
  "auix.gen.tailwind_classes"
  "format"
  "compile --warnings-as-errors"
  "credo --strict --format oneline"
  "dialyzer --quiet"
  "doctor"
)

for i in "${!stage_cmds[@]}"; do
  echo "=== mix ${stage_cmds[$i]} ===" >>"$log"
  # shellcheck disable=SC2086
  mix ${stage_cmds[$i]} >>"$log" 2>&1
  exit_code=$?
  if [ "$exit_code" -ne 0 ]; then
    emit "STAGE: ${stage_names[$i]}"
    emit "$(tail -n 40 "$log")"
    emit "EXIT: ${exit_code}"
    exit "$exit_code"
  fi
done

emit "EXIT: 0"
