defmodule Aurora.UixWeb.Test.Mirror.Variants.IndexQuery do
  @moduledoc """
  The `index-query` views variant: the layout order, a runtime `where`, paging and infinite
  scroll.

  ## Key Features

  - Declares a product index ordered by name, whose handler adds a runtime `where`
  - Declares a product locations index with `pagination_disabled?`

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.IndexQuery` and
    `Aurora.UixWeb.Test.MirrorCtx.IndexQuery`
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

      mirror_resource(:product_location)

      auix_create_ui do
        index_columns(:product, [:id, :reference, :name, :cost],
          order_by: :name,
          handler_module: Aurora.UixWeb.Test.Mirror.Handlers.LoadItemsOptionsHandler
        )

        index_columns(:product_location, [:reference, :name],
          order_by: :name,
          pagination_disabled?: true
        )
      end
    end
  end
end
