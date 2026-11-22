defmodule Aurora.Uix.Test.MirrorCtx.ProductSupplier do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset, warn: false

  alias Aurora.Uix.Test.MirrorCtx.Product
  alias Aurora.Uix.Test.MirrorCtx.Supplier

  @primary_key false
  @foreign_key_type :binary_id
  @schema_prefix "mirror"
  @timestamps_opts [type: :utc_datetime_usec]
  schema "product_suppliers" do
    belongs_to(:product, Product, primary_key: true)
    belongs_to(:supplier, Supplier, primary_key: true)
  end

  @type t :: %__MODULE__{
          product_id: Ecto.UUID.t() | nil,
          supplier_id: Ecto.UUID.t() | nil
        }
end
