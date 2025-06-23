defmodule Aurora.Uix.CounterAgent do
  @moduledoc """
  Provides process-safe, agent-based counters for generating unique component identifiers in Aurora UIX.

  ## Purpose
  - Start, increment, peek, and reset named or unnamed counters for UI component identification.
  - Ensure unique identifiers across dynamic or concurrent operations in Aurora UIX.

  ## Key Constraints
  - Counter names must be unique if using named counters.
  - All operations are process-safe via Elixir's Agent.
  - Not intended for general-purpose counting outside UIX internals.

  ## Features
  - Start a default or named counter agent
  - Increment and retrieve the next value atomically
  - Peek at the current value without incrementing
  - Reset counters to a specific value

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
  - `_args` (term()) - Arguments for initialization (unused).

  ## Returns
  `{:ok, module()}` - Tuple with module reference.
  """
  @spec init(term()) :: {:ok, module()}
  def init(_args), do: {:ok, __MODULE__}

  @doc """
  Starts the default counter agent with the name `:auix_fields`.

  ## Parameters
  - `_` (term()) - Arguments for starting the agent (unused).

  ## Returns
  `{:ok, pid()}` | `{:error, term()}` - Result of starting the agent.

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.start_link(nil)
  # => {:ok, #PID<...>}
  Aurora.Uix.CounterAgent.start_link(:ignored)
  # => {:error, {:already_started, #PID<...>}}
  ```
  """
  @spec start_link(term()) :: {:ok, pid()} | {:error, term()}
  def start_link(_) do
    Agent.start_link(fn -> 0 end, name: :auix_fields)
  end

  @doc """
  Initializes a new counter for generating unique component identifiers.

  ## Parameters
  - `name` (atom() | binary() | nil) - Counter identifier. If `nil`, an unnamed agent is started and its PID is returned.
  - `initial` (integer()) - Starting value for the counter.

  ## Returns
  `atom()` | `binary()` | `pid()` - Counter reference (name or PID).

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.start_counter(:my_counter, 10)
  # => :my_counter

  Aurora.Uix.CounterAgent.start_counter(nil, 5)
  # => #PID<...>
  ```
  """
  @spec start_counter(atom() | binary() | nil, integer()) :: atom() | binary() | pid()
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
  - `name` (atom() | pid() | {atom(), term()} | {:via, atom(), term()}) - Counter reference.

  ## Returns
  `integer()` - Next counter value.

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.next_count(:my_counter)
  # => 11
  Aurora.Uix.CounterAgent.next_count(self())
  # => 1
  ```
  """
  @spec next_count(atom() | pid() | {atom(), term()} | {:via, atom(), term()}) :: integer()
  def next_count(name) do
    Agent.get_and_update(name, fn state -> {state + 1, state + 1} end)
  end

  @doc """
  Returns the current counter value without incrementing.

  ## Parameters
  - `name` (atom() | binary()) - Counter reference.

  ## Returns
  `integer()` - Current counter value.

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.peek_count(:my_counter)
  # => 11
  Aurora.Uix.CounterAgent.peek_count(self())
  # => 1
  ```
  """
  @spec peek_count(atom() | binary()) :: integer()
  def peek_count(name) do
    Agent.get(name, fn state -> state end)
  end

  @doc """
  Resets a counter to a specified value.

  ## Parameters
  - `name` (atom() | binary() | pid()) - Counter reference.
  - `initial` (integer()) - Value to reset the counter to.

  ## Returns
  `atom()` | `binary()` | `pid()` - Counter reference (name or PID).

  ## Examples
  ```elixir
  Aurora.Uix.CounterAgent.reset_count(:my_counter, 0)
  # => :my_counter
  Aurora.Uix.CounterAgent.reset_count(self(), 42)
  # => self()
  ```
  """
  @spec reset_count(atom() | binary() | pid(), integer()) :: atom() | binary() | pid()
  def reset_count(name, initial) do
    Agent.get_and_update(name, fn _state -> {name, initial} end)
  end
end
