# improve-issue · Documentation section

Read by `improve-issue` **Draft** when `DOC-1` is in scope. Holds every rule about `DOC-1`'s
content, once. Whether `DOC-1` exists, and what depends on it, is **Partition**'s.

## Rules

1. `DOC-1` edits only documentation files: `CHANGELOG.md`, `README.md`, `CONTRIBUTING.md`,
   `ROADMAP.md` and every `*.md` under `guides/`. `@moduledoc` and `@doc` text is code: it belongs
   to the section that edits the module, never to `DOC-1`.
2. `DOC-1` prescribes every documentation edit the issue owes. Every documentation file another
   section cites as changed has a block here.
3. One `##### <path>` block per file edited, the path verbatim as the heading. A file the issue
   does not edit has no block.
4. Block order: `CHANGELOG.md`, then `README.md`, then every other path alphabetically.
5. Inside a block: numbered edits, each anchored `§ Section name`, never a line number (H-1).
6. Every edit is complete and verbatim. `code-issue` transcribes it; it never composes.
7. `CHANGELOG.md` (H-4): the block inserts the entry under the current unreleased version's
   section (`### Added`, `### Changed`, `### Fixes` or `### Documentation`), in the style of the
   entries already there. The entry carries no issue-link suffix. Name the UI components by their
   simple names (H-2).
8. What the common targets owe:

   | File | The block carries |
   |---|---|
   | `CHANGELOG.md` | the entry, complete, under the current unreleased version |
   | `guides/**` | the paragraph, table row or code sample the change makes stale or new; a new `auix-*` rule owes the upgrade note in `guides/customization/styling.md` |
   | `README.md` | only what a first-time reader must know; usually no block |

9. Never invent a name. When a documented name is wrong, prescribe the doc change and state the
   reason in the edit.
10. Doc content that contradicts an existing rule is a question (Question rule). It is never
    specced around.
11. Prescribed text carries no `file.md:NNN` reference (H-1).
12. AC-1 and AC-2 are fixed: verbatim, in that position, in every `DOC-1`. AC-3 onward are
    issue-specific, at least one per `#####` block other than `CHANGELOG.md`.
13. No red tests. Every AC ends `(mechanical — no red test; verified by <command>)` and names
    the command.
14. `DOC-1` is absent only for an issue that delivers neither a feature nor a fix (a chore, a CI
    change, a refactor with no behaviour change). The Overview then says so in one sentence.

## Template

`<…>` is a placeholder. The `#####` file blocks and AC-3 onward are examples of shape, not a
fixed set.

````markdown
<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
<the § anchors this section edits or builds on>

#### Implementation details

##### CHANGELOG.md
1. § `## [<version>]` › `### <Added|Changed|Fixes|Documentation>` — insert verbatim:
   ```
   - **<title>**
     - <the entry text>
   ```

##### guides/<dir>/<file>.md
1. § <Section> — <exact edit>

##### Acceptance criteria
- [ ] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [ ] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-<n>-enriched-spec.md`)
- [ ] AC-3: `guides/<dir>/<file>.md § <Section>` reads as prescribed (mechanical — no red test;
      verified by `<the grep>`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
````
