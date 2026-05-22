---
name: split-issue
description: >
  Execute a previously-approved split plan on a GitHub issue: create the
  child issues, slice the parent's enriched spec into each, wire parent ↔
  children, and optionally run improve-issue on each child. Use when the
  user says "split this issue", "create the child issues", "apply the
  split", or after evaluate-issue has written a Chosen split plan section.
  Requires evaluate-issue to have been run AND a Chosen split plan to be
  present in the issue-evaluation marker block. This skill DOES create new
  GitHub issues — it is the only writer-of-issues skill in the set.
  Idempotent: re-running detects already-created children and skips them.
---

# Skill: split-issue

Execute the split plan that `evaluate-issue` recorded in the parent issue's
`<!-- issue-evaluation:start v1 -->` block. Create each child, copy the
relevant slice of the parent's enriched spec into it, link parent ↔ children
so GitHub renders progress, and (optionally) auto-enrich each child via
`improve-issue`.

This is the writer counterpart to `evaluate-issue`. `evaluate-issue` decides
*whether* to split and *how*; `split-issue` performs the split.

---

## Required input

The parent issue number (or URL). Resolve to a numeric `<n>` and use it
explicitly in every `gh` call. Do not rely on chat context.

---

## Step 0 — Re-read the parent from GitHub

Always re-read state from GitHub — never trust chat context:

```bash
gh issue view <n> --json title,body,labels,url
gh issue view <n> --comments
```

Extract from the body:

- The full `<!-- enriched-spec:start v1 -->` block.
- The full `<!-- issue-evaluation:start v1 -->` block.
- The full `<!-- split-children:start v1 -->` block, if present.

---

## Step 1 — Preconditions (fail-fast, in order)

Check each in sequence. Stop at the first failure with the listed message.

1. **Evaluation block present.** Body must contain
   `<!-- issue-evaluation:start v1 -->`.
   - On miss: `❌ Issue #<n> has no evaluation block. Run /skill evaluate-issue <n> first.`
2. **Verdict is SPLIT.** Inside the evaluation block, the line
   `**Verdict:** SPLIT — ...` must be present.
   - If `KEEP`: `❌ Verdict is KEEP — nothing to split. Run /skill orchestrate-issue <n>.`
   - If `COMPLETED`: `❌ Issue is COMPLETED — nothing to split.`
3. **Chosen split plan present.** Inside the evaluation block, a
   `### Chosen split plan` section with **at least 2** numbered children.
   - On miss: `❌ No Chosen split plan recorded. Re-run /skill evaluate-issue <n> and pick a strategy via the prompt.`
4. **Test owner present.** The `### Chosen split plan` section must contain
   exactly one line matching `**Test owner:** parent` or
   `**Test owner:** sibling`.
   - On miss: `❌ Chosen split plan lacks a Test owner line. Re-run /skill evaluate-issue <n> to set it.`
4. **Enriched spec present.** Body must contain
   `<!-- enriched-spec:start v1 -->` (we slice from it).
   - On miss: `❌ Parent enriched spec missing. Run /skill improve-issue <n> first.`

---

## Step 2 — Parse the Chosen split plan

From the `### Chosen split plan` section parse each child into:

- `title` — text after the bold marker.
- `acs` — list of AC IDs (`AC-1`, `AC-3`, …).
- `files` — list of paths.
- `model` — recommended tier (e.g. `claude-sonnet-4-6`).
- `depends_on` — list of sibling labels mentioned ("depends on A").
- `independent?` — `true` if no `depends on` clause.

Also pull from the parent's enriched-spec block (do **not** modify it):

- `Summary` (verbatim).
- The full AC list — used to look up the verbatim text for each AC ID.
- `Affected Files / Modules` — verbatim entries per file path.
- `Project Conventions Touched` — verbatim, copied to every child.

Also parse the strategy name from the line above the numbered children
(e.g. `**Strategy:** by-layer`) and the **Test owner** value (`parent` or
`sibling`).

