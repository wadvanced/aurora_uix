defmodule Aurora.UixWeb.Test.Mirror.Variants.Groups do
  @moduledoc """
  The `groups` views variant: a product form laid out in groups.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Groups` and `Aurora.UixWeb.Test.MirrorCtx.Groups`
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
        edit_layout :product, [] do
          inline([:reference, :name, :description])

          group "Quantities" do
            inline([:quantity_at_hand, :quantity_initial])
          end

          group "Sale Prices" do
            stacked([:list_price, :rrp])
          end
        end
      end
    end
  end
end
