---
name: evaluate-issue
description: >
  Evaluate an already-enriched GitHub issue and recommend whether to keep it
  as-is (with a model-tier recommendation), declare it already completed, or
  split it into smaller children. Use when the user says "evaluate this
  issue", "is this issue too big", "should we split this", "size this issue",
  "which model should code this", or before kicking off orchestrate-issue on
  a heavy spec. Requires improve-issue to have been run first — this skill
  does NOT enrich specs and does NOT modify code. Read-mostly: the only
  write is an idempotent issue-evaluation marker block on the issue body.
---

# Skill: evaluate-issue

Decide if a GitHub issue's enriched spec is rightly sized for one coding pass,
already done, or large enough that splitting would help. Output is a
detailed, evidence-backed assessment persisted to the issue body so a future
session (or a teammate) can act on it without re-doing the analysis.

This skill is advisory. It never creates child issues, never edits code, never
runs the test gate. It writes one marker block and asks the user to choose if a
split is warranted.

---

## Required input

The issue number (or URL). Resolve to a numeric `<n>` and use it explicitly in
every `gh` call. Do not rely on chat context.

## Precondition

The issue body **must already contain** the `<!-- enriched-spec:start v1 -->`
marker block. If it does not, fail fast — do not invoke `improve-issue` from
here.

```bash
gh issue view <n> --json body --jq '.body' \
  | grep -q '<!-- enriched-spec:start v1 -->' \
  || { echo "❌ Issue #<n> has no enriched spec. Run /skill improve-issue <n> first, then re-run evaluate-issue."; exit 1; }
```

---

## Step 0 — Re-read the issue from GitHub

Always re-read state from GitHub — never trust chat context:

```bash
gh issue view <n> --json title,body,labels,url
gh issue view <n> --comments
```

Extract these from the body:

- The full enriched-spec block between `<!-- enriched-spec:start v1 -->` and
  `<!-- enriched-spec:end -->`.
- The full review-gaps block between `<!-- review-gaps:start v1 -->` and
  `<!-- review-gaps:end -->`, if present.
- The literal phrase `Issue is completed and ready to be closed.`, if present.

From the enriched-spec block, parse:

- The Acceptance Criteria list and each item's checkbox state (`- [ ]` vs
  `- [x]`).
- The "Affected Files / Modules" list.
- The "Dependencies" section (migrations, packages, external services,
  feature flags, locales).
- The "Open Questions" section (empty or non-empty).

---

## Step 1 — Detect completion state

Classify the issue into exactly one bucket:

- **`completed`** — any of:
  - body contains `Issue is completed and ready to be closed.`, OR
  - review-gaps block contains `✅ No outstanding gaps.`, OR
  - every AC checkbox is `[x]`.
- **`partial`** — some AC boxes ticked, OR review-gaps lists `INCOMPLETE_TASKS`
  / `MISSING_COVERAGE` items.
- **`fresh`** — no AC ticked, no review-gaps block (or empty/never-reviewed).

For `partial`: build the **remaining-work slice** before sizing — only the
unticked ACs and the files those ACs reference, plus any files cited in the
review-gaps block. Subsequent steps run on the slice, not the original spec.
A 90%-done large issue routinely lands in the trivial/standard tier.

If `completed`: skip Steps 2–4, write the assessment with verdict
`COMPLETED`, and end.

---

## Step 2 — Size the remaining work

Use a transparent rubric. **The primary signal is the number and spread of
files involved, not the AC count.** A 20-AC issue that targets a single file
is well within a smaller model's range — the ACs are just enumerated cases on
one surface. A 4-AC issue that spans 8 files across 3 layers is genuinely
large.

### Primary signals (drive the tier)

| Signal | Source | Threshold |
|---|---|---|
| Affected files (outstanding only) | Affected Files / Modules section, filtered to outstanding ACs | 1 trivial · 2–4 standard · 5–8 complex · >8 oversized |
| Layers touched | Router / LiveView / Ash domain / Ash resource / Migration / Oban / Mail / PubSub | 1 trivial · 2–3 standard · 4 complex · ≥5 oversized |
| Cross-domain coupling | spec mentions ≥2 distinct Ash domains | yes → at least complex |
| Migration required | Dependencies section | yes → at least standard |
| New external dependency | Dependencies section | yes → at least standard |

### Modifiers (bump or lower one tier; never the sole reason for a verdict)

- Authorization / Ash policies in scope → bump one tier.
- Open Questions in spec non-empty → bump one tier and lower confidence.
- AC count is **not** a primary signal. Many ACs on a single file → no bump.
  Many ACs spread across many files → already captured by the file-count
  signal, so no extra bump.
