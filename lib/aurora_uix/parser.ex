defmodule Aurora.Uix.Parser do
  @moduledoc """
  Provides parsing utilities for transforming schema modules into configuration maps for UI rendering.

  This module serves as the primary interface for converting Ecto schema modules into structured
  configuration maps, enabling dynamic UI generation across the Aurora.Uix system.

  Key responsibilities:
  - Extract metadata from schema modules
  - Generate human-readable names and titles
  - Prepare configuration maps for different UI views (index, form, etc.)
  """

  alias Aurora.Uix.Parsers.Common
  alias Aurora.Uix.Parsers.ContextParser
  alias Aurora.Uix.Parsers.IndexParser

  @callback get_options() :: list()
  @doc """
  Returns a default value for a given configuration key.

  ## Parameters
  - `parsed_opts` (`map()`) - Parsed configuration options.
  - `resource_config` (`map()`) - Module configuration info.
  - `key` (`atom()`) - Configuration key to get default value for.

  ## Returns
  `term()` - The default value for the given key.
  """
  @callback default_value(parsed_opts :: map(), resource_config :: map(), key :: atom()) :: term()

  @doc """
  Parses schema and options into a structured configuration map for UI rendering.

  ## Parameters
  - `resource_config` (`map()`) - Module configuration info.
  - `opts` (`keyword()`) - Optional config settings:
    * Aurora.Uix.Parsers.Common.parse/3: Source and schema options.
    * Aurora.Uix.Parsers.IndexParser.parse/3: Index view customization.
    * Aurora.Uix.Parsers.ContextParser.parse/3: Default context functions.

  ## Returns
  `map()` - Schema metadata, fields config, and template settings.
  """
  @spec parse(map(), keyword()) :: map()
  def parse(resource_config, opts \\ []) do
    opts =
      List.flatten(opts)

    Enum.reduce(
      [Common, IndexParser, ContextParser],
      %{},
      &parser_process_options(&1, &2, resource_config, opts)
    )
  end

  defp parser_process_options(parser, parsed_opts, resource_config, opts) do
    parser_options = parser.get_options()
    Enum.reduce(parser_options, parsed_opts, &add_opt(&1, &2, parser, resource_config, opts))
  end

  defp add_opt(key, parsed_opts, parser, resource_config, opts) do
    parsed_opts
    |> parser.default_value(resource_config, key)
    |> then(&Keyword.get(opts, key, &1))
    |> then(&Map.put_new(parsed_opts, key, &1))
  end
end
