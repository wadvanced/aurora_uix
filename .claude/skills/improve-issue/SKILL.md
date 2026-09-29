---
name: improve-issue
description: >
  Partition and enrich a GitHub issue into an ordered set of self-contained,
  atomic sections — Documentation, Schema, Parser, UI — each deliverable as its
  own PR, for aurora_uix (an Elixir/Phoenix low-code UI generation library with
  Ash and Ecto backends). Use whenever the user says "work on issue", "improve
  issue", "enrich issue", "clarify requirements", or pastes an issue URL/number.
  Always runs FIRST, before code-issue — it produces the sectioned spec that
  code-issue implements one section at a time. Presents the spec for approval
  and writes nothing until a human approves it.
---

# Skill: improve-issue

Turn a raw GitHub issue into a sectioned spec that the `normal` coder executes without guessing.
Each section is coded on its own branch and merged through its own PR.

A state machine. One run executes the steps below top to bottom — steps 1–4 once, steps 5–12
once per pass.

`aurora_uix` is a **low-code UI generation library**, not an application: host applications
declare resource metadata and a layout, and the library generates LiveView index / form / show
UIs over **two interchangeable backends** — Ash and Ecto (`aurora_ctx`) — both normalized into
`%Aurora.Uix.Field{}`. That boundary shapes every spec (Writing rule 8).

## Glossary

Each term has one meaning in this file. No synonym is used.

| Term | Meaning |
|---|---|
| **spec** | `specs/issue-<n>-enriched-spec.md` on `main` — the only authoritative copy |
| **draft** | `/tmp/improve-issue-<n>-spec.md` — the text this run builds and a human approves |
| **working text** | the spec text this run is editing; it becomes the draft at Present |
| **mirror** | the pointer and Section Map copy in the issue body; regenerated, no authority |
| **store** | write the draft to the spec through `spec-store` (branch → PR → merge), which also regenerates the mirror and posts the resolution comment |
| **section** | one unit of delivery: one `<SEC-ID>`, one branch, one PR |
| **fence** | the `<!-- section:<SEC-ID>:start -->` / `:end -->` line pair that delimits a section |
| **enrichment** / **re-enrichment** | a run with no spec / a run that edits an existing spec |
| **defect**, **feedback**, **resolution comment** | defined in `../shared/improve-issue/comment-protocol.md` |
| **scope** | the sections this run drafts or changes |

## Invariants

1. Nothing is stored, and no comment is posted, until a human approves the draft's exact bytes.
   This holds on every run, including a one-word re-enrichment.
2. This skill edits no file in the repository — no documentation, no code. It writes only
   `/tmp/improve-issue-<n>-*` files; a sub-skill it invokes writes its own `/tmp` files, and the
   spec reaches the repository only through `spec-store`'s spec PR. `DOC-1` describes
   documentation edits; `code-issue` applies them.
3. This skill never creates, splits or closes an issue.
4. No question survives into the spec. A question is never answered by assumption. The spec has
   no "Open Questions" section.
5. The spec's depth is fixed at what the `normal` coder needs, at every level. The spec records
   the level, never a model name.
6. A section whose PR is merged is never changed. A section whose PR is open may be changed — and
   the user is told, because the open branch's local AC ticks will then conflict with the rewrite
   (`spec-store` § Re-enrichment while sections are in flight).
7. A `<SEC-ID>` is never renumbered and never re-used.
   Why: it is a branch name, a PR title, a review-table row, a section-log marker and a fence.
8. Facts come from GitHub and the repository, never from chat context. An existing spec is read
   through `spec-load`, never from the issue body.
9. This skill spawns no subagents. Grounding, drafting, checking and revision run inline,
   sequentially, in this run's own context. Being spawned as an agent by a caller is
   unaffected.

## Machine

`R` is this run's working record. **Steps communicate only through `R`.**

