defmodule Aurora.Uix.Web.Templates.Basic do
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

  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Web.Templates.Basic.RoutingComponents

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

  @doc """
  Returns the default core components module used in the template system.

  ## Returns
    - `module()` - The default core components module.
  """
  @impl true
  @spec default_core_components_module() :: module
  def default_core_components_module do
    Aurora.Uix.Web.Templates.Basic.CoreComponents
  end

  @doc """
  Provides CSS class mappings for different template components.

  ## Returns
  `%{atom() => map()}` - Map with component categories as keys and their respective CSS class mappings as values:
    - `:core_components` - Classes for core template components.
    - `:index_renderer` - Classes for index page components.
    - `:show_renderer` - Classes for show page components.
  """
  @impl true
  @spec css_classes() :: %{atom() => map()}
  def css_classes do
    %{
      core_components: core_components(),
      index_renderer: index_renderer(),
      show_renderer: show_renderer()
    }
  end

  @doc """
  Returns a list of template component modules used for extension or customization.

  ## Returns
  `list(module())` - List of component modules.
  """
  @impl true
  @spec template_component_modules() :: list(module())
  def template_component_modules do
    [RoutingComponents]
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
