defmodule Aurora.Uix.Template do
  @moduledoc """
  Defines the behavior and utilities for template modules in Aurora UIX,
  enforcing a standard interface for dynamic UI template generation and management.

  ## Purpose
  - Specify required callbacks for template modules.
  - Provide utility functions for field extraction and safe atom conversion.
  - Validate template modules at compile time for contract compliance.

  ## Key Constraints
  - All template modules must implement the required callbacks.
  - Validation is performed at compile time; missing callbacks or contract violations raise errors.
  - Not intended for direct use outside Aurora UIX internals.

  ## Required Callbacks
  Template modules must implement:

  - `generate_module(modules :: map(), parsed_opts :: map()) :: Macro.t()`
    Generates the handling code for the given mode and options.

  - `default_core_components_module() :: module()`
    Returns the module containing the default core UI components.

  - `css_classes() :: %{atom() => map()}`
    Returns a map of CSS class mappings for template components.

  ## Utilities
  - `uix_template/0`: Returns the validated template module.
  - `field_row_value/2`: Extracts a field value from an entity.
  - `safe_existing_atom/1`: Safely converts a binary to an existing atom.

  """

  @uix_template Application.compile_env(:aurora_uix, :template, Aurora.Uix.Web.Templates.Basic)

  @doc """
  Generates the handling code for the given mode.

  ## Parameters
  - `modules` (`map()`) - Map with caller, module, web and context modules.
  - `parsed_opts` (`map()`) - Customization options for code generation.

  ## Returns
  `Macro.t()` - Generated module code.
  """
  @callback generate_module(modules :: map(), parsed_opts :: map()) :: Macro.t()

  @doc """
  Returns the default core components module.

  ## Returns
  `module()` - The module containing core UI components.
  """
  @callback default_core_components_module() :: module()

  @doc """
  Returns CSS class mappings for different template components.

  ## Returns
  `map()` - A map with component categories as keys and CSS class mappings as values.
  """
  @callback css_classes() :: %{atom() => map()}

  @doc """
  Validates and returns the configured UIX template module.

  ## Returns
  `module()` - The validated template module.

  ## Examples
  ```elixir
  Aurora.Uix.Template.uix_template()
  # => Aurora.Uix.Web.Templates.Basic
  ```
  """
  @spec uix_template() :: module()
  def uix_template, do: validate(@uix_template)

  @doc """
  Extracts the value of a specified field from an entity.

  ## Parameters
  - `entity` (`tuple()` | `struct()` | `map()`) - Entity containing field values.
  - `field_config` (`map()`) - Field configuration with field key.

  ## Returns
  `term()` - Value of the specified field or nil if not found.

  ## Examples
  ```elixir
  Aurora.Uix.Template.field_row_value({1, %{foo: 42}}, %{field: :foo})
  # => 42
  Aurora.Uix.Template.field_row_value(%{bar: "baz"}, %{field: :bar, field_type: :string})
  # => "baz"
  Aurora.Uix.Template.field_row_value(%{}, %{field: :id})
  # => "id"
  ```
  """
  @spec field_row_value(tuple() | struct() | map(), map()) :: term()
  def field_row_value({_id, entity}, %{field: field}), do: Map.get(entity, field)

  def field_row_value(entity, %{field: field, field_type: field_type})
      when field_type not in [:one_to_many_association, :many_to_one_association],
      do: Map.get(entity, field, "")

  def field_row_value(_auix_entity, %{field: field}), do: to_string(field)

  @doc """
  Safely converts a binary to an existing atom.

  ## Parameters
  - `name` (`term()` | `nil`) - The name to convert to an atom.

  ## Returns
  `atom()` | `nil` - The existing atom if it exists, otherwise nil.

  ## Examples
  ```elixir
  Aurora.Uix.Template.safe_existing_atom("foo")
  # => :foo (if :foo exists)
  Aurora.Uix.Template.safe_existing_atom(:bar)
  # => :bar
  Aurora.Uix.Template.safe_existing_atom("nonexistent")
  # => nil
  ```
  """
  @spec safe_existing_atom(term() | nil) :: atom() | nil
  def safe_existing_atom(name) when is_binary(name) do
    String.to_existing_atom(name)
  catch
    _ -> nil
  end

  def safe_existing_atom(name) when is_atom(name), do: name

  def safe_existing_atom(_name), do: nil

  ## PRIVATE

  # Validates that a module implements the required behavior and exports expected functions
  # Raises ArgumentError if validation fails
  @spec validate(module()) :: module()
  defp validate(module) do
    Code.ensure_compiled!(module)

    functions_not_exported =
      functions_not_exported(module, generate_module: 2, default_core_components_module: 0)

    message =
      case {behaviour_implemented?(module), functions_not_exported} do
        {true, []} ->
          nil

        {false, _} ->
          "The #{module} does not implement the `#{__MODULE__}` behaviour."

        {_, functions_not_exported} ->
          "The #{module} does not implement the following function(s) `#{functions_not_exported}`."
      end

    if message,
      do:
        raise(
          ArgumentError,
          message
        )

    module
  end

  # Checks if the module implements the Template behavior
  @spec behaviour_implemented?(module()) :: boolean()
  defp behaviour_implemented?(module) do
    :attributes
    |> module.__info__()
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(__MODULE__)
  end

  # Returns a list of expected functions that are not exported by the module
  @spec functions_not_exported(module(), keyword()) :: list()
  defp functions_not_exported(module, expected_functions) do
    expected_functions
    |> Enum.reject(&function_exported?(module, elem(&1, 0), elem(&1, 1)))
    |> Enum.map(&inspect/1)
  end
end
