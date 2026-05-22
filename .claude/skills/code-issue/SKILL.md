---
name: code-issue
description: >
  Implement a GitHub issue in this Elixir/Phoenix/Ash codebase, following an
  enriched spec produced by improve-issue. Use this skill when the user says
  "implement the issue", "code this up", "start coding", or provides an enriched
  spec from improve-issue. Also triggers on "fix the gaps", "address the review
  findings", or "retry with these requirements" — in those cases the gaps live
  in the review-gaps marker block of the issue body. Always write tests
  alongside implementation.
---

# Skill: code-issue

Implement every Acceptance Criterion from the enriched spec (or remaining gaps
from `review-issue`). Produce working, tested Elixir/Phoenix/Ash code that
respects every rule in CLAUDE.md.

---

## Inputs

This skill always reads the GitHub issue directly — never trust chat context
alone.

```bash
gh issue view <n> --json title,body,url
gh issue view <n> --comments
```

Look for two marker blocks in the body:

| Block | Written by | Meaning |
|---|---|---|
| `<!-- enriched-spec:start v1 -->` … `<!-- enriched-spec:end -->` | `improve-issue` | The implementation spec |
| `<!-- review-gaps:start v1 -->` … `<!-- review-gaps:end -->` | `review-issue` | Outstanding gaps from the last review (replaced each iteration) |

**Mode A — Fresh implementation**: only the spec block is present, or the
gaps block contains `✅ No outstanding gaps.`. Implement every AC.