- For `partial` issues, all signals above run on the **remaining slice**, not
  the full spec.

Aggregate the highest-driven tier:

- **`trivial`** → recommend `claude-haiku-4-5-20251001`.
- **`standard`** → recommend `claude-sonnet-4-6`.
- **`complex`** → recommend `claude-opus-4-7` **or** propose a split.
- **`oversized`** → split is strongly recommended; do not recommend a
  single-model run.

These are recommendations to the user, not enforcement.

---

## Step 3 — Decide the verdict

Pick exactly one:

1. **`COMPLETED`** — Step 1 returned `completed`.
2. **`KEEP — model: <tier>`** — tier is `trivial`, `standard`, or `complex`
   AND there is no compelling structural reason to split (single domain,
   single migration, no cross-cutting concerns).
3. **`SPLIT — propose options`** — tier is `oversized`, OR tier is `complex`
   with cross-domain coupling, OR review-gaps shows the issue has already
   needed multiple iterations and is still large. Continue to Step 4.

---

## Step 4 — Propose split options (only when verdict is `SPLIT`)

Generate 2–3 mutually exclusive strategies derived from the spec. Pick from:

- **By layer**: data-model + migration → resource actions + policies →
  LiveView/UI → Oban/async.
- **By acceptance-criterion grouping**: cluster ACs that share files; each
  cluster becomes a child.
- **By happy-path vs edge cases**: ship the happy-path first; defer
  error/authorization paths to a follow-up.
- **By feature flag**: hidden-behind-flag MVP child, then enablement child.

For each strategy describe:
- Proposed child issue titles (short).
- Which ACs and files each child covers.
- Execution order and which children unblock which.
- Recommended model tier per child (rerun the Step 2 rubric on each child's
  slice).
- Estimated parallelism: which children can run concurrently.
- **Test owner**: `parent` (parent issue keeps integrated tests; children
  write implementation + smoke only) or `sibling` (a final synthetic
  `kind:tests` child owns the integrated test surface and depends on every
  other sibling). Default by strategy:
  - by-layer / by-feature-flag → `parent` (layers share state; integrated
    tests at the top read cleaner).
  - by-AC-grouping / by-happy-vs-edges → `sibling` (clusters are loosely
    coupled; a dedicated tests child deduplicates the surface).
  Override per strategy if the spec suggests otherwise.
- One-line trade-off vs the other strategies.

Then ask the user with `AskUserQuestion` to pick a strategy or "none — keep
single issue". When a strategy is picked, ask a **second** question to
confirm or override the **Test owner** (`parent` vs `sibling`) — pre-select
the default from the strategy's recommendation above. Both answers must be
recorded in the `### Chosen split plan` section. Do **not** call
`gh issue create`. The skill writes the chosen plan into the assessment
block; `split-issue` executes creation.

---

## Step 5 — Persist the assessment block

Use the same idempotent splice pattern as `improve-issue` and `review-issue`.
The block must be informative enough that a user reading only this block can
make the keep-vs-split call without re-reading the whole spec.

Build the block with the following template (omit sections marked when their
condition does not hold):

