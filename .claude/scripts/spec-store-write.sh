#!/usr/bin/env bash
# The one implementation of a whole-spec write: `spec-store` Mode `write`, and
# `orchestrate-issue`'s Approved branch. Both call this script, so the manual
# path and the orchestrated path cannot drift.
#
# Nothing is ever written to `main` directly: aurora_uix's ruleset requires a
# pull request and a green `Build and test (1.19.4-otp-28, 28.2)`. A spec is
# stored by branch -> PR -> merge, and it is not "stored" until that PR has
# merged, because `spec-load` reads `main`.
#
# ┌─ TWO-PHASE CONTRACT ────────────────────────────────────────────────────────┐
# │ `merge-pr` is the single merge authority, and a shell script cannot invoke  │
# │ a skill, so the merge sits BETWEEN two invocations of this script:          │
# │                                                                             │
# │  1. spec-store-write.sh <n> <spec-file> [--sha256 <hex>]      (write mode)  │
# │       merged-section guard -> branch spec/<n>-enriched-spec from origin/    │
# │       main -> commit -> non-draft PR -> wait for green checks (one         │
# │       `gh pr update-branch` if BEHIND).  Ends `STATUS: OK-PR-READY <pr>`.   │
# │  2. the CALLER runs the `merge-pr` skill in direct mode: `merge-pr <pr>`.   │
# │  3. spec-store-write.sh <n> --finish <pr> [--resolution <file>]             │
# │       (finish mode) confirms the PR merged, refreshes local main,           │
# │       regenerates the issue-body mirror, posts the resolution comment.      │
# │       Ends `STATUS: OK <merge-commit-sha>`.                                 │
# │                                                                             │
# │ ONLY `STATUS: OK <sha>` means the spec is stored. `STATUS: OK-PR-READY` is  │
# │ exit 0 too but is NOT done: the caller must not continue to coding on it.   │
# │ Identical spec: when the file already equals main's copy there is nothing   │
# │ to merge; write mode repairs the mirror and prints `STATUS: OK <main-sha>`  │
# │ directly (skip steps 2-3).                                                  │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# Usage:
#   spec-store-write.sh <n> <spec-file> [--sha256 <hex>] [--resolution <file>]
#   spec-store-write.sh <n> --finish <pr-number> [--resolution <file>]
#   --sha256 <hex>       write mode: refuse unless `shasum -a 256 <spec-file>`
#                        equals <hex> (the bytes on disk are the bytes approved)
#   --resolution <file>  posted as one issue comment (spec-defect-resolved /
#                        review-feedback-resolved markers, drafted by
#                        improve-issue before approval) once the spec is stored:
#                        by --finish, or by write mode in the identical-spec case.
#                        Skipped when an identical comment is already on the issue.
#
# Output contract: progress lines may precede it; the LAST stdout line is
# exactly one of
#   STATUS: OK <sha>                              (exit 0 — stored: merge commit, or main's tip if identical)
#   STATUS: OK-PR-READY <pr-number>               (exit 0 — write mode only; run merge-pr <pr>, then --finish)
#   STATUS: BLOCKED — approved-spec-mismatch      (--sha256 differs; nothing written)
#   STATUS: BLOCKED — merged-section-modified     (a changed section's PR is merged; nothing written)
#   STATUS: BLOCKED — spec-pr-open <url>          (an open spec PR for this issue exists; nothing written)
#   STATUS: BLOCKED — concurrent-write            (PR CONFLICTING: main's copy changed; PR closed, branch
#                                                  deleted; re-run from a fresh read)
#   STATUS: BLOCKED — spec-pr-checks-failing <url>  (a check failed/cancelled; PR left open)
#   STATUS: BLOCKED — spec-pr-checks-pending <url>  (checks did not finish in the wait budget; PR left open;
#                                                  merge-pr <pr> then --finish when they do)
#   STATUS: BLOCKED — spec-merge-failed           (still BEHIND after the one update-branch, or --finish found
#                                                  the PR not merged; PR left open)
#   STATUS: BLOCKED — issue-unreadable            (spec merged, body mirror/comment not; re-run --finish)
#   STATUS: BLOCKED — spec-write-failed           (any other failure, or an unusable input; see the output above)
# Every BLOCKED path exits 1.
#
# Everything printed is also written to /tmp/spec-<n>.verdict with a final
# `EXIT: <code>` line, so a `run_in_background` run can be waited on with
# `.claude/scripts/wait-verdict.sh spec-<n>` (the checks wait alone can take
# up to SPEC_STORE_CHECK_BUDGET seconds, beyond a foreground Bash call).
#
# Environment (all optional): SPEC_STORE_REPO (default wadvanced/aurora_uix),
# SPEC_STORE_CHECK_BUDGET (seconds, default 600), SPEC_STORE_POLL (seconds, default 15),
# SPEC_STORE_COAUTHOR (the commit's Co-Authored-By trailer value).
set -uo pipefail

