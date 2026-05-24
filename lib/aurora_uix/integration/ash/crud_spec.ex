defmodule Aurora.Uix.Integration.Ash.CrudSpec do
  @moduledoc """
  Defines the specification structure for Ash CRUD operations.

  Encapsulates the Ash resource, action, Aurora UIX action name, and the optional
  `socket.assigns` key that holds the runtime actor used to authorize policy-protected
  resources.

  ## Key Features

  - Stores Ash resource module references
  - Associates Ash actions with Aurora UIX action names
  - Enables structured function reference creation
  - Carries `:actor_assign` — the compile-time atom naming which `socket.assigns`
    key holds the actor, resolved at every CRUD call site by
    `Aurora.Uix.Integration.Ash.Crud.socket_opts/2`
  - Factory methods for convenient instantiation

  ## Key Constraints

  - At least `:resource` should be provided for meaningful usage
  - `:action` contains Ash action struct (Read, Create, Update, or Destroy) or
    a function reference (only valid in :ash_new_function option)
  - `:auix_action_name` maps to Aurora UIX action conventions (e.g., `:list_function`,
    `:get_function`)
  - `:actor_assign` is `nil` by default — no `actor:` is forwarded to Ash, preserving
    the previous behaviour for resources that do not use `Ash.Policy.Authorizer`

  See the [Ash integration guide — Authorization &amp; policies](ash_integration.html#authorization--policies)
  for the end-to-end worked example and the behaviour matrix.
  """

  @type t() :: %__MODULE__{
          resource: module() | nil,
          action: struct() | function() | nil,
          auix_action_name: atom() | nil,
          actor_assign: atom() | nil
        }

  defstruct [:resource, :action, :auix_action_name, :actor_assign]

  @doc """
  Creates an empty CrudSpec struct.

  ## Returns

  t() - A new empty `%CrudSpec{}` struct with all fields set to `nil`.

  ## Examples

      iex> new()
      %CrudSpec{resource: nil, action: nil, auix_action_name: nil, actor_assign: nil}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new CrudSpec struct with the specified values.

  ## Parameters

  - `resource` (module() | nil) - The Ash resource module.
  - `action` (struct() | nil) - The Ash action struct.
  - `auix_action_name` (atom() | nil) - The Aurora UIX action name.
  - `opts` (keyword()) - Optional extras:
    * `:actor_assign` (atom() | nil) - Name of the `socket.assigns` key that holds
      the actor. When set, `Aurora.Uix.Integration.Ash.Crud.socket_opts/2` extracts
      the actor from the socket and forwards it as `actor:` on every Ash call.

  ## Returns

  t() - A new `%CrudSpec{}` struct with the provided values.

  ## Examples

      iex> new(MyApp.User, %Ash.Resource.Actions.Read{}, :list_function)
      %CrudSpec{resource: MyApp.User,
        action: %Ash.Resource.Actions.Read{}, auix_action_name: :list_function,
        actor_assign: nil}

      iex> new(MyApp.User, %Ash.Resource.Actions.Read{}, :list_function,
      ...>   actor_assign: :current_user)
      %CrudSpec{resource: MyApp.User,
        action: %Ash.Resource.Actions.Read{}, auix_action_name: :list_function,
        actor_assign: :current_user}
  """
  @spec new(module() | nil, struct() | nil, atom() | nil, keyword()) :: t()
  def new(resource, action, auix_action_name, opts \\ []) do
    %__MODULE__{
      resource: resource,
      action: action,
      auix_action_name: auix_action_name,
      actor_assign: Keyword.get(opts, :actor_assign)
    }
  end
end
