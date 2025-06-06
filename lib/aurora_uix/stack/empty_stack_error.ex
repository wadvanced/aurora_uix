defmodule Aurora.Uix.Stack.EmptyStackError do
  @moduledoc """
  Exception raised when attempting to perform operations on an empty stack.
  """

  @type t() :: %__MODULE__{message: String.t()}
  defexception message: "Stack is empty"
end
