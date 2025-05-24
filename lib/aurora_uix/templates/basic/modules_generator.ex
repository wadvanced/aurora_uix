defmodule Aurora.Uix.Web.Templates.Basic.ModulesGenerator do
  @moduledoc """
  Dynamic LiveView module generator for creating CRUD-oriented user interfaces.

  Generates complete LiveView modules with:
  - Comprehensive CRUD operations
  - Dynamic event handling
  - Integrated form validation
  - Flexible rendering strategies

  Supports components:
  - `:index`: Streamed entity listings
  - `:show`: Detailed entity views
  - `:form`: Interactive data forms
  - `:aurora_index_list`: Advanced listings

  Context modules must provide:
  - `list_<source>/0`: List entities
  - `get_<schema>!/1`: Get entity
  - `change_<schema>/1-2`: Validate changes
  - `create_<schema>/1`: Create entity
  - `update_<schema>/2`: Update entity
  - `delete_<schema>/1`: Delete entity

  ## Usage Example
  ```elixir
    generate_module(
    %{
      caller: MyAppWeb,
      context: MyApp.Accounts,
      module: MyApp.User,
      web: MyAppWeb
    },
    %{
      name: :product,
      tag: :index,
      config: [],
      opts: [],
      inner_elements: [
        %{name: :reference, tag: :field, opts: [], inner_elements: []},
        %{name: :name, tag: :field, opts: [], inner_elements: []},
        %{name: :description, tag: :field, opts: [], inner_elements: []},
      ]
    },
    %{source: "users", module: "User"}
    )
  ```
  Transforms configuration into fully-functional, dynamically generated LiveView modules.
  """

  alias Aurora.Uix.Web.Templates.Basic.Generators.FormGenerator
  alias Aurora.Uix.Web.Templates.Basic.Generators.IndexGenerator
  alias Aurora.Uix.Web.Templates.Basic.Generators.ShowGenerator
  require Logger

  @doc """
  Generates a LiveView module for the specified UI component type.

  ## Parameters
    - modules (map()) - Configuration with caller, context, module and web references
    - parsed_opts (map()) - Generation options with _path.tag and component configuration

  Returns:
    - Macro.t() - Generated LiveView module code
  """
  @spec generate_module(map, map) :: Macro.t()
  def generate_module(modules, %{_path: %{tag: :index}} = parsed_opts) do
    IndexGenerator.generate_module(modules, parsed_opts)
  end

  def generate_module(modules, %{_path: %{tag: :show}} = parsed_opts) do
    ShowGenerator.generate_module(modules, parsed_opts)
  end

  def generate_module(modules, %{_path: %{tag: :form}} = parsed_opts) do
    FormGenerator.generate_module(modules, parsed_opts)
  end

  def generate_module(_modules, %{_path: %{tag: type}}) do
    Logger.error("The logic for `#{inspect(type)} is not implemented.")

    quote do
      # no generation
    end
  end

  @doc """
  Removes fields marked as omitted from the parsed options.

  ## Parameters
    - parsed_options (map()) - Options with fields to filter

  Returns:
    - map() - Options with omitted fields removed
  """
  @spec remove_omitted_fields(map()) :: map()
  def remove_omitted_fields(parsed_options) do
    parsed_options
    |> Map.get(:fields, %{})
    |> Enum.reject(& &1.omitted)
    |> then(&Map.put(parsed_options, :fields, &1))
  end

  @doc """
  Generates a module name by concatenating the caller, module name and suffix.

  ## Parameters
    - modules (map()) - Module configuration with caller reference
    - parsed_opts (map()) - Options containing module_name
    - suffix (binary()) - String to append to module name

  Returns:
    - module() - Generated module name
  """
  @spec module_name(map(), map(), binary()) :: module()
  def module_name(modules, parsed_opts, suffix) do
    Module.concat(modules.caller, "#{parsed_opts.module_name}#{suffix}")
  end
end
