defmodule Aurora.UixWeb.Test.Mirror.Variants.ManyToOne do
  @moduledoc """
  The `many-to-one` views variant: a many-to-one select labelled from an atom, from a function of
  the entity and from a function of the assigns, with the parent fields of the relation.

  ## Key Features

  - Declares the product location select with an atom label and an ordered option list
  - Declares the product transaction and product barcode selects with function labels
  - Shows the parent fields of the product location in the product layout

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.ManyToOne` and
    `Aurora.UixWeb.Test.MirrorCtx.ManyToOne`
  """

  alias Aurora.UixWeb.Test.Mirror.Variants.ManyToOne

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
        field(:product_location_id, option_label: :name, query_opts: [order_by: [desc: :name]])
      end

      mirror_resource :product_transaction do
        field(:product_id, option_label: &ManyToOne.option_label/1)
      end

      mirror_resource :product_barcode do
        field(:product_id, option_label: &ManyToOne.option_label/2)
      end

      auix_create_ui do
        index_columns(:product_transaction, [:type, :quantity])
        index_columns(:product_barcode, [:code, :symbology])

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
            {:product_location, :name},
            product_location: :type
          ])
        end

        edit_layout :product_transaction do
          stacked([:type, :quantity, :cost, :product_id])
        end

        edit_layout :product_barcode do
          stacked([:code, :symbology, :product_id])
        end
      end
    end
  end

  @doc false
  @spec option_label(map()) :: binary()
  def option_label(entity), do: "The #{entity.name}"

  @doc false
  @spec option_label(map(), map()) :: binary()
  def option_label(assigns, entity), do: "#{assigns.auix.layout_type}: #{entity.name}"
end
