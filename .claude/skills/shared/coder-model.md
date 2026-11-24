# Model registry

Single source of truth for which model, at which exact version and effort, runs which step of the
issue pipeline. Edit only here — never hardcode a model, a version or an effort in a `SKILL.md`,
and never hand-edit one in an agent definition: the agents that carry them are generated from this
file (`How a cell binds`).

**One axis decides every cell: the complexity level the issue is started at.** A level does not
yield one model; it yields a set of four cells, one per skill group, each a model family and an
effort. The family becomes one exact model through the Model versions table.

## Level → models

| Group | `low` | `normal` ← default | `high` | `max` |
|---|---|---|---|---|
| Coordination | Sonnet+medium | Sonnet+medium | Sonnet+medium | Sonnet+medium |
| Spec / Review | Sonnet+high | Opus+high | Fable+medium | Fable+high |
| Coder | Sonnet+medium | Sonnet+high | Opus+medium | Fable+medium |
| Ship | Sonnet+low | Sonnet+low | Sonnet+low | Sonnet+low |

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

## Model versions

A cell names a family; this table pins the one exact model that family means. **The harness never
chooses a version.** A spawn's `model` argument takes only an alias (`sonnet`, `opus`, `fable`),
and an alias resolves to the launching session's version when the family matches and to the
harness default otherwise, so the same `sonnet` spawn can run as a different version for an
issue's last sections than for its first, only because a different session launched them. A run's
models must not depend on which session launched it, or on when.

| Family | Model ID | Announced as |
|---|---|---|
| Sonnet | `claude-sonnet-5-5` | Sonnet 5.5 |
| Opus | `claude-opus-5-5` | Opus 5.5 |
| Fable | `claude-fable-5-2` | Fable 5.2 |

**Adopting a new model version is a deliberate edit, never automatic:** change the row here, then
run the `sync-pipeline-agents` skill. The same two steps follow **any** edit to the Level → models
table.

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

## How a cell binds

A spawn call cannot carry a cell. It has no effort argument, and its `model` argument takes only
an alias, never a version. The one thing the harness binds exactly is an agent definition's own
`model:` and `effort:` lines. So every cell a spawn can need exists as an agent:

| Group | Agent |
|---|---|
| Coordination | `epic-orchestrator` |
| Spec / Review | `pipeline-worker-<level>-spec-review` |
| Coder | `pipeline-worker-<level>-coder` |
| Ship | `pipeline-worker-<level>-ship` |

`<level>` is `low`, `normal`, `high` or `max` — twelve workers. Each carries its cell's Model ID in
`model:` and its cell's effort in `effort:`. A spawn names the agent and **never passes `model`**:
the argument would override the agent's pin with an alias. A step is therefore spawned by name
alone — `code-issue` at level `high` is `pipeline-worker-high-coder` — with nothing to resolve.

**The agents are generated, never written.** `.claude/scripts/pipeline-agents.sh generate`
renders the twelve workers from the two tables above and sets the `model:` and `effort:` lines of
`.claude/agents/epic-orchestrator.md` from the Coordination row. It runs only through the
`sync-pipeline-agents` skill, which only a user invokes — no pipeline step ever regenerates them.
Coordination's four cells must be identical: one agent cannot run at four settings, and the
script refuses a table where they differ.

**A mismatch is a halt, checked twice:**

- **At launch** — `orchestrate-issue` runs `.claude/scripts/pipeline-agents.sh check` before it
  spawns anything. A worker that is missing, stray, hand-edited or stale against this file, or an
  `epic-orchestrator` whose `model:` or `effort:` differs from the Coordination row, ends the run
  with `STATUS: BLOCKED — agent-mismatch`. The fix is the `sync-pipeline-agents` skill, never an
  edit to an agent.
- **At run time** — every worker and the `epic-orchestrator` read what the run is actually
  bound to, before any work: the model ID their environment states, and the effort in
  `CLAUDE_EFFORT`. Either one differing from the agent's cell ends that run with
  `STATUS: BLOCKED — binding-mismatch`, naming what was expected and what was found. That
  catches what the launch check cannot see: a spawn that passed a `model` argument, which
  outranks an agent's `model:` line, and a harness that bound anything other than what the
  agent's definition says.

An agent the session does not offer is a halt too — `STATUS: BLOCKED — unknown-agent` — never a
spawn through `general-purpose`, which runs at whatever model and effort the parent happens to
have.

**A skill run by hand is not spawned**, so neither half binds: it runs at the model and effort
of the session it was invoked in. That is why every `👉 Next:` hand-off names both, version
included, so the session can be set to exactly that model first.

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
| none of the above: one surface, one backend, no migration (docs, copy, a small fix) | `low` |

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

Every skill opens with one line naming the level and **its own group's** model, written with the
family's "Announced as" name so the version is visible:

```
Level: low · Coder: Sonnet 5.5+medium
Level: high · Spec/Review: Fable 5.2+medium
Level: high (from issue) · Coder: Opus 5.5+medium
Level: normal (default) · Spec/Review: Opus 5.5+high
Level: normal (override; issue says high) · Coder: Sonnet 5.5+high
```

The source qualifier is omitted when the level came from a positional argument, and stated
otherwise — `(from issue)`, `(default)`, `(was: <previous>)`, `(override; issue says <level>)`.

Every `👉 Next:` hand-off names the following step's group and model, because the human choosing
a model before invoking it is the one who needs that number:

```
👉 Next: code-issue 905 SCH-1  (Coder: Opus 5.5+medium)
```

The hand-off does not carry the level — the next skill reads it from the issue.

## Rules

- **Family plus explicit effort in a cell; the version only in the Model versions table.** Cells
  read `Sonnet+medium`, `Opus+high`, `Fable+high`, and one row per family turns the family into
  an exact Model ID. **Every cell carries an effort**; there is no implied default, and a bare
  family name in the table is a defect.
- **An agent definition decides nothing.** A `model:` or `effort:` line appears in
  `.claude/agents/` only as generated output of this file (`How a cell binds`), and the launch
  check halts the run when one differs from it. Editing an agent to change what a step runs at
  is a defect; so is passing `model` on a spawn.
- **The level may be persisted; a model name may never be.** The level lives in the
  `**Complexity:**` line of the enriched-spec block and nowhere else — never a label, never a
  body line outside the block. A model name or version written onto an issue or into a spec is
  wrong the moment this table changes, with nothing to go back and correct it; a persisted level
  stays true and picks up the new mapping for free. Outside this file and the agents generated
  from it, terminal output is the only place a model name or version appears.
- **The level does not change the depth of the work, only who does it.** A `max` run does not
  license a shallower spec: `improve-issue`'s executability bar is fixed at the `normal` coder
  whatever level it was invoked at.
