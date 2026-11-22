defmodule Aurora.Uix.Test.MirrorAsh.ProductSupplier do
  @moduledoc false

  use Ash.Resource, data_layer: AshPostgres.DataLayer, domain: Aurora.Uix.Test.MirrorAsh

  alias Aurora.Uix.Test.MirrorAsh.Product
  alias Aurora.Uix.Test.MirrorAsh.Supplier

  postgres do
    table "product_suppliers"
    schema "mirror"
    repo(Aurora.Uix.Repo)
    migrate?(false)
  end

  relationships do
    belongs_to :product, Product, primary_key?: true, allow_nil?: false
    belongs_to :supplier, Supplier, primary_key?: true, allow_nil?: false
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end
end
