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
  - `parse_layout/2`: Delegates to `LayoutParser` for layout structure parsing
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

  defdelegate parse_layout(path, mode), to: LayoutParser
  defdelegate generate_module(modules, type, parsed_opts), to: LogicModulesGenerator
  defdelegate generate_view(type, parsed_opts), to: MarkupGenerator
end
