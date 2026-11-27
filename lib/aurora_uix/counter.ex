defmodule Aurora.Uix.Counter do
  @moduledoc """
  Counters generating unique identifiers inside Aurora UIX.

  ## Key Constraints
  - A counter is found by its name, any term; it is stored in `:persistent_term`.
  - Not intended for general-purpose counting outside UIX internals.

  ## Key Features
  - Increment and retrieve the next value atomically, through `:atomics`
  - Peek at the current value without incrementing
  - Reset a counter to a value

  A name used for the first time by `next_count/1` or `peek_count/1` starts at the current system
  time in milliseconds.

  ## Example
  ```elixir
  Aurora.Uix.Counter.start_counter(:my_counter, 100)
  #=> a reference to the counter

  Aurora.Uix.Counter.next_count(:my_counter)
  #=> 101

  Aurora.Uix.Counter.peek_count(:my_counter)
  #=> 101
  ```
  """

  @doc """
  Initializes a new counter for generating unique component identifiers.

  ## Parameters
  - `ref` (atom() | binary() | :atomics.atomics_ref() | nil) - Counter name. With `nil`, an
    unnamed counter is created.
  - `initial` (integer()) - Starting value. An unnamed counter keeps it.

  ## Returns
  `:atomics.atomics_ref()` - The counter reference.

  ## Examples
  ```elixir
  Aurora.Uix.Counter.start_counter(:my_counter, 10)
  #=> a reference

  Aurora.Uix.Counter.start_counter(nil, 5)
  #=> a reference
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
  - `ref` (term()) - Counter name or reference.

  ## Returns
  `integer()` - Next counter value.

  ## Examples
  ```elixir
  Aurora.Uix.Counter.start_counter(:my_counter, 10)
  Aurora.Uix.Counter.next_count(:my_counter)
  #=> 11
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
  - `ref` (atom() | binary()) - Counter name or reference.

  ## Returns
  `integer()` - Current counter value.

  ## Examples
  ```elixir
  Aurora.Uix.Counter.peek_count(:my_counter)
  #=> 11
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
  - `ref` (atom() | binary() | :atomics.atomics_ref()) - Counter name or reference.
  - `initial` (integer()) - Value to reset the counter to.

  ## Returns
  `:atomics.atomics_ref()` - The counter reference.

  ## Examples
  ```elixir
  Aurora.Uix.Counter.reset_count(:my_counter, 0)
  #=> a reference
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
