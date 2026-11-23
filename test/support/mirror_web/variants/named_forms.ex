defmodule Aurora.UixWeb.Test.Mirror.Variants.NamedForms do
  @moduledoc """
  The `named-forms` views variant: a named form component that other variants use.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.NamedForms` and `Aurora.UixWeb.Test.MirrorCtx.NamedForms`
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

      auix_create_ui generate: [:form_component, :show_component] do
        edit_layout :product, module_name: :reference_form do
          inline([:reference, :name])
        end
      end
    end
  end
end
