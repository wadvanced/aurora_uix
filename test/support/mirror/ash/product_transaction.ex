defmodule Aurora.Uix.Test.MirrorAsh.ProductTransaction do
  @moduledoc false

  use Ash.Resource, data_layer: AshPostgres.DataLayer, domain: Aurora.Uix.Test.MirrorAsh

  alias Aurora.Uix.Test.MirrorAsh.Product

  postgres do
    table "product_transactions"
    schema "mirror"
    repo(Aurora.Uix.Repo)
    migrate?(false)
  end

  attributes do
    uuid_primary_key :id

    attribute :type, :string, allow_nil?: false, constraints: [max_length: 20], public?: true
    attribute :quantity, :decimal, allow_nil?: false, constraints: [min: 0], public?: true
    attribute :cost, :decimal, allow_nil?: false, constraints: [min: 0], public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :product, Product, allow_nil?: false, public?: true
  end

  actions do
    default_accept [:type, :quantity, :cost, :product_id]
    defaults [:destroy, :create, :update]

    read :read do
      primary? true
      pagination required?: false, offset?: true
    end
  end
end
