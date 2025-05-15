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

## @spec
Add the missing @spec to each of the functions and MACROS. DO NOT touch existing @spec.
Use only 'map()' for map types.
Avoid using any().

## private functions
For complex private functions, add a common comment '#' with a description of the expected behaviour.
Only add parameters descriptions if needed.



