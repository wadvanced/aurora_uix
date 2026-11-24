defmodule Aurora.UixWeb.Test.Mirror.Variants.ComponentsPaired do
  @moduledoc """
  The `components_paired` views variant: components paired with a host.

  ## Key Features

  - Declares a compact product index and a reference form for hosts that pair with them
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.ComponentsPaired` and `Aurora.UixWeb.Test.MirrorCtx.ComponentsPaired`
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
      mirror_resource(:product_location)

      auix_create_ui generate: [:index_component, :form_component, :show_component] do
        index_columns(:product, [:reference, :name], module_name: :index_compact)

        edit_layout :product, module_name: :reference_form do
          inline([:reference, :name])
        end
      end
    end
  end
end
