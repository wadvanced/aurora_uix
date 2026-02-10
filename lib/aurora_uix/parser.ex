defmodule Aurora.Uix.Parser do
  @moduledoc """
  Core parsing interface for resource configuration in Aurora.Uix.

  Defines the behaviour contract and orchestration logic for converting resource definitions
  (Ecto schemas or Ash resources) into structured configuration maps that enable dynamic UI
  generation. Combines schema metadata extraction with context-based CRUD function discovery.

  ## Key Features

  - Schema metadata extraction (names, titles, sources, primary keys)
  - Automatic CRUD function discovery for Context and Ash integrations
  - Flexible parser composition through behaviour-based architecture
  - Support for multiple backend types (`:ctx` for Context, `:ash` for Ash Framework)
  - Option resolution through cascading parser modules

  ## Parser Architecture

  The parsing process delegates to specialized parser modules:

  1. **Common Parser** (`Aurora.Uix.Parsers.Common`) - Extracts schema-derived properties
     like module names, sources, titles, and primary keys from Ecto schemas.

  2. **Context Parser Defaults** (`Aurora.Uix.Integration.ContextParserDefaults`) -
     Dispatches to backend-specific implementations for CRUD function discovery:
     - `Aurora.Uix.Integration.Ctx.ContextParserDefaults` - Context-based function resolution
     - `Aurora.Uix.Integration.Ash.ContextParserDefaults` - Ash action resolution

  ## Behaviour Callbacks

  Parser implementations must provide:

  - `get_options/0` - Returns list of option keys the parser supports
  - `option_value/4` - Resolves default values for configuration options

  ## Key Constraints

  - Requires valid resource configuration with `:schema` key
  - Context-based parsers require `:type`, `:context` keys in resource configuration
  - Parser resolution happens at compile-time through application configuration
  - Options are merged with resource defaults before processing
  """

  alias Aurora.Uix.Integration.ContextParserDefaults
  alias Aurora.Uix.Parsers.Common

  @doc """
  Returns the list of supported configuration option keys for the parser.

  Parser implementations use this to declare which configuration options they can resolve.
  The keys are used by `parse/2` to iterate and resolve values through `option_value/4`.

  ## Returns

  list(atom()) - List of configuration option keys supported by the parser.

  ## Examples

      iex> Aurora.Uix.Parsers.Common.get_options()
      [:module, :module_name, :name, :source, :source_key, :title, :primary_key]
  """
  @callback get_options() :: list(atom())
  @doc """
  Resolves the default value for a configuration key.

  Called by the parsing process to determine the value for each option key. Implementations
  can inspect parsed options, resource configuration, and raw options to compute values.

  ## Parameters

  - `parsed_opts` (map()) - Accumulator of previously parsed options. Useful for deriving
    values based on other resolved options.
  - `resource_config` (map()) - Resource configuration containing `:schema`, `:type`,
    `:context`, and other metadata.
  - `opts` (keyword()) - Raw un-parsed keyword options passed to `parse/2`.
  - `key` (atom()) - Configuration key to resolve (e.g., `:module`, `:list_function`).

  ## Returns

  term() - The resolved value for the given key. Type depends on the key being resolved.

  ## Examples

      iex> option_value(%{}, %{schema: MyApp.User}, [], :module)
      "user"

      iex> option_value(%{source: "users"}, %{context: MyApp.Accounts}, [], :list_function)
      %Connector{type: :ctx, crud_spec: %CrudSpec{...}}
  """
  @callback option_value(
              parsed_opts :: map(),
              resource_config :: map(),
              opts :: keyword(),
              key :: atom()
            ) :: term()

  @doc """
  Parses resource configuration into a structured map for UI rendering.

  Orchestrates the parsing process by delegating to Common and ContextParserDefaults parsers,
  combining schema metadata extraction with CRUD function discovery.

  ## Parameters

  - `resource_config` (map()) - Resource configuration containing:
    * `:schema` (module()) - Ecto schema or Ash resource module
    * `:type` (atom()) - Backend type (`:ctx` or `:ash`)
    * `:context` (module()) - Context or domain module
    * `:opts` (keyword()) - Default options
  - `opts` (keyword()) - Additional configuration options merged with resource defaults.
    Options are delegated to parser modules:
    * `Aurora.Uix.Parsers.Common` - Schema properties (`:module`, `:name`, `:source`, etc.)
    * `Aurora.Uix.Integration.ContextParserDefaults` - CRUD functions (`:list_function`,
      `:get_function`, `:create_function`, etc.)

  ## Returns

  map() - Parsed configuration containing schema metadata, CRUD function references,
  and UI template settings.

  ## Examples

      iex> parse(%{schema: MyApp.User, type: :ctx, context: MyApp.Accounts, opts: []})
      %{
        module: "user",
        name: "User",
        source: "users",
        title: "Users",
        primary_key: [:id],
        list_function: %Connector{...},
        get_function: %Connector{...}
      }
  """
  @spec parse(map(), keyword()) :: map()
  def parse(resource_config, opts \\ []) do
    opts =
      opts
      |> List.flatten()
      |> then(&Keyword.merge(resource_config.opts, &1))

    Enum.reduce(
      [Common, ContextParserDefaults],
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
    |> parser.option_value(resource_config, opts, key)
    |> then(&Map.put_new(parsed_opts, key, &1))
  end
end
