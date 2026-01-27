defmodule Aurora.Uix.Integration.Connector do
  @moduledoc """
  Defines the integration connector structure for backend implementations.

  Represents the type of backend connector for crud operations and its associated crud_spec, 
  enabling polymorphic dispatch across different integration backends (Ash Framework or
  Context-based implementations).

  ## Key Features

  - Type-based backend identification (`:ash` or `:ctx`)
  - Flexible crud_spec storage for backend-specific configurations
  - Support for pattern matching on connector types

  ## Key Constraints

  - Type must be one of: `:ash`, `:ctx`, or `nil`
  - Definition structure varies based on connector type
  """

  @type t() :: %__MODULE__{
          type: :ash | :ctx | nil,
          crud_spec: term()
        }

  @enforce_keys [:type]
  defstruct [:type, :crud_spec]

  @doc """
  Creates a new Connector struct with the given crud_spec and type.

  ## Parameters

  - `crud_spec` (term()) - The backend-specific configuration or crud_spec data.
  - `type` (atom()) - The connector type (`:ash` or `:ctx`).

  ## Returns

  t() - A new Connector struct.

  ## Examples

      iex> new(%{action: :read, domain: MyApp.Domain}, :ash)
      %Connector{type: :ash, crud_spec: %{action: :read, domain: MyApp.Domain}}

      iex> new(%{context: MyApp.Context}, :ctx)
      %Connector{type: :ctx, crud_spec: %{context: MyApp.Context}}
  """
  @spec new(term(), atom()) :: t()
  def new(crud_spec, type) when is_atom(type) do
    %__MODULE__{type: type, crud_spec: crud_spec}
  end
end
