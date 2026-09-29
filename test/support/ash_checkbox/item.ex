defmodule Aurora.UixWeb.Test.AshCheckbox.Item do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    domain: Aurora.UixWeb.Test.AshCheckbox.Domain

  ets do
    private? false
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :active?, :boolean, allow_nil?: false, default: true, public?: true
    attribute :is_deleted, :boolean, allow_nil?: false, default: false, public?: true
  end

  actions do
    default_accept [:name, :active?, :is_deleted]
    defaults [:read, :destroy, :update, :create]
  end
end
