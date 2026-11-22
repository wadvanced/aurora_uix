defmodule Aurora.Uix.Test.MirrorCtx do
  @moduledoc false

  use Aurora.Ctx

  alias Aurora.Uix.Test.MirrorCtx.{
    Product,
    ProductBarcode,
    ProductLocation,
    ProductTransaction,
    Supplier
  }

  alias Aurora.Uix.Repo

  ctx_register_schema(Product, Repo)
  ctx_register_schema(ProductTransaction, Repo)
  ctx_register_schema(ProductLocation, Repo)
  ctx_register_schema(ProductBarcode, Repo)
  ctx_register_schema(Supplier, Repo)
end
