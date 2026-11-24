defmodule Aurora.UixWeb.Test.Mirror.Variants.OneToOne do
  @moduledoc """
  The `one-to-one` views variant: a product with its barcode as nested inputs in the form and
  read-only in the show view.

  ## Key Features

  - Lists the barcode association in the product form and show layouts
  - Lists the foreign key of the barcode in its form layout, which the renderer strips

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.OneToOne` and
    `Aurora.UixWeb.Test.MirrorCtx.OneToOne`
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
      mirror_resource(:product_barcode)

      auix_create_ui do
        edit_layout :product do
          stacked([:reference, :name, :quantity_initial, :product_barcode])
        end

        edit_layout :product_barcode do
          stacked([:code, :symbology, :registered_at, :product_id])
        end

        show_layout :product do
          stacked([:reference, :name, :product_barcode])
        end

        show_layout :product_barcode do
          stacked([:code, :symbology, :registered_at])
        end
      end
    end
  end
end
