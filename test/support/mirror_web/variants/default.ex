defmodule Aurora.UixWeb.Test.Mirror.Variants.Default do
  @moduledoc """
  The `default` views variant: every mirrored resource with the default layouts.

  ## Key Features

  - Declares the five mirrored resources with no option
  - Generates the index, form and show views from the default layouts

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Default` and `Aurora.UixWeb.Test.MirrorCtx.Default`
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
      mirror_resource(:product_barcode)
      mirror_resource(:supplier)

      auix_create_ui()
    end
  end
end
