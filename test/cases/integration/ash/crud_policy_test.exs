defmodule Aurora.Uix.Integration.Ash.CrudPolicyTest.Domain do
  @moduledoc false
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(Aurora.Uix.Integration.Ash.CrudPolicyTest.Item)
  end
end

defmodule Aurora.Uix.Integration.Ash.CrudPolicyTest.Item do
  @moduledoc false
  use Ash.Resource,
    domain: Aurora.Uix.Integration.Ash.CrudPolicyTest.Domain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer]

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, public?: true, allow_nil?: false)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name])
    end

    update :update do
      accept([:name])
      primary?(true)
    end
  end

  policies do
    policy always() do
      authorize_if(actor_present())
    end
  end
end

defmodule Aurora.Uix.Integration.Ash.CrudPolicyTest do
  @moduledoc "Ash actors and policies: the Ash CRUD module, its socket options and the actor assign options."
  use ExUnit.Case, async: true

  alias Ash.Resource.Info, as: AshInfo
  alias Aurora.Uix.Integration.Ash.ContextParserDefaults
  alias Aurora.Uix.Integration.Ash.Crud, as: AshCrud
  alias Aurora.Uix.Integration.Ash.CrudPolicyTest.Item
  alias Aurora.Uix.Integration.Ash.CrudSpec
  alias Aurora.Uix.Integration.Connector
  alias Aurora.Uix.Templates.Basic.Helpers
  alias Aurora.Uix.Test.MirrorAsh.ProductLocation

  @actor %{id: "actor-1"}

  @auix_action_keys [
    :list_function,
    :list_function_paginated,
    :get_function,
    :create_function,
    :update_function,
    :delete_function,
    :change_function,
    :new_function
  ]

  @spec list_spec() :: CrudSpec.t()
  defp list_spec do
    %CrudSpec{
      resource: Item,
      action: primary_action!(Item, :read),
      auix_action_name: :list_function,
      actor_assign: :current_user
    }
  end

  @spec create_spec() :: CrudSpec.t()
  defp create_spec do
    %CrudSpec{
      resource: Item,
      action: %{name: :create},
      auix_action_name: :create_function,
      actor_assign: :current_user
    }
  end

  @spec update_spec() :: CrudSpec.t()
  defp update_spec do
    %CrudSpec{
      resource: Item,
      action: %{name: :update},
      auix_action_name: :update_function,
      actor_assign: :current_user
    }
  end

  @spec delete_spec() :: CrudSpec.t()
  defp delete_spec do
    %CrudSpec{
      resource: Item,
      action: %{name: :destroy},
      auix_action_name: :delete_function,
      actor_assign: :current_user
    }
  end

  @spec primary_action!(module(), atom()) :: struct() | nil
  defp primary_action!(resource, type) do
    resource
    |> AshInfo.actions()
    |> Enum.find(&(&1.type == type and &1.primary?))
  end

  @spec ash_connector_with_actor(atom() | nil) :: Connector.t()
  defp ash_connector_with_actor(assign_key) do
    %Connector{type: :ash, crud_spec: %CrudSpec{actor_assign: assign_key}}
  end

  test "Ash CRUD runs with an actor and returns Forbidden without one" do
    {:ok, _item} = AshCrud.create(create_spec(), %{name: "visible"}, actor: @actor)

    results = AshCrud.list(list_spec(), actor: @actor)
    assert is_list(results.entries)
    assert Enum.any?(results.entries, &(&1.name == "visible"))
    assert AshCrud.list(list_spec(), []) == []

    assert {:ok, item} = AshCrud.create(create_spec(), %{name: "ok"}, actor: @actor)
    assert item.name == "ok"

    assert {:error, %Ash.Error.Forbidden{}} =
             AshCrud.create(create_spec(), %{name: "blocked"}, [])

    assert {:ok, updated} =
             AshCrud.update(update_spec(), item, %{name: "renamed"}, actor: @actor)

    assert updated.name == "renamed"

    assert {:error, %Ash.Error.Forbidden{}} =
             AshCrud.update(update_spec(), item, %{name: "renamed"}, [])

    assert {:error, %Ash.Error.Forbidden{}} = AshCrud.delete(delete_spec(), item, [])
    assert {:ok, _} = AshCrud.delete(delete_spec(), item, actor: @actor)
  end

  test "socket_opts/2 resolves the actor from the socket assigns" do
    {:ok, _item} = AshCrud.create(create_spec(), %{name: "from-handler"}, actor: @actor)

    socket_opts = AshCrud.socket_opts(list_spec(), %{assigns: %{current_user: @actor}})
    results = AshCrud.list(list_spec(), socket_opts)
    assert Enum.any?(results.entries, &(&1.name == "from-handler"))

    empty_opts = AshCrud.socket_opts(list_spec(), %{assigns: %{}})
    assert empty_opts == []
    assert AshCrud.list(list_spec(), empty_opts) == []

    actor = %{id: 1, role: :admin}

    assert AshCrud.socket_opts(%CrudSpec{actor_assign: nil}, %{assigns: %{current_user: actor}}) ==
             []

    assert AshCrud.socket_opts(%CrudSpec{actor_assign: :current_user}, %{
             assigns: %{current_user: actor}
           }) == [actor: actor]

    assert AshCrud.socket_opts(%CrudSpec{actor_assign: :current_user}, %{
             assigns: %{current_user: nil}
           }) == []

    assert AshCrud.socket_opts(%CrudSpec{actor_assign: :current_user}, %{assigns: %{}}) == []

    assert AshCrud.socket_opts(%CrudSpec{actor_assign: :actor}, %{
             assigns: %{actor: %{id: 42}, current_user: %{id: 99}}
           }) == [actor: %{id: 42}]

    assert AshCrud.socket_opts(%{}, %{assigns: %{}}) == []
    assert AshCrud.socket_opts(nil, %{assigns: %{}}) == []

    assert Helpers.backend_socket_opts(%{assigns: %{current_user: %{id: 1}}}, nil) == []
    assert Helpers.backend_socket_opts(%{current_user: %{id: 1}}, nil) == []

    connector = ash_connector_with_actor(:current_user)

    assert Helpers.backend_socket_opts(%{assigns: %{current_user: %{id: 1}}}, connector) == [
             actor: %{id: 1}
           ]

    assert Helpers.backend_socket_opts(%{current_user: %{id: 1}}, connector) == [actor: %{id: 1}]

    assert Helpers.backend_socket_opts(
             %{assigns: %{current_user: %{id: 1}}},
             ash_connector_with_actor(nil)
           ) == []
  end

  test "CrudSpec and the actor assign options carry the actor assign" do
    assert %CrudSpec{actor_assign: nil} = CrudSpec.new()

    action = %{name: :read}
    spec = CrudSpec.new(MyApp.User, action, :list_function)
    assert spec.resource == MyApp.User
    assert spec.action == action
    assert spec.auix_action_name == :list_function
    assert spec.actor_assign == nil

    assert CrudSpec.new(MyApp.User, action, :list_function, actor_assign: :current_user).actor_assign ==
             :current_user

    assert CrudSpec.new(MyApp.User, action, :list_function, []).actor_assign == nil

    resource_config = %{schema: ProductLocation, name: :product_location}

    for key <- @auix_action_keys do
      connector =
        ContextParserDefaults.option_value(
          %{},
          resource_config,
          [ash_actor_assign: :current_user],
          key
        )

      assert %Connector{type: :ash, crud_spec: %CrudSpec{actor_assign: :current_user}} = connector,
             "expected actor_assign: :current_user on CrudSpec for #{inspect(key)}"
    end

    assert %Connector{crud_spec: %CrudSpec{actor_assign: :viewer}} =
             ContextParserDefaults.option_value(
               %{},
               resource_config,
               [actor_assign: :viewer],
               :list_function
             )

    assert %Connector{crud_spec: %CrudSpec{actor_assign: nil}} =
             ContextParserDefaults.option_value(%{}, resource_config, [], :list_function)

    assert %Connector{crud_spec: %CrudSpec{actor_assign: nil}} =
             ContextParserDefaults.option_value(
               %{},
               resource_config,
               [ash_actor_assign: "current_user"],
               :list_function
             )
  end
end
