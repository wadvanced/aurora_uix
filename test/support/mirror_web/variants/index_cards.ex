defmodule Aurora.UixWeb.Test.Mirror.Variants.IndexCards do
  @moduledoc """
  The `index-cards` views variant: declared index cards.

  ## Key Features

  - Declares a product card with a title, a subtitle and a group
  - Declares a product transactions card with a function title, shown on every screen

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.IndexCards` and
    `Aurora.UixWeb.Test.MirrorCtx.IndexCards`
  """

  alias Aurora.UixWeb.Test.Mirror.Variants.IndexCards

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
      mirror_resource(:product_transaction)

      auix_create_ui do
        index_columns :product, [:reference, :name, :description, :quantity_at_hand] do
          card title: :name, subtitle: :reference do
            group "Stock" do
              field(:quantity_at_hand, label: "On hand")
            end
          end
        end

        index_columns :product_transaction, [:type, :quantity, :cost, :product] do
          card title: &IndexCards.card_title/1,
               subtitle: "Transaction",
               show_on: :all do
            inline([:quantity, :product])
          end
        end
      end
    end
  end

  @doc false
  @spec card_title(map()) :: binary()
  def card_title(assigns), do: "#" <> assigns.entity.type
end
