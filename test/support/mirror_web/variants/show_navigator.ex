defmodule Aurora.UixWeb.Test.Mirror.Variants.ShowNavigator do
  @moduledoc """
  The `show-navigator` views variant: the placement of the record navigator.

  ## Key Features

  - Declares product show with no navigator and product edit with a bottom navigator
  - Declares product location show with a top navigator and product location edit with the
    default one

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.ShowNavigator` and
    `Aurora.UixWeb.Test.MirrorCtx.ShowNavigator`
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

      auix_create_ui do
        index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)

        show_layout :product, record_navigator: :none do
          stacked do
            inline([:reference, :name, :description])
            inline([:quantity_initial, :quantity_at_hand])
          end
        end

        edit_layout :product, record_navigator: :bottom do
          stacked do
            inline([:reference, :name, :description])
            inline([:quantity_initial, :quantity_at_hand])
          end
        end

        show_layout :product_location, record_navigator: :top do
          stacked([:reference, :name, :type])
        end

        edit_layout :product_location do
          stacked([:reference, :name, :type])
        end
      end
    end
  end
end
