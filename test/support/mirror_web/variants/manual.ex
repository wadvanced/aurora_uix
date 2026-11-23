defmodule Aurora.UixWeb.Test.Mirror.Variants.Manual do
  @moduledoc """
  The `manual` views variant: edit and show layouts declared with auix_create_layout.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Manual` and `Aurora.UixWeb.Test.MirrorCtx.Manual`
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

      mirror_resource(:product)
      mirror_resource(:product_location)
      mirror_resource(:product_transaction)

      auix_create_layout do
        edit_layout :product, [] do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
          inline([:product_location_id])
          inline([:product_transactions])
        end
      end

      auix_create_layout do
        show_layout :product, [] do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:product_location_id])
          inline([:product_transactions])
        end
      end

      auix_create_ui do
        index_columns(:product, [:reference, :name, :description, :product_location_id],
          order_by: :name
        )
      end
    end
  end
end
