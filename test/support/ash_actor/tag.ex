defmodule AshActorTest.Tag do
  @moduledoc false
  use Ash.Resource, data_layer: :embedded

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
  end

  actions do
    default_accept [:name]
    defaults [:read, :destroy, :create, :update]
  end
end
