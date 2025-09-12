defmodule Aurora.Uix.Layout.Options do
  @moduledoc """
  Provides a framework for defining and retrieving layout-specific options.

  This module is intended to be `use`d by other layout modules (e.g., `Index`, `Form`, `Page`)
  to establish a common interface for handling options. It works by introspecting the calling
  module to automatically discover available options.

  ## Key Features

  - **Option Discovery**: Automatically discovers available options from the calling module's
    `get_default/2` function implementation via a `__before_compile__` callback.
  - **Centralized Retrieval**: Offers a unified `get/2` function that delegates option
    retrieval to the appropriate layout-specific module (`ShowOptions`, `FormOptions`,
    `IndexOptions`).
  - **Dynamic Rendering**: Includes a `render_binary/2` helper to render values within
    HEEx templates.

  ## Usage

  To use this module, you should `use Aurora.Uix.Layout.Options, :layout_type` in your
  layout-specific option module, where `:layout_type` is an atom representing the layout
  (e.g., `:index`, `:form`).

  ```elixir
  defmodule MyLayout.Options do
    use Aurora.Uix.Layout.Options, :my_layout

    # The `get_default/2` function is required for option discovery.
    def get_default(assigns, :my_option, _default_opts \ []) do
      # implementation
    end
  end
  ```
  """

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.HTML, only: [raw: 1]

  alias Aurora.Uix.Layout.Options.Form, as: FormOptions
  alias Aurora.Uix.Layout.Options.Index, as: IndexOptions
  alias Aurora.Uix.Layout.Options.Show, as: ShowOptions
  require Logger

  @doc """
  Injects option-handling capabilities into the calling module.

  When `use Aurora.Uix.Layout.Options` is invoked, this macro sets up the necessary
  attributes and callbacks to enable automatic option discovery. It defines an
  `available_options/0` function in the calling module that returns all discovered options.

  ## Parameters

  - `layout_type` (atom()) - The atom representing the layout type (e.g., `:page`, `:form`).
  """
  @spec __using__(layout_type :: atom()) :: Macro.t()
  defmacro __using__(layout_type) do
    quote do
      Module.put_attribute(__MODULE__, :auix_layout_type, unquote(layout_type))

      @before_compile Aurora.Uix.Layout.Options
    end
  end

  @doc false
  # This callback is triggered before the calling module is compiled. It inspects the
  # `get_default/2` function definition within the calling module to extract the names of
  # the available options. These options are then stored in the `@auix_options` module
  # attribute of the caller.
  @spec __before_compile__(env :: Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module

    layout_type = Module.get_attribute(module, :auix_layout_type)
    {_version, _kind, _metadata, def_args} = Module.get_definition(module, {:get_default, 2})

    options =
      def_args
      |> Enum.map(fn {_meta, args, _guards, _ast} -> List.last(args) end)
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&{layout_type, &1})
      |> IO.inspect(label: "******* parsed options")

    quote do
      @doc false
      @spec available_options() :: [{atom(), atom()}]
      def available_options do
        unquote(options)
      end
    end
  end

  @doc """
  Retrieves all available options for a given layout type.

  It fetches the options from all registered layout option modules
  and filters them based on the provided `layout_type`.

  ## Parameters

  - `layout_type` (atom()) - The type of layout to filter options for (e.g., `:page`, `:form`).

  ## Returns

  - `list(atom())` - A list of option atoms available for the specified layout type.
  """
  @spec available_options(layout_type :: atom()) :: [atom()]
  def available_options(layout_type) do
    [
      ShowOptions,
      FormOptions,
      IndexOptions
    ]
    |> Enum.flat_map(&(&1.available_options() |> IO.inspect(label: "****** read options")))
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
    `%{layout_tree: %{tag: atom(), name: String.t()}}` structure.
  - `option` (atom()) - The option key to retrieve.

  ## Returns

  - `{:ok, term()}` - If the option is found, returns a tuple with `:ok` and the option value.
  - `{:not_found, atom()}` - If the option is not found or the tag is unsupported.

  ## Examples

      iex> assigns = %{auix: %{layout_tree: %{tag: :show, name: "resource"}}}
      iex> Aurora.Uix.Layout.Options.get(assigns, :unsupported_option)
      {:not_found, :unsupported_option}

      iex> Aurora.Uix.Layout.Options.get(%{}, :page_title)
      {:not_found, :page_title}

  """
  @spec get(assigns :: map(), option :: atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{auix: %{layout_tree: %{tag: tag, name: name}}} = assigns, option) do
    with {:not_found, _option} <- ShowOptions.get(assigns, option),
         {:not_found, _option} <- FormOptions.get(assigns, option),
         {:not_found, _option} <- IndexOptions.get(assigns, option) do
      Logger.warning("Option #{option} is not implemented for tag: #{tag}: #{name}")
      {:not_found, option}
    end
  end

  def get(_assigns, option), do: {:not_found, option}

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

      iex> assigns = %{}
      iex> rendered = Aurora.Uix.Layout.Options.render_binary(assigns, "Hello, World!")
      iex> Phoenix.HTML.safe_to_string(rendered)
      "Hello, World!"

  """
  @spec render_binary(assigns :: map(), value :: term()) :: Phoenix.LiveView.Rendered.t()
  def render_binary(assigns, value) do
    assigns =
      value
      |> raw()
      |> then(&Map.put(assigns, :auix_option_value, &1))

    ~H"{@auix_option_value}"
  end
end
