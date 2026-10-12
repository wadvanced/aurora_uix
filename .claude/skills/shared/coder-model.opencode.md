# Model registry — OpenCode binding

The OpenCode half of the model registry. The **policy** — the one axis
(complexity level), the four skill groups, which groups are pinned and why, the
signals that choose a level, level-resolution precedence, where the level lives,
and every rule in `coder-model.md` § Rules — is `coder-model.md`, unchanged.
This file binds that policy to OpenCode model references.

Read it **instead of** `coder-model.md` § "Level → models"; never in addition
to it. `improve-issue` still reads `coder-model.md` § "Choosing a level" for the
level signals, and every skill still resolves the level (not the model) through
`coder-model.md` § "Resolving the level".

## Which binding applies

`coder-model.md` § "Resolving the harness" decides. In short: a `HARNESS:
opencode` line in the invoking prompt selects this file; otherwise the runtime
the skill is executing in does. An unrecognised harness is a halt —
`STATUS: BLOCKED — unknown-harness` — never a silent fall back.

## Model reference syntax

OpenCode references a model as `<provider>/<model>` with an optional `#<effort>`
variant. `#effort` is this binding's spelling of `coder-model.md`'s `+effort`:

```
opencode/space-bunny-free#high
ollama/qwen3.6:35b-coder
```

A model that exposes no variant list renders bare (`opencode/big-pickle`) and
cannot carry a level. It may fill a pinned group only — never Coder or
Spec/Review, whose whole point is that the level moves them. The nine Zen models
available to this environment expose variants as follows; nothing outside this
list scales:

| Model | Variants |
|---|---|
| `opencode/space-bunny-free` | `low` `medium` `high` `xhigh` `max` |
| `opencode/muse-spark-1.3-contributor-free` | `minimal` `low` `medium` `high` `xhigh` |
| `opencode/step-5-preview-free` | `low` `medium` `high` |
| `opencode/exo-free` | `high` |
| `opencode/big-pickle` | — |
| `opencode/ling-3.1-flash-free` | — |
| `opencode/longcat-2.5-preview-free` | — |
| `opencode/mimo-v2.6-flash-free` | — |
| `opencode/nemotron-3.5-lightning-free` | — |

## Level → models (OpenCode)

| Group | `normal` ← default | `high` | `max` |
|---|---|---|---|
| Coordination | `opencode/ling-3.1-flash-free` | (pinned) | (pinned) |
| Spec / Review | `opencode/muse-spark-1.3-contributor-free#medium` | `opencode/muse-spark-1.3-contributor-free#high` | `opencode/muse-spark-1.3-contributor-free#xhigh` |
| Coder | `opencode/step-5-preview-free#high` | `opencode/space-bunny-free#high` | `opencode/space-bunny-free#xhigh` |
| Ship | `opencode/nemotron-3.5-lightning-free` | (pinned) | (pinned) |

Pinned groups, and why, are in `coder-model.md`; the reasons do not change with
the harness. Coordination and Ship use variantless models precisely because a
pinned group must not scale with the level.

The table is a starting template — retune a cell freely, keeping the variant
constraint above.

## Announcing

```
Level: high (from issue) · Coder: opencode/space-bunny-free#high
Level: normal (default) · Spec/Review: opencode/muse-spark-1.3-contributor-free#medium
👉 Next: review-issue 905 SCH-1  (Spec/Review: opencode/muse-spark-1.3-contributor-free#high)
```

The `<source>` qualifiers — `(from issue)`, `(default)`, `(was: <previous>)`,
`(override; issue says <level>)` — are exactly as `coder-model.md` § Announcing
defines them; only the `<model+effort>` rendering changes.

## Spawning

The model is bound at spawn time through OpenCode's `subagent` tool `model`
parameter (`providerID/modelID#variant`). The agent definitions carry no `model`
of their own, so the registry stays the only source. Sub-skills are still never
spawned with a model of their own.

The full Claude → OpenCode translation lives in `harness.md`.
