defmodule Aurora.Uix.Stack do
  @moduledoc """
  Provides a stack data structure implementation with standard stack operations: push, pop, peek, and empty checks.
  Includes both safe (error tuple) and bang (raising) variants of operations.
  """

  alias Aurora.Uix.Stack.EmptyStackError

  defstruct values: []

  @type t() :: %__MODULE__{
          values: list(term())
        }

  @doc """
  Creates a new empty stack.

  Returns:
    - __MODULE__.t() - An empty stack
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a new stack with initial value(s).

  Parameters:
    - value: term() | list(term()) - A single value or list of values to initialize the stack

  Returns:
    - t() - A stack containing the value(s)
  """
  @spec new(any()) :: t()
  def new(values) when is_list(values) do
    %__MODULE__{values: values}
  end

  def new(value) do
    %__MODULE__{values: [value]}
  end

  @doc """
  Pushes a new value onto the top of the stack.

  Parameters:
    - stack: __MODULE__.t() - The stack to push onto
    - value: term() - The value to push

  Returns:
    - __MODULE__.t() - A stack with the value pushed on top
  """
  @spec push(t(), any()) :: t()
  def push(stack, value) do
    %__MODULE__{
      values: [value | stack.values]
    }
  end

  @doc """
  Replaces the top value of the stack with a new value.

  Parameters:
    - stack: __MODULE__.t() - The stack to modify
    - value: term() - The new value to replace the top value with

  Returns:
    - __MODULE__.t() - A stack with the top value replaced

  Raises:
    - EmptyStackError - When the stack is empty
  """
  @spec push_replace(t(), any()) :: t()
  def push_replace(%__MODULE__{} = stack, value) do
    stack
    |> pop!()
    |> elem(0)
    |> push(value)
  end

  @doc """
  Returns the top value of the stack.

  Parameters:
    - stack: `Aurora.Uix.Stack.t()` - The stack to peek

  Returns:
    - term() - The top value of the stack

  Raises:
    - EmptyStackError - When the stack is empty
  """
  @spec peek!(__MODULE__.t()) :: any()
  def peek!(%__MODULE__{values: []}), do: raise(EmptyStackError)

  def peek!(%__MODULE__{values: [head | _tail]}), do: head

  @doc """
  Returns the top value of the stack in a safe way.

  Parameters:
    - stack: `Aurora.Uix.Stack.t()` - The stack to peek

  Returns:
    - `{:ok, term()}` - A tuple with :ok and the top value if stack is not empty
    - `{:error, Aurora.Uix.Stack.t()}` - A tuple with :error and the stack if empty
  """
  @spec peek(__MODULE__.t()) :: {:ok, any()} | {:error, __MODULE__.t()}
  def peek(%__MODULE__{values: []} = stack), do: {:error, stack}

  def peek(%__MODULE__{values: [head | _tail]}), do: {:ok, head}

  @doc """
  Removes and returns the top value from the stack.

  Parameters:
    - stack: `Aurora.Uix.Stack.t()` - The stack to pop from

  Returns:
    - `{Aurora.Uix.Stack.t(), term()}` - A tuple with the new stack and the popped value

  Raises:
    - EmptyStackError - When the stack is empty
  """
  @spec pop!(__MODULE__.t()) :: {__MODULE__.t(), term()}
  def pop!(%__MODULE__{values: []}), do: raise(EmptyStackError)

  def pop!(%__MODULE__{values: [head | tail]}), do: {%__MODULE__{values: tail}, head}

  @doc """
  Removes and returns the top value from the stack in a safe way.

  ## Parameters
    - `stack` - `Aurora.Uix.Stack.t()` - The stack to pop from

  ## Returns
    - `{:ok, Aurora.Uix.Stack.t(), term()}` - A tuple with `:ok`, the new stack, and the popped value if not empty
    - `{:error, Aurora.Uix.Stack.t()}` - A tuple with `:error` and the stack if empty
  """
  @spec pop(__MODULE__.t()) :: {:ok, __MODULE__.t(), term()} | {:error, __MODULE__.t()}
  def pop(%__MODULE__{values: []} = stack), do: {:error, stack}

  def pop(%__MODULE__{values: [head | tail]}), do: {:ok, %__MODULE__{values: tail}, head}

  @doc """
  Checks if the stack is empty.

  Parameters:
    - stack: __MODULE__.t() - The stack to check

  Returns:
    - boolean() - true if stack is empty, false otherwise
  """
  @spec empty?(__MODULE__.t()) :: boolean
  def empty?(%__MODULE__{values: []}), do: true
  def empty?(_stack), do: false
end
