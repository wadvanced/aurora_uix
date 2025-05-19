defmodule Aurora.Uix.Web.Templates.Basic do
  @moduledoc """
  A centralized module for coordinating template generation processes in Aurora UIX,
  serving as the primary entry point for template-related functionality.

  ## Architecture
  This module acts as a facade, delegating specific template generation tasks to specialized components:
  - `LayoutParser`: Handles complex layout structure parsing
  - `LogicModulesGenerator`: Generates business logic and LiveView modules
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
  - `generate_module/2`: Delegates to `LogicModulesGenerator` for module creation

  ## Usage Example
  ```elixir
  # Automatic delegation happens through the Template behavior
  Aurora.Uix.Web.Templates.Basic.generate_view(:index, %{fields: [:name, :email]})
  ```
  The module ensures a clean separation of concerns while providing a streamlined
  template generation process for different UI components.
  """
  @behaviour Aurora.Uix.Template

  alias Aurora.Uix.Field
  alias Aurora.Uix.Web.Templates.Basic.LogicModulesGenerator

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
    to: LogicModulesGenerator

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
