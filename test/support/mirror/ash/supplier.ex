defmodule Aurora.Uix.Test.MirrorAsh.Supplier do
  @moduledoc false

  use Ash.Resource, data_layer: AshPostgres.DataLayer, domain: Aurora.Uix.Test.MirrorAsh

  postgres do
    table "suppliers"
    schema "mirror"
    repo(Aurora.Uix.Repo)
    migrate?(false)
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, constraints: [max_length: 60], public?: true
    attribute :country, :string, constraints: [max_length: 40], public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    default_accept [:name, :country]
    defaults [:destroy, :create, :update]

    read :read do
      primary? true
      pagination required?: false, offset?: true
    end
  end
end