| Field | Content |
|---|---|
| `n` | the issue number |
| `mode` | `interactive` \| `non-interactive` |
| `decisions` | every `DECISION:` line of the prompt |
| `changes` | the text of a change request, or none |
| `level_arg` | the level the prompt asked for, or none |
| `level` | `normal` \| `high` \| `max` |
| `obs` | `/tmp/improve-issue-<n>-issue.json`, `/tmp/improve-issue-<n>-comments.jsonl`, the mentioned issues, `spec: /tmp/spec-<n>.md \| missing`, `prs`: per Section Map row, its PR's number and state, or none |
| `inputs` | unresolved defect and feedback comments: `id`, kind, `<SEC-ID>`, defect `Class:` |
| `scope` | `all` on an enrichment; otherwise the ids this run changes or adds — it grows as the run edits |
| `answered` | the count of questions the user answered in this run |
| `aids` | the reading aids Present built, or none |
| `unchanged` | set when the working text is byte-identical to the spec |
| `verdict` | `approved` \| `changes` \| `rejected`, or unset |
| `stored` | the merge-commit sha `spec-store` returned, or unset |
| `halt` | `{kind, payload}` — first writer wins |

Each step opens with a **pre-flight** that yields one verdict:

| Verdict | Meaning |
|---|---|
| **continue** | do the step |
| **skip** | nothing for this step this pass — next step |
| **stop** | set `R.halt` — next step |

**Universal pre-flight, before a step's own:** `R.halt` set → **skip**. Step 12 alone is exempt.
A step's `Loads` file is read only on **continue**, at most once per run.

| `halt.kind` | Payload |
|---|---|
| `relay` | a sub-skill's terminal output, verbatim |
| `decision` | one question, its options, and the facts already established |
| `blocked` | a slug, and the facts behind it |

### Question rule

A **question** is any point where two readings, two designs or two names remain after the
repository and the documentation have been read. Every step applies this rule at the point
where the question appears:

| Condition | Action |
|---|---|
| a line in `R.decisions` answers it | take that answer; continue |
| `mode = interactive` | `AskUserQuestion`; take the answer; `answered += 1`; continue |
| `mode = non-interactive` | **stop** `decision`, with the same options in the same order as the interactive question |
| the user cannot answer it | **stop** `blocked` `unresolved-question` |

Always a question, never a judgement of this skill:

- a design that removes, bypasses or makes unreachable an existing guard, validation or
  constraint;
- a design that puts `Ecto.Association.*` / `Ecto.Embedded` outside `integration/ctx/`, or
  `Ash.Resource.*` outside `integration/ash/`;
- a capability specced for one backend only, when the issue does not say why;
- a design that has the library build a changeset (`cast_assoc`, `cast_embed`,
  `manage_relationship`) — the library is transport-only for writes, so this is a scope expansion;
- a `%Field{}` consumer site whose add / do-NOT-add verdict the code does not decide;
- documentation content that contradicts an existing rule;
- a symbol or a capability claim that stays unclassified after searching.

---

## 1 · Boot

- **Pre-flight:** continue.
- **Loads:** `../shared/turn-discipline.md`
- **Do:** parse the prompt.

  | Input | Sets |
  |---|---|
  | issue URL, `#123`, a number, or a pasted issue body carrying either | `n` |
  | the line `NON_INTERACTIVE: true` | `mode = non-interactive`; absent → `interactive` |
  | each `DECISION:` line | `decisions` |
  | a `CHANGES:` line, under `non-interactive` only | `changes`; under `interactive` the line is ignored |
  | a positional level, else a `LEVEL:` line | `level_arg` |

- **Writes:** `n`, `mode`, `decisions`, `changes`, `level_arg`.

## 2 · Load

- **Pre-flight:** continue.
- **Do**, batched in one turn:
  1. Issue: `gh issue view <n> --json title,body,state,labels`. Save it as
     `/tmp/improve-issue-<n>-issue.json`.
  2. Comments, with ids:
     ```bash
     gh api "repos/wadvanced/aurora_uix/issues/<n>/comments" --paginate \
       --jq '.[] | {id, body}' > /tmp/improve-issue-<n>-comments.jsonl
     ```
  3. Spec: `spec-load <n>`. `STATUS: OK <sha>` → `obs.spec = /tmp/spec-<n>.md`.
     `STATUS: BLOCKED — spec-missing` → `obs.spec = missing`; this run is an enrichment.

  Then, in one more turn: fetch the title, body and state of every issue the body or a comment mentions as `#<k>` or
  by URL, one level deep;
  and, for each Section Map row of the spec, record its PR in `obs.prs`:
  `gh pr list --head <branch> --state all --json number,state`.

  The **working text** the run edits:

  | Condition | Working text |
  |---|---|
  | `changes` set and the draft file exists | the draft |
  | otherwise, `obs.spec` is a path | that file |
  | otherwise | none — drafted from nothing |

- **Writes:** `obs`.

## 3 · Gate

