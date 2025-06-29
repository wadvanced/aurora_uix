defmodule Aurora.Uix.Layout.Helpers do
  @moduledoc """
  Helper utilities for Aurora.Uix UI DSL,
  providing functions for processing HEEX markup and managing component state.

  ## Key Features
  - Supports DSL block processing, normalization, and component registration for UI layout macros.
  - Manages unique identifier counters and component configuration for dynamic UI generation.

  """
  require Logger

  @doc """
  Extracts the `:do` block from options while preserving other options.

  ## Parameters
  - `opts` (`keyword()`) - Options list that may contain a :do key.
  - `block` (`any()`) - Optional explicit block value.

  ## Returns
  `{block, opts}` (tuple()) - Extracted block and remaining options.
  """
  @spec extract_block_options(keyword(), any()) :: tuple()
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
  Normalizes quoted blocks into a list of quoted expressions for HEEX processing.

  ## Parameters
  - `block` (`Macro.t()`) - Input block to be normalized.

  ## Returns
  `list(Macro.t())` - List of normalized quoted expressions.
  """
  @spec prepare_block(any()) :: list()
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
  Transforms DSL macro calls into standardized component entries for HEEX generation.

  ## Parameters
  - `tag` (`atom()`) - Component type identifier.
  - `name` (`atom()`) - Component name.
  - `config` (`keyword()` | tuple() | `nil`) - Static configuration or field definitions.
  - `opts` (`keyword()`) - Component options.
  - `do_block` (`Macro.t()`) - Nested component definitions.

  ## Returns
  map() - Standardized component entry map.
  """
  @spec register_dsl_entry(atom(), atom(), keyword() | tuple() | nil, keyword(), any()) ::
          Macro.t()
  def register_dsl_entry(tag, name, config, opts, do_block) do
    {block, opts} = extract_block_options(opts, do_block)

    inner_elements =
      case config do
        {:fields, fields} ->
          fields
          |> Enum.map(&create_field_tag/1)
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
          inner_elements: unquote(prepare_block(block)) ++ unquote(inner_elements)
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      end

    quote do
      unquote(registration)
    end
  end

  ## PRIVATE

  # Normalizes block structure by removing empty blocks and preserving non-empty ones
  # Used in block preparation for HEEX template generation
  @spec reduce_blocks(Macro.t()) :: Macro.t()
  defp reduce_blocks([[]]), do: []
  defp reduce_blocks(blocks), do: blocks

  # Extracts block content from either a keyword list with :do key or direct block
  # Used to handle both inline and do-block syntax in DSL macros
  @spec extract_block(keyword() | Macro.t()) :: Macro.t()
  defp extract_block(do: block), do: block
  defp extract_block(block), do: block

  # Creates a standardized field tag structure from various field specifications
  # Handles atom fields, tuple fields, and fields with options
  @spec create_field_tag(atom() | {atom(), keyword()}) :: map()
  defp create_field_tag(field) when is_atom(field) do
    %{tag: :field, name: field, config: [], inner_elements: []}
  end

  defp create_field_tag(field) when is_tuple(field) do
    %{tag: :field, name: field, config: [], inner_elements: []}
  end

  defp create_field_tag({field_name, opts}) do
    %{tag: :field, name: field_name, config: opts, inner_elements: []}
  end
end
