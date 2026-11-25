defmodule Aurora.UixWeb.Test.Mirror.Variants.Index do
  @moduledoc """
  The `index` views variant: sortable and opted-out columns, field types in cells, filters and
  a disabled sort.

  ## Key Features

  - Declares a product index with sortable, opted-out and upload columns, a select status, a
    many-to-one location, multi-value labels and an enum grade
  - Declares a product locations index without sortable fields
  - Declares a suppliers index with `sort_disabled?`

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Index` and `Aurora.UixWeb.Test.MirrorCtx.Index`
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
        field(:cost, sortable?: false)

        field :image do
          sortable?(true)
          upload(allow: [accept: ~w(.png)], consume: &Function.identity/1)
        end

        field(:status,
          html_type: :select,
          data: %{
            select: %{
              opts: [
                "In stock": "in_stock",
                Discontinued: "discontinued",
                "Only available online": "online_only",
                "Only available in the store": "in_store_only"
              ],
              multiple: false
            }
          }
        )

        field(:product_location_id, option_label: :name)
      end

      mirror_resource :product_location do
        field(:reference, sortable?: false)
        field(:name, sortable?: false)
      end

      mirror_resource(:supplier)

      auix_create_ui do
        index_columns(:product, [
          :reference,
          :name,
          :cost,
          :image,
          :product_location_id,
          :status,
          :inactive,
          :quantity_at_hand,
          :labels,
          :grade,
          description: [sortable?: false]
        ])

        edit_layout :product do
          stacked([:reference, :name, :description, :status])
        end

        index_columns(:product_location, [:reference, :name])
        index_columns(:supplier, [:name, :country], sort_disabled?: true)
      end
    end
  end
end