- **Pre-flight:** continue.
- **Loads:** `../shared/coder-model.md`
- **Do:**
  1. Resolve the level, first match: `level_arg` · the spec's `**Complexity:**` line ·
     `normal`. An unrecognised value → **stop** `blocked`
     `unknown-level`. On an enrichment, propose the level from `coder-model.md` § Choosing a
     level; the user's `level_arg` overrides it.
  2. Announce, before any other output, in the format and with the `<source>` that file
     defines: `Level: <level>[ (<source>)] · Spec/Review: <model+effort>`. A halt's output
     follows this line.

- **Writes:** `level`.

## 4 · Inputs

- **Pre-flight:** continue.
- **Loads:** `../shared/improve-issue/comment-protocol.md`, only when a line of the comments file
  matches `<!-- spec-defect #` or `<!-- review-feedback #`.
- **Do:** with that file loaded, list the unresolved defects and feedback as it defines them;
  each one is handled as it prescribes, in this run. Otherwise `inputs` is empty.
  When `obs.spec` is a path, compare every requirement in the issue body and its comments with
  the spec's ACs. A requirement no AC covers is **owed**: add the section it belongs to, or note
  it as new work for Partition.
- **Writes:** `inputs`; `scope`:

  | Condition | `scope` |
  |---|---|
  | `obs.spec = missing` | `all` |
  | `changes` set and naming no `<SEC-ID>` | every section whose PR in `obs.prs` is not merged. When there is none, `changes` is new work for Partition |
  | otherwise | the `<SEC-ID>` of every input, of every owed requirement, and every `<SEC-ID>` `changes` names. It may be empty |

## 5 · Ground

- **Pre-flight:** `scope` empty and no new work noted → skip.
- **Do:** ground every name the sections in `scope` will use. Read the guidance and the
  documentation before the code — they are the specification:

  | Read | For |
  |---|---|
  | `AGENTS.md` | the backend boundary, `%Field{}` risk, renderer, styling, testing and gate rules |
  | `guides/**/*.md` | the documented behaviour and vocabulary the issue changes |
  | `CHANGELOG.md` | the current unreleased version's section, and the entry style |
  | `lib/aurora_uix/field.ex`, `lib/aurora_uix/integration/{ash,ctx}/` | the `%Field{}` shape, every type atom, parser clauses and their order (which functions have no catch-all) |
  | `lib/aurora_uix/layout/` | `blueprint.ex`, `create_ui.ex`, `resource_metadata.ex` — what metadata and layout declarations expand into |
  | `lib/aurora_uix/templates/basic/` | renderers (`default_renderer.ex` dispatch), generators, handlers, actions, themes (`themes/base.ex` `rule/1` clauses), components |
  | `lib/aurora_uix/guides/{blog,inventory}/`, `priv/repo/migrations/`, `priv/resource_snapshots/` | guide schemas (Ash / Ecto), migrations and snapshots |
  | `test/support/{helper.ex,app_web/routes.ex}`, the touched modules' tests | fixtures, registered routes and existing coverage |

  On a re-enrichment, re-ground the working text of every section in `scope` against the
  current repository.

  **Grounding rules:**

  1. **Verify every name at its definition.** This covers functions, parser clauses, `%Field{}`
     type atoms, `auix` assign keys, generator/handler callbacks, DOM selectors, `data-*` attrs,
     component attr and input names, theme rule names, and third-party DSL options. Open the
     `def`, the template markup or the package source and copy the name verbatim. A call site, a
     grep hit, memory and a subagent's report are not definitions. A name the section itself
     introduces is prescribed as new.
  2. **Write every file-editing instruction with that file open at the edit site.** A report is
     evidence only for the lines it quotes.
  3. **Sweep every consumer of what the issue changes**, not only the modules it edits. For a
     `%Field{}` type atom, `rg -n ':<sibling_atom>' lib/` and read every hit; for a parser
     function, its callers; for a renderer, its dispatch clause and the `layout_type` values it
     branches on. The spec never hand-rolls a check something downstream already performs.
  4. **An inventory is extracted, never recalled.** A statement of what a construct contains — a
     parser clause list, a `%Field{}` `data` map's keys, a renderer's assigns, a component's
     attrs — is produced by extracting the block and reading the extraction.
  5. **Classify every symbol and every capability claim** as `existing` (cited) or `new` (with
     the search terms that returned nothing). A claim such as "the Ash parser already handles
     embedded resources" is verified in code. One that cannot be classified is a question.
  6. **Grounding never defers.** The spec may tell the coder to copy from a named, verified
     source. It never tells the coder to discover whether a parser clause, renderer dispatch or
     field key exists.

  Budget: 15–20 targeted searches plus a handful of file reads per section, the same for every
  section. The budget is a floor: it never excuses an unproven claim.