REPO="${SPEC_STORE_REPO:-wadvanced/aurora_uix}"
CHECK_BUDGET="${SPEC_STORE_CHECK_BUDGET:-600}"
POLL="${SPEC_STORE_POLL:-15}"
COAUTHOR="${SPEC_STORE_COAUTHOR:-Claude Sonnet 5.5 <noreply@anthropic.com>}"

usage() {
  echo "usage: spec-store-write.sh <n> <spec-file> [--sha256 <hex>] [--resolution <file>]" >&2
  echo "       spec-store-write.sh <n> --finish <pr-number> [--resolution <file>]" >&2
  echo "STATUS: BLOCKED — spec-write-failed"
  exit 1
}

[ $# -ge 2 ] || usage
issue_number="$1"
case "$issue_number" in '' | *[!0-9]*) usage ;; esac

# Outer wrapper: mirror everything into the verdict file `wait-verdict.sh spec-<n>`
# blocks on. Re-executes this script so every line — including gh's stderr — is captured.
if [ -z "${SPEC_STORE_INNER:-}" ]; then
  verdict="/tmp/spec-${issue_number}.verdict"
  rm -f "$verdict" "$verdict.tmp"
  SPEC_STORE_INNER=1 bash "$0" "$@" 2>&1 | tee "$verdict.tmp"
  code=${PIPESTATUS[0]}
  { cat "$verdict.tmp"; echo "EXIT: ${code}"; } >"$verdict.new" && mv "$verdict.new" "$verdict"
  rm -f "$verdict.tmp"
  exit "$code"
fi

for tool in gh jq shasum base64; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "❌ '$tool' is required and was not found on PATH."
    echo "STATUS: BLOCKED — spec-write-failed"
    exit 1
  }
done

mode=write
NEW=""
finish_pr=""
expected_sha256=""
resolution_file=""
shift
if [ "$1" = "--finish" ]; then
  mode=finish
  [ $# -ge 2 ] || usage
  finish_pr="$2"
  case "$finish_pr" in '' | *[!0-9]*) usage ;; esac
  shift 2
else
  NEW="$1"
  shift
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --sha256) [ "$mode" = write ] && [ $# -ge 2 ] || usage; expected_sha256="$2"; shift 2 ;;
    --resolution) [ $# -ge 2 ] || usage; resolution_file="$2"; shift 2 ;;
    *) usage ;;
  esac
done

SPEC_PATH="specs/issue-${issue_number}-enriched-spec.md"
BRANCH="spec/${issue_number}-enriched-spec"
API="repos/${REPO}/contents/${SPEC_PATH}"
CUR="/tmp/spec-store-${issue_number}-current.md"

blocked() { # $1 = reason (may carry an argument), rest = human-readable lines
  local reason="$1"
  shift
  local line
  for line in "$@"; do echo "$line"; done
  echo "STATUS: BLOCKED — ${reason}"
  exit 1
}

delete_branch() {
  gh api --method DELETE "repos/${REPO}/git/refs/heads/${BRANCH}" >/dev/null 2>&1 || true
}

# ── Mirror + resolution (shared by both modes) ───────────────────────────────

