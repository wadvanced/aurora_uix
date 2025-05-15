---
mode: 'agent'
tools: ['codebase']
---
## Try to reduce the number of public functions (NOT MACROS)

1. Determine which functions should be private. 

2. Change def to defp when they should be private.

3. Append a ## PRIVATE comment at the bottom of the module, if it does not exists.

4. Ensure that all private functions are below the ## PRIVATE line

6. Convert the @doc to a simple (probably one liner) regular comment.

