defmodule Aurora.UixWeb.Test.Mirror.Variants.Events do
  @moduledoc """
  The `events` views variant: product views whose events reach other views.

  ## Key Features

  - Declares the product index with an events probe handler and the product edit and show layouts
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Events` and `Aurora.UixWeb.Test.MirrorCtx.Events`
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

      mirror_resource(:product_location)
      mirror_resource(:product_transaction)
      mirror_resource(:product)

      auix_create_ui do
        index_columns(:product, [:reference, :name],
          handler_module: Aurora.UixWeb.Test.Mirror.Handlers.EventsProbeIndexHandler
        )

        edit_layout :product do
          stacked([:reference, :name, :quantity_initial, :product_transactions])
        end

        show_layout :product do
          stacked([:reference, :name])
        end
      end
    end
  end
end
