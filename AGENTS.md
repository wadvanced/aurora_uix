# AGENTS.md

Canonical guidance for any AI coding agent working in this repository (Claude Code, GitHub Copilot, opencode, qwen-code, Cursor, Aider, etc.). `CLAUDE.md` and `.github/copilot-instructions.md` are symlinks to this file.

## Overview

LogaMoney is a Phoenix/Elixir financial management application for loan management, targeting the Dominican Republic market. It handles loan lifecycle, payment processing, employer payroll deduction integration, user KYC, and multi-tenant role-based access (borrower, investor, employer).

## Commands

```bash
# Development
mix setup                    # Install deps, create and migrate DB (first time)
iex -S mix phx.server        # Start dev server with interactive shell (port 4000)

# Testing
mix test                     # Run all tests
mix test path/to/test.exs    # Run a specific test file
mix test --failed            # Re-run previously failed tests
mix test --cover             # Run with coverage report

# Code quality (run before committing)
mix precommit                # Full CI compliance check: format, compile, docs, credo, doctor, dialyzer
mix format                   # Auto-format code
mix credo --strict           # Lint
mix dialyzer                 # Static analysis (first run ~10 minutes)

# Database
mix ecto.reset               # Drop, recreate, and migrate DB
mix ecto.gen.migration NAME  # Create a new migration
mix ecto.psql                # Open PostgreSQL console

# Localization
mix localise                 # Extract and merge gettext translations (en, es)

# Assets
mix assets.build             # Build Tailwind + esbuild
```
## Naming Conventions section near the top of CLAUDE.md

When referencing UI components in documentation or code, use simple names (e.g., 'Phone', 'Email') not prefixed/namespaced names (e.g., 'EmbeddedPhone', 'EmbeddedEmail') unless explicitly asked.

## Domain Glossary

Two terms are frequently confused in this codebase. Use them precisely:

| Term | Definition | Example correct usage |
|---|---|---|
| **Customer / User** | Any authenticated person on the platform. Every account holder is a customer the moment they sign up, regardless of which account types they hold. | "Contact Customer Support", "Unlock your potential as a Loga Money customer", KYC ("Know Your Customer") |
| **Borrower** | The `:borrower` `account_type` value on an `Account`. One of three account types (`:borrower`, `:investor`, `:employer`). A single user may hold all three simultaneously. | `account_type: :borrower`, `BorrowerDetails`, `borrower_account_id`, `ValidateBorrowerRole` |

**Key rule:** A user is a customer the moment they sign up. They become a borrower only when they hold an account with `account_type: :borrower`.

**When to write "customer":** Generic product/marketing context where you mean any platform user, not a specific account type. Example: learn pages, support copy, onboarding headline text.

**When to write "borrower":** Anywhere you are referring specifically to the borrower account type: Ash resource names, field names, route segments under the borrower flow, UI labels on the borrower account card.

## Architecture

### Core Structure

```
lib/
  loga_money/           # Business logic (Ash resources)
    models/             # Domain models: accounts, core, settings
    mail/               # Email system (Swoosh)
    oban_jobs/          # Background jobs (Oban)
    application.ex      # OTP supervision tree
  loga_money_web/       # Web interface (Phoenix)
    live/               # LiveView modules
    controllers/        # HTTP controllers
    components/         # Reusable UI components (core_components.ex)
priv/
  repo/migrations/      # Ecto migrations
  gettext/              # Translation files (es_DO default, en supported)
docs/                   # Comprehensive architecture documentation
```

### Key Patterns

**Ash Framework**: Business logic is defined as declarative Ash resources (not plain Ecto schemas) — never raw Ecto queries. Ash automatically generates GraphQL from resources.

