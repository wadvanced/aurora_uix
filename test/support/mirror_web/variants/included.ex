defmodule Aurora.UixWeb.Test.Mirror.Variants.Included do
  @moduledoc """
  The `included` views variant: layouts included from another module.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Included` and `Aurora.UixWeb.Test.MirrorCtx.Included`
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

      auix_create_ui include: Aurora.UixWeb.Test.Mirror.IncludedLayouts do
        show_layout :product do
          inline([:name])
        end
      end
    end
  end
end