**Mode B — Gap remediation**: the gaps block contains `INCOMPLETE_TASKS` and
either `MISSING_COVERAGE` (Full mode) or `MISSING_HINTS` (Lite mode). Focus
exclusively on those entries. Do not re-implement what already passes. Read
both the spec (for context) and the gaps (for the actual work). The header
name tells you which mode the previous review ran in — it must match the
current `Test Ownership` value; if they differ, trust the current
`Test Ownership` value (it's the source of truth) and treat
`MISSING_COVERAGE` items in a Lite-mode run as `MISSING_HINTS` to re-post.

If linked issues are referenced in the body, fetch them too.

---

## Step 0 — Read Test Ownership (mechanical)

Inside the enriched-spec block, find `### Test Ownership` and read the
`Owner:` value. Three possible values drive the entire skill's test
behavior:

| `Owner:` value | Mode | Behavior |
|---|---|---|
| `this-issue` | **Full** | Author tests per AC. Step 3's per-AC test rule applies. Step 4's 8-row Test Coverage Self-Check runs. |
| `parent:#<n>` | **Implementation-only** | Do NOT write per-AC tests. Step 4's coverage self-check is replaced by the 3-row smoke check. Step 5 posts Test Hints to issue `#<n>`. |
| `sibling:#<n>` | **Implementation-only** | Same as `parent:#<n>` but Test Hints go to issue `#<n>` (the test-owner sibling). |

If the field is missing, default to **Full** mode and add a one-line
warning to the Implementation Summary in Step 5.

Capture the owner issue number (when delegated) as `$OWNER_ISSUE` — every
Test Hints write uses it.

---

## Step 1 — Parse what to do

Extract internally:
- All Acceptance Criteria (AC-1, AC-2, …) and the affected-files list
- Edge cases from the error-handling table
- Open Questions — resolve each with a reasonable default and state the
  assumption in your output
- In Mode B: every numbered entry from `INCOMPLETE_TASKS` and
  `MISSING_COVERAGE`, including the file:line and assertion if specified

---

## Step 2 — Plan before coding

Output a short **Implementation Plan** before touching any file:

```
### Implementation Plan

**Order of operations:**
1. Ash resource changes (attributes, relationships, actions, policies)
2. Migration via `mix ash.codegen <name>` then `mix ash.migrate`
3. Domain action implementations
4. LiveView/Router/API endpoints
5. Localization keys (gettext extract/merge)
6. Tests (alongside each step above)

**Key design decisions:**
- <decision and rationale>

**Assumptions (for any open questions):**
- <assumption>
```

If running under `orchestrate-issue`, never block on this plan — proceed
immediately. Otherwise, ask only when an Open Question affects the data model
or a public API contract.

---

## Step 3 — Implement, AC by AC

### Non-negotiables (CLAUDE.md)

Every change in this codebase must respect these. Re-read before each AC:

- **LiveView**:
  - Templates start with `<Layouts.app flash={@flash} ...>`.
  - No inline `class=` attrs in LiveView/LiveComponent templates — use or
    extend function components in `core_components.ex` (or a domain
    component file).
  - Use `<.icon name="hero-...">`, `<.input>`, `<.button>`, `<.card>`,
    `<.info_card>` etc. from `core_components.ex`. Never use `Heroicons`
    modules directly.
  - Use streams for collections; track counts/empty-state in separate assigns
    (streams are not enumerable).
  - Avoid LiveComponents unless there is a specific, strong need.
  - No raw `<script>` tags. Colocated hooks only
    (`:type={Phoenix.LiveView.ColocatedHook}`, name starts with `.`).
  - Use `<.link navigate>` / `push_navigate` — never deprecated
    `live_redirect`.
  - Routes inside a `scope` block already have the alias — don't duplicate it.
- **Ash**:
  - Business logic lives in Ash resources/domains, not LiveView/controllers.
  - Multi-step DB operations use `Ash.transaction/1`. No `Ecto.Multi` /
    `Repo.transaction`.
  - Errors are tagged tuples (`{:ok, _} | {:error, _}`). No bare `raise`
    without a structured error.
  - Authorization belongs in Ash policies, not in handlers.
- **Data invariants**:
  - Soft delete only (`is_deleted`, `deleted_at`). Never hard-delete.
  - State-changing actions thread `process_id` and `parent_event_id`.
- **Localization**: every user-visible string goes through gettext. Default
  locale is `es_DO`; tests run in `en`.
- **HTTP**: only `Req`. Never add `:httpoison`, `:tesla`, `:httpc`.
- **Elixir gotchas**:
  - Lists do **not** support `mylist[i]` — use `Enum.at/2` or pattern match.
  - Block expressions must rebind: `socket = if ... do ... end`.
  - Never call `String.to_atom/1` on user input.
  - Never nest multiple modules in the same file.
  - Predicate functions end with `?`, not `is_` prefix.
- **Tests**:
  - Case modules: `DataCase` (business logic), `ConnCase` (HTTP/LiveView),
    `FeatureCase` (Wallaby — last resort).
  - Factories from `test/support/factory.ex` (`build/2`, `insert!/2`). Never
    `Ash.create!` to seed test data.
  - No mocks. Use real implementations and the test adapters configured in
    `config/test.exs`.
  - No `Process.sleep/1`. Use `start_supervised!/1`,
    `_ = :sys.get_state(pid)`, or `Process.monitor/1` +
    `assert_receive {:DOWN, ...}`.

### Per-AC workflow

For each AC (or each gap entry in Mode B):

1. State: `### Implementing AC-N: <text>` (or `### Fixing gap: <id>`).
2. Write the implementation code.
3. **In Full mode** (`Owner: this-issue`): write the corresponding test(s)
   immediately after.
   **In Implementation-only mode** (`Owner: parent:#<n>` /
   `Owner: sibling:#<n>`): do NOT write per-AC tests. Instead, append a
   one-line Test Hint to your in-memory hints list:
   ```
   AC-N: <observable behavior> · assert: <suggested ExUnit assertion> · test file: <test/...>
   ```
   These hints are posted to `$OWNER_ISSUE` in Step 5.
4. Run `mix format` to keep the diff clean.

Defer `mix credo --strict` and `mix dialyzer` — they run as part of the single
`mix consistency` at the end of Step 4. Per-AC dialyzer would dominate runtime
(~10 min first run per CLAUDE.md).

### Reusable patterns

**Ash resource — attributes, actions, policies**

```elixir
defmodule LogaMoney.Loans.Loan do
  use Ash.Resource,
    domain: LogaMoney.Loans,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :amount, :decimal, allow_nil?: false
    attribute :status, :atom,
      constraints: [one_of: [:pending, :approved, :rejected, :disbursed]],
      default: :pending,
      allow_nil?: false
    attribute :is_deleted, :boolean, default: false, allow_nil?: false
    attribute :deleted_at, :utc_datetime_usec
    timestamps()
  end

  actions do
    create :request do
      accept [:amount]
      change set_attribute(:status, :pending)
    end
  end

  policies do
    policy action(:request) do
      authorize_if actor_attribute_equals(:role, :borrower)
    end
  end
end
```

**Multi-step domain action — `Ash.transaction`**

```elixir
def disburse(loan_id, actor) do
  Ash.transaction(fn ->
    with {:ok, loan} <- Ash.get(Loan, loan_id, actor: actor),
         {:ok, loan} <- loan |> Ash.Changeset.for_update(:disburse) |> Ash.update(actor: actor),
         {:ok, _event} <- emit_event(loan, :loan_disbursed, actor) do
      {:ok, loan}
    end
  end)
end
```

**Migrations**

Edit the Ash resource, then:

```bash
mix ash.codegen <name>   # generates migration into priv/repo/migrations
mix ash.migrate          # runs it
```

Never write migrations by hand or call `mix ash.generate` (does not exist in
this project).

### Test patterns

**Prefer `Phoenix.LiveViewTest` for all UI tests** — it is faster, requires no
browser driver, and covers the vast majority of LiveView interactions. Use
`has_element?/2` and `element/2` for assertions; never assert on raw HTML.

```elixir
# DataCase — Ash action
describe "request/2" do
  test "valid attrs creates loan in :pending" do
    borrower = insert!(:user, role: :borrower)
    assert {:ok, loan} = Loans.request(%{amount: Decimal.new("1000.00")}, actor: borrower)
    assert loan.status == :pending
  end

  test "non-borrower is rejected by policy" do
    investor = insert!(:user, role: :investor)
    assert {:error, %Ash.Error.Forbidden{}} =
             Loans.request(%{amount: Decimal.new("1000.00")}, actor: investor)
  end
end

# ConnCase — LiveView interaction
test "borrower can submit loan request", %{conn: conn} do
  borrower = insert!(:user, role: :borrower)
  conn = log_in_user(conn, borrower)

  {:ok, lv, _html} = live(conn, ~p"/loans/new")

  assert lv
         |> form("#loan-form", loan: %{amount: "1000.00"})
         |> render_submit() =~ "Loan requested"

  assert has_element?(lv, "[data-role=loan-status]", "pending")
end
```

**Wallaby (`FeatureCase`) is a last resort.** Only use it when LiveViewTest is
genuinely insufficient — file downloads, native browser dialogs, or
multi-tab scenarios. Document **why** in a comment above the test.

```elixir
# Documented exception: file download cannot be exercised via LiveViewTest.
test "user can download statement PDF", %{session: session} do
  session
  |> visit(~p"/statements")
  |> click(Query.link("Download"))
  |> assert_has(Query.css(".alert", text: "Statement ready"))
end
```

---

## Step 4 — Final quality gate

After all ACs are implemented, run the full project gate:

```bash
mix consistency
```

This runs `deps.unlock → format → compile → docs → credo → doctor → dialyzer`.
Fix every warning and error before declaring this skill complete. If
`mix consistency` fails, treat the failures as additional work to do in this
same skill invocation — do not hand off red.

### Test coverage self-check

**Full mode (`Owner: this-issue`)** — tick each box. If any are unchecked,
add the missing tests:

```
- [ ] Happy path for each AC
- [ ] At least one error/edge path per AC
- [ ] Ash changeset / validation errors tested
- [ ] Ash policy / authorization tested (if policies apply)
- [ ] Database constraints tested (unique, FK)
- [ ] LiveView events tested (if applicable)
- [ ] Async/Oban paths tested (if applicable)
- [ ] All new public domain functions have at least one test
- [ ] Locale keys exist in en and es_DO
```

**Implementation-only mode (`Owner: parent:#<n>` / `sibling:#<n>`)** —
3-row smoke check only. If any is unchecked, fix before declaring done:

```
- [ ] `mix compile --warnings-as-errors` is clean
- [ ] `mix test` is still green (no pre-existing test became red)
- [ ] Every new public function is reachable from a sibling AC (no orphans)
```

Do **not** author new tests in this mode — the owner issue will. If a
new test is genuinely required to keep `mix test` green (e.g. a contract
change that broke an existing test), add the *minimum* fix and note it in
the Implementation Summary as `regression-fix`, not as AC coverage.

---

## Step 5 — Output and write back

Emit a structured **Implementation Summary** in chat:

```
### Implementation Summary

**ACs addressed:** AC-1, AC-2, …
**Files created/modified:**
- `lib/loga_money/...` — <what changed>
**Tests written:** <N> test cases across <M> describe blocks  ← in Full mode
**Tests written:** none — owner is <Owner value>            ← in Implementation-only mode
**Assumptions made:**
- <list>
**Known limitations / TODOs:**
- <list, or "none">
```

**In Implementation-only mode**, also include a `Test Hints for Owner`
subsection — one bullet per AC, verbatim from the in-memory list captured
in Step 3:

```
**Test Hints for Owner (#<owner>):**
- AC-1: <observable behavior> · assert: <suggested assertion> · test file: <path>
- AC-2: ...
```

Then write back to the GitHub issue:

1. **Tick completed AC checkboxes in the spec block.** Re-fetch the body
   first to avoid clobbering concurrent edits:

   ```bash
   gh issue view <n> --json body --jq '.body' > /tmp/body.md
   # edit /tmp/body.md: change `- [ ] AC-N` → `- [x] AC-N` for each completed AC
   gh issue edit <n> --body-file /tmp/body.md
   ```

2. **Post the Implementation Summary as a comment** on the current issue
   for audit trail:

   ```bash
   gh issue comment <n> --body-file /tmp/summary.md
   ```

3. **In Implementation-only mode** — also post the Test Hints to the
   owner issue so the owner doesn't have to scrape sibling comments. The
   comment must be prefixed with a fixed marker so `review-issue` can
   detect it when checking `MISSING_HINTS`:

   ```bash
   TMP_HINTS=$(mktemp)
   cat > "$TMP_HINTS" <<EOF
   <!-- test-hints from:#<n> -->
   ## Test Hints from #<n>

   - AC-1: <observable behavior> · assert: <suggested assertion> · test file: <path>
   - AC-2: ...
   EOF
   gh issue comment $OWNER_ISSUE --body-file "$TMP_HINTS"
   ```

   The `from:#<n>` marker is mandatory — `review-issue` greps it to verify
   hints were posted for each non-owner sibling.

End with:

- Full mode: `👉 Next: run /skill review-issue <n>.`
- Implementation-only mode: `👉 Next: run /skill review-issue <n>. Test Hints posted to #<owner>.`
