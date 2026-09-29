---
name: spec-load
description: >
  Load an issue's enriched spec, or one section of it, from the version-controlled
  spec file. Invoked as a sub-skill by `improve-issue`, `code-issue`,
  `review-issue`, `pr-from-issue`, `address-pr-review` and the
  `epic-orchestrator` agent — never directly by a user. It is the only place
  that knows where a spec is stored or how a section fence is matched.
---

# Skill: spec-load

Read the enriched spec for issue `<n>`, and optionally extract exactly one
section from it. Every skill in the issue pipeline opens with this instead of
fetching the issue body and running its own `awk`.

Follows `../shared/turn-discipline.md`: `Read`/`Grep` over shell `cat`/`grep`,
no narration-only turns.

## Why this exists

The spec is **not** in the issue body. It lives at
`specs/issue-<n>-enriched-spec.md`, version-controlled, because a real spec
outgrows what a GitHub issue body will accept.

The issue body carries a pointer and a regenerated mirror of the Section Map.
**Never read the mirror.** It exists so a human scanning GitHub sees the shape of
the work; it is rewritten wholesale on every `spec-store` run and has no
authority. Anything a skill decides on comes from the file.

One fence contract, one implementation, here.

## Two sources, one rule

| What | Read from | Why |
|---|---|---|
| structure — `**Complexity:**`, the Section Map, every other section, the merged-section facts | **`main`** | a spec is stored only once its spec PR has merged; `main` is the one ref every step agrees on |
| a section's **instructions** | **`main`** | a section is coded and reviewed on different days from different checkouts; each must read the same words |
| a section's **AC checkbox state** (`- [ ]` / `- [x]`) | the **working copy** — `specs/issue-<n>-enriched-spec.md` in the current checkout, when present — unioned with `main`'s | `code-issue` and `review-issue` tick ACs as a local edit on the section branch (`spec-store` Mode `tick`); the tick reaches `main` only inside the section's code PR, so until then `main` cannot know it |

The working copy is consulted for ticks **only**. Its text never replaces `main`'s. A working
copy that differs from `main` in anything but checkbox characters is reported (`NOTICE`, Step 2)
and otherwise ignored: the spec was rewritten after the branch was cut, and the resulting
conflict is the orchestrator's to halt on, not this skill's to resolve.

## Arguments

```
spec-load <n>              # whole spec
spec-load <n> <SEC-ID>     # whole spec, plus one section extracted
```

## Step 1 — Fetch the spec file

Always from `main`, never from the working branch. The meta fetch always runs
— it is one small call — but the raw download is skipped when `/tmp` already
holds that exact `sha`: `/tmp/spec-<n>.md` is a plain path, not namespaced to
this skill or to any one spawn, so a spec fetched by an earlier pass or an
earlier skill spawn in the same run is still sitting there for this one to
reuse.

```bash
SPEC=/tmp/spec-<n>.md
META=/tmp/spec-<n>-meta.json

PREV_SHA=""
[ -s "$META" ] && PREV_SHA=$(jq -r '.sha // empty' "$META" 2>/dev/null)

gh api "repos/wadvanced/aurora_uix/contents/specs/issue-<n>-enriched-spec.md?ref=main" \
  --jq '{sha, size}' > "$META" 2>/dev/null || {
  echo "⚠️ No spec file for issue #<n> at specs/issue-<n>-enriched-spec.md on main."
  echo "STATUS: BLOCKED — spec-missing"; exit 1
}

NEW_SHA=$(jq -r '.sha' "$META")

if [ -n "$PREV_SHA" ] && [ "$PREV_SHA" = "$NEW_SHA" ] && [ -s "$SPEC" ]; then
  echo "Cache hit — reusing $SPEC (sha $NEW_SHA), no raw download"
else
  gh api "repos/wadvanced/aurora_uix/contents/specs/issue-<n>-enriched-spec.md?ref=main" \
    -H "Accept: application/vnd.github.raw" > "$SPEC"

  [ -s "$SPEC" ] || {
    echo "⚠️ Spec file for issue #<n> is empty. Refusing to guess."
    echo "STATUS: BLOCKED — spec-missing"; exit 1
  }
fi
```

`?ref=main` is load-bearing, not decoration. A section is coded on its own
branch and reviewed later from another; if either resolved the spec's instructions from the
branch it happens to be standing on, a coder could implement against bytes that
changed under it, and `review-issue` could verify against a spec the coder never
saw.

`Accept: application/vnd.github.raw` returns the bytes exactly — no base64
round-trip, and no 1 MB inline-content limit to worry about below that size.

