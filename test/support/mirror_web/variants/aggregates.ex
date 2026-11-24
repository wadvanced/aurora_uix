defmodule Aurora.UixWeb.Test.Mirror.Variants.Aggregates do
  @moduledoc false

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource(:product_location)

      mirror_resource :product do
        order_by(discontinued_at: :desc)
      end

      auix_create_ui do
        index_columns(:product_location, [
          :name,
          :products_count,
          :latest_product_name,
          :last_discontinued_at
        ])

        edit_layout :product_location do
          stacked([
            :name,
            :reference,
            :products,
            :products_count,
            :latest_product_name,
            :product_names
          ])
        end

        edit_layout :product, new_title: "Aggregates" do
          stacked do
            inline([:status])
            stacked([:name, :description])
            stacked([:summary])
          end
        end
      end
    end
  end
end
