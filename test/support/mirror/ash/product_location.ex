defmodule Aurora.Uix.Test.MirrorAsh.ProductLocation do
  @moduledoc false

  use Ash.Resource, data_layer: AshPostgres.DataLayer, domain: Aurora.Uix.Test.MirrorAsh

  alias Aurora.Uix.Test.MirrorAsh.Product

  postgres do
    table "product_locations"
    schema "mirror"
    repo(Aurora.Uix.Repo)
    migrate?(false)
  end

  attributes do
    uuid_primary_key :id

    attribute :reference, :string, constraints: [max_length: 30], public?: true
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :type, :string, allow_nil?: false, constraints: [max_length: 20], public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :products, Product
  end

  actions do
    default_accept [:reference, :name, :type]
    defaults [:destroy, :create, :update]

    read :read do
      primary? true
      pagination required?: false, offset?: true
    end

    read :read_all
  end

  aggregates do
    count :products_count, :products

    first :latest_product_name, :products, :name do
      sort inserted_at: :desc
    end

    list :product_names, :products, :name
    max :last_discontinued_at, :products, :discontinued_at
  end
end