If **Test owner = `sibling`**, append a synthetic child to the in-memory
plan **before Step 3** (it is not in the user's plan, but it must be
materialized like any other child):

- `title`: `Integrated tests for #<parent>`
- `acs`: empty (this child does not implement code)
- `files`: `test/...` paths derived from every other sibling's `files`
  list (de-duped). When a sibling's `files` cite `lib/foo/bar.ex`, the
  test-owner child cites the matching `test/foo/bar_test.exs` (or new
  `test/foo/integration/bar_test.exs` for cross-sibling flows).
- `model`: same tier the parent's recommendation in the evaluation block
  used; default to `claude-sonnet-4-6` if absent.
- `depends_on`: **every** other sibling's label.
- `independent?`: false.
- `kind`: `tests` (used to add the `kind:tests` label in Step 4).

---

## Step 3 — Idempotency check

Inside the evaluation block, look for a `### Created children` subsection
under the Chosen split plan. It contains lines like:

```
- A → #142 — <title>
- B → #143 — <title>
```

For each child in the plan:

- If its label (`A`, `B`, …) is already mapped to an open issue number,
  reuse that number — mark **reused**.
- Otherwise mark **to create**.

Verify each reused number still resolves to an open issue:

```bash
gh issue view <num> --json state --jq '.state'
```

If `CLOSED` or the issue does not exist, treat it as **to create** (re-create
under a new number; update Step 5b mapping).

---

## Step 4 — Create each missing child

For each `to create` child, in plan order:

```bash
TMP_BODY=$(mktemp)
cat > "$TMP_BODY" <<'BODY'
> **Split from parent:** #<parent>
> **Strategy:** <name>
> **Recommended model tier:** <tier>
> **Test owner:** <owner-value>           # one of: parent | sibling:#<x> | this-issue
> **Depends on:** #<sibling>              # omit this line if independent

## Original context
<verbatim Summary section from parent's enriched spec>

## Scope of this child
<verbatim child entry from the parent's Chosen split plan section>

## ACs assigned to this child
<verbatim AC bullets from parent enriched spec, only the assigned ones>

## Files in scope
<verbatim file list, only the assigned ones>

## Project Conventions
<verbatim Project Conventions Touched section from parent enriched spec>
BODY

gh issue create \
  --title "$CHILD_TITLE" \
  --label "split-of:#<parent>" \
  --label "model-tier:<tier>" \
  $EXTRA_LABELS \
  --body-file "$TMP_BODY"
```

**Pick the `Test owner` line mechanically** based on the parsed strategy
value and the child's role:

| Plan `Test owner` | Child role | Line written into child body |
|---|---|---|
| `parent` | any implementation child | `> **Test owner:** parent` |
| `sibling` | implementation child | `> **Test owner:** sibling:#<x>` (where `#<x>` is the test-sibling number; create the test-sibling **last**, so substitute its captured number when writing earlier siblings retroactively — see below) |
| `sibling` | the synthetic test-owner child | `> **Test owner:** this-issue` |

The synthetic test-owner child (`kind: tests`) also gets
`$EXTRA_LABELS="--label kind:tests"`. All other children leave
`$EXTRA_LABELS` empty.

**Retroactive sibling-number substitution.** When the strategy is
`sibling`, the synthetic test-owner child is created **last** so its number
is not known when earlier siblings are created. Two-pass approach:

1. First pass: create each implementation child with the placeholder
   line `> **Test owner:** sibling:#TBD` and capture each new number.
2. Create the synthetic test-owner child with `Depends on` listing every
   captured number. Capture its number `#<x>`.
3. Second pass: for each implementation child created in step 1, fetch
   its body, `sed`-replace `sibling:#TBD` → `sibling:#<x>`, and push back
   via `gh issue edit`.

If Step 3 idempotency already populated the test-sibling number, skip the
`#TBD` placeholder and write `sibling:#<x>` directly.

