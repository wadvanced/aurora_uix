defmodule Aurora.UixWeb.Test.Mirror.Variants.ComponentsHandled do
  @moduledoc """
  The `components_handled` views variant: index component with a component handler.

  ## Key Features

  - Declares the product index component with a component handler module
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.ComponentsHandled` and `Aurora.UixWeb.Test.MirrorCtx.ComponentsHandled`
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

      auix_create_ui generate: [:index_component] do
        index_columns(:product, [:reference],
          component_handler_module: Aurora.UixWeb.Test.Mirror.Handlers.ComponentsIndexHandler
        )
      end
    end
  end
end
