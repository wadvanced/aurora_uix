defmodule Aurora.UixWeb.Test.Mirror.Variants.Named do
  @moduledoc """
  The `named` views variant: an imported form component and a named live view.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Named` and `Aurora.UixWeb.Test.MirrorCtx.Named`
  """

  alias Aurora.UixWeb.Test.Mirror

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    forms = Mirror.sibling(opts[:backend], NamedForms)

    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      @auix_modules %{reference_form: unquote(forms).auix_module(:reference_form)}
      mirror_resource(:product_location)

      auix_create_ui do
        edit_layout(:product_location, use: :reference_form)
        index_live(:product_location, module_name: :locations)
      end
    end
  end
end
