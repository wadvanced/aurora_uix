defmodule Aurora.UixWeb.Test.Mirror.Variants.ManyToOneQueries do
  @moduledoc """
  The `many-to-one-queries` views variant: a many-to-one select whose options are ordered and
  limited by `query_opts`.

  ## Key Features

  - Declares the product location select with an `order_by` and a `where`
  - Shows the product location as a parent record in the product layout

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.ManyToOneQueries` and
    `Aurora.UixWeb.Test.MirrorCtx.ManyToOneQueries`
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

      mirror_resource :product_location do
        field(:products, omitted: true)
      end

      mirror_resource :product do
        field(:product_location_id,
          option_label: :name,
          query_opts: [
            order_by: [desc: :name],
            where: [{:name, :between, "test-name-many2-08", "test-name-many2-14"}]
          ]
        )
      end

      auix_create_ui do
        edit_layout :product_location do
          inline([:reference, :name, :type])
        end

        edit_layout :product do
          stacked([
            :reference,
            :name,
            :description,
            :quantity_initial,
            :product_location_id,
            :product_location
          ])
        end
      end
    end
  end
end