publish_mirror() { # $1 = the spec file whose Section Map is mirrored
  local spec="$1"
  local tmp_body="/tmp/spec-store-${issue_number}-body.md"
  local mirror="/tmp/spec-store-${issue_number}-mirror.md"
  local complexity section_map

  complexity=$(sed -n 's/^\*\*Complexity:\*\* *//p' "$spec" | head -n 1)
  section_map=$(awk '/^### Section Map$/{f=1;next} f&&/^\|/{print;next} f{exit}' "$spec")
  {
    echo '<!-- enriched-spec:start v2 -->'
    echo '## Enriched Spec'
    echo
    echo "**Complexity:** ${complexity}"
    echo
    echo "<!-- spec-file: ${SPEC_PATH} -->"
    echo "📄 **Full spec:** [\`${SPEC_PATH}\`](../blob/main/${SPEC_PATH})"
    echo
    echo '### Section Map'
    printf '%s\n' "$section_map"
    echo
    echo '*Mirror of the Section Map in the spec file above, regenerated on every write.'
    echo 'Do not edit here — no skill reads it, and an edit will be overwritten.*'
    echo '<!-- enriched-spec:end -->'
  } >"$mirror"

  # Splice into a freshly fetched body — never a scratch file from an earlier
  # step or run, which may hold a different issue's body.
  gh issue view "$issue_number" --repo "$REPO" --json body --jq '.body' >"$tmp_body" || {
    blocked issue-unreadable "❌ Could not read issue #${issue_number}. The spec is stored; the mirror is not. Re-run to repair."
  }
  [ -s "$tmp_body" ] || {
    blocked issue-unreadable "❌ Empty body returned. Refusing to write."
  }

  if grep -q '<!-- enriched-spec:start v2 -->' "$tmp_body"; then
    awk -v mirror_file="$mirror" '
      BEGIN { while ((getline line < mirror_file) > 0) mirror = mirror line ORS
              sub(/\n$/, "", mirror) }   # else `print` adds a second newline and
                                         # the body grows a byte on every write
      /<!-- enriched-spec:start v2 -->/ { print mirror; skip=1; next }
      /<!-- enriched-spec:end -->/ && skip { skip=0; next }
      !skip { print }
    ' "$tmp_body" >"$tmp_body.new" && mv "$tmp_body.new" "$tmp_body"
  else
    printf '\n\n' >>"$tmp_body"
    cat "$mirror" >>"$tmp_body"
  fi

  # Strip every trailing newline before writing. GitHub appends one to a body on
  # each edit, so writing a body that ends in a newline grows it by a byte on
  # every run and "idempotent" stops being true. Sending none makes the write a
  # fixed point.
  printf '%s' "$(cat "$tmp_body")" >"$tmp_body.norm" && mv "$tmp_body.norm" "$tmp_body"

  gh issue edit "$issue_number" --repo "$REPO" --body-file "$tmp_body" >/dev/null || {
    blocked issue-unreadable "❌ Could not write the issue body. The spec is stored; the mirror is not. Re-run to repair."
  }
}

post_resolution() {
  [ -n "$resolution_file" ] && [ -s "$resolution_file" ] || return 0
  # Skip when this exact comment is already there, so a repair re-run does not duplicate it.
  if gh issue view "$issue_number" --repo "$REPO" --json comments \
    | jq -e --rawfile r "$resolution_file" \
      '[.comments[].body | rtrimstr("\n")] | index($r | rtrimstr("\n"))' >/dev/null 2>&1; then
    echo "Resolution comment already present on #${issue_number}; not reposting."
    return 0
  fi
  # Unposted, the defects stay unresolved and the pipeline would re-open them;
  # a re-run repairs it the same way it repairs a mirror.
  gh issue comment "$issue_number" --repo "$REPO" --body-file "$resolution_file" >/dev/null || {
    blocked issue-unreadable "❌ Spec and mirror are written; the resolution comment is not. Re-run to post it."
  }
}

refresh_local_main() {
  git fetch origin main --quiet || {
    echo "⚠️  Could not fetch origin/main; local main not refreshed."
    return 0
  }
  if [ "$(git branch --show-current 2>/dev/null)" = main ]; then
    git merge --ff-only origin/main --quiet ||
      echo "⚠️  Local main was not fast-forwarded (uncommitted changes or divergence)."
  else
    git fetch origin main:main --quiet 2>/dev/null ||
      echo "⚠️  Local main was not updated (checked out in another worktree, or diverged); origin/main is current."
  fi
}

# ── Finish mode ──────────────────────────────────────────────────────────────

if [ "$mode" = finish ]; then
  info=$(gh pr view "$finish_pr" --repo "$REPO" --json state,headRefName,mergeCommit,url 2>&1) || {
    blocked spec-write-failed "$info" "❌ Could not read PR #${finish_pr}."
  }
  state=$(jq -r '.state' <<<"$info")
  head=$(jq -r '.headRefName' <<<"$info")
  url=$(jq -r '.url' <<<"$info")
  merge_sha=$(jq -r '.mergeCommit.oid // ""' <<<"$info")
  if [ "$head" != "$BRANCH" ]; then
    blocked spec-write-failed "❌ PR #${finish_pr} is head '${head}', not '${BRANCH}'. Not a spec PR for issue #${issue_number}."
  fi
  if [ "$state" != MERGED ] || [ -z "$merge_sha" ]; then
    blocked spec-merge-failed "❌ PR #${finish_pr} (${url}) is ${state}, not merged. Run merge-pr ${finish_pr} first."
  fi

  refresh_local_main

  gh api "$API?ref=main" -H "Accept: application/vnd.github.raw" >"$CUR" 2>&1 && [ -s "$CUR" ] || {
    blocked spec-write-failed "❌ Could not read ${SPEC_PATH} from main after the merge."
  }
  publish_mirror "$CUR"
  post_resolution
  echo "STATUS: OK ${merge_sha}"
  exit 0