## 6 · Partition

- **Pre-flight:** `obs.spec` is a path and no new work is noted → skip.
- **Do:** build the Section Map. Ground every row added here under the Grounding rules. On a re-enrichment, existing rows keep their ids; new work
  appends ids. A row is removed only when its section has no section-log comment and no PR of
  any state.

  ### Types

  | Type | Id | One section per |
  |---|---|---|
  | Documentation | `DOC-1` | issue — exactly one, carrying every documentation edit the issue owes, and its CHANGELOG entry |
  | Schema | `SCH-k` | guide backend (Ecto `inventory/` `accounts/`, or Ash `blog/`) whose persisted entities change |
  | Parser | `PAR-k` | backend (`ash` or `ctx`) whose parser, CRUD or query behaviour changes |
  | UI | `UI-k` | unit of generated UI that changes: a renderer, a generator/handler, a theme, or a layout/blueprint piece |

  A type the issue does not need is absent. `DOC-1` is absent only when the issue delivers
  neither a feature nor a fix (`documentation.md` rule 14); the Overview then says so in one
  sentence. A capability both backends must support is one Parser section per backend, or
  `### Out of Scope` states why only one applies.

  ### Ids

  Unique per type, numbered per type, appended in Section Map order. A gap left by a removed
  section stays a gap.

  ### Order and dependencies

  1. Map order is Documentation, all Schema, all Parser, all UI. Map order is execution order.
  2. Every section carries `Depends on:` — sibling ids, or `none`.
  3. A dependency points backward across the layer order, or sideways inside a layer. UI
     depends on Parser, Parser on Schema (only when it needs the fixtures). Nothing depends on
     UI. The graph is a DAG.
  4. `DOC-1` depends on nothing. Every other section's dependency chain reaches `DOC-1`: the
     first Schema section — or the first Parser, or the first UI section when there is none
     before it — carries `Depends on: DOC-1`. With no `DOC-1`, those sections carry `none`.
  5. A section starts only when every dependency's PR is merged. Independent sections of one
     type may run in parallel.
  6. A dependency on another issue's section is written `#<n>·<SEC-ID>`. Use it when this section
     builds on code that section creates or changes; never duplicate that work.
  7. `DOC-1` is the only section that prescribes a documentation edit.
  8. Two sections that edit the same region of one code file declare a dependency: the later
     depends on the earlier.

  ### Atomicity

  Every section passes this test: *merged alone on top of its dependencies, the library compiles
  with `--warnings-as-errors`, the guide schemas migrate, and `mix consistency` and the full
  suite stay green.* When a section fails it, move content between sections until it passes.

  A section that introduces a `%Field{}` type atom owns every consumer site whose absence would
  raise for that atom (`filter_preloads/1`, `replace_related_field_data/2` and their siblings);
  the sites whose absence only degrades may sit in a later UI section that depends on it.

  ### Scope separation

  An issue is never oversized; more work is more sections. Propose a separation only when the
  issue bundles parts with distinct goals, or a part that cannot be specced until another
  part's output exists. The proposal names each part's goal, its contents, and why it cannot be
  specced now. It is a question (Question rule). When the user separates, enrich the retained
  scope only and record the rest under `### Out of Scope`.

  ### Branch and PR title

  | Item | Form | Example |
  |---|---|---|
  | Branch | `federico/<n>-<sec>-<slug>`, `<sec>` lowercased | `federico/360-doc-1-changelog`, `federico/360-par-2-one-to-one` |
  | PR title | `<conventional type>: … (#<n> · <SEC-ID>)` | `docs: … (#360 · DOC-1)`, `feat: … (#360 · PAR-2)` |

  Every branch is unique within the issue.
  Why: `code-issue` and `review-issue` find a section's PR by an exact `gh pr list --head` probe.
  The PR title is never used to detect state: GitHub's title search matches `SCH-10` for `SCH-1`.

- **Writes:** `scope` (every row added or re-scoped).

## 7 · Draft