Capture the new issue number from `gh issue create`'s output.

The body is a **scope brief**, not an enriched spec. Step 6 handles enrichment.

**On `gh issue create` failure**: do not roll back already-created children.
Record what was created so far in Step 5, then fail loudly. Re-running the
skill picks up at the missing children via Step 3 idempotency.

If the dependency `#<sibling>` is itself a freshly-created child whose number
isn't known yet (because it was created earlier in this same loop), substitute
the number captured a moment ago. Children are created in plan order so
dependencies always exist before dependents.

---

## Step 5 — Wire parent ↔ children (two idempotent writes)

### 5a — `split-children` block on the parent body

Build the block:

```markdown
<!-- split-children:start v1 -->
## Children (split on <YYYY-MM-DD>, strategy: <name>, test owner: <parent|sibling>)
- [ ] #<a> — <title> · model: <tier> · test owner: <parent|sibling:#<x>>
- [ ] #<b> — <title> · model: <tier> · depends on #<a> · test owner: <parent|sibling:#<x>>
- [ ] #<x> — Integrated tests for #<parent> · model: <tier> · depends on #<a>, #<b> · test owner: this-issue   ← only present when strategy's Test owner = sibling
<!-- split-children:end -->
```

Splice into the parent body using the same `awk` pattern as
`improve-issue` Step 3 — replace if present, append if absent:

```bash
TMP_CHILDREN=$(mktemp)
cat > "$TMP_CHILDREN" <<'CHILDREN'
<!-- split-children:start v1 -->
... block content above ...
<!-- split-children:end -->
CHILDREN

TMP_BODY=$(mktemp)
gh issue view <parent> --json body --jq '.body' > "$TMP_BODY"

if grep -q '<!-- split-children:start v1 -->' "$TMP_BODY"; then
  awk -v children_file="$TMP_CHILDREN" '
    BEGIN { while ((getline line < children_file) > 0) c = c line ORS }
    /<!-- split-children:start v1 -->/ { print c; skip=1; next }
    /<!-- split-children:end -->/ { skip=0; next }
    !skip { print }
  ' "$TMP_BODY" > "$TMP_BODY.new" && mv "$TMP_BODY.new" "$TMP_BODY"
else
  printf '\n\n' >> "$TMP_BODY"
  cat "$TMP_CHILDREN" >> "$TMP_BODY"
fi

gh issue edit <parent> --body-file "$TMP_BODY"
```

### 5b — `### Created children` subsection inside the evaluation block

The evaluation block is owned by `evaluate-issue` but this subsection is
specifically the contract between the two skills, recording the actual
issue numbers so re-runs are idempotent (Step 3 reads it).

Build the new evaluation block in memory:

1. Read the current evaluation block out of the parent body.
2. Inside it, locate the `### Chosen split plan` section.
3. Add (or replace) a `### Created children` subsection immediately after
   the numbered children list:

   ```markdown
   ### Created children
   - A → #<a> — <title>
   - B → #<b> — <title>
   ```

4. Splice the updated evaluation block back into the parent body using the
   same `awk` pattern, keyed on `<!-- issue-evaluation:start v1 -->`.

Be careful not to disturb other content in the evaluation block (verdict,
sizing tables, reasoning, risks, split options) — only edit the
`### Created children` subsection.

### 5c — Label the parent

```bash
gh issue edit <parent> --add-label parent-of-split
```

`gh` is idempotent here — no-op if the label is already set.

### 5d — Flip parent's Test Ownership when strategy = `parent`