fi

# ── Write mode ───────────────────────────────────────────────────────────────

if [ ! -s "$NEW" ]; then
  blocked spec-write-failed "❌ Spec file '$NEW' is missing or empty. Refusing to write."
fi

# Before Step 1: the approval named these exact bytes.
if [ -n "$expected_sha256" ]; then
  actual_sha256=$(shasum -a 256 "$NEW" | cut -d' ' -f1)
  if [ "$actual_sha256" != "$expected_sha256" ]; then
    blocked approved-spec-mismatch "❌ $NEW hashes to $actual_sha256, not the approved $expected_sha256. Nothing written."
  fi
fi

# One open spec PR per issue: never stack a second.
open_pr=$(gh pr list --repo "$REPO" --head "$BRANCH" --state open --json number,url \
  --jq '.[0].url // ""' 2>/dev/null) || open_pr=""
if [ -n "$open_pr" ]; then
  blocked "spec-pr-open ${open_pr}" "❌ A spec PR for issue #${issue_number} is already open. Merge or close it, then re-run."
fi

# ── Step 1 — Read the current file, pinned to one commit of main ─────────────
# Reading the file and branching from the SAME commit makes the PUT's sha valid
# by construction; the only remaining race is a later change to that file on
# main, which GitHub reports as a CONFLICTING PR (see the wait loop).
main_sha=$(gh api "repos/${REPO}/git/ref/heads/main" --jq '.object.sha' 2>/dev/null) || main_sha=""
[ -n "$main_sha" ] || blocked spec-write-failed "❌ Could not resolve the tip of origin/main."

CUR_SHA=""
if get_out=$(gh api "$API?ref=${main_sha}" --jq '.sha' 2>&1); then
  CUR_SHA="$get_out"
  gh api "$API?ref=${main_sha}" -H "Accept: application/vnd.github.raw" >"$CUR" ||
    blocked spec-write-failed "❌ Could not read the current ${SPEC_PATH}."
elif grep -q 'HTTP 404' <<<"$get_out"; then
  : >"$CUR" # first write for this issue — no prior file, no sha
else
  blocked spec-write-failed "$get_out" "❌ Could not read the current ${SPEC_PATH}."
fi

# ── Step 2 — Merged-section guard ────────────────────────────────────────────
extract() { # $1 = SEC-ID, $2 = file. Same contract as `spec-load` Step 2 —
            # whole-line `$0 ==`, never a regex or heading bound. It is
            # duplicated here only because the guard compares a *local* file
            # against the remote one; if that form ever changes, change both.
            # Single-quoted so the shell never sees the `!`; id via ENVIRON.
  SEC="$1" awk '
    $0 == "<!-- section:" ENVIRON["SEC"] ":start -->" {f=1; next}
    $0 == "<!-- section:" ENVIRON["SEC"] ":end -->"   {f=0}
    f' "$2"
}

