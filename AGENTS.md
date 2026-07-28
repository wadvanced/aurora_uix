# AGENTS.md

Canonical guidance for any AI coding agent working in this repository (Claude Code, GitHub Copilot, opencode, qwen-code, Cursor, Aider, etc.). `CLAUDE.md` includes this file via `@AGENTS.md`.

## Overview

Aurora UIX (`aurora_uix`) is a **low-code UI generation library** for Phoenix — *not* an application. Host applications declare resource metadata and a layout, and the library generates the LiveView index / form / show UIs, including routing, CRUD wiring, filtering, pagination and theming.

Its defining characteristic is that it works over **two interchangeable backends**:

| Backend | Data access | Parser |
|---|---|---|
| **Ash** | `Ash.*` resources | `lib/aurora_uix/integration/ash/` |
| **Ecto** | `aurora_ctx` generated contexts | `lib/aurora_uix/integration/ctx/` |

Both are normalized into a common `%Aurora.Uix.Field{}` shape that everything downstream consumes. Keeping that boundary intact is the single most important rule in this codebase.

## Commands

```bash
# Setup
mix deps.get
mix ecto.create && mix ecto.migrate   # test/demo database

# Testing  (migrations are NOT run by mix test — run ecto.migrate yourself)
mix test                     # Run all tests
mix test path/to/test.exs    # Run a specific test file
mix test --failed            # Re-run previously failed tests

# Quality gate (run before committing) — see "Quality Gate" below
mix consistency              # tailwind classes, format, compile, credo, dialyzer, doctor
mix format                   # Auto-format code
mix credo --strict           # Lint
mix dialyzer                 # Static analysis (first run is slow)

# Assets / generated artifacts
mix auix.gen.stylesheet      # Regenerate the theme stylesheet
mix auix.gen.icons           # Regenerate the icon set
mix auix.gen.tailwind_classes # Regenerate the auix-* class inventory
mix assets.build             # Full asset pipeline (icons + stylesheet + esbuild + digest)

# Demo server for the test app (routes come from test/support/app_web/routes.ex)
iex -S mix run test/start_test_server.exs
```

## Naming Conventions

When referencing UI components in documentation or code, use simple names (e.g. 'Phone', 'Email') not prefixed/namespaced names (e.g. 'EmbeddedPhone', 'EmbeddedEmail') unless explicitly asked.

## Glossary

| Term | Meaning |
|---|---|
| **Resource** | A registered schema + its UIX metadata (`auix_resource_metadata/2`). Identified by an atom name such as `:product`. |
| **Field** | `%Aurora.Uix.Field{}` — the normalized, backend-agnostic description of one schema field: `type`, `html_type`, `data`, plus presentation flags. |
| **Layout tree** | The declarative `%TreePath{}` structure produced by `auix_create_ui`, describing what renders where for a given `layout_type`. |
| **`layout_type`** | One of `:index`, `:form`, `:show`. Nearly every renderer branches on it. |
| **Blueprint** | Compile-time expansion that turns resource metadata + layout declarations into the generated LiveView modules. |
| **Backend / integration** | `:ash` or `:ctx`. Selected per resource; determines which parser and CRUD module are used. |
| **Host application** | The app that depends on `aurora_uix`. Owns its schemas, changesets and Ash actions — the library never writes those. |
| **Guides** | `lib/aurora_uix/guides/` — demo schemas shipped with the library, doubling as test fixtures. `blog/` is Ash, `inventory/` is Ecto. |

## Architecture

### Core Structure

```
lib/
  aurora_uix/
    integration/        # BACKEND-SPECIFIC — the only place backend structs may appear
      ash/              #   Ash: fields_parser, crud, query_parser, context_parser_defaults
      ctx/              #   Ecto/aurora_ctx: same set
      crud.ex           #   backend-agnostic dispatcher
    layout/             # blueprint.ex, create_ui.ex, resource_metadata.ex — metadata → layout trees
    templates/basic/    # the default template: everything that renders
      renderers/        #   default_renderer.ex (dispatch), fields/, predefined/
      generators/       #   index/form/show module generation
      handlers/         #   LiveView callbacks (index_impl, form_impl, show_component_impl)
      actions/          #   row/header/footer action definitions
      themes/           #   base.ex + theme variants (all auix-* CSS lives here)
      components/       #   core_components.ex and friends
    guides/             # demo schemas: blog/ (Ash), inventory/ (Ecto), accounts/
    field.ex            # %Field{} — the normalized backend-agnostic field struct
  mix/tasks/uix/gen/    # auix.gen.{icons,stylesheet,tailwind_classes}
priv/
  repo/migrations/      # migrations for the demo/test schemas
  resource_snapshots/   # AshPostgres snapshots (commit alongside generated migrations)
  gettext/              # *.pot templates (no per-locale translations shipped)
test/
  cases/                # metadata + parser tests (no DB)
  cases_live/           # LiveView tests — the default for UI work
  browser_cases/        # Wallaby — last resort
  doctests/
  support/              # UICase, WebCase, helper.ex, app_web/routes.ex
guides/                 # end-user documentation
```

