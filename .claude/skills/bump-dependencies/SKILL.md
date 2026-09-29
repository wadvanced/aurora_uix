---
name: bump-dependencies
description: >
  Bump Elixir dependency versions in mix.exs and mix.lock, updating
  CHANGELOG.md and closing the GitHub issues (labeled `bump`)
  it resolves. Use this skill when the user says "bump dependencies",
  "update deps", "check for outdated dependencies", or similar.
---

Bump outdated Elixir dependencies declared in `mix.exs` (Ash, Phoenix,
LiveView, `aurora_ctx`, Ecto, ...), regenerate `mix.lock`, update
`CHANGELOG.md`, then gate, commit, and close the GitHub issues (labeled `bump`)
that the bump resolves. This skill never opens a PR — that is a separate,
explicit `do-pr` invocation.

The `bump` issues come from `.github/workflows/dependency-check.yml`, which runs
`mix hex.outdated` every Sunday and opens one issue per outdated dependency
(`Bump <dep> from <old> to <new>`, label `bump`; a major update that the
current requirement forbids is titled `[HIGH PRIORITY] Bump ...` and also
carries `high-priority`). It never closes them — step 6 does.

Follows `../shared/turn-discipline.md` throughout: batch independent tool
calls, never poll, no narration-only turns.

## 1. Preflight

1. `git rev-parse --abbrev-ref HEAD`. Branch creation is **conditional, not
   automatic**: only when the current branch is `main` does this skill create
   a feature branch per the repo's naming convention
   (`git checkout -b federico/bump-dependencies` off `origin/main`) before doing
   anything else. Never work on `main`. If the current branch is anything other than `main`, stay
   on it — never create or switch branches.
2. Read `mix.exs` `deps/0` and record the **current** version/pin of every
   dependency before touching anything. This is the `old_version` used later
   in both the commit body and any CHANGELOG entries — it must be the
   pre-bump version, never a version from a previous bump in this same run.

## 2. Discover updates

- `mix hex.outdated` — the primary command. Lists every hex.pm dependency
  with a newer version available and flags ones violating their own version
  requirement.
- Git-sourced deps (e.g. `heroicons`, pinned via `github:`/`tag:`) don't
  appear in `hex.outdated`. Check them explicitly:
  `git ls-remote --tags <repo-url>` or
  `gh release list --repo <owner>/<repo> --limit 5`.
- Pre-release/exact-pinned deps (a hand-written `"1.0.0-rc.1"` string) — check
  `hex.outdated` output, or the package's hex.pm page, for a newer exact
  version.
- `>= 0.0.0`-style deps (`postgrex`, `lazy_html`) are intentionally
  unconstrained — only touch one if the user asks for that package by name.
