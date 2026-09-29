# House conventions

Standing corrections the user has given, which no lint check enforces. They are
small, they recur, and each one that slips through costs a full pipeline round
trip — which is the entire reason this file exists.

`improve-issue` checks its working text against this list in its **Check**
step, before presenting the draft. `review-issue` sweeps the branch diff against
it in its **Step 4** light-fix pass. In `review-issue`, a hit here is
**REVIEWER-FIXED** unless it changes behaviour: the reviewer corrects it and
reports it, rather than spending a `code-issue` iteration on a word.

The `H-` numbers are stable identifiers other skills cite; a gap in the sequence is a retired
rule, never a slot to reuse.

---

## H-1 · Cite documentation by section, never by line

In anything written into an issue, a spec, a plan, a guide, or a code comment,
reference `guides/**/*.md`, `README.md` and `AGENTS.md` by their **section or
heading name**:

- ✅ `guides/core/layouts.md § Sections and groups`
- ❌ `guides/core/layouts.md:128`

The guides move constantly; a line number captured in a spec is stale within a
few merges and then points confidently at the wrong paragraph.

**Code `file:line` references are the opposite — required, and verifiable by
grep.** `improve-issue`'s citations demand them. The restriction is
documentation files only. For a config file the issue is itself about to edit,
cite the named entry rather than its line.

## H-2 · Simple component names in documentation and code

Name a UI component by its simple name — `Phone`, `Email`, `OneToMany` — never by a prefixed or
namespaced form (`EmbeddedPhone`, `EmbeddedEmail`) unless the issue explicitly asks for it. This
applies to spec text, guides, `@doc`/`@moduledoc` prose and CHANGELOG entries.

Quoting an existing module name verbatim in a citation is fine; your own prose is not.

## H-3 · No tests for stubs or placeholders

Never spec, write, or demand a test for:

- a function that unconditionally returns a hardcoded value (`[]`, `nil`) until
  real behaviour exists;
- a renderer or page that emits only a static placeholder with no real content.

Tests land when the real behaviour lands. A test that confirms a stub returns its
hardcoded result verifies nothing.

Consequence for `improve-issue`: an AC whose red-test row would only observe a
placeholder is not an AC — drop it, or defer it to the issue that builds the
real thing. Consequence for `review-issue`: never raise missing coverage
against a stub.

## H-4 · Every feature and fix carries a CHANGELOG entry, without an issue link

`CHANGELOG.md` gets an entry under the current unreleased version's section (`Added`, `Changed`,
`Fixes` or `Documentation`) for every feature or fix. The new entry has **no** issue-link suffix
(no `[#343](…)`); older releases keep theirs, and that predates this rule — do not copy it, do not
strip it.

`improve-issue` prescribes the entry verbatim in `DOC-1`; `code-issue` transcribes it;
`review-issue` raises a missing entry as a gap. A section outside `DOC-1` never edits the file.

## H-5 · Styling and markup rules the gate does not see

`mix consistency` does not check these; `review-issue` Step 4 greps for them. Every hit is a
behaviour-affecting markup change, so it loops to `code-issue` rather than being reviewer-fixed:

- no inline `class=` in generated or component markup — styling is an `auix-*` class defined in
  `templates/basic/themes/base.ex`;
- no raw `<script>` tag in a template; hooks are colocated (`:type={Phoenix.LiveView.ColocatedHook}`,
  name starting with `.`);
- icons and inputs come from `core_components.ex` (`<.icon>`, `<.input>`), never `Heroicons`
  directly;
- user-visible strings go through `dt/1`.

## H-6 · Never touch the human review labels

`approved` and `amends-required` are human-only gates on a PR. Never add or
remove either — not when CI is green, not when the work was self-reviewed, not
when asked to "finish" or "unblock" a PR. An `amends-required` label with no
review comments is not feedback to go chase.

**Writing is what this forbids; reading is the point of the labels.** They exist
to be acted on: `amends-required` sends a section back through the pipeline, and
`approved` is the sole authority under which `merge-pr` merges a PR (a spec PR,
recognised by its fixed name and sole file, is the one exemption). Acting on a
label a human wrote is not touching it. Writing one — to unblock yourself, to
record your own approval, or to clear an `amends-required` you believe you have
satisfied — is, and stays forbidden in every skill including `merge-pr`.
