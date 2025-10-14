defmodule Aurora.Uix.Templates.Basic do
  @moduledoc """
  Provides a unified interface for template generation in Aurora UIX, implementing the `Aurora.Uix.Template` behavior and coordinating specialized components for layout parsing, module generation, and markup creation.

  ## Key Features
  - Implements the `Aurora.Uix.Template` behavior for standardized template modules.
  - Delegates template generation to:
    - `LayoutParser` (layout structure parsing)
    - `ModulesGenerator` (business logic and LiveView modules)
    - `MarkupGenerator` (HEEx template fragments)
  - Coordinates between template generation components.
  - Utility functions for core component access and CSS class mapping.

  ## Key Constraints
  - Only coordinates and delegates; does not implement business logic directly.
  - Expects specialized modules to implement actual generation logic.

  ## Generation Flow
  1. Parse layout configurations.
  2. Generate logic modules.
  3. Create markup templates.
  4. Combine generated components.
  """

  @behaviour Aurora.Uix.Template

  alias Aurora.Uix.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Templates.Basic.Themes.Light, as: BasicLightTheme

  @doc """
  Generates logic modules by delegating to `ModulesGenerator` based on the provided configuration.

  ## Parameters
    - `parsed_opts` (map()) - Parsed options for generation.

  ## Returns

    - `Macro.t()` - The generated module as a macro.
  """
  @impl true
  @spec generate_module(map()) :: Macro.t()
  defdelegate generate_module(parsed_opts),
    to: ModulesGenerator

  @impl true
  @spec layout_tags() :: list()
  def layout_tags, do: [:index, :form, :show]

  @doc """
  Returns the default core components module used in the template system.

  ## Returns
    - `module()` - The default core components module.
  """
  @impl true
  @spec default_core_components_module() :: module()
  def default_core_components_module do
    Aurora.Uix.Templates.Basic.CoreComponents
  end

  @impl true
  @spec default_theme_module() :: module()
  def default_theme_module, do: BasicLightTheme
end
