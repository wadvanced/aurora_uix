defmodule Aurora.Uix.Layout.Helpers do
  @moduledoc """
  Helper utilities for Aurora.Uix UI DSL,
  providing functions for processing HEEX markup and managing component state.

  ## Key Features
  - Supports DSL block processing, normalization, and component registration for UI layout macros.
  - Manages unique identifier counters and component configuration for dynamic UI generation.

  """

  alias Aurora.Uix.Action

  require Logger

  @one_to_many_action_names :one_to_many |> Action.available_actions() |> Map.keys()

  @doc """
  Extracts the `:do` block from options while preserving other options.

  ## Parameters
  - `opts` (`keyword()`) - Options list that may contain a :do key.
  - `block` (`term()`) - Optional explicit block value.

  ## Returns
  `{block, opts}` (tuple()) - Extracted block and remaining options.
  """
  @spec extract_block_options(keyword() | list(), term()) :: tuple()
  def extract_block_options(opts, block \\ nil)

  def extract_block_options(opts, nil) do
    Keyword.pop(opts, :do, [])
  end

  def extract_block_options(opts, do: block) do
    {block, opts}
  end

  def extract_block_options([], block) when is_tuple(block) do
    {block, []}
  end

  def extract_block_options([], shifted_options) do
    {[], shifted_options}
  end

  def extract_block_options(opts, block) do
    block
    |> extract_block()
    |> then(&{&1, opts})
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
  @spec register_dsl_entry(
          atom(),
          atom(),
          keyword() | tuple() | nil,
          keyword(),
          any(),
          Macro.Env.t()
        ) ::
          Macro.t()
  def register_dsl_entry(tag, name, config, opts, do_block, env) do
    {block, opts} = extract_block_options(opts, do_block)

    inner_elements =
      case config do
        {:fields, fields} ->
          fields
          |> Enum.map(&create_field_tag(&1, env))
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
  @spec extract_block(keyword() | Macro.t() | list()) :: Macro.t()
  defp extract_block(nil), do: []
  defp extract_block(do: block), do: block
  defp extract_block(block), do: block

  # Creates a standardized field tag structure from various field specifications
  # Handles atom fields, tuple fields, and fields with options
  @spec create_field_tag(atom() | {atom(), keyword()}, Macro.Env.t()) :: map()
  defp create_field_tag(field, _env) when is_atom(field) do
    %{tag: :field, name: field, config: [], inner_elements: []}
  end

  defp create_field_tag({field_name, opts} = _field, env) when is_list(opts) do
    opts
    |> Enum.map(&process_field_tag_option(&1, env))
    |> then(&%{tag: :field, name: field_name, opts: &1, config: [], inner_elements: []})
  end

  defp create_field_tag(field, _env) when is_tuple(field) do
    %{tag: :field, name: field, config: [], inner_elements: []}
  end

  defp create_field_tag({field_name, opts}, _env) do
    %{tag: :field, name: field_name, config: opts, inner_elements: []}
  end

  @spec process_field_tag_option(Keyword.t(), Macro.Env.t()) :: Keyword.t()
  defp process_field_tag_option({action_name, {action_key, {:&, _, _} = function_component}}, env)
       when action_name in @one_to_many_action_names do
    env
    |> Code.env_for_eval()
    |> then(&Code.eval_quoted_with_env(function_component, [], &1))
    |> elem(0)
    |> then(&{action_name, {action_key, &1}})
  end

  defp process_field_tag_option(option, _env), do: option
end
