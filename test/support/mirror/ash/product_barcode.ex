defmodule Aurora.Uix.Test.MirrorAsh.ProductBarcode do
  @moduledoc false

  use Ash.Resource, data_layer: AshPostgres.DataLayer, domain: Aurora.Uix.Test.MirrorAsh

  alias Aurora.Uix.Test.MirrorAsh.Product

  postgres do
    table "product_barcodes"
    schema "mirror"
    repo(Aurora.Uix.Repo)
    migrate?(false)
  end

  attributes do
    uuid_primary_key :id

    attribute :code, :string, allow_nil?: false, constraints: [max_length: 20], public?: true

    attribute :symbology, :string,
      default: "EAN-13",
      constraints: [max_length: 20],
      public?: true

    attribute :registered_at, :date, public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :product, Product, public?: true
  end

  actions do
    default_accept [:code, :symbology, :registered_at, :product_id]
    defaults [:read, :destroy, :create, :update]
  end

  identities do
    identity :unique_product, [:product_id]
  end
end
