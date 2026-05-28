defmodule AshActorTest.PublicItem do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    domain: AshActorTest.PolicyDomain

  ets do
    private? false
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
  end

  actions do
    default_accept [:name]
    defaults [:read, :destroy, :update, :create]
  end
end
