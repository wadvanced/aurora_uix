---
name: documentation
description: Rules to use when documenting elixir code
applyTo:
  - "**/*.ex"
  - "**/*.exs"
---

Document a single Elixir module by adding/repairing `@moduledoc`, `@doc`, `@spec`, and `@shortdoc`. Never alter code logic.

## Inputs

This skill operates on ONE target file path provided by the caller. Do not touch any other file.

## Loop and termination

1. Run `mix consistency` and capture output.
2. If the failing stage is `docs` or `doctor` and the warning references the target file, apply the rules below to the target file and re-run.
3. Stop when:
   - `mix consistency` no longer reports `docs`/`doctor` warnings on the target file, OR
   - 3 iterations have passed (report remaining warnings to the user and stop), OR
   - `mix consistency` fails on a non-docs stage (stop and report — do NOT attempt to fix it from this skill).

Do NOT commit changes. The caller decides when to commit.

## Anti-rules (never do these)

- Never modify the body of a `def`, `defp`, `defmacro`, or `defmacrop`.
- Never re-order, rename, add, or delete functions.
- Never change `alias`, `import`, `use`, or `require` lines.
- Never change `@spec` if it is already correct — only add missing ones or fix the specific issues listed below.
- Never document internal map structures.

## `@shortdoc`

- Only on modules implementing `Mix.Task`.
- Position: immediately before `@moduledoc`.
- Content: a single short phrase stating the task's purpose.

## `@moduledoc`

- Position: first module attribute, or directly after `@shortdoc` for `Mix.Task` modules.
- Content rules:
  - Do NOT start the description with the module name.
  - Add a missing summary if absent.
  - Remove an example if it is **trivial**, defined as: its output is a literal restatement of its input (e.g. `add(2, 2) #=> 4`), OR it uses no module-specific behaviour.
  - Remove or correct outdated references (modules/functions that no longer exist).
  - For non-trivial modules, list `key features` and `key constraints` as bullet sections when they apply.
- Format: Markdown. Use fenced code blocks for examples.
- `Mix.Task` modules MUST include at least one example.
- Preservation rule: if existing `@moduledoc` text already matches the function/module name and parameters and contains no forbidden patterns, leave it alone. When unsure, leave it alone.

## `@doc`

Place `@doc` only on the FIRST function in an arity-matched group. Do not repeat for additional clauses or arities of the same name.

Use this skeleton:

```elixir
@doc """
Short description ending with a dot.

## Parameters
- `arg1` (type()) - Description ending with a dot.
- `opts` (Keyword.t()) - Options:
  * `:option` (type()) - Description.

## Returns
type() - Description ending with a dot.

## Raises
ExceptionType - Reason.

## Examples
```elixir
# Meaningful example showing edge cases
```
"""
```

Type rules inside `@doc`:
- Always parenthesise: `map()` not `map`, `MyStruct.t()` not `MyStruct`.
- Never use `any()`. Replace with concrete types: `binary()`, `tuple()`, `map()`, `integer()`, etc.
- Wrap struct, tuple, and map literals in backticks: `` `%MyStruct{}` ``, `` `{:ok, value}` ``, `` `%{}` ``.

Examples rules:
- Remove **trivial examples** (same definition as `@moduledoc`).
- Fix examples that no longer compile or whose result is wrong.
- Add an example for error/edge cases when the function has non-obvious branches.

### `@callback`

Apply the same `@doc` rules to every `@callback`.

## `@spec`

- Add a missing `@spec` for the FIRST function/macro of every arity-matched group, both public and private.
- Modify an existing `@spec` only to:
  - Add parentheses (e.g. `keyword` → `keyword()`).
  - Replace `any()` with a concrete type.
- Never write `arg :: type()` — `::` is not allowed in arguments.
- Use the outermost type only; do not specify inner types. Examples:
  - Good: `@spec parse(binary()) :: list()`.
  - Bad: `@spec parse(binary()) :: list(binary())`.
- Use project-local custom types where they exist.

### `@spec` examples

Good:
```elixir
@spec build(map()) :: {:ok, struct()} | {:error, term()}
```

Bad (uses `any()`):
```elixir
@spec build(any()) :: any()
```

Bad (specifies inner types):
```elixir
@spec build(map()) :: {:ok, %MyMod{name: binary(), age: integer()}}
```

## Private functions

If a module has any `defp`/`defmacrop`:

1. Place all private functions after a single `## PRIVATE` comment near the end of the module. Add the `## PRIVATE` line only if private functions exist.
2. No `@doc` attributes on private functions.
3. Add a `# Descriptive comment` line above any private function that meets either of:
   - Body is over 15 lines, OR
   - Contains a `case`, `cond`, or `with` with 3 or more branches.
4. Add `@spec` for the first function/macro of each arity-matched private group.

## Formatting

- Max line length: 98 chars.
- Bullet points under a parameter description use a single dash (`-`).
- Returns: explicit type before the description.
