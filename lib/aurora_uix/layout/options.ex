defmodule Aurora.Uix.Layout.Options do
  @moduledoc """
  Provides a framework for defining and retrieving layout-specific options.

  Intended to be `used` by layout option sets (e.g., `Index`, `Form`, `Show`) to establish
  a common interface for handling options. Each option set declares its options with
  `option name, type`, exposed as `Aurora.Uix.Layout.Options.Option` structs by `options/0`.

  ## Usage

  ```elixir
  defmodule MyLayout.Options do
    use Aurora.Uix.Layout.Options, layout_type: :my_layout

    option :my_option, {:or, [:string, {:fun, 1}]}

    # The option's value when the layout does not set it.
    defp get_default(_assigns, :my_option), do: {:ok, "default"}
    defp get_default(_assigns, option), do: {:not_found, option}
  end
  ```

  A layout's value for an option is validated against the option's `Spark.Options` type when the
  layout compiles.

  ## Function-valued options

  Two distinct function mechanisms are supported, and they are not interchangeable:

  - **Layout options** (e.g. `:page_title`, `:edit_title`, `:new_action_label`) accept an
    arity-1 function that receives `assigns` and returns a `Phoenix.LiveView.Rendered.t()`.
    See `get_option/3`.
  - **Resource `name`/`title` metadata** (set via `auix_resource_metadata`, consumed as
    `assigns.auix.name` / `assigns.auix.title`) additionally accepts a **0-arity** function
    returning a `binary()`, resolved through `parse_value/1`. This is what every title,
    subtitle and action-label default interpolates when building its display string.
  """

  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Layout.Options.Form, as: FormOptions
  alias Aurora.Uix.Layout.Options.Index, as: IndexOptions
  alias Aurora.Uix.Layout.Options.Option
  alias Aurora.Uix.Layout.Options.Show, as: ShowOptions

  require Logger

  @layout_options_parsers Application.compile_env(:aurora_uix, :layout_options_parsers, []) ++
                            [
                              IndexOptions,
                              ShowOptions,
                              FormOptions
                            ]

  @doc """
  Returns the options the layout type accepts.

  ## Returns
  [Option.t()] - One `Aurora.Uix.Layout.Options.Option` per option.
  """
  @callback options() :: [Option.t()]

  @doc """
  Fetches the value of a specific layout option.

  ## Parameters
  - `assigns` (map()) - The assigns map.
  - `option` (atom()) - The option to retrieve.

  ## Returns
  any() - The value of the option.
  """
  @callback get(assigns :: map(), option :: atom()) :: any()

  # Brings in the option set DSL (`option name, type`).
  #
  # ## Parameters
  # - `opts` (keyword()) - `:layout_type`, the layout the options belong to. Each option needs a
  #   `get_default/2` clause in the calling module.
  #
  # ## Returns
  # Macro.t() - The DSL, the behaviour and the `get_option/3` import.
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    layout_type = LayoutOptions.__layout_type__(opts)

    quote do
      use Aurora.Uix.Layout.Options.Definition

      @behaviour LayoutOptions
      import LayoutOptions, only: [get_option: 3]

      @auix_layout_type unquote(layout_type)
    end
  end

  @doc false
  # Reads the `use` options. The 0.1.x `use Aurora.Uix.Layout.Options, :layout_type` fails, so a
  # set never ends up accepting no options.
  @spec __layout_type__(keyword() | atom()) :: atom()
  def __layout_type__(opts) when is_list(opts) do
    opts |> Keyword.validate!([:layout_type]) |> Keyword.fetch!(:layout_type)
  end

  def __layout_type__(layout_type) do
    raise ArgumentError,
          "use Aurora.Uix.Layout.Options, #{inspect(layout_type)} no longer finds the options; " <>
            "write `use Aurora.Uix.Layout.Options, layout_type: #{inspect(layout_type)}` and " <>
            "declare each option with `option :name, type`"
  end

  @doc """
  Returns the code defining an option set's `options/0` and `get/2`.

  ## Parameters
  - `layout_type` (atom()) - The layout the options belong to.
  - `options` ([Option.t()]) - The declared options.

  ## Returns
  `Macro.t()` - The function definitions. `get/2` reads a declared option from the layout, then
  from the set's `get_default/2`.
  """
  @spec options_code(atom(), [Option.t()]) :: Macro.t()
  def options_code(layout_type, options) do
    names = Enum.map(options, & &1.name)

    quote do
      @doc false
      @spec options() :: [Option.t()]
      def options do
        unquote(Macro.escape(options))
      end

      @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
      def get(
            %{auix: %{layout_type: unquote(layout_type), layout_tree: %{options: opts}}} = assigns,
            option
          )
          when option in unquote(names) do
        if Keyword.has_key?(opts, option),
          do: get_option(assigns, opts[option], option),
          else: get_default(assigns, option)
      end

      def get(_assigns, option), do: {:not_found, option}
    end
  end

  @doc """
  Returns the options of a layout type, from every registered option set.

  ## Parameters
  - `layout_type` (atom()) - The layout type (e.g., `:index`, `:form`).

  ## Returns
  `[Option.t()]` - The options, with their types.
  """
  @spec options(atom()) :: [Option.t()]
  def options(layout_type) do
    @layout_options_parsers
    |> Enum.flat_map(& &1.options())
    |> Enum.filter(&(&1.layout_type == layout_type))
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
    layout_type
    |> options()
    |> Enum.map(& &1.name)
  end

  @doc """
  Retrieves a layout option for the given assigns and option key.

  This function delegates the option retrieval to specialized modules (`ShowOptions`,
  `FormOptions`, `IndexOptions`). If the option is not found in any of the delegated
  modules, it logs a warning and returns a `:not_found` tuple.

  ## Parameters

  - `assigns` (map()) - The assigns map, which must contain an `:auix` key with a
    `layout_type` and a `layout_tree` layout node.
  - `option` (atom()) - The option key to retrieve.

  ## Returns

  - `{:ok, term()}` - If the option is found, returns a tuple with `:ok` and the option value.
  - `{:not_found, atom()}` - If the option is not found or the tag is unsupported.

  ## Examples

  ```elixir
  iex> assigns = %{auix: %{layout_type: :show, layout_tree: %Aurora.Uix.Layout.Node.Show{resource: :resource}}}
  iex> Aurora.Uix.Layout.Options.get(assigns, :unsupported_option)
  {:not_found, :unsupported_option}

  iex> Aurora.Uix.Layout.Options.get(%{}, :page_title)
  {:not_found, :page_title}
  ```
  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{auix: %{layout_type: tag, layout_tree: %{resource: name}}} = assigns, option) do
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

  def get_option(_assigns, value, _option), do: {:ok, value}

  @doc """
  Normalizes a value into a display binary.

  Used to resolve resource `name`/`title` metadata (and similar values) into the binary
  ultimately interpolated into title, subtitle and action-label defaults. Unlike the
  arity-1 functions accepted by `get_option/3` (which receive `assigns`), this accepts a
  **0-arity** function, letting `name`/`title` be computed independently of the render
  context.

  ## Parameters

  - `value` (`nil | binary() | function()`) - The raw value to normalize:
    - `nil` resolves to `""`.
    - A `binary()` is returned as-is.
    - A 0-arity function is called and its result returned.
    - Any other value is converted with `to_string/1`.

  ## Returns

  - `binary()` - The resolved display value.

  ## Examples

  ```elixir
  iex> Aurora.Uix.Layout.Options.parse_value(nil)
  ""

  iex> Aurora.Uix.Layout.Options.parse_value("Product")
  "Product"

  iex> Aurora.Uix.Layout.Options.parse_value(fn -> "Product" end)
  "Product"
  ```
  """
  @spec parse_value(nil | binary() | function()) :: binary()
  def parse_value(nil), do: ""

  def parse_value(name) when is_binary(name), do: name

  def parse_value(name_fun) when is_function(name_fun, 0), do: name_fun.()

  def parse_value(name), do: to_string(name)

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
