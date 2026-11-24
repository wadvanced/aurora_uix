defmodule Aurora.UixWeb.Test.Mirror.Variants.HooksShow do
  @moduledoc """
  The `hooks_show` views variant: product show with a custom show handler.

  ## Key Features

  - Declares the product edit layout with a show handler module and the product transactions
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.HooksShow` and `Aurora.UixWeb.Test.MirrorCtx.HooksShow`
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
        edit_layout :product,
          show_handler_module: Aurora.UixWeb.Test.Mirror.Handlers.ShowHandlerHook do
          stacked([:reference, :name, :description, :quantity_initial, :product_transactions])
        end
      end
    end
  end
end
