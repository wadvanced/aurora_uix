defmodule Aurora.UixWeb.Test.Mirror.Variants.Form do
  @moduledoc """
  The `form` views variant: a product form and show view with one field of every type.

  ## Key Features

  - Declares a product form and show view stacking a text, textarea, number, date, time,
    datetime, boolean, select, enum, multi-select and many-to-one field
  - Enables the `inactive` boolean and disables `deleted`, so a form sets one and shows the other
  - Lists the products by reference, with their labels

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Form` and `Aurora.UixWeb.Test.MirrorCtx.Form`
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
        field(:deleted, disabled: true)
        field(:inactive, disabled: false)
        field(:description, html_type: :textarea)

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
        field(:products, omitted: true)
      end

      auix_create_ui do
        index_columns(:product, [:reference, :name, :labels])

        edit_layout :product do
          stacked([
            :reference,
            :name,
            :description,
            :quantity_initial,
            :units_per_box,
            :margin,
            :list_price,
            :released_on,
            :opens_at,
            :audited_at,
            :discontinued_at,
            :status,
            :grade,
            :inactive,
            :deleted,
            :labels,
            :product_location_id
          ])
        end

        show_layout :product do
          stacked([
            :reference,
            :name,
            :description,
            :quantity_initial,
            :units_per_box,
            :margin,
            :list_price,
            :released_on,
            :opens_at,
            :audited_at,
            :discontinued_at,
            :status,
            :grade,
            :inactive,
            :deleted,
            :labels,
            :product_location_id
          ])
        end
      end
    end
  end
end
