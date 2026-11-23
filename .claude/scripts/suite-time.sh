#!/usr/bin/env bash
# Compares the full-suite time of this checkout with the time of a reference checkout of the
# original suite, run back to back so both see the same machine load.
#
# Usage: suite-time.sh <reference-dir> [<runs>]     (runs defaults to 5; an odd number)
#
# Warms both checkouts (a run that excludes every test, so a recompile is not timed), then runs
# `mix test` in <reference-dir> and in the current directory, alternating, <runs> times each.
# Every run gives two seconds: `Finished in` of the ExUnit summary, and `real` of the whole
# command (VM start, test helper and tests). A run with a failure is not a timing: the run is
# repeated, up to three times, and the script stops with EXIT: 3 when all three fail (the
# original suite has one browser feature that fails now and then).
#
# Output (stdout, also /tmp/suite-time-<branch>.verdict):
#   finished reference: <seconds>... median <m>
#   finished candidate: <seconds>... median <m>
#   real reference: <seconds>... median <m>
#   real candidate: <seconds>... median <m>
#   PASS | FAIL      then      EXIT: 0 | 1
#   EXIT: 3 (a run failed or printed no time), EXIT: 64 (bad argument)
# PASS means the candidate median is not greater than the reference median, for both seconds.
#
# `mix test` provisions the test database of each checkout itself; run `mix ecto.migrate`
# (MIX_ENV=test) in a fresh reference checkout first.
set -uo pipefail

export MIX_ENV=test

reference="${1:-}"
runs="${2:-5}"
branch=$(git branch --show-current 2>/dev/null | tr '/' '-')
branch=${branch:-detached}
verdict="/tmp/suite-time-${branch}.verdict"
rm -f "$verdict"

emit() {
  printf '%s\n' "$1" | tee -a "$verdict"
}

case "$runs" in
  '' | *[!0-9]* | 0)
    emit "usage: suite-time.sh <reference-dir> [<odd runs>]"
    emit "EXIT: 64"
    exit 64
    ;;
esac
if [ $((runs % 2)) -eq 0 ] || [ ! -d "$reference" ]; then
  emit "usage: suite-time.sh <reference-dir> [<odd runs>]"
  emit "EXIT: 64"
  exit 64
fi

candidate="$(pwd)"
work=$(mktemp -d)
finished_reference=""
finished_candidate=""
real_reference=""
real_candidate=""

# Prints the `Finished in` seconds of a log, or nothing when the run had a failure.
finished_of() {
  grep -qE '^[0-9]+ (doctests?, )?[0-9]* ?(properties, )?[0-9]* ?(features?, )?[0-9]* ?tests?, 0 failures' "$1" || return 1
  grep -oE 'Finished in [0-9.]+' "$1" | tail -n 1 | grep -oE '[0-9.]+'
}

real_of() {
  grep -E '^real ' "$1" | tail -n 1 | grep -oE '[0-9.]+'
}

median_of() {
  tr ' ' '\n' | grep -v '^$' | sort -n | awk '{ v[NR] = $1 } END { print v[int((NR + 1) / 2)] }'
}

for dir in "$reference" "$candidate"; do
  (cd "$dir" && mix test --exclude test --exclude feature >/dev/null 2>&1)
done

for i in $(seq 1 "$runs"); do
  for side in reference candidate; do
    dir="$candidate"
    [ "$side" = reference ] && dir="$reference"
    log="$work/${side}-${i}.log"
    finished=""
    for attempt in 1 2 3; do
      (cd "$dir" && /usr/bin/time -p mix test) >"$log" 2>&1
      finished=$(finished_of "$log") && real=$(real_of "$log") && break
      finished=""
    done
    if [ -z "$finished" ]; then
      emit "run $i of $side failed three times: $log"
      emit "EXIT: 3"
      exit 3
    fi
    if [ "$side" = reference ]; then
      finished_reference="$finished_reference $finished"
      real_reference="$real_reference $real"
    else
      finished_candidate="$finished_candidate $finished"
      real_candidate="$real_candidate $real"
    fi
  done
done

finished_reference_median=$(printf '%s' "$finished_reference" | median_of)
finished_candidate_median=$(printf '%s' "$finished_candidate" | median_of)
real_reference_median=$(printf '%s' "$real_reference" | median_of)
real_candidate_median=$(printf '%s' "$real_candidate" | median_of)

emit "finished reference:${finished_reference} median ${finished_reference_median}"
emit "finished candidate:${finished_candidate} median ${finished_candidate_median}"
emit "real reference:${real_reference} median ${real_reference_median}"
emit "real candidate:${real_candidate} median ${real_candidate_median}"

not_greater() {
  awk -v c="$1" -v r="$2" 'BEGIN { exit !(c <= r) }'
}

if not_greater "$finished_candidate_median" "$finished_reference_median" &&
  not_greater "$real_candidate_median" "$real_reference_median"; then
  emit "PASS"
  emit "EXIT: 0"
  exit 0
fi

emit "FAIL"
emit "EXIT: 1"
exit 1
