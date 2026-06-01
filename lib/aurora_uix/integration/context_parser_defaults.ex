defmodule Aurora.Uix.Integration.ContextParserDefaults do
  @moduledoc """
  Dispatcher for context-based resource configuration parsing.

  Routes default value resolution to backend-specific parser implementations (Ash or Context)
  that automatically discover and configure CRUD function references by inferring function
  names from module conventions.

  Unlike `Aurora.Uix.Integration.Crud` which defines a behaviour contract, this module acts
  as a **flexible dispatcher** where implementations determine their own handling of option
  atoms based on their backend's capabilities and conventions.

  ## Key Features

  - Type-based routing to Ash or Context parser implementations
  - Flexible option handling - implementations define their own resolution logic
  - Automatic function name inference from conventions
  - Support for all common CRUD operations
  - Runtime module resolution via application configuration

  ## Implementation Resolution

  Uses compile-time configuration to resolve parser implementation modules:

      config :aurora_uix, :crud_integration_modules,
        ash: Aurora.Uix.Integration.Ash.ContextParserDefaults,
        ctx: Aurora.Uix.Integration.Ctx.ContextParserDefaults

  Resolution mechanism:

  1. Extracts `type` from `resource_config` (`:ash` or `:ctx`)
  2. Looks up parser module in `@parser_defaults_integration_modules` map
  3. Delegates `default_value/3` to resolved implementation
  4. Implementation uses its own logic to resolve the option atom
  5. Raises error if type is `nil` or not configured

  ## Supported Options

  The following options are commonly supported by implementations, though each backend
  may handle them differently based on its conventions:

  * `:list_function` - Read all elements (e.g., `list_users/1`)
  * `:list_function_paginated` - Read elements with pagination
  * `:get_function` - Get single element (e.g., `get_user/2`)
  * `:delete_function` - Delete element (e.g., `delete_user/1`)
  * `:create_function` - Create element (e.g., `create_user/1`)
  * `:update_function` - Update element (e.g., `update_user/2`)
  * `:change_function` - Create changeset (e.g., `change_user/2`)
  * `:new_function` - Create new struct (e.g., `new_user/2`)

  Note: These atoms serve as **keys for resolution**, not as a behaviour contract.
  Implementations are free to handle options in their own way, add new options, or
  ignore unsupported ones.

  ## Implementation Guidelines

  When creating a new parser defaults implementation:

  1. Implement `default_value/3` to handle option atoms
  2. Return `Connector.t()` wrapping the resolved function reference
  3. Use backend-specific conventions for function discovery
  4. Document backend-specific behavior and conventions

  ## Key Constraints

  - Requires valid context module in resource configuration
  - Type must be configured in application environment
  - Invalid types raise runtime errors
  - Implementations define their own option handling logic
  """

  @behaviour Aurora.Uix.Parser

  @parser_defaults_integration_modules :aurora_uix
                                       |> Application.compile_env(:crud_integration_modules,
                                         ash: Aurora.Uix.Integration.Ash.ContextParserDefaults,
                                         ctx: Aurora.Uix.Integration.Ctx.ContextParserDefaults
                                       )
                                       |> Map.new()

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

  """
  @callback option_value(
              parsed_opts :: map(),
              resource_config :: map(),
              opts :: keyword(),
              key :: atom()
            ) :: term()

  @doc """
  Fills in missing configuration options based on parsed values and resource configuration.

  This callback can be used to perform any final adjustments or fill in derived options after the main parsing process has completed. 
  It receives the fully parsed options and can return an updated map with any additional options or adjustments needed for UI rendering. 

  ## Parameters
  - `parsed_opts` (map()) - The fully parsed options after processing all parsers. Contains all resolved configuration values.
  - `resource_config` (map()) - The original resource configuration passed to `parse/2`. Contains the initial schema, type, context, and any default options.
  ## Returns
  map() - An updated map of options with any missing values filled in or adjustments made. This allows for final transformations or derived values to be added after the main parsing process.
  """
  @callback fill_missing_options(parsed_opts :: map, resource_config :: map()) :: map()

  @doc """
  Filters the valid options for this parser based on the resource configuration and raw options.
  This callback allows implementations to dynamically determine which options they will handle based on the resource configuration and the raw options provided. It can be used to conditionally support certain options or to adjust the set of options based on the context. 

  ## Parameters
  - `valid_opts` (map()) - A map of all valid options that have been collected from all parsers. This represents the full set of options that could potentially be handled.
  - `resource_opts` (map()) - The original resource configuration options passed to `parse/2`. This includes the initial schema, type, context, and any default options.

  ## Returns
  list(atom()) - A list of option keys (atoms) that this parser will handle. The parsing process will only call `option_value/3` for the options returned in this list. 
  This allows the parser to focus on a specific subset of options and ignore others.
  """
  @callback filter_options(valid_opts :: list(atom()), resource_opts :: keyword()) :: list(atom())

  @impl true
  def get_options(%{type: type} = _resource_config, resource_opts) do
    parser = get_parser_defaults_module(type)

    parser.filter_options(
      [
        :list_function,
        :list_function_paginated,
        :get_function,
        :delete_function,
        :update_function,
        :create_function,
        :change_function,
        :new_function
      ],
      resource_opts
    )
  end

  @impl true
  def option_value(parsed_opts, %{type: type} = resource_config, opts, option),
    do: get_parser_defaults_module(type).option_value(parsed_opts, resource_config, opts, option)

  @impl true
  def fill_missing_options(parsed_opts, %{type: type} = resource_config),
    do: get_parser_defaults_module(type).fill_missing_options(parsed_opts, resource_config)

  ## PRIVATE

  # Resolves parser defaults implementation module based on resource type.
  #
  # Uses compile-time configuration map to look up the appropriate parser module.
  # The type must match a key in @parser_defaults_integration_modules or an error is raised.
  @spec get_parser_defaults_module(atom()) :: module()
  defp get_parser_defaults_module(nil), do: raise("The type of connector is nil")

  defp get_parser_defaults_module(type) do
    case Map.get(@parser_defaults_integration_modules, type) do
      nil -> raise("Not found a parser defaults module for type: #{inspect(type)}")
      parser_defaults_module -> parser_defaults_module
    end
  end
end