### Key Patterns

**Backend abstraction boundary (STRICT)** — the rule that everything else depends on:

- `Ecto.Association.*` / `Ecto.Embedded` may appear **only** under `lib/aurora_uix/integration/ctx/`.
- `Ash.Resource.*` may appear **only** under `lib/aurora_uix/integration/ash/`.
- Everything downstream — `layout/`, `templates/`, generators, handlers — consumes the normalized `%Field{}` atoms and must stay backend-agnostic.
- **A feature is not complete until both parsers support it.** Adding a capability to one backend only is a bug unless explicitly justified.

```elixir
# ❌ Bad — Ecto struct leaking into a renderer
def render(%{field: %{data: %Ecto.Association.Has{}}} = assigns), do: ...

# ✅ Good — renderers match on the normalized atom
def render(%{field: %{type: :one_to_many_association}} = assigns), do: ...
```

**Adding a new `%Field{}` type atom is the highest-risk change in this codebase.** Many modules pattern-match on the existing atoms. Grep for a sibling atom and make a deliberate *add / do-NOT-add* decision at every hit — silent omission (e.g. forgetting `filter_preloads/1`) fails far from the change and is the dominant failure mode here.

**The library is transport-only for writes.** It renders input names and forwards params untouched; it never builds a changeset. Persisting nested data is the **host's** responsibility — `cast_assoc`/`cast_embed` in an Ecto changeset, or `argument` + `change manage_relationship(...)` in an Ash action. The only `cast_*` calls in this repo are in `lib/aurora_uix/guides/`, which is demo host code.

**Renderers** implement the `Aurora.Uix.Renderer` behaviour (`render/1`) and are dispatched from `templates/basic/renderers/default_renderer.ex`. Prefer swapping `auix` keys (`:layout_tree`, `:resource_name`, `:form`, `:entity`) and delegating to `Renderer.render_inner_elements/1` over hand-writing child markup — that keeps renderer overrides, sections and groups working.

> Note the module-vs-path convention: field renderers live in `renderers/fields/` but are named `Aurora.Uix.Templates.Basic.Renderers.OneToMany`, **not** `…Renderers.Fields.OneToMany`.

**Localization**: user-visible strings go through `dt/1` (`use Aurora.Uix.Gettext`) and are extracted to `priv/gettext/*.pot`. This project ships no per-locale translations.

### Tech Stack

- **Elixir 1.19.4 / Erlang 28.2** (see `.tool-versions`; the package supports `~> 1.17`)
- **Phoenix 1.8+** with **LiveView 1.1+** — no separate SPA framework
- **Ash 3.0+** + `ash_phoenix` + `ash_postgres` — one of the two supported backends
- **`aurora_ctx`** — generated Ecto contexts; the other supported backend
- **PostgreSQL** via `ecto_sql` / `postgrex`
- **TailwindCSS v4** — `@import` syntax, no `tailwind.config.js`; the stylesheet is *generated* by `mix auix.gen.stylesheet`
- **esbuild** for JS, **bandit** as the test-app server
- **Wallaby** for the few browser-level tests
- Quality tooling: **credo**, **dialyxir**, **doctor**, **ex_doc**

This is a **library**: it has no application of its own beyond a minimal test app. There is no Oban, no mail layer, no GraphQL, and no HTTP client dependency.

### Supervision Tree (application.ex)

`Aurora.Uix.Supervisor` (`:one_for_one`) is **conditional on the `:aurora_uix, :endpoint` config**. When an endpoint is configured (the test/demo app), it starts:

`Aurora.UixWeb.Telemetry` → `Aurora.Uix.Repo` → `{Phoenix.PubSub, name: Aurora.Uix.PubSub}` → the configured endpoint

When no endpoint is configured — the normal case for a host application depending on this library — it starts **no children at all**.

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
def render_field(key, type, html_type, layout_type, resource_name, form, entity), do: ...

# ✅ Good
def render_field(%Field{} = field, %{} = auix), do: ...
```

#### 6. Do not trespass namespaces
Every module this project defines must start with `Aurora.Uix.` (or `Aurora.UixWeb.` / `Mix.Tasks.Auix.`). Never define modules under `Ecto.`, `Phoenix.`, `Ash.`, `Enum.`, etc.

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
%Field{is_association: true, is_embed: false, is_upload: false}

# ✅ Good
%Field{type: :one_to_many_association}
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
def render_field({:one_to_many_association, :form, "product"}), do: ...

# ✅ Good
def render_field(%Field{} = field, %{layout_type: :form} = auix), do: ...
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
mod = String.to_atom("Elixir.Aurora.Uix.Templates.Basic.Renderers.#{name}")
mod.render(assigns)

# ✅ Good — explicit map
case name do
  "one_to_many" -> Renderers.OneToMany.render(assigns)
  "many_to_one" -> Renderers.ManyToOne.render(assigns)
end
```

## Phoenix / LiveView Rules

LiveView modules here are **generated**, not hand-written — the rules apply to the renderers and components that produce them.