Record the `sha` from `$META`. It is the spec's identity for this run: a
`spec-defect` report names it, so the version an instruction was read from is
recoverable later. It is also the cache key above — the meta call is what
detects a spec that changed under a stale `/tmp/spec-<n>.md`, so it is never skipped even on a
cache hit.

A spec is on `main` only after its spec PR merged. `STATUS: BLOCKED — spec-missing` therefore
also covers a spec whose PR is still open: `improve-issue` / `orchestrate-issue` have not
finished storing it, and nothing may be coded against it yet.

## Step 2 — Extract one section, when `<SEC-ID>` was given

Instructions, from `main`'s copy:

```bash
SEC=<SEC-ID> awk '
  $0 == "<!-- section:" ENVIRON["SEC"] ":start -->" {f=1; next}
  $0 == "<!-- section:" ENVIRON["SEC"] ":end -->"   {f=0}
  f' "$SPEC" > /tmp/spec-<n>-<SEC-ID>.md
```

Whole-line equality (`$0 ==`), never a regex or a heading bound. A heading bound
prefix-matches `SCH-1` against `SCH-10`; a `---` bound runs into whatever
follows. The id arrives through `ENVIRON` so the shell never sees the `!` in the
comment marker.

An **empty** result means the spec carries no fence for that id:

```
STATUS: BLOCKED — section-fence-missing
```

Never fall back to a looser bound to "find something". A wrong section is worse
than no section.

**AC state from the working copy.** When the current checkout holds
`specs/issue-<n>-enriched-spec.md` (a section worktree does), extract the same fence from it and
overlay its ticks:

```bash
WC="$(git rev-parse --show-toplevel)/specs/issue-<n>-enriched-spec.md"
OUT=/tmp/spec-<n>-<SEC-ID>.md
if [ -s "$WC" ]; then
  SEC=<SEC-ID> awk '
    $0 == "<!-- section:" ENVIRON["SEC"] ":start -->" {f=1; next}
    $0 == "<!-- section:" ENVIRON["SEC"] ":end -->"   {f=0}
    f' "$WC" > /tmp/spec-<n>-<SEC-ID>-wc.md

  # ticked in the working copy → ticked in the extract; never the reverse
  sed -n 's/^- \[x\] \(AC-[0-9][0-9]*\):.*/\1/p' /tmp/spec-<n>-<SEC-ID>-wc.md |
  while IFS= read -r ac; do
    sed "s/^- \[ \] $ac:/- [x] $ac:/" "$OUT" > "$OUT.new" && mv "$OUT.new" "$OUT"
  done

  norm() { sed 's/^- \[x\]/- [ ]/' "$1"; }
  [ "$(norm /tmp/spec-<n>-<SEC-ID>-wc.md)" = "$(norm "$OUT")" ] ||
    echo "NOTICE: spec-drift — the working copy of <SEC-ID> differs from main beyond checkboxes"
fi
```

A working copy with no fence for the id contributes nothing (a fresh section on a checkout cut
before the spec merged). `NOTICE: spec-drift` does not change the status: the extract is `main`'s
text, which is what the section must be coded and reviewed against. The caller mentions the
notice in its output; the eventual `gh pr update-branch` in the orchestrator is where the
conflict surfaces and halts.

## Step 3 — Return

One terminal `STATUS:` line. The caller branches on it: `BLOCKED` stops the
caller, anything else lets it continue in the same turn.

| Status | Meaning |
|---|---|
| `STATUS: OK <sha>` | `$SPEC` holds the whole spec (main's, at `<sha>`); with a `<SEC-ID>`, `/tmp/spec-<n>-<SEC-ID>.md` holds that section with the working copy's ticks overlaid |
| `STATUS: BLOCKED — spec-missing` | no spec file on `main`, or it is empty, or its spec PR has not merged — run `improve-issue <n>` |
| `STATUS: BLOCKED — section-fence-missing` | the spec exists but has no fence for that id — re-run `improve-issue <n>` |

Report the status and the paths written. Do not summarise the spec's contents:
the caller reads the files.

## What the caller does next

- **Whole-spec reads** — `**Complexity:**`, the `### Section Map` table, and the
  presence of a fence — come from `$SPEC`.
- **Section work** reads `/tmp/spec-<n>-<SEC-ID>.md` and **never** `$SPEC`.
  Reading the whole spec wholesale pulls every sibling section into context,
  which is exactly what the fence exists to make avoidable.

## Forbidden

- Reading the spec from the issue body, or from the body's Section Map mirror.
- Resolving the file from any ref but `main`. The working copy is read for AC ticks only.
- Matching a fence with a regex, a heading, or a `---` bound.
- Writing anything but the `/tmp` files above. This skill only reads; `spec-store` owns every
  write.
