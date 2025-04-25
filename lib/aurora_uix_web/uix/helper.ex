defmodule AuroraUixWeb.Uix.Helper do
  @moduledoc """
  Internal utilities for the AuroraUix UI DSL.

  This module provides helper functions used to support the macros defined in `AuroraUixWeb.Uix`.
  It focuses on extracting and transforming `do` blocks from macro invocations, building layout trees,
  and preparing UI components for registration within the system.

  These helpers are typically not used directly by end users, but they are critical for the internal
  functioning of the UI layout and configuration macros.
  """

  @doc """
  Extracts the `:do` block from the given options list.

  This function checks if a block is provided. If no block is given (`block == nil`),
  it extracts the `:do` key from the `opts` keyword list, returning the block and
  the remaining options. If a block is provided, it simply returns the block and
  the original options.

  ## Parameters

    - `opts` (`keyword`): A keyword list of options that may contain a `:do` key.
    - `block` (`any`, optional): An explicit block value. Defaults to `nil`.

  ## Returns

    - `{block, remaining_opts}` (`tuple`): A tuple where the first element is
      the extracted block (either from `opts` or the explicitly provided `block`),
      and the second element is the remaining options.

  ## Examples

      iex> extract_block_options([do: :some_block, other: :value])
      {:some_block, [other: :value]}

      iex> extract_block_options([other: :value], :explicit_block)
      {:explicit_block, [other: :value]}

  """
  @spec extract_block_options(keyword, any) :: tuple
  def extract_block_options(opts, block \\ nil) do
    if is_nil(block) do
      Keyword.pop(opts, :do, [])
    else
      block
      |> extract_block()
      |> then(&{&1, opts})
    end
  end

  @doc """
  Normalizes a quoted block into a list of quoted expressions.

  This function ensures that both single expressions and multi-expression `do` blocks are
  returned as a list of quoted expressions. This is useful for macros that expect a uniform
  structure when processing layout or UI definitions.

  ## Examples

      iex> prepare_block({:__block__, [], [:a, :b]})
      [quote(do: :a), quote(do: :b)]

      iex> prepare_block(:a)
      [quote(do: :a)]

  """
  @spec prepare_block(any) :: []
  def prepare_block(block) do
    blocks =
      case block do
        {:__block__, _, separated_blocks} -> separated_blocks
        single_block -> [single_block]
      end

    blocks
    |> Enum.map(&quote(do: unquote(&1)))
    |> reduce_blocks()
  end

  @doc """
  Transforms a DSL macro invocation into a standardized entry map.

  This helper is used by both resource- and UI-configuration macros to convert a macro call
  into a uniform `%{tag, name, opts, config, inner_elements}` representation. That map can then
  be aggregated and processed by the DSL engine to build your full configuration tree.

  ## Parameters

    - `tag` (`atom`): The kind of DSL element (e.g. `:resource`, `:field`, `:ui`, etc.).
    - `name` (`atom`): The identifier for this element.
    - `config` (`any`): Any static or shorthand configuration (e.g. `{:fields, [...]}`) to carry through.
    - `opts` (`keyword`): Options passed to the macro invocation.
    - `do_block` (`Macro.t()`): An optional `do` block AST containing nested child elements.

  ## Returns

  A quoted expression that, when expanded, produces:

  ```elixir
  %{
    tag: tag,
    name: name,
    opts: opts,
    config: config,          # only if non-empty
    inner_elements: [...]    # flattened list of nested blocks or children
  }

  Any keys with nil or empty values are automatically omitted from the resulting map.

  ## Example
  ```elixir
    quote do
      register_dsl_entry(
        :field,
        :price,
        [],
        [placeholder: "Enter price", required: true],
        quote do
          # no nested children in this example
        end
      )
    end
    |> Macro.expand_once(__ENV__)
    #=> %{
    #     tag: :field,
    #     name: :price,
    #     opts: [placeholder: "Enter price", required: true],
    #     inner_elements: []
    #   }
  ```
  """
  @spec register_dsl_entry(atom, atom, keyword | tuple | nil, keyword, any) :: Macro.t()
  def register_dsl_entry(tag, name, config, opts, do_block) do
    {block, opts} = extract_block_options(opts, do_block)

    inner_elements =
      case config do
        {:fields, fields} ->
          fields
          |> Enum.map(fn field ->
            %{tag: :field, name: field, config: [], inner_elements: []}
          end)
          |> Macro.escape()

        _other ->
          []
      end
    config = if inner_elements == [], do: config, else: []

    registration =
      quote do
        %{
          tag: unquote(tag),
          name: unquote(name),
          opts: unquote(opts),
          config: unquote(config),
          inner_elements: unquote(inner_elements) ++ unquote(prepare_block(block))
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end

    quote do
      unquote(registration)
    end
  end

  ## PRIVATE
  defp reduce_blocks([[]]), do: []
  defp reduce_blocks(blocks), do: blocks

  defp extract_block(do: block), do: block
  defp extract_block(block), do: block
end
