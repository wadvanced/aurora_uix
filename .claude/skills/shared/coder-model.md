# Model registry

Single source of truth for which model runs which step of the issue pipeline. Edit only here —
never hardcode a model name in a `SKILL.md` or in an agent definition.

**One axis decides every model: the complexity level the issue is started at.** A level does not
yield one model; it yields a set of four, one per skill group.

## Level → models

| Group | `normal` ← default | `high` | `max` |
|---|---|---|---|
| Coordination | Sonnet+medium | Sonnet+medium | Sonnet+medium |
| Spec / Review | Opus+high | Fable+medium | Fable+high |
| Coder | Sonnet+high | Opus+medium | Fable+medium |
| Ship | Sonnet+low | Sonnet+low | Sonnet+low |

Only **Spec / Review** and **Coder** move with the level. Coordination and Ship are pinned at
every level, for reasons that do not vary with how hard the issue is:

- **Coordination** is a first-match state machine. It caches no state across ticks, re-derives
  everything from GitHub each time, and delegates every judgement call upward as a verbatim
  `NEEDS_DECISION` (`escalation.md`) rather than deciding it — so a misroute self-corrects on the
  next pass instead of compounding. Routing that hands off its own hard calls does not get easier
  with a larger model.
- **Ship** is mechanical: branch, push, `gh pr create`, splice the issue reference into the body.
  The `gate-fix` edits it can trigger are consistency-mechanical too — `mix format`, a credo
  rewrite, a dialyzer spec. None of it is design work. A gate failure that genuinely needs design
  judgement is not `gate-fix`'s job either: it fixes mechanical issues in place and produces a
  plan for approval instead of attempting a refactor-class one. That escalation, not a larger
  model on the ship step, is the answer when it happens. Pinning also bounds the cost of the one
  step that runs on **every** node of a tree.

## Group → skills

| Group | Skills |
|---|---|
| Coordination | `orchestrate-issue`, `epic-orchestrator` |
| Spec / Review | `improve-issue`, `review-issue` |
| Coder | `code-issue` |
| Ship | `pr-from-issue`, `do-pr`, `gate`, `gate-fix`, `gate-commit` |

Sub-skills are never spawned with a model of their own. They are invoked inline by another skill
and run at that caller's model, so assigning them one would record a setting that never binds.
On the ship path the `gate*` chain therefore runs at Ship's pin however the node was coded —
the intended consequence of that pin, not a gap in it.

## Choosing a level

`improve-issue` proposes the level; the user may override it. Signals, strongest first — the
highest one that applies wins. The number of files and layers matters more than the AC count:
twenty ACs on one surface are still `normal`.

| Signal | At least |
|---|---|
| a new `%Field{}` type atom (full downstream consumer audit) | `high` |
| a capability that needs both the Ash and the Ecto (`ctx`) parser | `normal`; `high` when the two parsers diverge in mechanism |
| 5 or more files, or 4 or more layers (parser · layout · renderer · generator/handler · theme · guide schema) | `high` |
| a change to the blueprint macro expansion, or to a behaviour every renderer implements | `high` |
| a migration, or a guide schema on both backends | `normal` |

## Resolving the level

Precedence, **first match wins**:

1. A positional argument — `/skill improve-issue 905 high`.
2. A `LEVEL: <level>` line in the invoking prompt, for a spawned run. Same convention as
   `NON_INTERACTIVE:` (`escalation.md`) and `GATE_RECEIPT:` (`gate-receipt.md`).
3. The `**Complexity:** <level>` line in the issue's enriched-spec v2 block.
4. `normal`.

**An unrecognised value is a halt** — `STATUS: BLOCKED — unknown-level` — never a silent fall
back to `normal`. A typo'd level that quietly downgrades a `max` issue is indistinguishable from
a correct `normal` run, and the evidence that it happened is gone by the time the output is read.

## Where the level lives

`improve-issue` writes the level into the enriched-spec v2 block, directly under the header:

```markdown
<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** high

### Overview
```

`code-issue` and `review-issue` **read** it from there. This is what makes them re-entrant: a
section coded three days later, in a fresh session, resolves the same model as the run that coded
its predecessor, with nothing carried over in chat.

Both accept a positional argument as a **one-off override** — announced as such, and **never
written back**. The spec block is `improve-issue`'s to own, and a single coder run must not
quietly re-level the issue for every later section.

`improve-issue` invoked with an argument that differs from the persisted level updates the block
and says so (`Level: max (was: high)`). Invoked with no argument on an issue that already has a
spec, it reuses the persisted level rather than resetting to `normal`.

## Announcing

Every skill opens with one line naming the level and **its own group's** model:

```
Level: high · Spec/Review: Fable+medium
Level: high (from issue) · Coder: Opus+medium
Level: normal (default) · Spec/Review: Opus+high
Level: normal (override; issue says high) · Coder: Sonnet+high
```

The source qualifier is omitted when the level came from a positional argument, and stated
otherwise — `(from issue)`, `(default)`, `(was: <previous>)`, `(override; issue says <level>)`.

Every `👉 Next:` hand-off names the following step's group and model, because the human choosing
a model before invoking it is the one who needs that number:

```
👉 Next: code-issue 905 SCH-1  (Coder: Opus+medium)
```

The hand-off does not carry the level — the next skill reads it from the issue.

## Rules

- **Family plus explicit effort** — `Sonnet+medium`, `Opus+high`, `Fable+high`. No version
  numbers; add one only if two versions of a family become selectable at once. **Every cell
  carries an effort**; there is no implied default, and a bare family name in the table is a
  defect.
- **The level may be persisted; a model name may never be.** The level lives in the
  `**Complexity:**` line of the enriched-spec block and nowhere else — never a label, never a
  body line outside the block. A persisted model name is wrong the moment this table changes,
  with nothing to go back and correct it; a persisted level stays true and picks up the new
  mapping for free. Terminal output is the only place a model name appears.
- **The level does not change the depth of the work, only who does it.** A `max` run does not
  license a shallower spec: `improve-issue`'s executability bar is fixed at the `normal` coder
  whatever level it was invoked at.
