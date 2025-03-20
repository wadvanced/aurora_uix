defmodule AuroraUix.Parsers.ParserCore do
  @moduledoc """
  Provides a base implementation and macro for parser behaviors in the AuroraUix system.

  This module defines common utilities and macros used across different parser modules,
  including:
  - Default option handling
  - String capitalization helpers
  - Standardized parsing behaviors

  When used, it automatically adds:
  - A default implementation of the `default_value/2` callback
  - Utility functions for option manipulation
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour AuroraUix.Parser

      @spec add_opt(map, module, Keyword.t(), atom) :: map
      defp add_opt(parsed_opts, module, opts, key) do
        module
        |> default_value(key)
        |> then(&Keyword.get(opts, key, &1))
        |> then(&Map.put_new(parsed_opts, key, &1))
      end

      @spec capitalize(binary) :: binary
      defp capitalize(string) do
        string
        |> Macro.underscore()
        |> String.split("_")
        |> Enum.map_join(" ", &String.capitalize/1)
      end
    end
  end
end
