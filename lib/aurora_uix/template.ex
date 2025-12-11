defmodule Aurora.Uix.Template do
  @moduledoc """
  Defines the behaviour for `Aurora.Uix` template modules.

  A template module is responsible for generating the UI components and handler
  code for a resource. Any module that acts as a template must adopt this
  behaviour.

  ### Key Features

  - **Code Generation**: Dynamically generates handler code for different layouts.
  - **Customizable Components**: Allows for specifying a default core components module.

  ### Key Constraints

  - Any module acting as a template **must** adopt this behaviour.

  The configured template module can be retrieved using `uix_template/0`.
  """

  alias Aurora.Uix.BehaviourHelper
  alias Aurora.Uix.Counter

  @uix_template Application.compile_env(:aurora_uix, :template, Aurora.Uix.Templates.Basic)

  @doc """
  Generates the handling code for the given layout type.

  ## Parameters

  - `parsed_opts` (`map()`) - Customization options for code generation.

  ## Returns

  - `Macro.t()` - The generated module code.
  """
  @callback generate_module(parsed_opts :: map()) :: Macro.t()

  @doc """
  Returns the list of layout tags supported by the template.

  ## Returns

  - `list(atom())` - A list of atoms representing the supported layout tags.
  """
  @callback layout_tags() :: [atom()]

  @doc """
  Returns the default core components module.

  ## Returns

  - `module()` - The module containing core UI components.
  """
  @callback default_core_components_module() :: module()

  @callback default_theme_name() :: atom()

  @doc """
  Validates and returns the configured UIX template module.

  This function retrieves the template module from the application environment,
  validates it against the `Aurora.Uix.Template` behaviour, and returns it.

  ## Returns

  - `module()` - The validated template module.

  ## Examples

  ```elixir
  # Assuming the default template is configured
  Aurora.Uix.Template.uix_template()
  # => Aurora.Uix.Templates.Basic
  ```

  If a module that does not implement the behaviour is configured, it will raise an error.

  ```elixir
  # Assuming `MyInvalidTemplate` does not implement the behaviour
  Application.put_env(:aurora_uix, :template, MyInvalidTemplate)
  # Aurora.Uix.Template.uix_template()
  # ** (ArgumentError) MyInvalidTemplate must adopt the Aurora.Uix.Template behaviour.
  ```
  """
  @spec uix_template() :: module()
  def uix_template do
    Counter.start_counter(:auix_fields)
    BehaviourHelper.validate(@uix_template, __MODULE__)
  end
end
