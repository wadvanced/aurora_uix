defmodule AuroraUixWeb.Template do
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
  - `generate_module/3`: Generate handling code for UI components
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

  @uix_template Application.compile_env(:aurora_uix, :template, AuroraUixWeb.Templates.Core)

  @doc """
  Generates a HTML code fragment for the specified mode and options.

  ## Parameters

  - `mode` (atom): Specifies the type of UI component to generate.
    The types implemented and supported by the library are: `:index`, `:form`, `:show`.

  - `parsed_opts` (map): A map with the customized value for generating HTML code.

  ## Returns

  - `binary`: The html code fragment.

  ## Examples

  ```elixir
  generate_view(:index, %{fields: [:name, :email})
  # => quote do: ~H"<ul><li><%= @name %></li><li><%= @email %></li></ul>"

  generate_view(:card, %{title: "User Info", content: ~H"<p><%= @user %></p>"})
  # => quote do: ~H"<div class=\"card\"><h1>User Info</h1><p><%= @user %></p></div>"
  ```
  """
  @callback generate_view(mode :: atom, parsed_opts :: map) :: binary

  @doc """
  Generates the handling code for the given mode.

  ## Parameters
  - `modules` (map): Map containing the involved modules:
    %{
      caller: caller, # The caller module.
      module: resource_module, # The struct module representing the resource. For example the schema module.
      web: web, # The main web module. For example MyAppWeb.
      context: context # The module with the backend functions for creating, reading, updating and deleting elements of the struct.
    }
  - `mode` (atom): Specifies the type of UI component to generate.
  - `parsed_opts` (map): A map with the customized value for generating the handling code.
  """
  @callback generate_module(modules :: map, mode :: atom, parsed_opts :: map) :: Macro.t()

  @doc """
  Creates the layout HTML code.

  The implementer will receive a call per each path of the layout.

  At the end of the process, the UIX will add the field `form_fields` to parsed_opts and will be part of the
  parameters to be sent to the downstream function.

  ## Parameters

  - `path` (map): Contains the relevant information for a layout path.
    See `AuroraUixWeb.Uix.LayoutConfigUI` for details on the path structure.
  - `configurations` (map): contains the overall configuration for all resources.
  - `parsed_opts` (map): Additional parsing options
  - `resource_name` (atom): Name of the resource that is going to be processed.
  - `mode` (atom): Indicates if the type of layout to be generated.
  """
  @callback parse_layout(
              paths :: map | list,
              configurations :: map,
              parsed_opts :: map,
              resource_name :: atom,
              mode :: atom
            ) :: binary

  @callback default_core_components() :: module

  @doc """
  Validates and return the configured uix template.
  """
  @spec uix_template() :: module
  def uix_template, do: validate(@uix_template)

  @doc """
  Replaces [[key]] with the string value found in the parsed_options.
  If the key value is not found, then the [[key]] is not replaced.

  ## Parameters
    - `template` (binary): The template to apply the interpolation.
    - `parsed_options` (map): Options to use.

  ## Examples
    iex> AuroraUixWeb.Template.build_html(%{title: "Aurora UIX builder"},
    ... ~S\"""
    ... This application: [[title]]
    ... \""")
    "this application: Aurora UIX builder\n"
  """
  @spec build_html(map, binary) :: binary
  def build_html(parsed_options, template), do: Enum.reduce(parsed_options, template, &replace/2)

  @doc """
  Extracts the value of a specified field from an entity.

  ## Parameters
    - `{_id, entity}` (tuple): A tuple containing an ID and an entity map.
    - `%{field: field}` (map): A map containing a field key that specifies which field to extract.

  ## Returns
    - `any`: The value of the specified field from the entity map, or nil if the field doesn't exist.

  ## Examples

      iex> field_row_value({123, %{name: "John", age: 30}}, %{field: :name})
      "John"

      iex> field_row_value({456, %{name: "Mary", age: 25}}, %{field: :age})
      25

      iex> field_row_value({789, %{name: "Bob"}}, %{field: :age})
      nil
  """
  @spec field_row_value(tuple | struct | map, map) :: any
  def field_row_value({_id, entity}, %{field: field}), do: Map.get(entity, field)

  def field_row_value(entity, %{field: field, field_type: field_type})
      when field_type not in [:one_to_many_association, :many_to_one_association],
      do: Map.get(entity, field, "")

  def field_row_value(_auix_entity, %{field: field}), do: to_string(field)

  @doc """
  Safely converts a binary to an existing atom.
  If the binary does not exist as an atom, it returns nil.
  This function is useful for safely converting strings to atoms without
  causing an error if the atom does not exist.
  ## Parameters
    - `name` (any | nil): The name to convert to an atom.
  ## Returns
    - `atom | nil`: The existing atom if it exists, or nil if it doesn't.
  ## Examples
    iex> safe_existing_atom("existing_atom")
    :existing_atom

    iex> safe_existing_atom("non_existing_atom")
    nil

    iex> safe_existing_atom(:existing_atom)
    :existing_atom

    iex> safe_existing_atom(nil)
    nil
  """
  @spec safe_existing_atom(any | nil) :: atom | nil
  def safe_existing_atom(name) when is_binary(name) do
    String.to_existing_atom(name)
  catch
    _ -> nil
  end

  def safe_existing_atom(name) when is_atom(name), do: name

  def safe_existing_atom(_name), do: nil

  defmacro compile_heex(mode, parsed_opts) do
    template = get_in(parsed_opts, [:templates, mode]) || ""

    options = [
      engine: Phoenix.LiveView.TagEngine,
      tag_handler: Phoenix.LiveView.HTMLEngine,
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      caller: __CALLER__,
      source: template
    ]

    quote do
      # Ensure `assigns` is in scope for Phoenix's HEEx engine
      var!(assigns) =
        assigns
        |> var!()
        |> Map.get(:_auix, %{})
        # Inject the parsed_opts into assigns for template use
        |> then(&Map.merge(unquote(Macro.escape(parsed_opts)), &1))
        |> then(&(assigns |> var!() |> Map.put(:_auix, &1)))

      # Compile the template into Phoenix.LiveView.Rendered struct
      unquote(EEx.compile_string(template, options))
    end
  end

  ## PRIVATE FUNCTIONS

  @spec validate(module) :: module
  defp validate(module) do
    Code.ensure_compiled!(module)

    functions_not_exported =
      functions_not_exported(module, generate_view: 2, generate_module: 3, parse_layout: 5)

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

  @spec behaviour_implemented?(module) :: boolean
  defp behaviour_implemented?(module) do
    :attributes
    |> module.__info__()
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(__MODULE__)
  end

  @spec functions_not_exported(module, keyword) :: list
  defp functions_not_exported(module, expected_functions) do
    expected_functions
    |> Enum.reject(&function_exported?(module, elem(&1, 0), elem(&1, 1)))
    |> Enum.map(&inspect/1)
  end

  @spec replace(tuple, binary) :: binary
  defp replace({key, value}, template) when is_binary(value),
    do: String.replace(template, "[[#{key}]]", value)

  defp replace({key, value}, template), do: replace({key, inspect(value)}, template)
end