When `Test owner = parent`, the parent issue itself becomes the integrated
test surface for its children. The parent's existing enriched-spec block
likely still says `Owner: this-issue` (because at enrichment time the
issue wasn't yet a parent), but the *meaning* has changed: it now owns
tests for the union of child ACs.

Do not attempt to rewrite the parent's enriched spec from here — that is
`improve-issue`'s job, and `improve-issue` is the only skill in this set
that runs on a capable model. Instead, **append a one-line hint** above
the parent's enriched-spec block, outside any marker:

```bash
TMP_BODY=$(mktemp)
gh issue view <parent> --json body --jq '.body' > "$TMP_BODY"
if ! grep -q '^> \*\*Integrated tests owner:\*\* this-issue' "$TMP_BODY"; then
  TMP_NEW=$(mktemp)
  awk '
    /<!-- enriched-spec:start v1 -->/ && !done {
      print "> **Integrated tests owner:** this-issue (split children write implementation only)"
      print ""
      done=1
    }
    { print }
  ' "$TMP_BODY" > "$TMP_NEW" && mv "$TMP_NEW" "$TMP_BODY"
  gh issue edit <parent> --body-file "$TMP_BODY"
fi
```

This hint is picked up by a subsequent `improve-issue` run on the parent
(see Step 2 — Detect a propagated test-owner hint) and flipped into the
spec block. Step 7's output line points the user to re-run
`improve-issue <parent>` to materialize the Integrated Test Plan section.

When `Test owner = sibling`, **skip this step entirely** — the synthetic
test-sibling already carries `Test owner: this-issue` in its body.

---

## Step 6 — Optional auto-enrich

Ask the user once via `AskUserQuestion`:

> **"Run /skill improve-issue on each newly-created child now?"** (default yes)

Options: `Yes — enrich all newly-created children` / `No — leave as raw scope briefs`.

If **yes**: invoke `improve-issue` on each **newly-created** child (skip
reused ones — they were presumably already enriched on a prior run)
**sequentially**, not in parallel. `improve-issue` may itself open
`AskUserQuestion` for ambiguities, which doesn't compose with parallel
invocation.

If **no**: leave the scope briefs as-is. Tell the user the next manual step
in Step 7's output.

Do **not** auto-run `evaluate-issue` on children — their slice was already
sized in the parent's evaluation. The user can re-run it manually if they
tweak the spec later.

---

## Step 7 — Output

Echo a compact summary in chat (≤ 20 lines):

```
🪓 Split applied to #<parent> (strategy: <name>, test owner: <parent|sibling>)
Created children:
  • #<a> — <title> · model: <tier> · test owner: <parent|sibling:#<x>> · enriched: yes/no
  • #<b> — <title> · model: <tier> · depends on #<a> · test owner: <parent|sibling:#<x>> · enriched: yes/no
  • #<x> — Integrated tests for #<parent> · model: <tier> · test owner: this-issue · enriched: yes/no   ← only when test owner = sibling
Reused (already created):
  • (none)
  - or -
  • #<c> — <title>
Parent body updated with split-children block and `parent-of-split` label.
👉 Next:
  - When test owner = parent: /skill improve-issue <parent> (re-run on the parent so its Integrated Test Plan is materialized), then /skill orchestrate-issue <a> on each implementation child, then /skill orchestrate-issue <parent>.
  - When test owner = sibling: /skill orchestrate-issue <a> on each implementation child (independent first), then /skill orchestrate-issue <x> last to author the integrated tests.
```

If auto-enrich was declined, prefix the `Next` line with
`/skill improve-issue <a>` (and one line per other child).

---

## Out of scope

- Reconciling renames or deletions of children when the user edits the
  Chosen split plan after a previous run. This skill only **adds** missing
  children.
- Closing the parent issue. It stays open as a tracker; the
  `split-children` task list shows progress as child PRs land.
- Running tests / quality gates. Only writes are `gh issue create`,
  `gh issue edit`, and (optionally) invoking `improve-issue`.
- Modifying `evaluate-issue` or `improve-issue`.

---

## Tone & output budget

Be specific. Every issue number cited must come from a `gh issue create`
output captured in this run, not guessed. Total chat output ≤ 30 lines.
Never invent child titles or dependencies — they all come from the parsed
Chosen split plan.
