defmodule Aurora.Uix.Helper do
  @moduledoc """
  Helper module for Aurora.Uix UI DSL that provides utilities for processing HEEX markup and managing component state.

  Core functionalities:
  - DSL block processing and normalization
  - Component registration and configuration
  - Unique identifier counter management
  """

  @doc """
  Extracts the `:do` block from options while preserving other options.

  Parameters:
  - opts (keyword): Options list that may contain a :do key
  - block (any): Optional explicit block value

  Returns:
  - {block, opts} (tuple): Extracted block and remaining options
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
  Normalizes quoted blocks into a list of quoted expressions for HEEX processing.

  Parameters:
  - block (Macro.t()): Input block to be normalized

  Returns:
  - list(Macro.t()): List of normalized quoted expressions
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
  Transforms DSL macro calls into standardized component entries for HEEX generation.

  Parameters:
  - tag (atom): Component type identifier
  - name (atom): Component name
  - config (keyword|tuple|nil): Static configuration or field definitions
  - opts (keyword): Component options
  - do_block (Macro.t()): Nested component definitions

  Returns:
  - map: Standardized component entry map
  """
  @spec register_dsl_entry(atom, atom, keyword | tuple | nil, keyword, any) :: Macro.t()
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

  @doc """
  Initializes a new counter for generating unique component identifiers.

  Parameters:
  - name (binary|atom|nil): Counter identifier
  - initial (integer): Starting value for the counter

  Returns:
  - binary|atom|pid: Counter reference
  """
  @spec start_counter(binary | atom | nil, integer) :: binary | atom | pid
  def start_counter(name \\ nil, initial \\ 0)

  def start_counter(nil, initial) do
    case Agent.start_link(fn -> initial end) do
      {:ok, pid} -> pid
      {:error, {:already_started, _}} -> reset_count(nil, initial)
    end
  end

  def start_counter(name, initial) do
    case Agent.start_link(fn -> initial end, name: name) do
      {:ok, _} -> name
      {:error, {:already_started, _}} -> reset_count(name, initial)
    end
  end

  @doc """
  Increments and returns the next value for a counter.

  Parameters:
  - name (atom|pid|{atom, any}|{:via, atom, any}): Counter reference

  Returns:
  - integer: Next counter value
  """
  @spec next_count(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: any()
  def next_count(name) do
    Agent.get_and_update(name, fn state -> {state + 1, state + 1} end)
  end

  @doc """
  Returns the current counter value without incrementing.

  Parameters:
  - name (binary|atom): Counter reference

  Returns:
  - integer: Current counter value
  """
  @spec peek_count(binary | atom) :: integer
  def peek_count(name) do
    Agent.get(name, fn state -> state end)
  end

  @doc """
  Resets a counter to a specified value.

  Parameters:
  - name (binary|atom|pid): Counter reference
  - initial (integer): Value to reset the counter to

  Returns:
  - binary|atom|pid: Counter reference
  """
  @spec reset_count(binary | atom | pid, integer) :: binary | atom | pid
  def reset_count(name, initial) do
    Agent.get_and_update(name, fn _state -> {name, initial} end)
  end

  ## PRIVATE
  @spec reduce_blocks(Macro.t()) :: Macro.t()
  defp reduce_blocks([[]]), do: []
  defp reduce_blocks(blocks), do: blocks

  @spec extract_block(keyword | Macro.t()) :: Macro.t()
  defp extract_block(do: block), do: block
  defp extract_block(block), do: block

  @spec create_field_tag(atom | {atom, keyword}) :: map
  defp create_field_tag(field) when is_atom(field) do
    %{tag: :field, name: field, config: [], inner_elements: []}
  end

  defp create_field_tag({field_name, opts}) do
    %{tag: :field, name: field_name, config: opts, inner_elements: []}
  end
end
