defmodule Aurora.Uix.Web.Templates.Core do
  @moduledoc """
  A centralized module for coordinating template generation processes in Aurora UIX,
  serving as the primary entry point for template-related functionality.

  ## Architecture
  This module acts as a facade, delegating specific template generation tasks to specialized components:
  - `LayoutParser`: Handles complex layout structure parsing
  - `LogicModulesGenerator`: Generates business logic and LiveView modules
  - `MarkupGenerator`: Creates HEEx template fragments

  ## Responsibilities
  - Implement the `Aurora.Uix.Web.Template` behavior
  - Coordinate between different template generation components
  - Provide a unified interface for template creation

  ## Generation Flow
  1. Parse layout configurations
  2. Generate logic modules
  3. Create markup templates
  4. Combine generated components

  ### Key Delegations
  - `parse_layout/3`: Delegates to `LayoutParser` for layout structure parsing
  - `generate_module/2`: Delegates to `LogicModulesGenerator` for module creation
  - `generate_view/2`: Delegates to `MarkupGenerator` for template generation

  ## Usage Example
  ```elixir
  # Automatic delegation happens through the Template behavior
  Aurora.Uix.Web.Templates.Core.generate_view(:index, %{fields: [:name, :email]})
  ```
  The module ensures a clean separation of concerns while providing a streamlined
  template generation process for different UI components.
  """
  @behaviour Aurora.Uix.Web.Template

  alias Aurora.Uix.Field
  alias Aurora.Uix.Web.Templates.Core.LayoutParser
  alias Aurora.Uix.Web.Templates.Core.LogicModulesGenerator
  alias Aurora.Uix.Web.Templates.Core.MarkupGenerator

  @doc """
  Parses the layout configuration for template generation.

  ## Parameters

    - `paths` (map | list) - The layout path configuration
    - `configurations` (%{required(atom()) => any()}) - Contains the overall configuration for all resources
    - `parsed_opts` (%{optional(atom()) => any()}) - Additional parsing options
    - `mode` (:index | :form | :show) - The type of layout to parse

  ## Returns

    - `binary` - The parsed layout content as a string
  """
  @spec parse_layout(map | list, map, map, atom, atom) :: binary
  defdelegate parse_layout(paths, configurations, parsed_opts, resource_name, mode),
    to: LayoutParser

  @doc """
  Generates logic modules based on the provided configuration.

  ## Parameters

    - `modules` ([{atom(), module()}] | map()) - The module specifications
    - `layout` - Layout type and path to be generated
    - `configurations` - Resource configurations
    - `parsed_opts` (%{optional(atom()) => any()}) - Additional generation options

  ## Returns

    - `Macro.t()` - The generated module as a macro
  """
  @spec generate_module([{atom, module}] | map, map) :: Macro.t()
  defdelegate generate_module(modules, parsed_opts \\ %{}),
    to: LogicModulesGenerator

  @doc """
  Generates view templates based on the specified type and options.

  ## Parameters

    - `type` (:index | :form | :show) - The type of view to generate
    - `parsed_opts` (%{optional(atom()) => any()}) - View generation options

  ## Returns

    - `binary()` - The generated view template as a string
  """
  @spec generate_view(atom, map) :: binary
  defdelegate generate_view(type, parsed_opts), to: MarkupGenerator

  @doc """
  Returns the default core components module used in the template system.
  ## Returns
    - `module` - The default core components module
  """
  @spec default_core_components() :: module
  def default_core_components do
    Aurora.Uix.Web.Templates.Core.CoreComponents
  end

  @doc """
  Retrieves and processes field configuration from the resource configurations.

  Parameters:
  - field: %{name: atom()} - Map containing the field name and options
  - configurations: map - Global configurations for all resources
  - resource_name: atom - The name of the resource the field belongs to

  Returns:
  - Field.t() - A Field struct containing the processed field configuration
  """
  @spec get_field(map, map, atom) :: Field.t()
  def get_field(%{name: field_name} = field, configurations, resource_name) do
    configurations
    |> Map.get(resource_name, %{})
    |> Map.get(:resource_config, %{})
    |> Map.get(:fields, %{})
    |> Map.get(field_name, Field.new(%{field: field_name}))
    |> Field.change(Map.get(field, :opts, []))
  end
end
