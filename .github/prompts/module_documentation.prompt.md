---
mode: 'agent'
tools: ['codebase']
description: 'Preferences for module documentation'
---
Modify only the focused module. Do not CHANGE any code.
DO NOT change code

## Formatting
parameters, maps, list are to be edited into one line, when the resulting text do not exceed the 98 characters limit.

## @moduledoc
Create or update the @moduledoc according to the implementation respecting existing documentation
On existing @moduledoc do not overdo, if the semantics are right DO NOT modify it.
Add missing documentation elements and remove the ones that shouldn't be mentioned.
Remove duplicated or unmeaningful or naive examples.
Fix wrong examples.

## @doc
Create or update the @doc for each of the public functions.
Include parameters with their type. DO NOT include map expected contents.
Use the () for the common typings.
Use dash for arguments list.
Include options details, also with dashes.
Include the expected return.
Remove duplicated or unmeaningful or naive examples.
Fix wrong examples.
If the functions raise any kind of exception, document it.

## @callback
Document the @callback declarations

## @spec
Add the missing @spec to each of the functions and MACROS. 
DO NOT change existing @spec, except for changing types from their simple name to the one with '()'. Example: 'map' to 'map()', 'keyword' to 'keyword()'.
Avoid using any(), try your best to replace any() appropriately if found in existing declarations.
Do not use the :: notation for function arguments.

## private functions
- All private functions are at the end of the file after a comment '## PRIVATE', DO NOT remove this comment, add the comment if it is missed, ensure is written as described here.
- Move private functions to the proper place.
- For complex private functions, add a common comment '#' with a description of the expected behaviour.
Only add parameters descriptions if needed.