- **Pre-flight:** `scope` empty → skip.
- **Loads:** `../shared/house-conventions.md`; `../shared/improve-issue/templates/<type>.md` —
  `documentation`, `schema`, `parser`, `ui` — one file per type that has a section in
  `scope`, and no other.
- **Do:** write the working text: the skeleton below, and every section in `scope` from its
  type's template under its type's rules. Sections outside `scope` are copied unchanged.
  Untick every AC whose text this run changed.
  Why: `code-issue` writes a red test for the new words and `review-issue` re-proves them.

  ### Skeleton

  ```markdown
  <!-- enriched-spec:start v2 -->
  ## Enriched Spec

  **Complexity:** <R.level>

  ### Overview
  <2–3 short sentences: what this issue delivers, and which backends it covers>

  ### Section Map
  | ID | Type | Scope | Depends on | Branch | PR title |
  |---|---|---|---|---|---|
  | DOC-1 | Documentation | <file § section, …> | none | federico/<n>-doc-1-<slug> | docs: … (#<n> · DOC-1) |
  | PAR-1 | Parser | <ctx \| ash> · <capability> | DOC-1 | federico/<n>-par-1-<slug> | feat: … (#<n> · PAR-1) |

  A section starts only when every dependency is **merged**. Independent
  sections may run in parallel. Status is derived from GitHub, never recorded
  here.

  <one fenced section per Section Map row, in map order>

  ---

  ### Out of Scope
  - <what this issue explicitly does NOT include>
  <!-- enriched-spec:end -->
  ```

  The fence is the only section delimiter. Every section is wrapped in one; every fence id is a
  Section Map row; no id is fenced twice; nothing sits between one section's `:end` line and the
  next section's `:start` line.
  Why: `spec-load` extracts a section by matching the two fence lines whole. A heading match
  would take `SCH-10` for `SCH-1`.

  ### Writing rules

  1. **Register.** Numbered sequential steps. Short plain sentences; noun phrases, imperatives
     and tables. One instruction, one outcome. No motivating narrative, no rationale, no
     restating of the problem. A sentence the coder can lose without acting differently is
     deleted.
  2. **No optionality.** "or", "consider" and "if appropriate" never appear in an instruction.
  3. **Citations.** Every existing symbol is cited by a signature that identifies exactly one
     definition. A line number is used only when no named anchor exists. Every new symbol is
     marked `new`, with its search evidence.

     | Cited thing | Signature |
     |---|---|
     | Function | `file.ex` + `name/arity` |
     | Parser clause | `fields_parser.ex` + function `name/arity` + the clause head, verbatim |
     | `%Field{}` type atom | `field.ex` + the atom, and the parser clause that produces it |
     | Renderer dispatch | `default_renderer.ex` + the `render/1` clause head, verbatim |
     | Component | `file.ex` + `name/1` + the attr names relied on |
     | Theme rule | `themes/base.ex` + the `rule/1` clause head |
     | Guide schema / migration | `guides/<group>/<schema>.ex` / `priv/repo/migrations/<file>` |
     | Documentation | `§ Section name` |

  4. **Strings.** Every user-visible string is fixed: exact text, wrapped in `dt/1`.
  5. **Contract changes.** A section that changes a function's return shape, a `%Field{}` key, a
     `data` map key or a `@spec` lists the `@spec` change and every current caller with its new
     handling.
  6. **Markup changes.** A section that gates, moves, renames or removes existing markup — an
     `:if`, a selector, an input name, an id, a label — greps that selector, name or label
     across `test/`, and lists every test that drives it with its new drive.
  7. **Load guarantees.** A section that consumes a preloaded association or a `%Field{}` `data`
     key names the exact parser or CRUD path that fills it, and confirms that path fills it.
  8. **Standing project rules** are restated only where the section touches them:
     - the backend boundary — `Ecto.Association.*` / `Ecto.Embedded` only in `integration/ctx/`,
       `Ash.Resource.*` only in `integration/ash/`; everything downstream stays backend-agnostic
       and consumes `%Field{}` atoms;
     - both backends supported, or the reason only one applies;
     - a new `%Field{}` type atom carries the type-atom audit (`parser.md` rule 5);
     - the library is transport-only for writes: it never builds a changeset;
     - localization through `dt/1`, extracted to `priv/gettext/*.pot`, no per-locale
       translations;
     - no inline `class=`; styling is an `auix-*` rule in `themes/base.ex`;
     - `doctor` coverage: `@moduledoc` with `## Key Features` / `## Key Constraints`, `@doc` +
       `@spec` on the first clause of public functions, `@spec` on private functions;
     - streams for collections; function components over raw HTML tags for styled elements;
       no LiveComponent without a stated strong need;
     - `mix test` does not run migrations.
  9. **House conventions.** `../shared/house-conventions.md` applies to every sentence of the
     spec.
  10. **Edge cases.** Every Parser and UI section states at least one error or degraded path as an
      AC. The recurring ones: an unregistered related resource (`field.data.resource == nil`);
      an unloaded association (`%Ecto.Association.NotLoaded{}` / `%Ash.NotLoaded{}`) and whether
      the missing preload raises or degrades; a parser clause reached after a catch-all; host
      misconfiguration that must surface loudly rather than be swallowed.

  11. **Dependencies.** A section that adds a Hex package justifies it; `ash`, `ash_phoenix`,
      `ash_postgres`, `ecto_sql`, `phoenix_ecto` and `aurora_ctx` are already hard deps. A section
      that adds a guide-schema migration says which path it takes (`schema.md` rule 5).

  ### Test rules

  1. **Placement**, in order of preference, stated on every red-test row:

     | Placement | When | Row says |
     |---|---|---|
     | amend an existing test | a test already exercises the port | `amend <file> "<test>"` |
     | add to an existing file | the module under test has a test file | `add to <file>`, in the matching `describe` |
     | new file | the module under test has none | `new file`, with the search that found none |

  2. **Layer.** Parser output → `test/cases/integration/{ash,ctx}/` (no DB) and the shared golden
     `test/cases/integration/fields_parser_validations_test.exs`; metadata / layout →
     `test/cases/`; rendered behaviour → `test/cases_live/` (the default for UI work); doctests →
     `test/doctests/`. `test/browser_cases/` (Wallaby) only when a behaviour is genuinely
     impossible to observe with LiveViewTest, and the row says why.
  3. **Setup.** Every row states how the test reaches the port: the schema declared inside the
     test module (parser tests), or `auix_resource_metadata` + `auix_create_ui` and the route
     (registered in `test/support/app_web/routes.ex` via `RoutesHelper.register_crud/2`), the
     sample data from `test/support/helper.ex` (`create_sample_products/2`,
     `delete_all_inventory_data/0`, …). No mocks, no `Process.sleep/1`.
  4. **Assertion API follows the mount type.** Name the mount type when it is not a LiveViewTest
     view.

     | Mount | Assert with |
     |---|---|
     | LiveViewTest view | `has_element?/2`, `element/2` on stable selectors — never `=~` on HTML, never `auix-field-*` ids |
     | parser output | `Validations.compare_maps/2 == []` or a match on the `%Field{}` |
     | directly rendered component | `render_component/2`, as its test file already does |

  5. **Every Parser and UI AC has a red-test row, or ends**
     `(<visual|mechanical|manual> — no red test; verified by <means>)`.
  6. **Both backends.** A Parser section for one backend names the mirrored section for the other,
     or the sentence in `### Out of Scope` that excuses it.

