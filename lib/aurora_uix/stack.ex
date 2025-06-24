defmodule Aurora.Uix.Stack do
  @moduledoc """
  Provides a stack data structure implementation with standard stack operations: push, pop, peek, and empty checks.
  Includes both safe (error tuple) and bang (raising) variants of operations.

  ## Key Features
  - Implements push, pop, peek, and empty checks for stack-based algorithms.
  - Supports both safe (error tuple) and bang (raising) variants of operations.

  ## Key Constraints
  - Not intended for general-purpose use outside Aurora UIX internals.
  - Raises Aurora.Uix.Stack.EmptyStackError on invalid bang operations.
  """

  alias Aurora.Uix.Stack.EmptyStackError

  defstruct values: []

  @type t() :: %__MODULE__{
          values: list(term())
        }

  @doc """
  Creates a new empty stack.

  ## Returns
  `Aurora.Uix.Stack.t()` - An empty stack.

  ## Examples
  ```elixir
  Aurora.Uix.Stack.new()
  # => %Aurora.Uix.Stack{values: []}
  ```
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a new stack with initial value(s).

  ## Parameters
  - `values` (`list(term())` | `term()`) - A single value or list of values to initialize the stack.

  ## Returns
  `Aurora.Uix.Stack.t()` - A stack containing the value(s).

  ## Examples
  ```elixir
  Aurora.Uix.Stack.new([1, 2, 3])
  # => %Aurora.Uix.Stack{values: [1, 2, 3]}
  Aurora.Uix.Stack.new(:foo)
  # => %Aurora.Uix.Stack{values: [:foo]}
  ```
  """
  @spec new(list(term())) :: t()
  @spec new(term()) :: t()
  def new(values) when is_list(values) do
    %__MODULE__{values: values}
  end

  def new(value) do
    %__MODULE__{values: [value]}
  end

  @doc """
  Pushes a new value onto the top of the stack.

  ## Parameters
  - `stack` (`Aurora.Uix.Stack.t()`) - The stack to push onto.
  - `value` (`term()`) - The value to push.

  ## Returns
  `Aurora.Uix.Stack.t()` - A stack with the value pushed on top.

  ## Examples
  ```elixir
  stack = Aurora.Uix.Stack.new([1, 2])
  Aurora.Uix.Stack.push(stack, 3)
  # => %Aurora.Uix.Stack{values: [3, 1, 2]}
  ```
  """
  @spec push(t(), term()) :: t()
  def push(stack, value) do
    %__MODULE__{
      values: [value | stack.values]
    }
  end

  @doc """
  Replaces the top value of the stack with a new value.

  ## Parameters
  - `stack` (`Aurora.Uix.Stack.t()`) - The stack to modify.
  - `value` (`term()`) - The new value to replace the top value with.

  ## Returns
  `Aurora.Uix.Stack.t()` - A stack with the top value replaced.

  ## Raises
  Aurora.Uix.Stack.EmptyStackError - When the stack is empty.

  ## Examples
  ```elixir
  stack = Aurora.Uix.Stack.new([1, 2])
  Aurora.Uix.Stack.push_replace(stack, :foo)
  # => %Aurora.Uix.Stack{values: [:foo, 2]}
  ```
  """
  @spec push_replace(t(), term()) :: t()
  def push_replace(%__MODULE__{} = stack, value) do
    stack
    |> pop!()
    |> elem(0)
    |> push(value)
  end

  @doc """
  Returns the top value of the stack.

  ## Parameters
  - `stack` (`Aurora.Uix.Stack.t()`) - The stack to peek.

  ## Returns
  `term()` - The top value of the stack.

  ## Raises
  Aurora.Uix.Stack.EmptyStackError - When the stack is empty.

  ## Examples
  ```elixir
  stack = Aurora.Uix.Stack.new([:a, :b])
  Aurora.Uix.Stack.peek!(stack)
  # => :a
  ```
  """
  @spec peek!(t()) :: term()
  def peek!(%__MODULE__{values: []}), do: raise(EmptyStackError)

  def peek!(%__MODULE__{values: [head | _tail]}), do: head

  @doc """
  Returns the top value of the stack in a safe way.

  ## Parameters
  - `stack` (`Aurora.Uix.Stack.t()`) - The stack to peek.

  ## Returns
  `{:ok, term()}` | `{:error, Aurora.Uix.Stack.t()}` - Tuple with :ok and the top value if stack is not empty, or :error and the stack if empty.

  ## Examples
  ```elixir
  stack = Aurora.Uix.Stack.new([:a, :b])
  Aurora.Uix.Stack.peek(stack)
  # => {:ok, :a}
  Aurora.Uix.Stack.peek(Aurora.Uix.Stack.new())
  # => {:error, %Aurora.Uix.Stack{values: []}}
  ```
  """
  @spec peek(t()) :: {:ok, term()} | {:error, t()}
  def peek(%__MODULE__{values: []} = stack), do: {:error, stack}

  def peek(%__MODULE__{values: [head | _tail]}), do: {:ok, head}

  @doc """
  Removes and returns the top value from the stack.

  ## Parameters
  - `stack` (`Aurora.Uix.Stack.t()`) - The stack to pop from.

  ## Returns
  `{Aurora.Uix.Stack.t(), term()}` - Tuple with the new stack and the popped value.

  ## Raises
  Aurora.Uix.Stack.EmptyStackError - When the stack is empty.

  ## Examples
  ```elixir
  stack = Aurora.Uix.Stack.new([:a, :b])
  Aurora.Uix.Stack.pop!(stack)
  # => {%Aurora.Uix.Stack{values: [:b]}, :a}
  ```
  """
  @spec pop!(t()) :: {t(), term()}
  def pop!(%__MODULE__{values: []}), do: raise(EmptyStackError)

  def pop!(%__MODULE__{values: [head | tail]}), do: {%__MODULE__{values: tail}, head}

  @doc """
  Removes and returns the top value from the stack in a safe way.

  ## Parameters
  - `stack` (`Aurora.Uix.Stack.t()`) - The stack to pop from.

  ## Returns
  `{:ok, Aurora.Uix.Stack.t(), term()}` | `{:error, Aurora.Uix.Stack.t()}` - Tuple with :ok, the new stack, and the popped value if not empty, or :error and the stack if empty.

  ## Examples
  ```elixir
  stack = Aurora.Uix.Stack.new([:a, :b])
  Aurora.Uix.Stack.pop(stack)
  # => {:ok, %Aurora.Uix.Stack{values: [:b]}, :a}
  Aurora.Uix.Stack.pop(Aurora.Uix.Stack.new())
  # => {:error, %Aurora.Uix.Stack{values: []}}
  ```
  """
  @spec pop(t()) :: {:ok, t(), term()} | {:error, t()}
  def pop(%__MODULE__{values: []} = stack), do: {:error, stack}

  def pop(%__MODULE__{values: [head | tail]}), do: {:ok, %__MODULE__{values: tail}, head}

  @doc """
  Checks if the stack is empty.

  ## Parameters
  - `stack` (`Aurora.Uix.Stack.t()`) - The stack to check.

  ## Returns
  `boolean()` - true if stack is empty, false otherwise.

  ## Examples
  ```elixir
  Aurora.Uix.Stack.empty?(Aurora.Uix.Stack.new())
  # => true
  Aurora.Uix.Stack.empty?(Aurora.Uix.Stack.new([1]))
  # => false
  ```
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{values: []}), do: true
  def empty?(_stack), do: false
end
