---
mode: 'agent'
tools: ['codebase']
description: 'Preferences for module documentation'
---
Modify only the focused module.

## Formatting
parameters, maps, list are to be edited into one line, when they do not exceed the 98 characters limit.

## @moduledoc
Create or update the @moduledoc according to the implementation.
On existing @moduledoc do not overdo, if the semantics are right DO NOT modify it.
Add missing elements and remove non existing ones.
Avoid unnecesary examples.

## @doc
Create or update the @doc for each of the public functions.
Include parameters with their type. DO NOT include map expected contents.
Use the () for the common typings.
Use dash for arguments list.
Include options details, also with dashes.
Include the expected return.

## @callback
Document @callback.

## @spec
Add the missing @spec to each of the functions and MACROS. 
DO NOT change existing @spec, except for changing types from their simple name to the one with '()'. Example: 'map' to 'map()', 'keyword' to 'keyword()'.
Avoid using any().
Do not use the :: notation for function arguments.

## private functions
For complex private functions, add a common comment '#' with a description of the expected behaviour.
Only add parameters descriptions if needed.



