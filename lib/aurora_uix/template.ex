defmodule Aurora.Uix.Template do
  @moduledoc """
  Defines the behaviour for Aurora UIX template modules.

  A template module is responsible for generating the UI components and handler
  code for a resource. Any module that acts as a template must adopt this
  behaviour.

  ## Callbacks

  - `generate_module/1`: Generates the handling code for a given layout.
  - `default_core_components_module/0`: Returns the default core components module.

  The configured template module can be retrieved using `uix_template/0`.
  """

  alias Aurora.Uix.BehaviourHelper

  @uix_template Application.compile_env(:aurora_uix, :template, Aurora.Uix.Templates.Basic)

  @doc """
  Generates the handling code for the given layout type.

  ## Parameters
  - `parsed_opts` (map()) - Customization options for code generation.

  ## Returns
  `Macro.t()` - Generated module code.
  """
  @callback generate_module(parsed_opts :: map()) :: Macro.t()

  @doc """
  Returns the default core components module.

  ## Returns
  `module()` - The module containing core UI components.
  """
  @callback default_core_components_module() :: module()

  @doc """
  Validates and returns the configured UIX template module.

  ## Returns
  `module()` - The validated template module.

  ## Examples
  ```elixir
  Aurora.Uix.Template.uix_template()
  # => Aurora.Uix.Templates.Basic
  ```
  """
  @spec uix_template() :: module()
  def uix_template, do: BehaviourHelper.validate(@uix_template, __MODULE__)
end