section_branch() { # $1 = SEC-ID, $2 = spec file. Branch column of that section's Section Map row.
  SEC="$1" awk -F'|' '
    $0 ~ /^\|/ && $2 ~ "^[[:space:]]*" ENVIRON["SEC"] "[[:space:]]*$" {
      branch = $6; gsub(/[[:space:]`]/, "", branch); print branch; exit }' "$2"
}

merged_offenders="/tmp/spec-store-${issue_number}-merged.txt"
: >"$merged_offenders"

# every SEC-ID fenced in either the current file or the new spec.
# `while read`, not `for sec in $sections` — zsh does not word-split an
# unquoted variable, so the `for` form would loop once over the whole list.
{ sed -n 's/^<!-- section:\(.*\):start -->$/\1/p' "$CUR"
  sed -n 's/^<!-- section:\(.*\):start -->$/\1/p' "$NEW"; } | sort -u \
| while IFS= read -r sec; do
    old=$(extract "$sec" "$CUR")
    [ -z "$old" ] && continue                              # new section
    [ "$old" = "$(extract "$sec" "$NEW")" ] && continue     # unchanged
    # changed or being removed — is its PR merged? Branch from its Section Map row.
    branch=$(section_branch "$sec" "$CUR")
    [ -z "$branch" ] && continue
    merged_hit=$(gh pr list --repo "$REPO" --head "$branch" --state all \
      --json state --jq '.[] | select(.state=="MERGED")')
    [ -n "$merged_hit" ] && echo "$sec" >>"$merged_offenders"
  done

if [ -s "$merged_offenders" ]; then
  blocked merged-section-modified \
    "❌ Merged section(s) would be altered or deleted: $(paste -sd' ' "$merged_offenders")." \
    "   Revert the edit, or take it to the user as a deliberate amendment of shipped history."
fi

# Identical to main: nothing to branch or merge; this is the mirror-repair path.
if [ -n "$CUR_SHA" ] && cmp -s "$CUR" "$NEW"; then
  echo "Spec already matches main; nothing to merge. Repairing the mirror."
  publish_mirror "$NEW"
  post_resolution
  echo "STATUS: OK ${main_sha}"
  exit 0
fi

# ── Step 3 — Branch from that main commit and commit the file to it ──────────
# The payload goes in a file, never on `argv`: base64 of a real spec runs past
# 400,000 characters, and building that into a command line courts `ARG_MAX`.
# The base64 content itself is written to its own file and read back with
# `--rawfile`, never passed as a `--arg` — a `--arg` value is still argv.
BODY="/tmp/spec-store-${issue_number}-put.json"
PUT_OUT="/tmp/spec-store-${issue_number}-put.out"
B64="/tmp/spec-store-${issue_number}-content.b64"

base64 < "$NEW" | tr -d '\n' >"$B64"

commit_message="docs(spec): enriched spec for issue #${issue_number}

Co-Authored-By: ${COAUTHOR}"

jq -n \
  --arg m "$commit_message" \
  --rawfile c "$B64" \
  --arg b "$BRANCH" \
  --arg s "$CUR_SHA" \
  '{message:$m, content:$c, branch:$b} + (if $s == "" then {} else {sha:$s} end)' \
  >"$BODY"

# A leftover branch with no open PR (closed or merged earlier, never deleted) is
# reset onto main's tip; the spec/ namespace holds nothing but disposable drafts.
if gh api "repos/${REPO}/git/ref/heads/${BRANCH}" >/dev/null 2>&1; then
  ref_out=$(gh api --method PATCH "repos/${REPO}/git/refs/heads/${BRANCH}" \
    -f sha="$main_sha" -F force=true 2>&1) || ref_failed=1
else
  ref_out=$(gh api --method POST "repos/${REPO}/git/refs" \
    -f ref="refs/heads/${BRANCH}" -f sha="$main_sha" 2>&1) || ref_failed=1
fi
[ -z "${ref_failed:-}" ] || blocked spec-write-failed "$ref_out" "❌ Could not create branch ${BRANCH}."

# `base64 < file`, not `base64 -i file` — the redirect form works on both macOS
# and Linux.
if ! gh api --method PUT "$API" --input "$BODY" --jq '.commit.sha' >"$PUT_OUT" 2>&1; then
  cat "$PUT_OUT"
  delete_branch
  blocked spec-write-failed "❌ Could not commit the spec to ${BRANCH}; branch removed."
fi
echo "Committed $(tail -n 1 "$PUT_OUT") to ${BRANCH}."

# ── Step 4 — Open the PR (non-draft: the CI job skips drafts) ────────────────
PR_BODY="/tmp/spec-store-${issue_number}-pr.md"
cat >"$PR_BODY" <<EOF
Stores the enriched spec for issue #${issue_number} at \`${SPEC_PATH}\`.

Spec-only PR (docs-only light CI). Merged by \`merge-pr <pr>\` in direct mode, which recognises it by branch, title and file set; no \`approved\` label is needed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF

pr_url=$(gh pr create --repo "$REPO" --base main --head "$BRANCH" \
  --title "docs(spec): enriched spec for issue #${issue_number}" \
  --body-file "$PR_BODY" 2>&1) || {
  delete_branch
  blocked spec-write-failed "$pr_url" "❌ Could not open the spec PR; branch removed."
}
pr_url=$(printf '%s\n' "$pr_url" | tail -n 1)
pr_number="${pr_url##*/}"
case "$pr_number" in '' | *[!0-9]*) blocked spec-write-failed "❌ Could not parse a PR number from: $pr_url" ;; esac
echo "Opened ${pr_url}"

# ── Step 5 — Wait for checks, bounded ────────────────────────────────────────
# One deadline covers everything, including the re-wait after `update-branch`.
# `gh pr checks` right after creation can say "no checks reported": that is
# "not yet", never "pass". Red or cancelled never proceeds.
close_conflicting() {
  gh pr close "$pr_number" --repo "$REPO" --delete-branch \
    --comment "Closed by spec-store-write.sh: main's copy of ${SPEC_PATH} changed after this PR was cut. Re-run from a fresh read." \
    >/dev/null 2>&1 || true
  blocked concurrent-write "❌ ${SPEC_PATH} changed on main since it was read (PR ${pr_url} was CONFLICTING); PR closed, branch deleted. Re-run from a fresh read."
}

deadline=$(($(date +%s) + CHECK_BUDGET))
updated=false
last_note=""
note() { [ "$1" = "$last_note" ] || { echo "$1"; last_note="$1"; }; }

while :; do
  info=$(gh pr view "$pr_number" --repo "$REPO" --json state,mergeable,mergeStateStatus,headRefOid 2>/dev/null) || info=""
  if [ -n "$info" ]; then
    pr_state=$(jq -r '.state' <<<"$info")
    mergeable=$(jq -r '.mergeable' <<<"$info")
    merge_status=$(jq -r '.mergeStateStatus' <<<"$info")

    [ "$pr_state" = OPEN ] || blocked spec-write-failed "❌ PR ${pr_url} is ${pr_state}, not open."
    if [ "$mergeable" = CONFLICTING ] || [ "$merge_status" = DIRTY ]; then
      close_conflicting
    fi

    checks=$(gh pr checks "$pr_number" --repo "$REPO" --json name,bucket 2>/dev/null || true)
    if jq -e 'type == "array"' >/dev/null 2>&1 <<<"$checks"; then
      total=$(jq 'length' <<<"$checks")
      failing=$(jq -r '[.[] | select(.bucket == "fail" or .bucket == "cancel") | .name] | join(", ")' <<<"$checks")
      pending=$(jq '[.[] | select(.bucket == "pending")] | length' <<<"$checks")
    else
      total=0 failing="" pending=0
    fi

    if [ -n "$failing" ]; then
      blocked "spec-pr-checks-failing ${pr_url}" "❌ Failing checks: ${failing}. PR left open."
    fi

    if [ "$total" -eq 0 ]; then
      note "Waiting for checks to be reported…"
    elif [ "$pending" -gt 0 ]; then
      note "Waiting for ${pending} pending check(s)…"
    else
      case "$merge_status" in
        CLEAN | HAS_HOOKS | UNSTABLE)
          echo "Spec PR #${pr_number} is green and up to date."
          echo "STATUS: OK-PR-READY ${pr_number}"
          exit 0
          ;;
        BEHIND)
          # The ruleset is strict: main moved elsewhere. Update once, then re-wait.
          if [ "$updated" = true ]; then
            blocked spec-merge-failed "❌ PR ${pr_url} is BEHIND main again after one update-branch. PR left open."
          fi
          old_head=$(jq -r '.headRefOid' <<<"$info")
          echo "PR is BEHIND main; running gh pr update-branch once."
          if ! update_out=$(gh pr update-branch "$pr_number" --repo "$REPO" 2>&1); then
            echo "$update_out"
            if grep -qi 'conflict' <<<"$update_out"; then
              close_conflicting
            fi
            blocked spec-merge-failed "❌ update-branch failed. PR ${pr_url} left open."
          fi
          updated=true
          # The old head's green checks are stale; wait for the new commit to register.
          for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do
            sleep 5
            new_head=$(gh pr view "$pr_number" --repo "$REPO" --json headRefOid --jq '.headRefOid' 2>/dev/null || true)
            [ -n "$new_head" ] && [ "$new_head" != "$old_head" ] && break
          done
          last_note=""
          continue
          ;;
        *) note "Checks are green; waiting for mergeability (state: ${merge_status})…" ;;
      esac
    fi
  fi

  if [ "$(date +%s)" -ge "$deadline" ]; then
    blocked "spec-pr-checks-pending ${pr_url}" \
      "❌ Checks did not finish within ${CHECK_BUDGET}s. PR left open: when green, run merge-pr ${pr_number}, then spec-store-write.sh ${issue_number} --finish ${pr_number}."
  fi
  sleep "$POLL"
done
