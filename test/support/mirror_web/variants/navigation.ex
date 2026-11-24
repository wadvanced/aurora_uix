defmodule Aurora.UixWeb.Test.Mirror.Variants.Navigation do
  @moduledoc """
  The `navigation` views variant: product index and form with child transactions, for the navigation scenarios.

  ## Key Features

  - Declares the product index columns and an edit layout that lists the product transactions
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Navigation` and `Aurora.UixWeb.Test.MirrorCtx.Navigation`
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

      mirror_resource(:product_transaction)
      mirror_resource(:product)

      auix_create_ui do
        index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)

        edit_layout :product do
          stacked([:reference, :name, :description, :quantity_initial, :product_transactions])
        end
      end
    end
  end
end
