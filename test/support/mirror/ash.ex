defmodule Aurora.Uix.Test.MirrorAsh do
  @moduledoc false

  use Ash.Domain

  resources do
    resource Aurora.Uix.Test.MirrorAsh.ProductLocation
    resource Aurora.Uix.Test.MirrorAsh.Product
    resource Aurora.Uix.Test.MirrorAsh.ProductTransaction
    resource Aurora.Uix.Test.MirrorAsh.ProductBarcode
    resource Aurora.Uix.Test.MirrorAsh.Supplier
    resource Aurora.Uix.Test.MirrorAsh.ProductSupplier
  end
end
