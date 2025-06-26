defmodule Aurora.Uix.Parser do
  @moduledoc """
  Utilities for converting Ecto schema modules into configuration maps for dynamic UI rendering.

  Defines the interface for transforming schema modules into structured configuration maps, enabling dynamic UI generation in Aurora.Uix.

  ## Key features
  - Extracts metadata from Ecto schema modules.
  - Generates human-readable names and titles.
  - Prepares configuration maps for various UI views (e.g., index, form).

  ## Key constraints
  - Expects Ecto schema modules as input.
  - Requires compatible field and metadata conventions.
  """

  alias Aurora.Uix.Parsers.Common
  alias Aurora.Uix.Parsers.ContextParser
  alias Aurora.Uix.Parsers.IndexParser

  @doc """
  Returns the list of supported configuration option keys for the parser.

  ## Returns
  list(atom()) - List of configuration option keys supported by the parser.
  """
  @callback get_options() :: list(atom())
  @doc """
  Returns the default value for a configuration key.

  ## Parameters
  - `parsed_opts` (map()) - Parsed configuration options.
  - `resource_config` (map()) - Module configuration info.
  - `key` (atom()) - Configuration key to get default value for.

  ## Returns
  term() - Default value for the given key.
  """
  @callback default_value(parsed_opts :: map(), resource_config :: map(), key :: atom()) :: term()

  @doc """
  Parses schema and options into a structured configuration map for UI rendering.

  ## Parameters
  - `resource_config` (map()) - Module configuration info.
  - `opts` (keyword()) - Optional config settings. Options are delegated to:
    * Aurora.Uix.Parsers.Common
    * Aurora.Uix.Parsers.IndexParser
    * Aurora.Uix.Parsers.ContextParser

  ## Returns
  map() - Schema metadata, fields config, and template settings.

  ## Examples
      iex> Aurora.Uix.Parser.parse(%{schema: MyApp.Account}, rows: [:id, :email])
      %{rows: [:id, :email], ...}
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

  # Applies parser options to the parsed_opts accumulator.
  @spec parser_process_options(module(), map(), map(), keyword()) :: map()
  defp parser_process_options(parser, parsed_opts, resource_config, opts) do
    parser_options = parser.get_options()
    Enum.reduce(parser_options, parsed_opts, &add_opt(&1, &2, parser, resource_config, opts))
  end

  # Adds a configuration option to the parsed_opts map.
  @spec add_opt(atom(), map(), module(), map(), keyword()) :: map()
  defp add_opt(key, parsed_opts, parser, resource_config, opts) do
    parsed_opts
    |> parser.default_value(resource_config, key)
    |> then(&Keyword.get(opts, key, &1))
    |> then(&Map.put_new(parsed_opts, key, &1))
  end
end
