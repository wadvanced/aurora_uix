defmodule Aurora.Uix.Parsers.ParserCore do
  @moduledoc """
  Provides a base implementation and macro for parser behaviors in the Aurora.Uix system.

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
      @behaviour Aurora.Uix.Parser

      @spec add_opt(map(), map(), keyword(), atom()) :: map()
      defp add_opt(parsed_opts, resource_config, opts, key) do
        parsed_opts
        |> default_value(resource_config, key)
        |> then(&Keyword.get(opts, key, &1))
        |> then(&Map.put_new(parsed_opts, key, &1))
      end

      @spec capitalize(binary()) :: binary()
      defp capitalize(string) do
        string
        |> Macro.underscore()
        |> String.split("_")
        |> Enum.map_join(" ", &String.capitalize/1)
      end
    end
  end
end