- **Writes:** `scope` (every section this step edited).

## 8 · Check

- **Pre-flight:** `scope` empty → skip.
- **Do:** for every section in `scope`, confirm each rule under each heading below. Fix every
  failure in the working text; never note one and move on. When `R.changes` states that this
  file gained a rule after the spec was stored, check every section whose PR is not merged.

  | Check | Home of the rule |
  |---|---|
  | Atomicity | 6 · Partition § Atomicity |
  | Map complete; ids unique per type; every `Depends on:` id exists; DAG; nothing points forward | § Ids, § Order and dependencies |
  | One `DOC-1`, or the Overview's one-sentence absence; every chain reaches it | § Types, § Order and dependencies 4 |
  | `DOC-1` is the only documentation writer; shared code regions declare a dependency | § Order and dependencies 7–8 |
  | Branch unique; PR title form | § Branch and PR title |
  | Fences | 7 · Draft § Skeleton |
  | Register; no optionality | § Writing rules 1–2 |
  | Citations; new symbols carry search evidence | § Writing rules 3 |
  | Strings; contract changes; markup changes; load guarantees | § Writing rules 4–7 |
  | Backend boundary; both backends or the stated reason; type-atom audit complete; transport-only | § Writing rules 8, `parser.md` rules 1, 5 |
  | Edge-case ACs | § Writing rules 10 |
  | Placement; layer; setup; assertion API; every AC tested or marked; both backends | § Test rules |
  | Names verified at their definition; inventories extracted; capability claims verified; no coding-time existence check | 5 · Ground § Grounding rules |
  | Per-type rules | the loaded template's `## Rules` |
  | No guard removed without a recorded decision; zero questions remain | § Question rule, Invariant 4 |
  | No model name; `**Complexity:**` is the one level mention | Invariant 5 |
  | CHANGELOG entry in `DOC-1`, with no issue link; H-1 (no `file.md:NNN`), H-2 (simple component names), H-3 (no AC that only observes a stub), H-5, and the rest of the list | `house-conventions.md` |

  **Hedge grep**, case-insensitive, over the sections in `scope`. `|` separates alternatives; the
  spaces around it are not part of a pattern:

  ```
  confirm with | before writing | before editing | if it does not |
  identify it with | verify .* exists | say which | consider | if appropriate | \bor\b
  ```

  Every hit is removed, or justified. A `\bor\b` hit inside a quoted string is justified by that
  fact; a hit in instruction prose is never justified. The grep and its output never appear in
  the spec or the issue.

