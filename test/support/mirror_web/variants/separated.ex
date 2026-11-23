defmodule Aurora.UixWeb.Test.Mirror.Variants.Separated do
  @moduledoc """
  The `separated` views variant: resources taken from another module.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Separated` and `Aurora.UixWeb.Test.MirrorCtx.Separated`
  """

  alias Aurora.UixWeb.Test.Mirror

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    resources = Mirror.sibling(opts[:backend], SeparatedResources)

    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      @auix_resource_metadata %{product: unquote(resources).auix_resource(:product)}
      @auix_resource_metadata %{
        product_transaction: unquote(resources).auix_resource(:product_transaction)
      }

      auix_create_ui do
        edit_layout :product, [] do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end
      end
    end
  end
end
