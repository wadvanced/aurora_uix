defmodule AuroraUixWeb.Templates.Core do
  @moduledoc """
  A centralized module for coordinating template generation processes in Aurora UIX,
  serving as the primary entry point for template-related functionality.

  ## Architecture
  This module acts as a facade, delegating specific template generation tasks to specialized components:
  - `LayoutParser`: Handles complex layout structure parsing
  - `LogicModulesGenerator`: Generates business logic and LiveView modules
  - `MarkupGenerator`: Creates HEEx template fragments

  ## Responsibilities
  - Implement the `AuroraUixWeb.Template` behavior
  - Coordinate between different template generation components
  - Provide a unified interface for template creation

  ## Generation Flow
  1. Parse layout configurations
  2. Generate logic modules
  3. Create markup templates
  4. Combine generated components

  ### Key Delegations
  - `parse_layout/3`: Delegates to `LayoutParser` for layout structure parsing
  - `generate_module/3`: Delegates to `LogicModulesGenerator` for module creation
  - `generate_view/2`: Delegates to `MarkupGenerator` for template generation

  ## Usage Example
  ```elixir
  # Automatic delegation happens through the Template behavior
  AuroraUixWeb.Templates.Core.generate_view(:index, %{fields: [:name, :email]})
  ```
  The module ensures a clean separation of concerns while providing a streamlined
  template generation process for different UI components.
  """
  @behaviour AuroraUixWeb.Template

  alias AuroraUixWeb.Templates.Core.LayoutParser
  alias AuroraUixWeb.Templates.Core.LogicModulesGenerator
  alias AuroraUixWeb.Templates.Core.MarkupGenerator

  @doc """
  Parses the layout configuration for template generation.

  ## Parameters
    * path - map: The layout path configuration
    * parsed_opts - map: Additional parsing options
    * type - atom: The type of layout to parse

  ## Returns
    * binary: The parsed layout content
  """
  @spec parse_layout(map, map, atom) :: binary
  defdelegate parse_layout(path, parsed_opts, type), to: LayoutParser

  @doc """
  Generates logic modules based on the provided configuration.

  ## Parameters
    * modules - [{atom, module}] | map: The module specifications
    * type - atom: The type of module to generate
    * parsed_opts - map: Additional generation options (optional)

  ## Returns
    * Macro.t(): The generated module as a macro
  """
  @spec generate_module([{atom, module}] | map, atom, map) :: Macro.t()
  defdelegate generate_module(modules, type, parsed_opts \\ %{}), to: LogicModulesGenerator

  @doc """
  Generates view templates based on the specified type and options.

  ## Parameters
    * type - atom: The type of view to generate
    * parsed_opts - map: View generation options

  ## Returns
    * binary: The generated view template
  """
  @spec generate_view(atom, map) :: binary
  defdelegate generate_view(type, parsed_opts), to: MarkupGenerator

  @doc """
  Returns a list of common modules used across the template system.

  ## Returns
    * [{atom, module}]: List of tuples containing module aliases and their corresponding modules
  """
  @spec common_modules :: [{atom, module}]
  def common_modules do
    [
      {:aurora_core_helpers, AuroraUixWeb.Core.Helpers},
      {:aurora_index_list, AuroraUixWeb.LiveComponents.AuroraIndexList}
    ]
  end
end
