defmodule Aurora.UixWeb.Test.Mirror.Variants.OneToMany do
  @moduledoc """
  The `one-to-many` views variant: a one-to-many list of the transactions of a product and of the
  products of a location, ordered and limited by the resource metadata and the layout.

  ## Key Features

  - Declares the product transactions list with an `order_by`
  - Declares the products list of a location with a `where` and an `order_by` in the resource
    metadata, and an `order_by` in the layout that takes precedence
  - Fixes the index columns of the related resources so both backends list them in one order

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.OneToMany` and
    `Aurora.UixWeb.Test.MirrorCtx.OneToMany`
  """

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource :product_location do
        field(:products,
          query_opts: [
            order_by: [asc: :name],
            where: {:name, :between, "Item test-2", "Item test-4"}
          ]
        )
      end

      mirror_resource(:product_transaction)
      mirror_resource(:product)

      auix_create_ui do
        index_columns(:product_transaction, [:type, :quantity, :cost])
        index_columns(:product, [:reference, :name, :quantity_initial])

        edit_layout :product do
          stacked([
            :reference,
            :name,
            :description,
            :quantity_initial,
            product_transactions: [order_by: [desc: :quantity]]
          ])
        end

        edit_layout :product_location do
          stacked([
            :reference,
            :name,
            products: [order_by: [desc: :name]]
          ])
        end
      end
    end
  end
end
