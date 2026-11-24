defmodule Aurora.UixWeb.Test.Mirror.Variants.Components do
  @moduledoc """
  The `components` views variant: embedded index, form and show components of the product.

  ## Key Features

  - Declares the product index with five items per page and the default layouts
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Components` and `Aurora.UixWeb.Test.MirrorCtx.Components`
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
        index_columns(:product, [:reference, :name], pagination_items_per_page: 5)
      end
    end
  end
end
