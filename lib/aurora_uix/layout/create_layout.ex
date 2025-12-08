defmodule Aurora.Uix.Layout.CreateLayout do
  @moduledoc """
  Provides the `auix_create_layout/2` macro to define reusable UI layouts.
  """

  alias Aurora.Uix.Layout.Blueprint
  alias Aurora.Uix.Layout.CreateLayout
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers

  @spec __auix_create_missing_layouts() :: Macro.t()
  defmacro __auix_create_missing_layouts do
    # __MODULE__
    # |> Module.get_attribute(:auix_layout_opts, [])
    # |> Keyword.get(:omit_missing_layouts_creation?, false)

    quote do
      :ok
    end
  end

  @doc false
  # Generates the `auix_layout_trees/0` function at compile time.
  #
  # This macro is automatically invoked by the Elixir compiler before the module is
  # fully compiled. It reads the layout definitions stored in the `@auix_layout_trees`
  # module attribute and injects a function `auix_layout_trees/0` into the calling
  # module. This function returns the stored layout trees, making them available
  # at runtime.
  #
  # ## Parameters
  # - `env` (Macro.Env.t()) - The macro environment.
  #
  # ## Returns
  # Macro.t() - A quoted expression containing the generated function.
  @spec __before_compile__(Macro.Env.t()) :: Macro.t()
  defmacro __before_compile__(env) do
    module = env.module

    __auix_create_missing_layouts()

    layout_trees =
      module
      |> Module.get_attribute(:auix_layout_trees, [])
      |> Macro.escape()

    quote do
      @doc false
      @spec auix_layout_trees() :: list()
      def auix_layout_trees do
        unquote(layout_trees)
      end
    end
  end

  @doc """
  Defines a reusable UI layout.

  This macro is the entry point for creating reusable layouts that can be later
  applied to a resource.

  ## Parameters
  - `opts` (`Keyword.t()`) - Configuration options for the layout. Currently not used.
  - `do_block` (`Macro.t()` | `nil`) - A block defining the layout using the layout DSL.

  ## Returns
  `Macro.t()` - A quoted expression that defines the layout.

  ## Examples
  ```elixir
  defmodule MyApp.MyAwesomeLayout do
    use Aurora.Uix.Layout

    auix_create_layout do
      form_layout do
        section "My Section" do
          inline [:name, :description]
        end
      end

      index_columns [:name]
    end
  end
  ```
  """
  @spec auix_create_layout(keyword(), Macro.t() | nil) :: Macro.t()
  defmacro auix_create_layout(opts \\ [], do_block \\ nil) do
    {block, opts} = LayoutHelpers.extract_block_options(opts, do_block)

    quoted_opts = LayoutHelpers.create_layout_opts(opts)
    layout_trees = LayoutHelpers.create_layout(block, __CALLER__)

    quote do
      import Blueprint

      @before_compile CreateLayout

      unquote(quoted_opts)
      unquote(layout_trees)
    end
  end
end
