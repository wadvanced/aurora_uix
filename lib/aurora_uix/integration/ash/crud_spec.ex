defmodule Aurora.Uix.Integration.Ash.CrudSpec do
  @moduledoc """
  Defines the specification structure for Ash CRUD operations.

  Encapsulates the Ash domain, resource, action, and Aurora UIX action name required
  for generating function references in the integration layer. This structure serves
  as a configuration container for Ash-based CRUD operations.

  ## Key Features

  - Stores Ash domain and resource module references
  - Associates Ash actions with Aurora UIX action names
  - Supports domain-only or domain-resource configurations
  - Enables structured function reference creation
  - Factory methods for convenient instantiation

  ## Key Constraints

  - At least one of `:domain` or `:resource` should be provided for meaningful usage
  - `:action` contains Ash action struct (Read, Create, Update, or Destroy)
  - `:auix_action_name` maps to Aurora UIX action conventions (e.g., `:list_function`,
    `:get_function`)
  """

  @type t() :: %__MODULE__{
          domain: module() | nil,
          resource: module() | nil,
          action: struct() | nil,
          auix_action_name: atom() | nil
        }

  defstruct [:domain, :resource, :action, :auix_action_name]

  @doc """
  Creates an empty CrudSpec struct.

  ## Returns

  t() - A new empty CrudSpec struct with all fields set to `nil`.

  ## Examples

      iex> new()
      %CrudSpec{domain: nil, resource: nil, action: nil, auix_action_name: nil}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new CrudSpec struct with the specified values.

  ## Parameters

  - `domain` (module() | nil) - The Ash domain module.
  - `resource` (module() | nil) - The Ash resource module.
  - `action` (struct() | nil) - The Ash action struct.
  - `auix_action_name` (atom() | nil) - The Aurora UIX action name.

  ## Returns

  t() - A new CrudSpec struct with the provided values.

  ## Examples

      iex> new(MyApp.Accounts, MyApp.User, %Ash.Resource.Actions.Read{}, :list_function)
      %CrudSpec{domain: MyApp.Accounts, resource: MyApp.User,
        action: %Ash.Resource.Actions.Read{}, auix_action_name: :list_function}
  """
  @spec new(module() | nil, module() | nil, struct() | nil, atom() | nil) :: t()
  def new(domain, resource, action, auix_action_name) do
    %__MODULE__{
      domain: domain,
      resource: resource,
      action: action,
      auix_action_name: auix_action_name
    }
  end
end
