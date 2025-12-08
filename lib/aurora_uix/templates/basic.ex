defmodule Aurora.Uix.Templates.Basic do
  @moduledoc """
  Provides the template implementation for Aurora UIX, implementing the
  `Aurora.Uix.Template` behavior.

  Delegates module generation to `ModulesGenerator`, which creates LiveView handler code
  for index, show, and form layouts. Provides information about supported layout tags and
  default core components and theme modules.
  """

  @behaviour Aurora.Uix.Template

  alias Aurora.Uix.Templates.Basic.ModulesGenerator
  alias Aurora.Uix.Templates.Basic.Themes.Light, as: BasicLightTheme

  @doc """
  Generates logic modules by delegating to `ModulesGenerator` based on the provided configuration.

  ## Parameters
  - `parsed_opts` (map()) - Parsed options for generation.

  ## Returns
  Macro.t() - The generated module as a macro.
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
