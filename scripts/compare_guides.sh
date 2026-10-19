#!/usr/bin/env bash
#
# Checks that the guide screens look as they did in a baseline version. Run it by hand for
# structural changes that must not change the rendered UI; `mix test` and CI never run it.
#
#   scripts/compare_guides.sh                  # compares with the `guides-baseline` tag
#   scripts/compare_guides.sh <baseline-ref>   # compares with any other ref
#
# Move `guides-baseline` forward when an accepted change is meant to alter the screens.
#
# Captures the guide screenshots from the baseline ref in a temporary worktree, then captures them
# again from this checkout in compare mode (AURORA_UIX_CAPTURES=compare, see
# test/guides/image_helper.exs). Both sets are temporary: the committed images are untouched, the
# current captures and any -diff.png land in tmp/captures/, and the worktree is removed at the end
# (pass KEEP_BASELINE=1 to keep it). Both runs happen on this machine, so fonts and anti-aliasing
# match.

set -euo pipefail

ref="${1:-guides-baseline}"
root=$(git rev-parse --show-toplevel)
baseline="$root/tmp/compare_guides_baseline"

cleanup() {
  if [ "${KEEP_BASELINE:-}" != "1" ] && [ -d "$baseline" ]; then
    (cd "$baseline" && scripts/test_pg.sh destroy >/dev/null 2>&1 || true)
    git -C "$root" worktree remove --force "$baseline"
  fi
}
trap cleanup EXIT

[ -d "$baseline" ] && git -C "$root" worktree remove --force "$baseline"
git -C "$root" worktree add --detach "$baseline" "$ref" >/dev/null

capture() {
  mix deps.get >/dev/null
  mix assets.setup >/dev/null
  mix assets.build >/dev/null
  MIX_ENV=test mix ecto.create >/dev/null
  MIX_ENV=test mix ecto.migrate >/dev/null
  mix test test/guides/capture_*.exs "$@"
}

echo "== capturing the baseline from $ref"
(cd "$baseline" && capture) || echo "warning: some baseline captures failed; their screens will report as not compared"

echo "== comparing this checkout with $ref"
rm -rf "$root/tmp/captures"
cd "$root"
AURORA_UIX_CAPTURES=compare AURORA_UIX_CAPTURES_BASELINE="$baseline" capture