## 9 · Verify

- **Pre-flight:** `scope` empty → skip.
- **Do:** prove the working text, section by section over `scope`, in two parts. This step
  answers one question: can the `normal` coder execute this text without guessing and without
  interpreting it? The bar does not move with `R.level`.

  ### Part 1 — falsification

  Walk the written text, not the memory of researching it. Every claim is false until a command
  run during this step proves it.

  | Claim | Proof |
  |---|---|
  | an `existing` symbol | open its definition now; compare name, arity, options and field names character by character. A paraphrase an instruction is derived from fails. |
  | a `new` symbol | run the recorded search terms verbatim now. A hit falsifies the claim. |
  | a type-atom audit | re-run the sibling-atom `rg` now; every hit has a row, no row is missing |
  | a red-test row | `amend` — the named test exists; `add to` — the file exists; `new file` — it does not. The assertion sketch states nothing the cited source disproves. |
  | a documentation edit in `DOC-1` | the file exists; the `§` anchor is in the current doc; the text to change is there verbatim; the CHANGELOG version section exists |
  | an instruction naming a function or call site to edit | open that site now; it contains what the instruction says it contains |
  | a gate, move, rename or removal of markup | re-run the selector/name/label grep across `test/` now; the section names every hit with its new drive |
  | the section as a whole | no two statements disagree; no instruction disagrees with the citation it leans on |

  **Ledger.** Build a table `claim | command run | output excerpt | verdict`, one row per claim.
  A claim with no command fails. Session memory, an earlier turn's output and a subagent's report
  are not commands. The ledger is working material: it never reaches the draft, the spec, the
  issue or this run's output.

  A failed claim → re-ground it (Grounding rules), rewrite the sentence, walk the section again.

  ### Part 2 — comprehension walk

  Skip for a section that is in `scope` only through a defect of `Class:` `mechanical` or
  `oversight`. Otherwise, for every numbered instruction under `#### Implementation details` and
  every red-test row, write one checklist line from the spec text alone: the file the coder
  opens, the exact change, what it runs, the outcome it expects. Then ask of each line:

  | Question | Failure |
  |---|---|
  | Did writing the line need an inference? | yes |
  | Do the same words fit a second target, value, file or approach? | yes |
  | Does the approach touch an AGENTS.md STRICT rule (the backend abstraction boundary above all)? Quote the rule. | the approach breaks it |

  A failed line → rewrite the instruction into the one reading that survives, citing the fact or
  rule that decided it; re-ground first when the fix turns on an unverified fact; ask the three
  questions of the rewritten line. A section is presented only when every line survives
  every part that applies to it.

## 10 · Present

- **Pre-flight:** `obs.spec` is a path and the working text is byte-identical to it → set
  `unchanged`; skip.
