defmodule Aurora.Uix.Templates.Basic.ModulesGenerator do
  @moduledoc """
  Dynamic LiveView module generator for creating CRUD-oriented user interfaces.

  Transforms configuration maps into fully-functional, dynamically generated LiveView modules
  for index, show, and form UI components. Generates modules with event handling, form
  validation, and flexible rendering. All code generation is performed at compile time.

  Delegates actual code generation to specialized sub-generators: FormGenerator, IndexGenerator,
  and ShowGenerator.
  """

  alias Aurora.Uix.Layout.Node
  alias Aurora.Uix.Templates.Basic.Generators.FormGenerator
  alias Aurora.Uix.Templates.Basic.Generators.IndexGenerator
  alias Aurora.Uix.Templates.Basic.Generators.ShowComponentGenerator
  alias Aurora.Uix.Templates.Basic.Helpers
  require Logger

  @doc """
  Generates a LiveView module for the specified UI component type.

  ## Parameters
  - `parsed_opts` (map()) - Generation options with `layout_type` and component configuration.

  ## Returns
  Macro.t() - The generated LiveView module code.

  ## Examples
  ```elixir
  Aurora.Uix.Templates.Basic.ModulesGenerator.generate_module(
    %{layout_type: :index, name: :product,
        modules: %{caller: MyAppWeb, context: MyApp.Accounts, module: MyApp.User, web: MyAppWeb}
      }
    }
  )
  ```

  If the tag is not implemented, returns a quoted block with no generation logic.
  """
  @spec generate_module(map()) :: Macro.t()
  def generate_module(%{layout_type: :index} = parsed_opts) do
    IndexGenerator.generate_module(parsed_opts)
  end

  def generate_module(%{layout_type: :show} = parsed_opts) do
    ShowComponentGenerator.generate_module(parsed_opts)
  end

  def generate_module(%{layout_type: :form} = parsed_opts) do
    FormGenerator.generate_module(parsed_opts)
  end

  def generate_module(%{layout_type: type}) do
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
  Aurora.Uix.Templates.Basic.ModulesGenerator.remove_omitted_fields(%{
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
  Returns the options a form or show component runs with: the omitted fields removed and
  `one2many_rendered?` set.

  ## Parameters
  - `parsed_opts` (map()) - Generation options with `fields` and `layout_tree`.

  ## Returns
  `map()` - The options, with `one2many_rendered?` telling whether the layout places a
  one-to-many field.
  """
  @spec component_opts(map()) :: map()
  def component_opts(parsed_opts) do
    cleaned_parsed_opts = remove_omitted_fields(parsed_opts)

    one2many_preload =
      cleaned_parsed_opts
      |> Helpers.extract_association_preload()
      |> Map.get(:one_to_many_association, [])

    one2many_rendered? =
      cleaned_parsed_opts
      |> Map.get(:layout_tree)
      |> Node.fields()
      |> Enum.any?(&(&1.key in one2many_preload))

    Map.put(cleaned_parsed_opts, :one2many_rendered?, one2many_rendered?)
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
  Aurora.Uix.Templates.Basic.ModulesGenerator.module_name(
    %{caller: MyAppWeb}, %{module_name: "User"}, ".Index"
  )
  # => MyAppWeb.User.Index
  ```
  """
  @spec module_name(map(), binary()) :: module()
  def module_name(parsed_opts, suffix) do
    Module.concat(parsed_opts.modules.caller, "#{parsed_opts.module_name}#{suffix}")
  end

  @doc """
  Returns the handler module or the default one.
  """
  @spec handler_module(map(), module()) :: module()
  def handler_module(%{layout_tree: %{handler_module: nil}}, default_module), do: default_module

  def handler_module(%{layout_tree: %{handler_module: handler_module}}, _default),
    do: handler_module
end