**Domain code interfaces (STRICT)**: All data access goes through the **domain**. Outside a domain module, **never** call the `Ash.*` data API directly — this applies to LiveViews, controllers, components, Oban jobs, channels, plugs, and tests. Every read, write, and relationship load must be exposed either as a domain *code interface* (`define :name, action: :action` inside the domain's `resources` block) or as a plain public function on the domain module. The raw `Ash.*` API is used **only inside** domain modules and resource definitions.

Forbidden outside domain modules:
- Actions: `Ash.create/2`, `Ash.update/2`, `Ash.destroy/2`, `Ash.run_action/2`
- Reads: `Ash.read/2`, `Ash.read_one/2`, `Ash.get/3`, `Ash.load/3`
- Builders: `Ash.Changeset.for_*`, `Ash.Query.for_*` / `filter` / `sort` / `load`

```elixir
# ❌ Bad — direct Ash API in a LiveView
Notification
|> Ash.Query.for_read(:read_by_id, %{id: id})
|> Ash.read_one!()

# ✅ Good — define the interface once in the domain `resources` block
resource Core.Notification do
  define :notification_get_by_id, action: :read_by_id, args: [:id]
end

# ...then call the domain from the LiveView
LogaMoney.Core.notification_get_by_id!(id)
```

If a call site needs custom filtering, loading, or sorting, encapsulate it in a resource read action (with arguments) or a domain function — never inline `Ash.Query`/`Ash.Changeset` in web/job/test code. Authorization options (`actor:`, `authorize?:`) pass straight through code interface functions.

**Role-based entity design**: One account entity maps to multiple functional roles. Role-based access is enforced via Ash policies.

**Event-driven audit trail**: Every operation is threaded via `process_id` and `parent_event_id`, stored in the events table.

**Soft deletes**: All records support `is_deleted` + `deleted_at` — never hard-delete business data.

**Localization**: Default locale is `es_DO` (Dominican Spanish). Tests set locale to English for consistent assertions.

### Tech Stack

- **Elixir 1.19.4 / OTP 28.3.2** (see `.tool-versions`)
- **Phoenix 1.8+** with **LiveView 1.1+** — no separate SPA framework
- **Ash 3.0+** — declarative resource framework
- **PostgreSQL 16+** via Ecto
- **AuroraUIX** — low-code UI generation on top of Ash
- **Oban** — background jobs (Postgres-backed)
- **TailwindCSS v4** — uses `@import` syntax (no `tailwind.config.js`)
- **GraphQL** via Absinthe (auto-generated from Ash resources)
- HTTP client: **Req** (never use `:httpoison`, `:tesla`, or `:httpc`)

### Supervision Tree (application.ex)

`LogaMoney.Repo` → `Cachex` → `Oban` → `Phoenix.PubSub` → `AshAuthentication.Supervisor` → `LogaMoneyWeb.Endpoint`

## Elixir Language Gotchas

Project-specific syntax/behavior rules that are easy to get wrong:

- Lists do **not** support index access (`mylist[i]` is invalid). Use `Enum.at/2`, pattern matching, or `List` functions.
- Block expressions (`if`, `case`, `cond`) must have their result rebound: `socket = if ... do ... end`
- **Never** nest multiple modules in the same file (cyclic dependency risk)
- **Never** use map access syntax (`changeset[:field]`) on structs — use `struct.field` or `Ecto.Changeset.get_field/2`
- Predicate functions end with `?`, not `is_` prefix (reserve `is_` for guards)
- Use `Task.async_stream/3` with `timeout: :infinity` for concurrent enumeration

## Elixir Anti-Patterns to Avoid

Authoritative rules derived from the [official Elixir anti-patterns guide](https://hexdocs.pm/elixir/1.19.5/what-anti-patterns.html). **Follow each rule literally.** If you find yourself writing one of the ❌ patterns, stop and rewrite as the ✅ version.

### Code Anti-Patterns

#### 1. Do not overuse comments
Comments must explain *why*, never *what*. If a comment restates the code, delete it.
```elixir
# ❌ Bad
# Increment counter by 1
counter = counter + 1

# ✅ Good — only when the why is non-obvious
# Backoff doubles each retry to avoid thundering herd
delay = delay * 2
```

#### 2. Do not write complex `else` clauses in `with`
Each `with` step's error must be distinguishable. Do not pile every error type into one `else`.
```elixir
# ❌ Bad
with {:ok, user} <- fetch_user(id),
     {:ok, post} <- fetch_post(user) do
  {:ok, post}
else
  nil -> {:error, :not_found}
  {:error, _} -> {:error, :failed}   # which step failed?
end

# ✅ Good — normalize returns inside helpers so `else` is unnecessary or trivial
with {:ok, user} <- fetch_user(id),
     {:ok, post} <- fetch_post(user) do
  {:ok, post}
end
```

#### 3. Do not extract complex values across many clauses
Pattern-match in the head only what is needed for dispatch. Bind extra fields inside the body.
```elixir
# ❌ Bad
def process(%{user: %{email: email, name: name}, meta: %{ip: ip, ua: ua}}), do: ...

# ✅ Good
def process(%{user: user, meta: meta}) do
  %{email: email, name: name} = user
  %{ip: ip, ua: ua} = meta
  ...
end
```

#### 4. Do not create atoms dynamically
`String.to_atom/1` on user/external input leaks memory. Atoms are never garbage-collected.
```elixir
# ❌ Bad — never on untrusted input
String.to_atom(params["role"])

# ✅ Good
String.to_existing_atom(params["role"])   # crashes if unknown — safe
# or explicit mapping:
case params["role"] do
  "admin" -> :admin
  "user"  -> :user
end
```

#### 5. Do not write long parameter lists
If a function takes more than ~4 arguments, group them into a struct, map, or keyword list.
```elixir
# ❌ Bad
def create_loan(amount, term, rate, borrower_id, employer_id, currency, start_date), do: ...

# ✅ Good
def create_loan(%LoanParams{} = params), do: ...
```

#### 6. Do not trespass namespaces
Every module this project defines must start with `LogaMoney.` or `LogaMoneyWeb.`. Never define modules under `Ecto.`, `Phoenix.`, `Ash.`, `Enum.`, etc.

#### 7. Do not use non-assertive map access
For keys that **must** be present, use `map.key` (crashes on missing). Use `map[:key]` only for truly optional keys.
```elixir
# ❌ Bad — silently returns nil if :name is missing
user[:name]

# ✅ Good
user.name                   # required field
Map.get(user, :nickname)    # truly optional field
```

#### 8. Do not write non-assertive pattern matches
Match the exact shape you expect. Do not use overly permissive patterns to "be safe".
```elixir
# ❌ Bad — accepts anything, hides bugs
def get_id(value), do: value["id"]

# ✅ Good — crashes loudly if shape is wrong
def get_id(%{"id" => id}), do: id
```

#### 9. Do not use truthy operators on booleans
Use `and`, `or`, `not` when both sides are guaranteed booleans. Reserve `&&`, `||`, `!` for nil/falsy logic.
```elixir
# ❌ Bad
if active? && verified?, do: ...

# ✅ Good
if active? and verified?, do: ...
```

#### 10. Do not create structs with 32 or more fields
Past 32 fields, the struct switches representation and loses optimizations. Split into nested structs.

### Design Anti-Patterns

#### 11. Do not return alternative types from one function
A function's return type must not change based on options. Split into separate functions.
```elixir
# ❌ Bad
def find_user(id, opts \\ []) do
  if opts[:raise], do: %User{...}, else: {:ok, %User{...}}
end

# ✅ Good
def find_user(id), do: {:ok, ...}
def find_user!(id), do: ...   # raises
```

#### 12. Do not encode state with multiple booleans
Use a single atom-valued field instead of overlapping boolean flags.
```elixir
# ❌ Bad
%User{is_admin: true, is_employer: false, is_borrower: false}

# ✅ Good
%User{role: :admin}
```

#### 13. Do not use exceptions for control flow
Expected failures (validation, not-found, etc.) return `{:ok, _}` / `{:error, _}`. Reserve `raise`/`rescue` for truly unexpected conditions.
```elixir
# ❌ Bad
def get_user(id) do
  try do
    Repo.get!(User, id)
  rescue
    Ecto.NoResultsError -> nil
  end
end

# ✅ Good
def get_user(id) do
  case Repo.get(User, id) do
    nil  -> {:error, :not_found}
    user -> {:ok, user}
  end
end
```

#### 14. Do not use primitive types for domain concepts
Wrap domain values in structs/maps, not bare strings/integers/tuples.
```elixir
# ❌ Bad
def transfer({"DOP", 1500}, {"DOP", 0}), do: ...

# ✅ Good
def transfer(%Money{} = from, %Money{} = to), do: ...
```

#### 15. Do not group unrelated logic in one multi-clause function
Multiple clauses of the same function must implement the *same* operation on different shapes. If clauses do unrelated things, split into named functions.

#### 16. Do not use Application config for library/module behavior
Pass configuration through function arguments or struct fields, not via `Application.get_env/2` reads at call time. Reading global config inside a function makes it untestable and non-reentrant.

### Process Anti-Patterns

#### 17. Do not use processes for code organization
Processes (`GenServer`, `Agent`, `Task`) exist to model **concurrency, state isolation, or fault isolation**. They are not a way to "group" code. Use modules and functions for that.

#### 18. Do not scatter process interfaces
All calls to a given `GenServer`/`Agent` go through one wrapper module that owns its API. Do not call `GenServer.call/2` directly from arbitrary callers.

#### 19. Do not send unnecessary data to processes
When sending messages or spawning, capture only the fields you need — not whole structs or socket assigns.
```elixir
# ❌ Bad
Task.async(fn -> process(socket.assigns) end)

# ✅ Good
user_id = socket.assigns.current_user.id
Task.async(fn -> process(user_id) end)
```

#### 20. Do not start unsupervised processes
Every long-lived process must be added to the supervision tree in `application.ex` (or under a `DynamicSupervisor`). Never call `GenServer.start_link/3` from arbitrary code paths without supervision.

### Meta-Programming Anti-Patterns

#### 21. Do not introduce unnecessary compile-time dependencies in macros
A macro that references another module via `Macro.expand/2` of an alias creates a compile-time dep and forces recompiles. Prefer runtime references where possible.

#### 22. Do not generate large amounts of code in macros
If a macro emits dozens of lines per invocation, move the logic into a helper function called from the `quote` block.

#### 23. Do not write unnecessary macros
Use functions unless you specifically need to manipulate AST or inject code at compile time. If a function would work, use a function.

#### 24. Do not use `use` when `import` or `alias` suffices
`use SomeModule` triggers `__using__/1` and injects unknown code. Prefer `alias` (for naming) or `import` (for direct calls). Reserve `use` for libraries that explicitly require it (Phoenix, Ash, ExUnit, etc.).

#### 25. Do not create module names dynamically
Building module names via `String.to_atom/1` or `Module.concat/1` from runtime data hides dependencies from the compiler.
```elixir
# ❌ Bad
mod = String.to_atom("Elixir.LogaMoney.#{name}")
mod.call()

# ✅ Good — explicit map
case name do
  "loan"    -> LogaMoney.Loan.call()
  "payment" -> LogaMoney.Payment.call()
end
```

## Phoenix / LiveView Rules

- LiveView templates **always** begin with `<Layouts.app flash={@flash} ...>`
- **Never** call `<.flash_group>` outside of `layouts.ex`
- Use `<.link navigate={href}>` / `push_navigate` (not deprecated `live_redirect`)
- **Avoid LiveComponents** unless there is a specific, strong need
- Use `<.icon name="hero-x-mark">` from `core_components.ex` — never use `Heroicons` modules directly
- Use `<.input>` from `core_components.ex` for all form inputs
- **Avoid inline `class` attrs in LiveView/LiveComponent templates.** Instead, create or improve reusable function components in `core_components.ex` (for general UI) or dedicated component files (for domain-specific logic). This keeps styling centralized and maintainable.
- **Prefer custom function components over raw HTML tags for styled UI elements** (buttons, cards, alerts, inputs, etc.). Use `<.button>`, `<.card>`, `<.info_card>`, and equivalents from `core_components.ex` or domain component files instead of bare tags with inline classes. Structural tags (`div`, `span`) are exempt.
- Routes within a `scope` block already have the module alias — don't duplicate it

### LiveView Streams

Always use streams for collections (prevents memory issues):

```elixir
stream(socket, :items, list)               # assign/reset
stream(socket, :items, list, reset: true)  # filter/refresh
stream_delete(socket, :items, item)        # delete
```

Streams are **not enumerable** — to filter, refetch data and re-stream with `reset: true`. Track counts and empty states via separate assigns.

### LiveView JS Interop

- Inline scripts use colocated hooks (`:type={Phoenix.LiveView.ColocatedHook}`) with names starting with `.`
- **Never** write raw `<script>` tags in HEEx templates
- `phx-hook` elements **must** have a unique DOM `id`
- When a hook manages its own DOM, also set `phx-update="ignore"`

## CSS / Assets

- TailwindCSS v4 uses `@import "tailwindcss" source(none)` syntax in `app.css`
- **Never** use `@apply` in raw CSS
- Only `app.js` and `app.css` bundles are supported — import all vendor deps into these files
- **Never** write inline `<script>` tags in templates

## Testing

### Test Case Modules
- Use `DataCase` (with DB sandbox) for business logic tests, `ConnCase` for HTTP/LiveView, `FeatureCase` for Wallaby browser tests
- Use `start_supervised!/1` for processes — never `Process.sleep/1`
- For async synchronization use `_ = :sys.get_state(pid)`, not sleep
- Monitor processes with `Process.monitor/1` + `assert_receive {:DOWN, ...}`

### Scope and Coverage
- **Write concise, targeted tests.** Each test should assert one behavior clearly.
- **Don't over-test.** Once a behavior is covered (e.g., validation of a field), do not repeat the same assertion in another test file or describe block.
- Prefer `describe` blocks to group related cases; avoid duplicating setup or assertions across groups.

### No Mocks
- **Never use mocks.** Test against real implementations with real database state.
- Use `test/support/factory.ex` (`build/2`, `insert!/2`) to create test data via Ash actions.
- For external services (email, SMS), rely on test adapters configured in `config/test.exs`, not mock modules.

### LiveView vs. Wallaby
- **Prefer `Phoenix.LiveViewTest` for all UI tests.** It is faster, does not require a browser driver, and covers the vast majority of LiveView interactions.
- Use `has_element?/2` and `element/2` for assertions — never assert on raw HTML strings.
- **Only create Wallaby (`FeatureCase`) tests when a behavior is genuinely impossible to test with LiveView** (e.g., file downloads, native browser dialogs, or complex multi-tab scenarios). Document why LiveView was insufficient in a comment above the test.

## Pre-commit Workflow

Run `mix precommit` before pushing. It executes: `deps.unlock → format → compile → docs → credo → doctor → dialyzer`. 
Fix all issues before committing. Use conventional commits to separate stages when all checks pass.

## Workflow section in CLAUDE.md

When working on issues, always read the full issue description and linked issues before starting implementation. 
If an issue involves multiple steps (docs, refactor, PR), outline the plan first and confirm before proceeding.
