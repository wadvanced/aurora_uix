defmodule Aurora.UixWeb.Test.Mirror.Variants.IndexWhere do
  @moduledoc """
  The `index-where` views variant: a layout `where` with the layout order.

  ## Key Features

  - Declares a product index ordered by name and bounded by a reference `where`

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.IndexWhere` and
    `Aurora.UixWeb.Test.MirrorCtx.IndexWhere`
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

      mirror_resource :product do
        order_by(:reference)
      end

      auix_create_ui do
        index_columns(:product, [:reference, :name],
          order_by: :name,
          where: [{:reference, :between, "item_group_2b", "item_group_3d"}]
        )
      end
    end
  end
end
