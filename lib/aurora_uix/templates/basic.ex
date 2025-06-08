defmodule Aurora.Uix.Web.Templates.Basic do
  @moduledoc """
  A centralized module for coordinating template generation processes in Aurora UIX,
  serving as the primary entry point for template-related functionality.

  ## Architecture
  This module acts as a facade, delegating specific template generation tasks to specialized components:
  - `LayoutParser`: Handles complex layout structure parsing
  - `ModulesGenerator`: Generates business logic and LiveView modules
  - `MarkupGenerator`: Creates HEEx template fragments

  ## Responsibilities
  - Implement the `Aurora.Uix.Template` behavior
  - Coordinate between different template generation components
  - Provide a unified interface for template creation

  ## Generation Flow
  1. Parse layout configurations
  2. Generate logic modules
  3. Create markup templates
  4. Combine generated components

  ### Key Delegations
  - `generate_module/2`: Delegates to `ModulesGenerator` for module creation

  ## Usage Example
  ```elixir
  # Automatic delegation happens through the Template behavior
  Aurora.Uix.Web.Templates.Basic.generate_view(:index, %{fields: [:name, :email]})
  ```
  The module ensures a clean separation of concerns while providing a streamlined
  template generation process for different UI components.
  """
  @behaviour Aurora.Uix.Template

  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator

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
  defdelegate generate_module(modules, parsed_opts),
    to: ModulesGenerator

  @doc """
  Returns the default core components module used in the template system.
  ## Returns
    - `module` - The default core components module
  """
  @spec default_core_components_module() :: module
  def default_core_components_module do
    Aurora.Uix.Web.Templates.Basic.CoreComponents
  end

  @doc """
  Provides CSS class mappings for different template components.

  ## Returns
  - map() - A map with component categories as keys and their respective CSS class mappings as values:
    - core_components: classes for core template components
    - index_renderer: classes for index page components
    - show_renderer: classes for show page components
  """
  @spec css_classes() :: %{atom() => map()}
  def css_classes do
    %{
      core_components: core_components(),
      index_renderer: index_renderer(),
      show_renderer: show_renderer()
    }
  end

  ## PRIVATE
  # Defines CSS classes for core components with container styles for modals and tables
  @spec core_components() :: map()
  defp core_components do
    %{
      modal_inner_container: "max-w-max max-w-3xl p-4 sm:p-6 lg:py-8 mx-auto",
      table_container: "overflow-y-auto px-4 overflow-visible sm:px-0"
    }
  end

  # Defines CSS classes for index page container with responsive padding and width
  @spec index_renderer() :: map()
  defp index_renderer do
    %{top_container: "max-w-max max-w-3xl p-4 sm:p-6 lg:py-8 mx-auto"}
  end

  # Defines CSS classes for show page container with responsive padding and width
  @spec show_renderer() :: map()
  defp show_renderer do
    %{top_container: "max-w-max max-w-3xl p-4 sm:p-6 lg:py-8 mx-auto"}
  end
end
