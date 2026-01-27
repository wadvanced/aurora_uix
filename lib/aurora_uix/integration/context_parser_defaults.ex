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
  4. Return `&undefined_function/2` for unresolvable options
  5. Document backend-specific behavior and conventions

  ## Key Constraints

  - Requires valid context or domain module in resource configuration
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
  Returns the list of commonly supported option keys.

  Provides a reference list of option atoms that implementations typically handle.
  This list is descriptive, not prescriptive - implementations may support additional
  options or handle these differently based on their backend's capabilities.

  ## Returns

  list(atom()) - List of common option keys for parser reference.

  ## Examples

      iex> get_options()
      [:list_function, :list_function_paginated, :get_function, ...]
  """
  @spec get_options() :: list(atom())
  def get_options do
    [
      :list_function,
      :list_function_paginated,
      :get_function,
      :delete_function,
      :update_function,
      :create_function,
      :change_function,
      :new_function
    ]
  end

  @doc """
  Resolves default values for context-derived properties.

  Dispatches to the appropriate parser defaults implementation based on resource type.
  Uses the type from resource_config to look up and delegate to backend-specific parsers.

  ## Parameters

  - `parsed_opts` (map()) - Map containing resolved options:
    * `:source` (binary()) - Table/resource name (e.g., "users")
    * `:module` (binary()) - Schema module name (e.g., "user")
  - `resource_config` (map()) - Resource configuration:
    * `:type` (atom()) - Backend type (`:ash` or `:ctx`)
    * `:context` (module()) - Context or domain module
    * `:schema` (module()) - Schema or resource module (optional)
  - `option` (atom()) - The option key to resolve (e.g., `:list_function`, `:get_function`)

  ## Returns

  Connector.t() | function() - Returns a Connector struct wrapping the resolved function
  reference, or `&undefined_function/2` if resolution fails.

  ## Examples

      iex> default_value(%{source: "users", module: "user"},
      ...>   %{type: :ctx, context: MyApp.Accounts}, :list_function)
      %Connector{type: :ctx, crud_spec: %CrudSpec{function_spec: &MyApp.Accounts.list_users/1}}

      iex> default_value(%{}, %{type: :ash, context: MyApp.Accounts,
      ...>   schema: MyApp.User}, :get_function)
      %Connector{type: :ash, crud_spec: %CrudSpec{action: %{name: :read}, ...}}
  """
  @spec default_value(map(), map(), atom()) :: term() | nil
  def default_value(parsed_opts, %{type: type} = resource_config, option),
    do: get_parser_defaults_module(type).default_value(parsed_opts, resource_config, option)

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
