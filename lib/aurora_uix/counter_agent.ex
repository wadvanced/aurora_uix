defmodule Aurora.Uix.CounterAgent do
  @moduledoc """
  Agent-based counter utility for generating unique component identifiers in Aurora UIX.

  This module provides functions to start, increment, peek, and reset named or unnamed counters using Elixir's `Agent`.
  It is designed to help generate unique identifiers for UI components, ensuring no collisions across dynamic or concurrent operations.

  ## Features
  - Start a default or named counter agent
  - Increment and retrieve the next value atomically
  - Peek at the current value without incrementing
  - Reset counters to a specific value

  ## Constraints
  - Counter names must be unique if using named counters
  - All operations are process-safe via Agent

  ## Example
  ```elixir
  # Start a named counter
  Aurora.Uix.CounterAgent.start_counter(:my_counter, 100)

  # Get the next value
  Aurora.Uix.CounterAgent.next_count(:my_counter)
  # => 101

  # Peek at the current value
  Aurora.Uix.CounterAgent.peek_count(:my_counter)
  # => 101

  # Reset the counter
  Aurora.Uix.CounterAgent.reset_count(:my_counter, 50)
  # => :my_counter
  ```
  """
  use Agent

  require Logger

  @doc """
  Initializes the agent state. Used internally by the Agent behaviour.

  ## Parameters
  - _args (term()) - Arguments for initialization (unused).

  ## Returns
  - `{:ok, module()}` - Tuple with module reference.
  """
  @spec init(term()) :: {:ok, module()}
  def init(_args), do: {:ok, __MODULE__}

  @doc """
  Starts the default counter agent with the name `:auix_fields`.

  ## Parameters
  - _ (term()) - Arguments for starting the agent (unused).

  ## Returns
  - `{:ok, pid()} | {:error, term()}` - Result of starting the agent.

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.start_link(nil)
  # => {:ok, #PID<...>}
  ```
  """
  @spec start_link(term()) :: {:ok, pid()} | {:error, term()}
  def start_link(_) do
    Agent.start_link(fn -> 0 end, name: :auix_fields)
  end

  @doc """
  Initializes a new counter for generating unique component identifiers.

  ## Parameters
  - name (binary() | atom() | nil) - Counter identifier. If `nil`, an unnamed agent is started and its PID is returned.
  - initial (integer()) - Starting value for the counter.

  ## Returns
  - `binary() | atom() | pid()` - Counter reference (name or PID).

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.start_counter(:my_counter, 10)
  # => :my_counter

  Aurora.Uix.CounterAgent.start_counter(nil, 5)
  # => #PID<...>
  ```
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
  - name (atom() | pid() | {atom(), any()} | {:via, atom(), any()}) - Counter reference.

  ## Returns
  - `integer()` - Next counter value.

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.next_count(:my_counter)
  # => 11
  ```
  """
  @spec next_count(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: integer()
  def next_count(name) do
    Agent.get_and_update(name, fn state -> {state + 1, state + 1} end)
  end

  @doc """
  Returns the current counter value without incrementing.

  ## Parameters
  - name (binary() | atom()) - Counter reference.

  ## Returns
  - `integer()` - Current counter value.

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.peek_count(:my_counter)
  # => 11
  ```
  """
  @spec peek_count(binary() | atom()) :: integer()
  def peek_count(name) do
    Agent.get(name, fn state -> state end)
  end

  @doc """
  Resets a counter to a specified value.

  ## Parameters
  - name (binary() | atom() | pid()) - Counter reference.
  - initial (integer()) - Value to reset the counter to.

  ## Returns
  - `binary() | atom() | pid()` - Counter reference (name or PID).

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.reset_count(:my_counter, 0)
  # => :my_counter
  ```
  """
  @spec reset_count(binary() | atom() | pid(), integer()) :: binary() | atom() | pid()
  def reset_count(name, initial) do
    Agent.get_and_update(name, fn _state -> {name, initial} end)
  end
end
