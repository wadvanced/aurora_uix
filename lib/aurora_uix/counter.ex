defmodule Aurora.Uix.Counter do
  @moduledoc """
  Counter utility for generating unique component identifiers in Aurora UIX.

  Provides functions to start, increment, peek, and reset named or unnamed counters.

  ## Key Constraints
  - Counter names must be unique if using named counters.
  - All operations are process-safe via :atomics.
  - Not intended for general-purpose counting outside UIX internals.

  ## Key Features
  - Increment and retrieve the next value atomically
  - Peek at the current value without incrementing
  - Reset counters to a specific value

  ## Example
  ```elixir
  # Start a named counter
  Aurora.Uix.Counter.start_counter(:my_counter, 100)

  # Get the next value
  Aurora.Uix.Counter.next_count(:my_counter)
  # => 101

  # Peek at the current value
  Aurora.Uix.Counter.peek_count(:my_counter)
  # => 101

  # Reset the counter
  Aurora.Uix.Counter.reset_count(:my_counter, 50)
  # => :my_counter
  ```
  """

  @doc """
  Initializes a new counter for generating unique component identifiers.

  ## Parameters
  - `name` (atom() | binary() | nil) - Counter identifier. If `nil`, an unnamed agent is started and its PID is returned.
  - `initial` (integer()) - Starting value for the counter.

  ## Returns
  `atom()` | `binary()` | `:atomics.atomics_ref()` - Counter reference (name or PID).

  ## Examples
  ```elixir
  Aurora.Uix.Counter.start_counter(:my_counter, 10)
  # => :my_counter

  Aurora.Uix.Counter.start_counter(nil, 5)
  # => #PID<...>
  ```
  """
  @spec start_counter(atom() | binary() | :atomics.atomics_ref() | nil, integer()) ::
          atom() | binary() | :atomics.atomics_ref()
  def start_counter(ref \\ nil, initial \\ 0)

  def start_counter(nil, initial) do
    counter_ref = create_new_counter(initial)
    :persistent_term.put(counter_ref, counter_ref)
    counter_ref
  end

  def start_counter(ref, initial), do: reset_count(ref, initial)

  @doc """
  Increments and returns the next value for a counter.

  ## Parameters
  - `name` (atom() | :atomics.atomics_ref() | {atom(), term()} | {:via, atom(), term()}) - Counter reference.

  ## Returns
  `integer()` - Next counter value.

  ## Examples
  ```elixir
  Aurora.Uix.Counter.next_count(:my_counter)
  # => 11
  Aurora.Uix.Counter.next_count(self())
  # => 1
  ```
  """
  @spec next_count(atom() | :atomics.atomics_ref() | {atom(), term()} | {:via, atom(), term()}) ::
          integer()
  def next_count(ref) do
    ref
    |> get_counter()
    |> :atomics.add_get(1, 1)
  end

  @doc """
  Returns the current counter value without incrementing.

  ## Parameters
  - `name` (atom() | binary()) - Counter reference.

  ## Returns
  `integer()` - Current counter value.

  ## Examples
  ```elixir
  Aurora.Uix.Counter.peek_count(:my_counter)
  # => 11
  Aurora.Uix.Counter.peek_count(self())
  # => 1
  ```
  """
  @spec peek_count(atom() | binary()) :: integer()
  def peek_count(ref) do
    ref
    |> get_counter()
    |> :atomics.get(1)
  end

  @doc """
  Resets a counter to a specified value.

  ## Parameters
  - `name` (atom() | binary() | :atomics.atomics_ref()) - Counter reference.
  - `initial` (integer()) - Value to reset the counter to.

  ## Returns
  `atom()` | `binary()` | `:atomics.atomics_ref()` - Counter reference (name or PID).

  ## Examples
  ```elixir
  Aurora.Uix.Counter.reset_count(:my_counter, 0)
  # => :my_counter
  Aurora.Uix.Counter.reset_count(self(), 42)
  # => self()
  ```
  """
  @spec reset_count(atom() | binary() | :atomics.atomics_ref(), integer()) ::
          atom() | binary() | :atomics.atomics_ref()
  def reset_count(ref, initial) do
    counter_ref = get_counter(ref)
    :atomics.put(counter_ref, 1, initial)
    counter_ref
  end

  @spec get_counter(atom() | binary() | :atomics.atomics_ref()) :: :atomics.atomics_ref()
  defp get_counter(ref) do
    case :persistent_term.get(ref, :undefined) do
      :undefined ->
        counter_ref = create_new_counter()
        :persistent_term.put(ref, counter_ref)
        counter_ref

      counter_ref ->
        counter_ref
    end
  end

  @spec create_new_counter() :: :atomics.atomics_ref()
  defp create_new_counter, do: :millisecond |> System.system_time() |> create_new_counter()

  @spec create_new_counter(integer()) :: :atomics.atomics_ref()
  defp create_new_counter(initial) do
    ref = :atomics.new(1, signed: false)
    :atomics.put(ref, 1, initial)

    ref
  end
end
