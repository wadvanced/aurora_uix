defmodule Aurora.UixWeb.Test.Mirror.Variants.OneToManyComponent do
  @moduledoc """
  The `one-to-many-component` views variant: a one-to-many list rendered by the index component
  of another resource over the same schema.

  ## Key Features

  - Declares a compact product resource with its own index, form and show components
  - Points the products list of a location at the compact resource

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.OneToManyComponent` and
    `Aurora.UixWeb.Test.MirrorCtx.OneToManyComponent`
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

      mirror_resource(:product_compact, schema: :product)
      mirror_resource(:product)

      mirror_resource :product_location do
        field(:products, resource: :product_compact)
      end

      auix_create_ui do
        index_columns(:product_compact, [:reference, :name], module_name: :index_compact)
        edit_layout(:product_compact, use: :product_form_component)
        show_layout(:product_compact, use: :product_show_component)
        index_live(:product_compact, module_name: :compact_products)

        show_layout :product_location do
          stacked([:reference, :name, :products])
        end
      end
    end
  end
end
