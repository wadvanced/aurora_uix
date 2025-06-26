defmodule Aurora.Uix.Template do
  @moduledoc """
  A core module for template generation and management in Aurora UIX, providing a standardized
  behavior and utility functions for creating dynamic UI templates.

  ## Key Responsibilities
  - Define a behavior for template implementations
  - Provide utility functions for template processing
  - Support dynamic template generation with interpolation
  - Validate and compile template modules

  ## Template Behaviour Requirements
  Templates must implement the following key callbacks:
  - `generate_view/3`: Generate HTML code fragments
  - `generate_module/2`: Generate handling code for UI components
  - `parse_layout/3`: Create layout HTML code

  ## Flow of Template Processing
  1. Initialize template configuration
  2. Parse layout and field definitions
  3. Generate view components
  4. Compile HEEx templates
  5. Produce final handler code

  ### Template Validation
  The module ensures that template implementations:
  - Implement the required behavior
  - Provide all necessary callback functions
  - Meet the specified interface contract

  ### Interpolation Support
  Supports simple string interpolation using `[[key]]` syntax, allowing dynamic
  template generation based on provided configuration.

  ### Flow processing view

  ```mermaid
  flowchart TD
  %% Grouping with subgraphs
  subgraph Initialization [ ]
    INIT_TITLE["Initialization"]:::groupTitle
    INIT_TITLE --> A[Initialize map parsed_opts with resource config]:::initFill
  end

  subgraph Parsing [ ]
    PARSE_TITLE["Parsing"]:::groupTitle
    PARSE_TITLE --> B[Add fields info and required modules]:::parseFill
    B --> C[Parse layout definition and update parsed_opts]:::parseFill
    C --> D[Parse field list and update parsed_opts]:::parseFill
  end

  subgraph Generation [ ]
    GEN_TITLE["Generation"]:::groupTitle
    GEN_TITLE --> E[Pass parsed_opts to generate_module]:::genFill
    E --> F[Invoke generate_view to create UI components and generate HTML binary]:::genFill
  end

  subgraph Output [ ]
    OUT_TITLE["Output"]:::groupTitle
    OUT_TITLE --> G[Compile generated HTML with EEx]:::outFill
    G --> H[Produce compiled HEEx AST and final handler code]:::outFill
  end

  %% Flow connections between groups
  A --> PARSE_TITLE
  D --> GEN_TITLE
  F --> OUT_TITLE

  %% Define custom styles for group title nodes
  classDef groupTitle fill:#ddd,stroke:#333,stroke-width:2px,font-weight:bold;

  %% Define colors for process nodes
  classDef initFill fill:#f9f,stroke:#333,stroke-width:2px;
  classDef parseFill fill:#ccf,stroke:#333,stroke-width:2px;
  classDef genFill fill:#cfc,stroke:#333,stroke-width:2px;
  classDef outFill fill:#fcf,stroke:#333,stroke-width:2px;

  %% Assign styles
  class INIT_TITLE,PARSE_TITLE,GEN_TITLE,OUT_TITLE groupTitle;
  ```
  """

  @uix_template Application.compile_env(:aurora_uix, :template, Aurora.Uix.Web.Templates.Basic)

  @doc """
  Generates the handling code for the given mode.

  ## Parameters
  - `modules` (map()) - Map with caller, module, web and context modules.
  - `parsed_opts` (map()) - Customization options for code generation.

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
  map() - A map with component categories as keys and CSS class mappings as values.
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
  - `entity` (tuple() | `struct()` | map()) - Entity containing field values.
  - `field_config` (map()) - Field configuration with field key.

  ## Returns
  `term()` - Value of the specified field or nil if not found.

  ## Examples
  ```elixir
  Aurora.Uix.Template.field_row_value({1, %{foo: 42}}, %{field: :foo})
  # => 42
  Aurora.Uix.Template.field_row_value(%{bar: "baz"}, %{field: :bar, type: :string})
  # => "baz"
  Aurora.Uix.Template.field_row_value(%{}, %{field: :id})
  # => "id"
  ```
  """
  @spec field_row_value(tuple() | struct() | map(), map()) :: term()
  def field_row_value({_id, entity}, %{field: field}), do: Map.get(entity, field)

  def field_row_value(entity, %{field: field, type: type})
      when type not in [:one_to_many_association, :many_to_one_association],
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
