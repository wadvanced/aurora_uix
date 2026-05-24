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
  @moduledoc """
  End-to-end actor-threading tests against a real policy-protected Ash resource.

  Pins AC-2 / AC-3 / AC-6 / AC-7 from issue #253:
  - Passing `actor:` to `Ash.Crud.list/2`, `create/3`, `update/4` succeeds when the
    actor satisfies `actor_present()`.
  - Omitting `actor:` returns an empty read and rejects writes with
    `Ash.Error.Forbidden` (never crashes).
  - The actor flows through `socket_opts/2` end-to-end, mirroring what handlers do.
  """
  use ExUnit.Case, async: true

  alias Ash.Resource.Info, as: AshInfo
  alias Aurora.Uix.Integration.Ash.Crud, as: AshCrud
  alias Aurora.Uix.Integration.Ash.CrudPolicyTest.Item
  alias Aurora.Uix.Integration.Ash.CrudSpec

  @actor %{id: "actor-1"}

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

  describe "list/2 with policy: authorize_if actor_present()" do
    setup do
      {:ok, _item} =
        AshCrud.create(create_spec(), %{name: "visible"}, actor: @actor)

      :ok
    end

    test "returns rows when actor is present" do
      results = AshCrud.list(list_spec(), actor: @actor)
      assert is_list(results)
      assert Enum.any?(results, &(&1.name == "visible"))
    end

    test "returns [] when actor is absent (policy filters)" do
      assert AshCrud.list(list_spec(), []) == []
    end
  end

  describe "create/3 with policy: authorize_if actor_present()" do
    test "succeeds when actor is present" do
      assert {:ok, item} = AshCrud.create(create_spec(), %{name: "ok"}, actor: @actor)
      assert item.name == "ok"
    end

    test "returns {:error, %Ash.Error.Forbidden{}} when actor is absent (never raises)" do
      assert {:error, %Ash.Error.Forbidden{}} =
               AshCrud.create(create_spec(), %{name: "blocked"}, [])
    end
  end

  describe "update/4 with policy: authorize_if actor_present()" do
    test "succeeds when actor is present" do
      {:ok, item} = AshCrud.create(create_spec(), %{name: "original"}, actor: @actor)

      assert {:ok, updated} =
               AshCrud.update(update_spec(), item, %{name: "renamed"}, actor: @actor)

      assert updated.name == "renamed"
    end

    test "returns {:error, %Ash.Error.Forbidden{}} when actor is absent" do
      {:ok, item} = AshCrud.create(create_spec(), %{name: "original"}, actor: @actor)

      assert {:error, %Ash.Error.Forbidden{}} =
               AshCrud.update(update_spec(), item, %{name: "renamed"}, [])
    end
  end

  describe "delete/3 with policy: authorize_if actor_present()" do
    test "succeeds when actor is present" do
      {:ok, item} = AshCrud.create(create_spec(), %{name: "to-delete"}, actor: @actor)

      assert {:ok, _} = AshCrud.delete(delete_spec(), item, actor: @actor)
    end

    test "returns {:error, %Ash.Error.Forbidden{}} when actor is absent" do
      {:ok, item} = AshCrud.create(create_spec(), %{name: "to-delete"}, actor: @actor)

      assert {:error, %Ash.Error.Forbidden{}} =
               AshCrud.delete(delete_spec(), item, [])
    end
  end

  describe "end-to-end via socket_opts/2 (handler-level flow)" do
    test "actor resolved from socket.assigns flows through list/2" do
      {:ok, _item} =
        AshCrud.create(create_spec(), %{name: "from-handler"}, actor: @actor)

      socket = %{assigns: %{current_user: @actor}}
      socket_opts = AshCrud.socket_opts(list_spec(), socket)

      results = AshCrud.list(list_spec(), socket_opts)
      assert Enum.any?(results, &(&1.name == "from-handler"))
    end

    test "missing actor in socket.assigns yields empty results, not a crash" do
      {:ok, _item} =
        AshCrud.create(create_spec(), %{name: "from-handler"}, actor: @actor)

      socket = %{assigns: %{}}
      socket_opts = AshCrud.socket_opts(list_spec(), socket)

      assert socket_opts == []
      assert AshCrud.list(list_spec(), socket_opts) == []
    end
  end
end
