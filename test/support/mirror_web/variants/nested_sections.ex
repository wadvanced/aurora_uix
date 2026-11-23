defmodule Aurora.UixWeb.Test.Mirror.Variants.NestedSections do
  @moduledoc """
  The `nested-sections` views variant: a product form laid out in nested sections.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.NestedSections` and `Aurora.UixWeb.Test.MirrorCtx.NestedSections`
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
        edit_layout :product, [] do
          # sections_index_1
          sections do
            # sections_index_1 tab_index_1
            section "References" do
              inline([:reference, :name])

              # sections_index_2
              sections do
                # sections_index_2 tab_index_1
                section "Descriptions" do
                  inline([:description, :status])
                end

                # sections_index_2 tab_index_2
                section "Specifications" do
                  stacked do
                    inline([:width, :height, :length])
                    inline([:weight])
                  end
                end
              end
            end

            # sections_index_1 tab_index_2
            section "Information" do
              # sections_index_3
              sections do
                # sections_index_3 tab_index_1
                section "Quantities" do
                  inline([:quantity_at_hand, :quantity_initial])
                end

                # sections_index_3 tab_index_2
                section "Sale Prices", default: true do
                  stacked([:list_price, :rrp])
                end
              end
            end
          end
        end
      end
    end
  end
end
