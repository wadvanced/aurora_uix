defmodule Aurora.Uix.CounterAgent do
  @moduledoc """
  Agent-based counter utility for generating unique component identifiers in Aurora UIX.

  Provides functions to start, increment, peek, and reset named or unnamed counters.
  """
  use Agent

  require Logger

  @doc """
  Initializes the agent state. Used internally by the Agent behaviour.

  ## Parameters
  - _args (term()) - Arguments for initialization (unused)

  ## Returns
  - {:ok, module()} - Tuple with module reference
  """
  @spec init(term()) :: {:ok, module()}
  def init(_args), do: {:ok, __MODULE__}

  @doc """
  Starts the default counter agent with the name :auix_fields.

  ## Parameters
  - _ (term()) - Arguments for starting the agent (unused)

  ## Returns
  - {:ok, pid()} | {:error, term()} - Result of starting the agent
  """
  @spec start_link(term()) :: {:ok, pid()} | {:error, term()}
  def start_link(_) do
    Agent.start_link(fn -> 0 end, name: :auix_fields)
  end

  @doc """
  Initializes a new counter for generating unique component identifiers.

  ## Parameters
  - name (binary() | atom() | nil) - Counter identifier
  - initial (integer()) - Starting value for the counter

  ## Returns
  - binary() | atom() | pid() - Counter reference
  """
  @spec start_counter(binary() | atom() | nil, integer()) :: binary() | atom() | pid()
  def start_counter(name \\ nil, initial \\ 0)

  def start_counter(nil, initial) do
    case Agent.start_link(fn -> initial end) do
      {:ok, pid} ->
        pid

      {:error, {:already_started, _}} ->
        Logger.warning("Counter was previously started")
        reset_count(nil, initial)
    end
  end

  def start_counter(name, initial) do
    case Agent.start_link(fn -> initial end, name: name) do
      {:ok, _} ->
        name

      {:error, {:already_started, _}} ->
        Logger.warning("Counter named: `#{name}`, was previously started")
        name
    end
  end

  @doc """
  Increments and returns the next value for a counter.

  ## Parameters
  - name (atom() | pid() | {atom(), any()} | {:via, atom(), any()}) - Counter reference

  ## Returns
  - integer() - Next counter value
  """
  @spec next_count(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: integer()
  def next_count(name) do
    Agent.get_and_update(name, fn state -> {state + 1, state + 1} end)
  end

  @doc """
  Returns the current counter value without incrementing.

  ## Parameters
  - name (binary() | atom()) - Counter reference

  ## Returns
  - integer() - Current counter value
  """
  @spec peek_count(binary() | atom()) :: integer()
  def peek_count(name) do
    Agent.get(name, fn state -> state end)
  end

  @doc """
  Resets a counter to a specified value.

  ## Parameters
  - name (binary() | atom() | pid()) - Counter reference
  - initial (integer()) - Value to reset the counter to

  ## Returns
  - binary() | atom() | pid() - Counter reference
  """
  @spec reset_count(binary() | atom() | pid(), integer()) :: binary() | atom() | pid()
  def reset_count(name, initial) do
    Agent.get_and_update(name, fn _state -> {name, initial} end)
  end
end