- **`hex.outdated`'s "Update possible" is not a resolvability guarantee.** It
  only checks whether the requirement *string* permits the newer version —
  not whether a full dependency-graph resolution actually reaches it. A
  target can flag as "Update possible" and still not move under
  `mix deps.update <dep>`, even fully unlocked, because reaching it would
  require **downgrading** an unrelated transitive dependency that nothing in
  `mix.exs` forces (e.g. a new `ash_postgres` release adds a tighter constraint on a transitive
  package whose locked version another dependency's permissive range had
  settled on; the resolver won't volunteer that downgrade without being
  asked). Diagnose this with `mix hex.info <dep> <target_version>`
  (compare its dependency list against what's actually locked) before
  concluding a dependency is simply stuck.
- When that's the cause, **do not force it** by tightening the pin to 3-part
  precision (`~> X.Y.Z`) just to win the resolution — that violates the
  2-part rule in step 3. Leave the dependency at its current version, note
  the specific conflicting package/constraint in the run's report, and let
  its `bump`-labeled issue stay open. Only pursue the forced downgrade path
  if the user explicitly asks for it after seeing the tradeoff.
- If nothing is outdated, skip straight to step 6 (the `bump`-labeled issue
  sweep is unconditional — a dependency can already be satisfied by earlier,
  unrelated work even when there's nothing left for *this* run to bump), then
  report `STATUS: NOTHING_TO_BUMP` once that sweep is done.

## 3. Rules for editing `mix.exs`

- Touch only dependencies that step 2 actually flagged as outdated. Never
  bump something that is already current.
- **Caret pins (`~>`) always target 2-part precision (`~> MAJOR.MINOR`).**
  Whatever precision the pin currently has, a bump collapses it to 2 integers
  — e.g. `tz "~> 0.28.2"` (3-part) bumps to `tz "~> 0.29"`, not
  `~> 0.29.0` or `~> 0.29.x`. This applies uniformly; there is no case where
  a caret pin is bumped to 3 parts.
  - `>= 0.0.0`-style stays untouched (it's already unconstrained).
  - Git deps: bump only the `tag:` value.
- **Never introduce or widen an exact (no-operator) version pin.** An exact
  string pin — e.g. `aurora_uix "0.1.6-rc.6"` — is only ever legitimate when
  a human deliberately hand-wrote it (typically a pre-release version `~>`
  can't express cleanly). When bumping an existing hand-written exact pin,
  replace the string with the new exact version and keep it exact — never
  convert it to `~>`. But never turn a `~>` (or any other operator) pin into
  an exact one, and never create a brand-new dependency entry as an exact
  pin — that conversion is a human decision, not this skill's to make.
- Don't reorder deps, don't touch the `# Dev and test only` grouping/comment,
  don't reformat unrelated lines. One line changes per bumped dependency.
- A major-version bump (the first segment changes) is a flag, not a silent
  action: call it out to the user before proceeding — it may carry breaking
  changes that `mix consistency`/`mix test` won't all catch. A major bump of
  `ash`, `phoenix`, `phoenix_live_view` or `aurora_ctx` also touches the
  backend contract this library generates code against, so name the affected
  parser or renderer in the note.
- After editing, run `mix deps.get` to regenerate `mix.lock`. Never
  hand-edit `mix.lock`.
- **Bumping `heroicons` (the git `tag:`) also requires regenerating the icon
  artifacts.** After the bump, run `mix auix.gen.icons` and
  `mix auix.gen.tailwind_classes` and stage any resulting changes
  (`priv/static/classes.js` and the generated icon set) in the same commit as
  the `mix.exs`/`mix.lock` bump — never as a separate commit.
- **Bumping `ash` / `ash_postgres` may produce resource-snapshot or migration
  drift.** If `mix ash.codegen` (or the test suite) reports new snapshots under
  `priv/resource_snapshots/`, that is a compatibility fix: its own commit, per
  step 5.4.

## 4. `CHANGELOG.md` rules

`CHANGELOG.md` always exists here, and every change carries an entry (the
repo's CHANGELOG-per-change rule) — **with no issue link suffix** (older
releases keep theirs; new entries never add one).

- The ongoing release is the **topmost** `## [<MAJOR>.<MINOR>.<PATCH>]` heading
  **without** a ` - <YYYY-MM-DD>` date suffix (there is no `## [Unreleased]`
  heading in this repo; e.g. `## [0.1.6]` while `mix.exs` reads
  `0.1.6-rc.N`). Dated headings are published: never edit them. If the topmost
  heading is dated or missing, **stop and report** — do not create one, do
  not guess which section is ongoing.
- Dependency bumps live under that release's `### Changed`, in one bullet
  titled `- **Updated Dependencies**`, whose sub-bullets are, exactly:
  `  - <dep_name>: <old_version> -> <new_version>`
  - `<dep_name>` is the atom key from `mix.exs` `deps/0` (e.g. `phoenix`), no
    backticks, no leading colon; versions have no leading `v`.
  - Sub-bullets are alphabetical by `<dep_name>`.
  - List only dependencies declared in `mix.exs` `deps/0` — never a
    transitive dependency that only shows up in `mix.lock`.
  - If the release has no `### Changed` section, add it, keeping the heading
    order the file already uses in that release.
- Re-bumping a dependency already listed during the same release rewrites
  **only** the `-> new_version` half of its existing sub-bullet — never adds a
  second line and never shifts `old_version` to the previous bump's target. One
  entry reads as the cumulative bump for the whole unreleased window.
- A compatibility fix (step 5.4) gets its own entry under `### Fixes` or
  `### Changed` in the file's existing style, describing the behavior, not the
  dependency.

**Worked template** (from this repo's `0.1.6` section):

```markdown
## [0.1.6]

### Changed

- **Updated Dependencies**
  - ash: 3.30.1 -> 3.32.1
  - ash_postgres: 2.11.0 -> 2.12.0
  - phoenix: 1.8.9 -> 1.8.13
  - phoenix_live_view: 1.2.8 -> 1.2.11
```

A second bump of `phoenix` in the same cycle rewrites its line to
`  - phoenix: 1.8.9 -> 1.8.14` — the `old` version stays `1.8.9`, only the `new`
version moves.

## 5. Gate and commit

1. Invoke the `gate` skill (runs `mix consistency` through
   `.claude/scripts/gate.sh`, then commits if clean).
2. Follow with the full test suite (`.claude/scripts/suite.sh`, per
   `../shared/background-long-commands.md`: `run_in_background`, then one
   foreground `.claude/scripts/wait-verdict.sh suite`) — `gate` alone does not run
   it, per AGENTS.md's Quality Gate section (`mix consistency` does not run tests).
3. Commit message convention (conventional commits, matching repo history):
   subject `build: update dependencies`, with a body listing every bumped
   dependency as `- name old -> new`, and the `Co-Authored-By` trailer the
   harness specifies.
4. If the bump surfaced a genuine break (a dependency's new version needs a
   config/code change to keep compiling or keep the suite green — see e.g. an
   Ash minor bump requiring a new `config :ash, ...` key),
   make that fix as its own commit (conventional type by what the fix
   actually is, e.g. `fix:`), then re-run this whole step (gate, test) before
   moving on. Never fold such a fix into the `build: update dependencies`
   commit — the bump and the compatibility fix are different intents.

## 6. Close resolved `bump`-labeled issues

**Gated on green tests — only when this run changed anything.** If step 2
found something to bump, this step is only reached once step 5.2's full
`mix test` run has actually finished green for the final tree (i.e. after any
compatibility-fix re-run in step 5.4 too, if one happened). A `mix consistency` pass
alone is not enough — if the suite is still running, still red, or was never
run, no issue gets closed; report `STATUS: BLOCKED` instead and leave every
candidate issue open. If step 2 found nothing to bump (arriving here straight
from that early exit), this run made no code change to gate on — reaching
this step needs no fresh test run; the sweep can proceed immediately.

The `dependency-check.yml` workflow (`github-actions`) opens one issue per
outdated dependency, labeled `bump`, with a body of the exact form:

```
Dependency `<dep_name>` is outdated. Current version: `<old_version>`, Latest version: `<new_version>`.
```

Once the suite is green and the commit(s) above land, sweep **every** open
`bump` issue — not just the ones for dependencies this run touched. A
dependency's requirement can already be satisfied by an earlier, unrelated
commit or PR (e.g. another dependency's bump dragged it along transitively,
or someone bumped it by hand), and the workflow never closes its own issue when
that happens — this step is what reconciles that drift, on every run.

1. List candidates: `gh issue list --label bump --state open --json number,title,body`.
2. For each issue, extract `<dep_name>` and `<target_version>` from the
   **body**, never the title — the workflow's title generation parses
   `mix hex.outdated` columns and is unreliable for `only:` scoped deps (an
   `only:` value such as `dev,test` can leak into the "from" slot, not a
   version). If the body's versions are not versions, take the target from
   `mix hex.outdated` instead.
3. Look up `<dep_name>`'s **current** locked version straight from `mix.lock`
   as it stands right now — regardless of whether this run bumped that
   dependency.
4. Compare semantically, not lexically (e.g. `2.13.10` must sort above
   `2.13.9`): `mix run --no-start -e 'IO.puts(Version.compare("<locked_version>", "<target_version>"))'`.
   On `lt`, leave the issue open — genuinely pending, nothing more to do here.
   On `gt` or `eq`, the locked version already meets or exceeds what the issue
   asked for — continue to step 5 before closing anything.
5. **Realign `mix.exs` before closing, if this dependency's pin needs it.**
   A `gt`/`eq` result means `mix.lock` is already where it should be, but for
   a dependency pinned by an **exact string** or a git **`tag:`** (never a
   `~>` pin — those express a range, so they can't drift), the `mix.exs`
   entry itself can still lag: someone may have resolved the bump by hand
   without updating the declared pin to match. Check `<dep_name>`'s current
   `mix.exs` entry against the *actual* locked/resolved version using the
   same rules as step 3 (preserve pin style, one line changes, no reordering,
   no touching unrelated comments):
   - Exact pin whose string ≠ the locked version → replace it with the
     locked version's exact string.
   - Git dep whose `tag:` ≠ the tag the lock actually resolved → update
     `tag:` to match.
   - `~>` / `>=` pins → never touched here; they already permit whatever's
     locked by construction.
   If an edit was needed, run `mix deps.get` to confirm it resolves to the
   same lock unchanged, then run this dependency's fix through step 5 (gate,
   test, commit — its own commit, `build:` type per `gate-commit`'s grouping
   table, message e.g. `build: align mix.exs pin for <dep_name>`) before
   closing the issue below. If `mix.exs` already matches, or the pin type
   doesn't apply, skip straight to closing — there's nothing to commit.
6. Close via `gh issue close <n> --comment "<comment>"`, where `<comment>` is:
   - `` Resolved by <sha> — locked to `<locked_version>`. `` when `<dep_name>`
     is one **this run** bumped, or one whose `mix.exs` pin this run just
     realigned in step 5 above (`<sha>` is that commit), or
   - `` Already resolved — mix.lock locks `<dep_name>` to `<locked_version>` (>= `<target_version>` requested here), from earlier work outside this run. ``
     when the dependency was already at or past target **and** its
     `mix.exs` pin already matched, before this run started.

Leave open every issue whose comparison came back `lt` — that is a genuinely
pending bump, report it in the terminal summary.

## Terminal status

This skill always returns exactly one of these, printed on its own line:

- `STATUS: BUMPED` — one or more dependencies were bumped, gated, committed,
  and every resolved `bump` issue closed (whether resolved by this run or by
  earlier, unrelated work).
- `STATUS: NOTHING_TO_BUMP` — `mix hex.outdated` and the manual git/hex
  checks found nothing newer.
- `STATUS: BLOCKED — <reason>` — a step failed (`mix consistency`, test suite, a
  malformed CHANGELOG) and nothing further was done.

## Returning to the caller

This skill may be invoked directly by the user, or by another skill. When a
skill invoked it, a `STATUS:` line is a **handoff, not a conclusion** — emit
it and continue in the same turn with whatever the caller has next. This
skill never opens a PR itself; if one is wanted, that is a separate `do-pr`
invocation triggered explicitly afterward.

## Forbidden

- Creating or switching branches when the current branch is not `main`, or
  committing on `main`.
- Bumping a dependency that step 2 did not flag as outdated.
- Bumping a caret pin to anything other than 2-part precision (e.g. leaving
  or writing `~> X.Y.Z`).
- Converting a `~>`/`>=` pin to an exact (no-operator) pin, or converting an
  existing hand-written exact pin to `~>`.
- Introducing a brand-new exact pin for a dependency that doesn't already
  have one.
- Hand-editing `mix.lock`.
- Editing a dated `CHANGELOG.md` release heading or its body.
- Guessing which `CHANGELOG.md` section is ongoing when the topmost heading is
  dated or missing — stop and report instead.
- Listing a transitive-only dependency (present in `mix.lock` but not in
  `mix.exs` `deps/0`) in the CHANGELOG.
- Adding a GitHub issue link inside a CHANGELOG entry.
- Editing `.github/workflows/dependency-check.yml` (its Elixir/OTP matrix is
  independent of the CI matrix and is not this skill's concern).
- Committing without a clean `mix consistency` and a green `mix test` run.
- Folding a compatibility fix (config/code change needed by a bumped
  dependency) into the `build: update dependencies` commit instead of its own.
- Closing any `bump`-labeled issue before step 5.2's full `mix test` run has
  finished green on the final tree, when this run changed anything.
- Closing a `bump`-labeled issue by parsing its title instead of its body.
- Closing a `bump`-labeled issue whose target version is lexically, not
  semantically, compared against the locked version (e.g. treating `2.13.9`
  as newer than `2.13.10`).
- Closing a `bump`-labeled issue whose target version is genuinely newer
  than what's currently locked in `mix.lock`.
- Claiming a specific commit `<sha>` resolved an issue when the dependency
  was already at or past target before this run started — use the
  "already resolved … from earlier work outside this run" wording instead
  (unless step 6.5 itself made a realigning commit, which does get its own
  `<sha>`).
- Closing a stale-resolved issue while leaving a mismatched exact-pin or
  git `tag:` in `mix.exs` unaligned with the version `mix.lock` actually
  resolved — step 6.5 is not optional when that mismatch exists.
- Editing a `~>`/`>=` pin during the step 6.5 realignment pass — those never
  need it; only exact pins and git `tag:` values can drift.
- Adding, removing, or otherwise editing the `bump` label itself.
- Opening a pull request from this skill.
