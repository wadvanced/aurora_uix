defmodule Aurora.UixWeb.Test.Mirror.Variants.HooksIndex do
  @moduledoc """
  The `hooks_index` views variant: product index with a custom index handler.

  ## Key Features

  - Declares the product index columns with an index handler module and the edit and show layouts
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.HooksIndex` and `Aurora.UixWeb.Test.MirrorCtx.HooksIndex`
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

      auix_create_ui do
        index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand],
          handler_module: Aurora.UixWeb.Test.Mirror.Handlers.IndexHandlerHook
        )

        edit_layout :product do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end

        show_layout :product do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end
      end
    end
  end
end
