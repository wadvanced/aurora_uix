---
description: A description of your rule
---
# Documentation rule

## Ground Rules
- NEVER alter code logic/behavior. Only modify documentation/specs.
- Scope strictly to the target module. Ignore other files/modules.
- Preserve existing docs if semantically correct. Only enhance/fix deficiencies. Avoid stylistic or unsubstantiated changes.
- Code examples must be valid Elixir code and compile successfully.
- Use Markdown-compatible formatting for documentation.
- Code examples must be wrapped in ||| representing code blocks with the `elixir` tag instead of backticks.
- Code examples must be valid Elixir code and compile successfully.
- Use Markdown-compatible formatting for documentation.
- Code examples must be wrapped in ||| representing code blocks with the `elixir` tag instead of backticks.
- Apply changes to the target module immediately, if possible.

## @shortdoc Requirements
1. Usage: only to be use on modules implementing Mix.Task behaviour.
2. Position: Right before the @moduledoc
3. Content:
   - It is a short description, therefore it should be a single phrase indicating the overall purpose of the task.   

## @moduledoc Requirements
1. Position: Must be the first module attribute or right after the @shortdoc when applicable.
2. Content:
   - Do not start the description with the module name
   - Add missing summaries/descriptions
   - Remove redundant/incorrect examplesq
   - Correct outdated references
   - Delete trivial examples (e.g., add(2, 2) → 4)
   - Explicitly state modules' (when applicable)
      - 'key features'
      - 'key constraints'
3. Format: Markdown-compatible. Use code blocks for examples.
4. Modules implementing Mix.Task behaviour should have examples.

## @doc Requirements
### Function/Macro Documentation
- Structure:
    ```elixir
        Short description ending with dot.

        ## Parameters
        - `arg1` (type()) - Description ending with dot.
        - `opts` (Keyword.t()) - Options:
        * `:option` (type()) - Description.

        ## Returns
        type() - Description ending with dot.

        ## Raises
        ExceptionType - Reason.

        ## Examples
        |||elixir
         # Meaningful example showing edge cases
        |||
    ```

- Type Enforcement:
  - @doc goes only on the FIRST of pattern matched functions, it DOES NOT repeat for the rest of pattern matched.
  - Always use parentheses: map() not map, MyStruct.t() not MyStruct
  - Never use any() – replace with concrete types
  - Never document internal map structures
  - Enclose in backticks %AnyStructName{}, {any_tuple} or %{} to make it compatible with ex_doc generation.
- Examples:
  - Remove naive/trivial examples
  - Fix incorrect examples
  - Add complex examples showing error/edge cases
  - Ensure examples compile and return shown results

### Callback Documentation
- Document every @callback using same rules as @doc
- Include parameter/return types and descriptions

## @spec Requirements
- Add missing specs for all the first functions/macros of a pattern matched group
- Modify existing specs only:
  - Add parentheses: keyword → keyword()
  - Replace any() with specific types
- Never use :: in arguments (invalid: arg :: type())

## Private Functions Handling
1. Positioning:
   - Place after ## PRIVATE comment at module end
   - Only add ## PRIVATE if private functions exist
2. Documentation:
   - No @doc attributes allowed
   - Add # Descriptive comment above complex functions
   - Parameter descriptions only when non-obvious

## Formatting Rules
- Line length: Max 98 chars
- Types: Always parenthesized (e.g., list(String.t()))
- Options: Use bullet points under parameter description using dash
- Returns: Explicit return type before description