- **Do:**
  1. Write the working text to the draft, replacing any file at that path, from `<!-- enriched-spec:start v2 -->` through
     `<!-- enriched-spec:end -->`.
  2. `R.inputs` non-empty → write the resolution comment to
     `/tmp/improve-issue-<n>-resolution.md`. Empty → delete that path.
  3. When `obs.spec` is a path, build the **reading aids**: one change line per section
     (`SCH-1 unchanged · PAR-2 rewritten (defect 2481937461) · UI-1 new`), then the feedback item
     lines exactly as the resolution comment carries them. When any Section Map row has an open
     PR (`obs.prs`), add one line naming those sections: their branches' local ticks will conflict
     with this rewrite.
  4. `mode = non-interactive` → nothing more; no verdict is set.
  5. `mode = interactive` → emit the draft verbatim in chat — never a summary, an outline or
     "unchanged sections omitted" — then the reading aids. Call `ExitPlanMode` with that same
     text, prefixed by the line `Store this enriched spec for issue #<n>.`

     | Result | `verdict` |
     |---|---|
     | approved | `approved` |
     | rejected, with text | `changes`; `R.changes` = that text |
     | rejected, no text | `rejected` |

- **Writes:** `unchanged`, `aids`, `verdict`, `changes`.

## 11 · Store

- **Pre-flight:** `verdict` is not `approved` → skip.
- **Do:** invoke `spec-store <n> write /tmp/improve-issue-<n>-spec.md`, adding
  `/tmp/improve-issue-<n>-resolution.md` when that file exists. `spec-store` drives the whole
  branch → PR → checks → `merge-pr` → mirror sequence and returns one terminal line. The draft is
  stored as approved, byte for byte: nothing is redrafted, reformatted or regenerated after the
  approval. Branch on the terminal line:

  | `spec-store` returns | Action |
  |---|---|
  | `STATUS: OK <sha>` | `stored = <sha>` |
  | `STATUS: BLOCKED — concurrent-write` | the spec moved while this run drafted. Run `spec-load <n>` again; its file becomes the working text; set `verdict = changes`, `R.changes = re-apply this run's changes onto the spec now on main` |
  | `STATUS: BLOCKED — issue-unreadable` | the spec is stored; the mirror or the resolution comment is not. Invoke `spec-store`'s `--finish` repair once more. A repeat → **stop** `relay` |
  | `STATUS: BLOCKED — merged-section-modified` | **stop** `relay`, naming the merged section. The user decides: revert that section's change, or amend shipped history deliberately |
  | `STATUS: BLOCKED — spec-pr-open <url>` / `spec-pr-checks-failing <url>` / `spec-pr-checks-pending <url>` / `spec-merge-failed` | **stop** `relay`. The spec is **not** stored: its PR is still open or was refused. Nothing may be coded against it; the user resolves the PR first |
  | any other `STATUS: BLOCKED` | **stop** `relay` |

  Never trim a draft to fit a size limit. The spec file has room; length is governed by Writing
  rule 1 alone.

- **Writes:** `stored`, `verdict`, `changes`.

## 12 · Settle

- **Pre-flight:** none — always runs. The only step that ends the run or starts another pass.
- **Loads:** `../shared/escalation.md`, only to compose a `NEEDS_DECISION`.
- **Do:** first match wins.

  | # | Condition on `R` | Then |
  |---|---|---|
  | 1 | `halt.kind = relay` | output the payload verbatim; end |
  | 2 | `halt.kind = decision` | output one `NEEDS_DECISION` block; end |
  | 3 | `halt.kind = blocked` | output the facts, then `STATUS: BLOCKED — <slug>` as the last line; end |
  | 4 | `unchanged` | delete the draft file, if any; output `Nothing to change: the spec already says what issue #<n> owes.`; end |
  | 5 | `mode = non-interactive` | output `R.aids`, when set, then `STATUS: SPEC_PENDING` as the last line; end. The draft is not emitted: the launcher reads it at its path |
  | 6 | `verdict = changes` | clear `verdict`; add to `scope` every `<SEC-ID>` `R.changes` names, or every section whose PR is not merged when it names none; go to step 5 |
  | 7 | `verdict = rejected` | output `Nothing stored. Draft kept at /tmp/improve-issue-<n>-spec.md.`; end |
  | 8 | `stored` set | delete the draft file; output the summary below; end |

  ```
  ✅ Sectioned spec stored for issue #<n> — <1|0> Documentation · <s> Schema · <p> Parser · <u> UI sections.
  📄 Documentation edits prescribed in DOC-1: <the files it edits, or "none — the issue owes no doc edit">
  ❓ Questions resolved with the user: <R.answered, or "none">
  ⚠️ <sections with an open PR whose local ticks will conflict with this rewrite, or omit the line>
  👉 Next: code-issue <n> <SEC-ID>  (Coder: <model+effort>) — the first section whose dependencies are merged.
  ```

  Rows 1–5 and 7 store nothing and post nothing.
