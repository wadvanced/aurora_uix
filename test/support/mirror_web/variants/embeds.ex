defmodule Aurora.UixWeb.Test.Mirror.Variants.Embeds do
  @moduledoc """
  The `embeds` views variant: a product with an embedded packaging and embedded contacts.

  ## Key Features

  - Lists the packaging and the contacts in the product form layout
  - Lists the packaging and the contacts as index columns

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Embeds` and `Aurora.UixWeb.Test.MirrorCtx.Embeds`
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
        index_columns(:product, [:reference, :name, :packaging, :contacts])

        edit_layout :product, new_title: "Embeds" do
          stacked do
            inline([:reference, :name])
            inline([:quantity_initial])
            stacked([:packaging, :contacts])
          end
        end
      end
    end
  end
end
