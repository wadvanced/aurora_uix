defmodule Aurora.UixWeb.Test.Mirror.Variants.ManualResource do
  @moduledoc false

  @doc false
  @spec resources() :: %{atom() => Aurora.Uix.Resource.t()}
  def resources do
    %{
      product_location: %Aurora.Uix.Resource{
        name: :product_location,
        schema: Aurora.Uix.Test.MirrorCtx.ProductLocation,
        context: Aurora.Uix.Test.MirrorCtx,
        fields: %{
          name: %Aurora.Uix.Field{
            key: :name,
            name: "name",
            label: "Name",
            placeholder: "Name"
          },
          type: %Aurora.Uix.Field{
            key: :type,
            name: "type",
            label: "Type",
            placeholder: "Type"
          },
          reference: %Aurora.Uix.Field{
            key: :reference,
            name: "reference",
            label: "Reference",
            placeholder: "Reference"
          }
        }
      },
      product_transaction: %Aurora.Uix.Resource{
        name: :product_transaction,
        schema: Aurora.Uix.Test.MirrorCtx.ProductTransaction,
        context: Aurora.Uix.Test.MirrorCtx,
        fields: %{
          type: %Aurora.Uix.Field{
            key: :type,
            name: "type",
            label: "Type",
            placeholder: "Type"
          },
          product: %Aurora.Uix.Field{
            key: :product,
            type: :many_to_one_association,
            name: "product",
            label: "",
            placeholder: "",
            data: %{
              resource: :product,
              owner_key: :product_id,
              related: Aurora.Uix.Test.MirrorCtx.Product,
              related_key: :id
            }
          },
          quantity: %Aurora.Uix.Field{
            key: :quantity,
            type: :decimal,
            html_type: :number,
            name: "quantity",
            label: "Quantity",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          },
          cost: %Aurora.Uix.Field{
            key: :cost,
            type: :decimal,
            html_type: :number,
            name: "cost",
            label: "Cost",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          },
          product_id: %Aurora.Uix.Field{
            key: :product_id,
            type: :binary_id,
            html_type: :select,
            name: "product_id",
            label: "Product",
            placeholder: "Product_id",
            data: %{
              resource: :product,
              owner_key: :product_id,
              related: Aurora.Uix.Test.MirrorCtx.Product,
              related_key: :id
            }
          }
        }
      },
      product: %Aurora.Uix.Resource{
        name: :product,
        schema: Aurora.Uix.Test.MirrorCtx.Product,
        context: Aurora.Uix.Test.MirrorCtx,
        fields: %{
          name: %Aurora.Uix.Field{
            key: :name,
            name: "name",
            label: "Name",
            placeholder: "Name"
          },
          status: %Aurora.Uix.Field{
            key: :status,
            name: "status",
            label: "Status",
            placeholder: "Status"
          },
          length: %Aurora.Uix.Field{
            key: :length,
            type: :decimal,
            html_type: :number,
            name: "length",
            label: "Length",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          },
          description: %Aurora.Uix.Field{
            key: :description,
            name: "description",
            label: "Description",
            placeholder: "Description"
          },
          reference: %Aurora.Uix.Field{
            key: :reference,
            name: "reference",
            label: "Reference",
            placeholder: "Reference"
          },
          image: %Aurora.Uix.Field{
            key: :image,
            type: :binary,
            name: "image",
            label: "Image",
            placeholder: "Image"
          },
          width: %Aurora.Uix.Field{
            key: :width,
            type: :decimal,
            html_type: :number,
            name: "width",
            label: "Width",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          },
          product_transactions: %Aurora.Uix.Field{
            key: :product_transactions,
            type: :one_to_many_association,
            name: "product_transactions",
            label: "",
            placeholder: "",
            filterable?: false,
            data: %{
              resource: :product_transaction,
              related: Aurora.Uix.Test.MirrorCtx.ProductTransaction,
              related_key: :product_id,
              owner_key: :id
            }
          },
          product_location_id: %Aurora.Uix.Field{
            key: :product_location_id,
            type: :binary_id,
            html_type: :select,
            name: "product_location_id",
            label: "Product location id",
            placeholder: "Product_location_id",
            data: %{
              resource: :product_location,
              owner_key: :product_location_id,
              related: Aurora.Uix.Test.MirrorCtx.ProductLocation,
              option_label: :name,
              related_key: :id
            }
          },
          quantity_at_hand: %Aurora.Uix.Field{
            key: :quantity_at_hand,
            type: :decimal,
            html_type: :number,
            name: "quantity_at_hand",
            label: "Quantity at hand",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          },
          quantity_initial: %Aurora.Uix.Field{
            key: :quantity_initial,
            type: :decimal,
            html_type: :number,
            name: "quantity_initial",
            label: "Quantity initial",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          },
          rrp: %Aurora.Uix.Field{
            key: :rrp,
            type: :decimal,
            html_type: :number,
            name: "rrp",
            label: "Rrp",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          },
          list_price: %Aurora.Uix.Field{
            key: :list_price,
            type: :decimal,
            html_type: :number,
            name: "list_price",
            label: "List price",
            placeholder: "0",
            length: 12,
            precision: 10,
            scale: 2
          }
        }
      }
    }
  end

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
      use Aurora.Uix

      @auix_resource_metadata Aurora.UixWeb.Test.Mirror.Variants.ManualResource.resources()

      auix_create_ui do
        index_columns(:product, [:reference, :name, :description, :product_location_id],
          order_by: :name
        )

        edit_layout :product, [] do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
          inline([:product_location_id])
          inline([:product_transactions])
        end
      end
    end
  end
end
