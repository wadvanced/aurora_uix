# GitHub Issue Skills for OpenCode (Elixir/Phoenix)

A quality-loop skill set that turns a raw GitHub issue into tested, reviewed
Elixir/Phoenix code with automatic iteration until quality thresholds are met.

## Skills included

| Skill | Purpose |
|---|---|
| `improve-issue` | Enriches a raw issue into a precise, testable spec |
| `evaluate-issue` | Evaluates an enriched spec and recommends keep-as-is (with a model tier), already-completed, or split into children |
| `split-issue` | Executes an approved split plan: creates child issues, slices the parent spec into each, wires parent ↔ children |
| `code-issue` | Implements the spec with tests (AC by AC) |
| `review-issue` | Scores completeness & coverage, produces gap lists |
| `orchestrate-issue` | Runs the code → review loop until quality thresholds are met (requires an enriched spec already on the issue) |
| `pr-from-issue` | Creates a PR from a completed issue, runs all tests |
| `gate` | Orchestrator — runs `gate-fix`, then `gate-commit` if clean |
| `gate-fix` | Runs `mix consistency` and fixes mechanical issues; emits a Refactor Plan for refactor-class issues |
| `gate-commit` | Groups the working tree into conventional commits; refuses to run unless `mix consistency` is clean |

## How to use

### Option A — Two-step (analysis + coding loop)

Spec enrichment and the coding loop are deliberately separated so each can be
run with the right model. Run `improve-issue` first (preferably with a more
capable model), then `orchestrate-issue` for the mechanical loop.

```
# Step 1 — Enrich the issue (run with the strongest model)
/skill improve-issue
<paste issue text or GitHub URL here>

# Step 2 — Run the coding loop (can use a smaller, coding-oriented model)
/skill orchestrate-issue
<issue number>
```
`orchestrate-issue` will run code → review → loop until scores ≥ 8.0/10 or
max 3 iterations. It fails fast if the enriched-spec marker block is not
present on the issue.

### Option B — Manual step-by-step
```
# Step 1 — Enrich the issue
/skill improve-issue
<paste issue text>

# Step 2 — Implement
/skill code-issue
<paste enriched spec from step 1>

# Step 3 — Review
/skill review-issue
<paste enriched spec + implementation summary>

# Step 4 — If review says LOOP, go back to step 2 in Mode B
/skill code-issue
<paste enriched spec + INCOMPLETE_TASKS + MISSING_COVERAGE from review>
```

### Option C — Create PR from completed issue
```
# After issue is completed and marked as ready to close
/skill pr-from-issue
```
The skill will:
1. Check if issue is marked as completed
2. Run all tests (`mix test`)
3. Run `gate` checks
4. Push to origin and create PR with proper formatting

## Quality thresholds

| Metric | Threshold | Meaning |
|---|---|---|
| AC completeness | 8.0 / 10 | Each acceptance criterion is implemented & tested |
| Test coverage | 8.0 / 10 | Happy paths, error paths, edge cases covered |

