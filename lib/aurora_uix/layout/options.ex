defmodule Aurora.Uix.Layout.Options do
  @moduledoc """
  Provides a framework for defining and retrieving layout-specific options.

  Intended to be `used` by layout modules (e.g., `Index`, `Form`, `Show`) to establish
  a common interface for handling options. Works by introspecting the calling module to
  automatically discover available options

  ## Usage

  To use this module, you should `use Aurora.Uix.Layout.Options, :layout_type` in your
  layout-specific option module, where `:layout_type` is an atom representing the layout
  (e.g., `:index`, `:form`, `:show`).

  ```elixir
  defmodule MyLayout.Options do
    use Aurora.Uix.Layout.Options, :my_layout

    # The `get_default/2` function is required for option discovery.
    def get_default(assigns, :my_option, _default_opts \\ []) do
      # implementation
    end
  end
  ```
  """

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.HTML, only: [raw: 1]

  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Layout.Options.Form, as: FormOptions
  alias Aurora.Uix.Layout.Options.Index, as: IndexOptions
  alias Aurora.Uix.Layout.Options.Show, as: ShowOptions

  require Logger

  @layout_options_parsers Application.compile_env(:aurora_uix, :layout_options_parsers, []) ++
                            [
                              IndexOptions,
                              ShowOptions,
                              FormOptions
                            ]
  @title_options Application.compile_env(:aurora_uix, :layout_title_options, []) ++
                   [
                     :edit_title,
                     :edit_subtitle,
                     :new_title,
                     :new_subtitle,
                     :page_title,
                     :page_subtitle
                   ]

  @doc """
  Retrieves the list of available options for the layout.

  ## Returns
  list(tuple()) - A list of tuples, where each tuple contains the layout type and the option name.
  """
  @callback available_options() :: list()

  @doc """
  Fetches the value of a specific layout option.

  ## Parameters
  - `assigns` (map()) - The assigns map.
  - `option` (atom()) - The option to retrieve.

  ## Returns
  any() - The value of the option.
  """
  @callback get(assigns :: map(), option :: atom()) :: any()

  # Injects option-handling capabilities into the calling module.
  #
  # When `use Aurora.Uix.Layout.Options` is invoked, this macro sets up the necessary
  # attributes and callbacks to enable automatic option discovery. It defines an
  # `available_options/0` function in the calling module that returns all discovered options.
  #
  # ## Parameters
  # - `layout_type` (atom()) - The atom representing the layout type (e.g., `:index`, `:form`, `:show`).
  #
  # ## Returns
  # Macro.t() - A quoted expression setting up the module attributes and callbacks.
  @spec __using__(atom()) :: Macro.t()
  defmacro __using__(layout_type) do
    quote do
      Module.put_attribute(__MODULE__, :auix_layout_type, unquote(layout_type))

      @behaviour LayoutOptions
      import LayoutOptions, only: [get_option: 3]

      @before_compile LayoutOptions
    end
  end

  @doc false
  # This callback is triggered before the calling module is compiled. It inspects the
  # `get_default/2` function definition within the calling module to extract the names of
  # the available options. These options are then stored in the `@auix_options` module
  # attribute of the caller.
  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module

    layout_type = Module.get_attribute(module, :auix_layout_type)

    {_version, _kind, _metadata, def_args} =
      Module.get_definition(module, {:get_default, 2})

    options =
      def_args
      |> Enum.map(fn {_meta, args, _guards, _ast} -> List.last(args) end)
      |> Enum.filter(&is_atom/1)

    typed_options = Enum.map(options, &{layout_type, &1})

    quote do
      @doc false
      @spec available_options() :: [{atom(), atom()}]
      def available_options do
        unquote(typed_options)
      end

      @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
      def get(%{auix: %{layout_tree: %{tag: unquote(layout_type), opts: opts}}} = assigns, option)
          when option in unquote(options) do
        if Keyword.has_key?(opts, option),
          do: get_option(assigns, opts[option], option),
          else: get_default(assigns, option)
      end

      def get(_assigns, option), do: {:not_found, option}
    end
  end

  @doc """
  Retrieves all available options for a given layout type.

  It fetches the options from all registered layout option modules
  and filters them based on the provided `layout_type`.

  ## Parameters

  - `layout_type` (atom()) - The type of layout to filter options for (e.g., `:index`, `:form`).

  ## Returns

  - `list(atom())` - A list of option atoms available for the specified layout type.
  """
  @spec available_options(atom()) :: list(atom())
  def available_options(layout_type) do
    @layout_options_parsers
    |> Enum.flat_map(& &1.available_options())
    |> Enum.filter(fn {type, _name} -> type == layout_type end)
    |> Enum.map(fn {_type, name} -> name end)
  end

  @doc """
  Retrieves a layout option for the given assigns and option key.

  This function delegates the option retrieval to specialized modules (`ShowOptions`,
  `FormOptions`, `IndexOptions`). If the option is not found in any of the delegated
  modules, it logs a warning and returns a `:not_found` tuple.

  ## Parameters

  - `assigns` (map()) - The assigns map, which must contain an `:auix` key with a
    `%{layout_tree: %{tag: atom, name: binary()}}` structure.
  - `option` (atom()) - The option key to retrieve.

  ## Returns

  - `{:ok, term()}` - If the option is found, returns a tuple with `:ok` and the option value.
  - `{:not_found, atom()}` - If the option is not found or the tag is unsupported.

  ## Examples

  ```elixir
  iex> assigns = %{auix: %{layout_tree: %{tag: :show, name: "resource"}}}
  iex> Aurora.Uix.Layout.Options.get(assigns, :unsupported_option)
  {:not_found, :unsupported_option}

  iex> Aurora.Uix.Layout.Options.get(%{}, :page_title)
  {:not_found, :page_title}
  ```
  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{auix: %{layout_tree: %{tag: tag, name: name}}} = assigns, option) do
    @layout_options_parsers
    |> Enum.reduce_while(
      {:cont, option},
      fn parser, _acc ->
        assigns
        |> parser.get(option)
        |> maybe_halt()
      end
    )
    |> evaluate_option_result(tag, name)
  end

  def get(_assigns, option), do: {:not_found, option}

  @doc """
  Gets an option value, processing it if it's a function or a title.

  ## Parameters

  - `assigns` (map()) - The assigns map.
  - `value` (term()) - The value of the option.
  - `option` (atom()) - The option key.

  ## Returns

  - `{:ok, term()}` - A tuple with `:ok` and the processed option value.
  """
  @spec get_option(map(), term(), atom()) :: {:ok, term()}
  def get_option(assigns, value, _option)
      when is_function(value, 1),
      do: {:ok, value.(assigns)}

  def get_option(assigns, value, option)
      when is_binary(value) and option in @title_options,
      do: {:ok, LayoutOptions.render_binary(assigns, value)}

  def get_option(_assigns, value, _option), do: {:ok, value}

  @doc """
  Renders a given value as a binary within a HEEx template.

  This helper function is used to safely render a value by embedding it into an assigns map
  and then rendering it with a `~H` sigil. The value is first passed through `raw/1` to
  prevent HTML escaping.

  ## Parameters

  - `assigns` (map()) - The assigns map for the template.
  - `value` (term()) - The value to be rendered.

  ## Returns

  - `Phoenix.LiveView.Rendered.t()` - The rendered HEEx content containing the value.

  ## Examples

  ```elixir
  iex> assigns = %{}
  iex> rendered = Aurora.Uix.Layout.Options.render_binary(assigns, "Hello, World!")
  iex> Phoenix.HTML.safe_to_string(rendered)
  "Hello, World!"
  ```
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

  # Halts the reduction if the option is found.
  @spec maybe_halt({:ok, term()} | {:not_found, atom()}) :: {:halt, term()} | {:cont, atom()}
  defp maybe_halt({:ok, result}), do: {:halt, result}
  defp maybe_halt({:not_found, result}), do: {:cont, result}

  # Evaluates the result of the option retrieval.
  @spec evaluate_option_result({:cont, atom()} | term(), atom(), atom()) ::
          {:ok, term()} | {:not_found, atom()}
  defp evaluate_option_result({:cont, option}, tag, name) do
    Logger.warning("Option #{option} is not implemented for tag: #{tag}: #{name}")
    {:not_found, option}
  end

  defp evaluate_option_result(result, _tag, _name), do: {:ok, result}
end
