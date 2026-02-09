defmodule Aurora.Uix.Integration.Ctx.CrudSpec do
  @moduledoc """
  Defines the specification structure for Context-based CRUD operations.

  Encapsulates a function reference and its associated Aurora UIX action name for
  Context-based (Ecto) CRUD operations. This structure serves as a lightweight
  configuration container for custom context function references.

  ## Key Features

  - Stores function references for Context-based operations
  - Associates functions with Aurora UIX action names
  - Enables polymorphic dispatch in the integration layer
  - Factory methods for convenient instantiation

  ## Key Constraints

  - `:function_spec` should be a valid function reference with appropriate arity
  - `:auix_action_name` maps to Aurora UIX action conventions
  - Used in conjunction with `Aurora.Uix.Integration.Connector` for backend routing
  """

  @type t() :: %__MODULE__{
          function_spec: function() | nil,
          auix_action_name: atom() | nil
        }

  defstruct [:function_spec, :auix_action_name]

  @doc """
  Creates an empty CrudSpec struct.

  ## Returns

  t() - A new empty CrudSpec struct with all fields set to `nil`.

  ## Examples

      iex> new()
      %CrudSpec{function_spec: nil, auix_action_name: nil}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new CrudSpec struct with the specified function and action name.

  ## Parameters

  - `function_spec` (function() | nil) - The function reference to invoke.
  - `auix_action_name` (atom() | nil) - The Aurora UIX action name.

  ## Returns

  t() - A new CrudSpec struct with the provided values.

  ## Examples

      iex> new(&MyContext.list_users/1, :list_function)
      %CrudSpec{function_spec: &MyContext.list_users/1, auix_action_name: :list_function}

      iex> new(&MyContext.get_user/2, :get_function)
      %CrudSpec{function_spec: &MyContext.get_user/2, auix_action_name: :get_function}
  """
  @spec new(function() | nil, atom() | nil) :: t()
  def new(function_spec, auix_action_name) do
    %__MODULE__{
      function_spec: function_spec,
      auix_action_name: auix_action_name
    }
  end
end
