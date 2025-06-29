defmodule Aurora.Uix.Web.Templates.Basic.ModulesGenerator do
  @moduledoc """
  Dynamic LiveView module generator for creating CRUD-oriented user interfaces.

  ## Key Features
  - Transforms configuration maps into fully-functional, dynamically generated LiveView modules for CRUD operations.
  - Generates LiveView modules for index view, show view, and form UI components.
  - Integrates event handling, form validation, and flexible rendering.
  - Supports advanced listing and custom component types.
  - Delegates code generation to specialized sub-generators.
  - All code generation is performed at compile time.

  ## Key Constraints
  - Requires context modules to implement standard CRUD functions.
  - Only modules with the required context functions are supported.
  """

  alias Aurora.Uix.Web.Templates.Basic.Generators.FormGenerator
  alias Aurora.Uix.Web.Templates.Basic.Generators.IndexGenerator
  alias Aurora.Uix.Web.Templates.Basic.Generators.ShowGenerator
  require Logger

  @doc """
  Generates a LiveView module for the specified UI component type.

  ## Parameters
  - `modules` (map()) - Configuration with caller, context, module, and web references.
  - `parsed_opts` (map()) - Generation options with `_path.tag` and component configuration.

  ## Returns
  - `Macro.t()` - The generated LiveView module code.

  ## Examples
  ```elixir
  Aurora.Uix.Web.Templates.Basic.ModulesGenerator.generate_module(
    %{caller: MyAppWeb, context: MyApp.Accounts, module: MyApp.User, web: MyAppWeb},
    %{_path: %{tag: :index}, name: :product}
  )
  ```
  If the tag is not implemented, returns a quoted block with no generation logic.
  """
  @spec generate_module(map(), map()) :: Macro.t()
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
  - `parsed_options` (map()) - Options with fields to filter.

  ## Returns
  - map() - Options with omitted fields removed.

  ## Examples
  ```elixir
  Aurora.Uix.Web.Templates.Basic.ModulesGenerator.remove_omitted_fields(%{
    fields: [
      %{name: :foo, omitted: true},
      %{name: :bar, omitted: false}
    ]
  })
  # => %{fields: [%{name: :bar, omitted: false}]}
  ```
  """
  @spec remove_omitted_fields(map()) :: map()
  def remove_omitted_fields(parsed_options) do
    parsed_options
    |> Map.get(:fields, %{})
    |> Enum.reject(& &1.omitted)
    |> then(&Map.put(parsed_options, :fields, &1))
  end

  @doc """
  Generates a module name by concatenating the caller, module name, and suffix.

  ## Parameters
  - `modules` (map()) - Module configuration with caller reference.
  - `parsed_opts` (map()) - Options containing `module_name`.
  - `suffix` (binary()) - String to append to module name.

  ## Returns
  - `module()` - The generated module name.

  ## Examples
  ```elixir
  Aurora.Uix.Web.Templates.Basic.ModulesGenerator.module_name(
    %{caller: MyAppWeb}, %{module_name: "User"}, ".Index"
  )
  # => MyAppWeb.User.Index
  ```
  """
  @spec module_name(map(), map(), binary()) :: module()
  def module_name(modules, parsed_opts, suffix) do
    Module.concat(modules.caller, "#{parsed_opts.module_name}#{suffix}")
  end
end
