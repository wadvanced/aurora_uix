defmodule Aurora.UixWeb.Test.Mirror.Variants.Gettext do
  @moduledoc """
  The `gettext` views variant: product views whose texts render through dt.

  ## Key Features

  - Declares the product index, edit and show layouts with two fields
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Gettext` and `Aurora.UixWeb.Test.MirrorCtx.Gettext`
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
        index_columns(:product, [:id, :reference, :name])

        edit_layout :product do
          inline([:reference, :name])
        end

        show_layout :product do
          inline([:reference, :name])
        end
      end
    end
  end
end
