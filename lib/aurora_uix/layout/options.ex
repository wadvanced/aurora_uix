defmodule Aurora.Uix.Layout.Options do
  @moduledoc """
  Provides utilities for retrieving and creating rendering layout options based on the
  assigns context.

  This module acts as a central dispatcher for layout options, delegating to tag-specific
  option modules and providing a unified interface for option registration and retrieval.

  ## Key features

    * Delegates option retrieval to tag-specific modules (e.g., `Aurora.Uix.Layout.Options.Page`) when applicable.
    * Logs warnings and returns `{:not_found, option}` for unsupported tags or missing options.
    * Centralizes error reporting for unknown or unimplemented options.
    * Provides macros for option registration with layout type support.
    * Renders option values as binary content for HEEx templates.

  ## Key constraints

    * Expects assigns to contain `auix` and `layout_tree` keys with appropriate structure.
    * Only delegates to tag-specific modules when the tag is recognized.
    * Does not implement option handling for all possible tags; unrecognized tags will log a warning.

  ## Usage

  To use the option registration macros in your module:

      defmodule MyModule do
        use Aurora.Uix.Layout.Options, :page

        register_option(:my_option, "default_value")
        register_option(:dynamic_option, fn assigns -> assigns.some_value end)
      end

  """

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.HTML, only: [raw: 1]

  alias Aurora.Uix.Layout.Options.Form, as: FormOptions
  alias Aurora.Uix.Layout.Options.Index, as: IndexOptions
  alias Aurora.Uix.Layout.Options.Show, as: ShowOptions

  require Logger

  @doc """
  Generates the necessary macros and attributes for option registration.

  Sets up module attributes for tracking registered options and provides macros for
  registering options with layout types.

  ## Parameters

    - `layout_type` (atom()) - The layout type to associate with registered options.

  ## Returns

    Quoted expression containing the module setup code.

  ## Examples

      defmodule MyLayoutOptions do
        use Aurora.Uix.Layout.Options, :form

        register_option(:form_title, "Default Form Title")
      end

  """
  @spec __using__(atom()) :: Macro.t()
  defmacro __using__(layout_type) do
    quote do
      import Aurora.Uix.Layout.Options, only: [get: 2, register_option: 2, register_option: 3]

      Module.register_attribute(__MODULE__, :auix_options, accumulate: true, persist: true)
      Module.put_attribute(__MODULE__, :auix_layout_type, unquote(layout_type))

      @doc false
      @spec registered_options() :: list()
      def registered_options(), do: @auix_options

      @doc false
      @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
      def get(%{auix: %{layout_tree: %{tag: :form, opts: opts}}} = assigns, option) do
        if Keyword.has_key?(opts, option),
          do: get_option(assigns, opts[option], option),
          else: get_default(assigns, option)
      end

      def get(_assigns, option), do: {:not_found, option}
    end
  end

  @doc """
  Registers an option with a default value for the current layout type.

  ## Parameters

    - `name` (atom()) - The option name to register.
    - `value` (term()) - The default value or function to compute the value.

  ## Returns

    Quoted expression for option registration.

  ## Examples

      register_option(:page_title, "Default Title")
      register_option(:breadcrumbs, fn assigns -> build_breadcrumbs(assigns) end)

  """
  @spec register_option(atom(), term()) :: Macro.t()
  defmacro register_option(name, value) do
    quote do
      register_option(unquote(name), unquote(value), [unquote(@auix_layout_type)])
    end
  end

  @doc """
  Registers an option with a default value for specific layout types.

  ## Parameters

    - `name` (atom()) - The option name to register.
    - `value` (term()) - The default value or function to compute the value.
    - `layout_types` (list(atom())) - List of layout types to register the option for.

  ## Returns

    Quoted expression for option registration and getter function definition.

  ## Examples

      register_option(:shared_title, "Shared Title", [:page, :form])
      register_option(:computed_value, fn assigns -> compute(assigns) end, [:index])

  """
  @spec register_option(atom(), term(), list(atom())) :: Macro.t()
  defmacro register_option(name, value, layout_types) do
    registrations =
      Enum.map(layout_types, fn layout_type ->
        quote do
          Module.put_attribute(__MODULE__, :auix_options, {unquote(layout_type), unquote(name)})
        end
      end)

    get_update =
      if is_function(value, 1) do
        quote do
          defp get_default(assigns, unquote(name)),
            do: {:ok, unquote(value).(assigns)}
        end
      else
        quote do
          defp get_default(_assigns, unquote(name)),
            do: {:ok, unquote(value)}
        end
      end

    quote do
      unquote(registrations)

      unquote(get_update)
    end
  end

  @doc """
  Retrieves a layout option for the given assigns and option key.

  Delegates to tag-specific option modules when the tag is recognized (e.g., `:show`).
  Logs a warning and returns `{:not_found, option}` for unsupported tags or missing options.

  ## Parameters

    - `assigns` (map()) - Assigns map containing the `auix` and `layout_tree` keys.
    - `option` (atom()) - The option key to retrieve.

  ## Returns

    - `{:ok, term()}` - The value of the requested option.
    - `{:not_found, atom()}` - Indicates the option or tag is not supported.

  ## Examples

      iex> assigns = %{auix: %{layout_tree: %{tag: :show}}}
      iex> Aurora.Uix.Layout.Options.get(assigns, :page_title)
      {:ok, "Product Details"}

      iex> assigns = %{auix: %{layout_tree: %{tag: :edit, name: "resource"}}}
      iex> Aurora.Uix.Layout.Options.get(assigns, :page_title)
      {:not_found, :page_title}

      iex> Aurora.Uix.Layout.Options.get(%{}, :page_title)
      {:not_found, :page_title}

  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{auix: %{layout_tree: %{tag: tag, name: name}}} = assigns, option) do
    with {:not_found, _option} <- ShowOptions.get(assigns, option),
         {:not_found, _option} <- FormOptions.get(assigns, option),
         {:not_found, _option} <- IndexOptions.get(assigns, option) do
      Logger.warning("Option #{option} is not implemented for tag: #{tag}: #{name}")
      {:not_found, option}
    else
      {:ok, option_value} when is_function(option_value) -> option_value.(assigns)
      {:ok, option_value} -> option_value
    end
  end

  @doc """
  Retrieves all available options for a given layout type.

  Collects options from all registered option modules and filters by the specified
  layout type.

  ## Parameters

    - `layout_type` (atom()) - The layout type to filter options for.

  ## Returns

    list(atom()) - List of available option names for the layout type.


  """
  @spec get_available_options(atom()) :: list(atom())
  def get_available_options(layout_type) do
    []
    |> add_options(ShowOptions.registered_options())
    |> add_options(FormOptions.registered_options())
    |> add_options(IndexOptions.registered_options())
    |> Enum.filter(&(elem(&1, 0) == layout_type))
    |> Enum.map(&elem(&1, 1))
  end

  @doc """
  Renders a value as a binary in a HEEx template.

  Inserts the value into assigns under the `:auix_option_value` key and renders it.

  ## Parameters

    - `assigns` (map()) - Assigns map for the template.
    - `value` (term()) - Value to render.

  ## Returns

    Phoenix.LiveView.Rendered.t() - Rendered HEEx content containing the value.


  """
  @spec render_binary(map(), term()) :: Phoenix.LiveView.Rendered.t()
  def render_binary(assigns, value) do
    assigns =
      value
      |> raw()
      |> then(&Map.put(assigns, :auix_option_value, &1))

    ~H"{@auix_option_value}"
  end

  ## PRIVATE

  # Adds options from a list to the result accumulator
  defp add_options(result, options), do: Enum.reduce(options, result, &[&1 | &2])
end
