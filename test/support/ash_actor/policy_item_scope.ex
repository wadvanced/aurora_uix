defmodule AshActorTest.PolicyItemScope do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    domain: AshActorTest.PolicyDomain,
    authorizers: [Ash.Policy.Authorizer]

  ets do
    private? false
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
  end

  policies do
    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if actor_present()
    end
  end

  actions do
    default_accept [:name]
    defaults [:read, :destroy, :update, :create]
  end
end
