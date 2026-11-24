defmodule Aurora.UixWeb.Test.Mirror.Variants.ContextFunctions do
  @moduledoc false

  alias Aurora.Uix.Test.MirrorCtx

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
      use Aurora.Uix

      auix_resource_metadata(:product,
        context: MirrorCtx,
        schema: MirrorCtx.Product,
        backend_opts: [
          list_function_paginated: &MirrorCtx.list_products_paginated/1
        ]
      )

      auix_create_ui do
        index_columns(:product, [:reference, :name])
      end
    end
  end
end