- Use `<.link navigate={href}>` / `push_navigate` (not deprecated `live_redirect`)
- **Avoid LiveComponents** unless there is a specific, strong need (state that must survive re-render, or self-targeted events). `embeds_many` is the existing precedent; `embeds_one` deliberately is not.
- Use `<.icon name="hero-x-mark">` and `<.input>` from `templates/basic/components/core_components.ex` — never use `Heroicons` modules directly
- **No inline `class` attrs.** All styling belongs to the theme (`templates/basic/themes/base.ex`) behind an `auix-*` class. Adding a class means editing the theme, re-running `mix auix.gen.tailwind_classes`, and committing the regenerated stylesheet.
- **Prefer function components over raw HTML tags for styled elements**. Structural tags (`div`, `span`) are exempt.
- Prefer swapping `auix` assigns and delegating to `Renderer.render_inner_elements/1` over emitting child markup directly
- Every route used by a `test/cases_live/` test must be registered in `test/support/app_web/routes.ex`, or the test 404s

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

- TailwindCSS v4 uses `@import "tailwindcss" source(none)` syntax — there is no `tailwind.config.js`
- **The stylesheet is generated.** Never hand-edit `priv/static/assets/css/app.css`; edit the theme module and run `mix auix.gen.stylesheet`
- New `auix-*` classes go in `templates/basic/themes/base.ex`, then `mix auix.gen.tailwind_classes`. This task is the **first stage of `mix consistency`** and fails on classes it doesn't know about
- **Never** use `@apply` in raw CSS
- Only `app.js` and `app.css` bundles are supported — import all vendor deps into these files
- **Never** write inline `<script>` tags in templates

## Testing

### Test layers

| Directory | Covers | DB? |
|---|---|---|
| `test/cases/integration/{ash,ctx}/` | parser output for one backend | no |
| `test/cases/integration/fields_parser_validations_test.exs` | shared golden `%Field{}` metadata | no |
| `test/cases/` | resource metadata, layout/blueprint generation | no |
| `test/cases_live/` | rendered LiveView behaviour — **the default for UI work** | yes |
| `test/browser_cases/` | Wallaby — last resort | yes |
| `test/doctests/` | doctests | no |

Parser and metadata tests are pure compile-time introspection — run them first as the fast feedback loop.

### Test Case Modules
- `use Aurora.UixWeb.Test.UICase, :phoenix_case` and `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`. There is no `FeatureCase` and no `test/support/factory.ex`.
- Test data comes from the guide schemas via `test/support/helper.ex` (`create_sample_products/2`, `delete_all_inventory_data/0`, …)
- **Migrations are not run by `mix test`.** Run `mix ecto.migrate` yourself, or DB-backed tests fail with a confusing `relation "…" does not exist`
- Use `start_supervised!/1` for processes — never `Process.sleep/1`
- For async synchronization use `_ = :sys.get_state(pid)`, not sleep
- Monitor processes with `Process.monitor/1` + `assert_receive {:DOWN, ...}`

### Scope and Coverage
- **Write concise, targeted tests.** Each test should assert one behavior clearly.
- **Don't over-test.** Once a behavior is covered (e.g., validation of a field), do not repeat the same assertion in another test file or describe block.
- Prefer `describe` blocks to group related cases; avoid duplicating setup or assertions across groups.

### No Mocks
- **Never use mocks.** Test against real implementations with real database state.
- Create test data through the guide schemas and `test/support/helper.ex`, not by hand-rolling structs.
- Cover **both backends** when a change touches the parser layer — an Ash-only or Ecto-only test is an incomplete test.

### LiveView vs. Wallaby
- **Prefer `Phoenix.LiveViewTest` for all UI tests.** It is faster, does not require a browser driver, and covers the vast majority of LiveView interactions.
- Use `has_element?/2` and `element/2` for assertions — never assert on raw HTML strings.
- Assert on **stable** selectors: `input[name='parent[child][field]']`, container ids, component names. Avoid `auix-field-*` ids — they embed a global counter and are not stable across test ordering.
- **Only create Wallaby (`test/browser_cases/`) tests when a behavior is genuinely impossible to test with LiveView** (file downloads, native browser dialogs, multi-tab scenarios). Document why LiveView was insufficient in a comment above the test.

## Quality Gate

Run `mix consistency` then `mix test` before pushing. The `consistency` alias is fail-fast and executes, in order:

```
auix.gen.tailwind_classes → format → compile --warnings-as-errors → credo --strict → dialyzer → doctor
```

Only the **first failing stage** is visible per run — fix it, re-run, repeat. `mix consistency` does **not** run tests; CI runs them as a separate step after `mix ecto.create && mix ecto.migrate`.

`doctor` enforces documentation coverage, which in this codebase means:
- `@moduledoc` with `## Key Features` / `## Key Constraints` sections
- `@doc` + `@spec` on public functions — on the **first clause only**
- `@spec` on private functions too

Fix all issues before committing. Use conventional commits to separate stages when all checks pass.

## Workflow

When working on issues, always read the full issue description and linked issues before starting implementation. 
If an issue involves multiple steps (docs, refactor, PR), outline the plan first and confirm before proceeding.