```markdown
<!-- issue-evaluation:start v1 -->
## Split Assessment (<YYYY-MM-DD>)

**Verdict:** COMPLETED | KEEP | SPLIT — <one-line justification>
**Completion state:** fresh | partial (X/Y ACs done) | completed
**Remaining-work tier:** trivial | standard | complex | oversized
**Recommended model (if KEEP):** claude-haiku-4-5-20251001 | claude-sonnet-4-6 | claude-opus-4-7
**Confidence:** high | medium | low — <why>

### Snapshot of remaining work
- **Outstanding ACs:** AC-2, AC-5, AC-7 (one verbatim line each)
- **Outstanding review-gaps:** <copied from INCOMPLETE_TASKS / MISSING_COVERAGE if any, else "none">
- **Files in play:** <deduped list, only files tied to outstanding ACs>
- **Layers touched:** Router · LiveView · Ash resource · Migration · Oban (only those present)
- **Migration required:** yes/no — <name if known>
- **New deps:** none / `<pkg> ~> x.y`
- **Authorization work:** yes/no — <which roles/policies>

### Sizing signals — primary (file/spread-driven)
| Signal | Observed | Tier contribution |
|---|---|---|
| Affected files (outstanding) | <N> | <tier> |
| Layers touched | <N> (<list>) | <tier> |
| Cross-domain coupling | <yes/no> (<which>) | <tier or —> |
| Migration required | <yes/no> | <≥ standard or —> |
| New external dependency | <yes/no> | <≥ standard or —> |

### Sizing signals — modifiers
| Modifier | Observed | Effect |
|---|---|---|
| Authorization / policies | <yes/no> | <+1 tier or —> |
| Open Questions | <count> | <+1 tier, confidence ↓> or — |
| AC count vs file count | <A> ACs / <F> files | no bump (rationale) |
| Partial-completion adjustment | <X>/<Y> ACs done, <F'> files remaining | rubric re-run on remaining slice |

**Aggregate tier:** <trivial | standard | complex | oversized>

### Why this verdict
- 2–4 plain-language bullets citing the rows above.
- For SPLIT: state which signals were the deciders.
- For KEEP: state what would have flipped it to SPLIT.

### Risks of keeping as-is
(omit if verdict = COMPLETED)
- bullet — concrete risk tied to a row above
- bullet — concrete risk tied to a row above

### Risks of splitting
(omit if verdict = COMPLETED, or if no split is being proposed)
- bullet — concrete risk (e.g. shared file, sequential dependency)
- bullet

### Split options
(present only if verdict = SPLIT and user has not yet picked)
**Option 1 — <strategy>:** <one-line rationale>
- Child A — <title> · ACs: ... · files: ... · model: ... · independent
- Child B — <title> · ACs: ... · files: ... · model: ... · depends on A
- Trade-off: <one line>

**Option 2 — <strategy>:** ...

### Chosen split plan
(present only after user picks via AskUserQuestion)
**Strategy:** <name>
**Test owner:** parent | sibling   ← required; drives `split-issue` behavior
1. **Child A — <title>** — covers AC-1, AC-3 · files: ... · model: ... · independent
2. **Child B — <title>** — covers AC-2, AC-4 · files: ... · model: ... · depends on A
(if Test owner = sibling, `split-issue` appends a final synthetic test-owner child)

### Recommended next step
- KEEP: `Run /skill orchestrate-issue <n> with model <recommended>.`
- SPLIT (pre-pick): `Pick a strategy above, or reply "keep" to override.`
- SPLIT (post-pick): `Create the listed child issues, then run /skill improve-issue on each.`
- COMPLETED: `Run /skill pr-from-issue <n>` or close the issue manually.
<!-- issue-evaluation:end -->
```

Splice it into the body idempotently — the same pattern `improve-issue` uses:

```bash
TMP_ASSESS=$(mktemp)
cat > "$TMP_ASSESS" <<'ASSESS'
<!-- issue-evaluation:start v1 -->
... assessment content above ...
<!-- issue-evaluation:end -->
ASSESS

TMP_BODY=$(mktemp)
gh issue view <n> --json body --jq '.body' > "$TMP_BODY"

if grep -q '<!-- issue-evaluation:start v1 -->' "$TMP_BODY"; then
  awk -v assess_file="$TMP_ASSESS" '
    BEGIN { while ((getline line < assess_file) > 0) assess = assess line ORS }
    /<!-- issue-evaluation:start v1 -->/ { print assess; skip=1; next }
    /<!-- issue-evaluation:end -->/ { skip=0; next }
    !skip { print }
  ' "$TMP_BODY" > "$TMP_BODY.new" && mv "$TMP_BODY.new" "$TMP_BODY"
else
  printf '\n\n' >> "$TMP_BODY"
  cat "$TMP_ASSESS" >> "$TMP_BODY"
fi

gh issue edit <n> --body-file "$TMP_BODY"
```

Re-running `evaluate-issue` on the same issue replaces the block in place; it
never stacks duplicates and never overwrites the enriched spec or
review-gaps blocks.

---

## Step 6 — Output

Echo the full assessment block in chat (same content just written to the
issue) so the user has the reasoning, signals, risks, and options visible
without clicking through to GitHub. This mirrors how `improve-issue` echoes
its spec and `review-issue` echoes its report.

End with one of:

- `✅ KEEP — issue #<n> is sized for <model>. Run /skill orchestrate-issue <n>.`
- `🧩 SPLIT proposed — see issue-evaluation block on issue #<n>. Pick a strategy above, or reply "keep" to override.`
- `🏁 COMPLETED — issue #<n> already satisfies its spec. Run /skill pr-from-issue <n> if no PR exists.`

---

## Tone & output budget

- Be specific. Every claim in the assessment must point at a row in the
  signal tables or a quoted line from the spec / review-gaps block.
- Do not echo the enriched spec back. Reference its sections by name.
- Total chat output (excluding the echoed block) ≤ 30 lines.
- Never recommend a model tier without showing the signals that drove it.
